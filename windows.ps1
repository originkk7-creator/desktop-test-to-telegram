param([switch]$Worker)
$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
$log = Join-Path $base 'transfer.log'
if (-not $Worker) {
    Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList @('-NoProfile', '-File', ('"' + $PSCommandPath + '"'), '-Worker') -WindowStyle Hidden
    Write-Host "Sending Desktop folder in background. Log: $log"
    exit
}
$archive = $null
try {
    $token = (Get-Content -LiteralPath (Join-Path $base 'token.txt') -Raw).Trim()
    $chat = (Get-Content -LiteralPath (Join-Path $base 'chat-id.txt') -Raw).Trim()
    $desktop = [Environment]::GetFolderPath('Desktop')
    $folder = Join-Path $desktop ([string][char]0x442 + [char]0x435 + [char]0x441 + [char]0x442)
    if (-not (Test-Path -LiteralPath $folder -PathType Container)) { throw "Desktop folder 'test' (Cyrillic) was not found." }
    $items = @((Get-Item -LiteralPath $folder -Force)) + @(Get-ChildItem -LiteralPath $folder -Force -Recurse)
    if ($items | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }) { throw 'Links or cloud placeholders found. Make the folder available locally and remove links first.' }
    $archive = Join-Path ([IO.Path]::GetTempPath()) ('desktop-test-' + [guid]::NewGuid().ToString('N') + '.zip')
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($folder, $archive, [IO.Compression.CompressionLevel]::Optimal, $true)
    if ((Get-Item -LiteralPath $archive).Length -gt 49000000) { throw 'ZIP exceeds 49 MB. Reduce the folder size.' }
    Add-Type -AssemblyName System.Net.Http
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $client = New-Object Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromMinutes(20)
    $form = New-Object Net.Http.MultipartFormDataContent
    $form.Add((New-Object Net.Http.StringContent($chat)), 'chat_id')
    $stream = [IO.File]::OpenRead($archive)
    $file = New-Object Net.Http.StreamContent($stream)
    $form.Add($file, 'document', ('desktop-test-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.zip'))
    try {
        $response = $client.PostAsync(('https://api.telegram.org/bot' + $token + '/sendDocument'), $form).GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) { throw ('Telegram HTTP status: ' + [int]$response.StatusCode) }
        $result = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
        if (-not $result.ok) { throw 'Telegram rejected the upload.' }
    } finally { $form.Dispose(); $client.Dispose() }
    Add-Content -LiteralPath $log -Value ((Get-Date -Format s) + ' SENT')
} catch {
    # Avoid writing request URLs or credentials into the log.
    Add-Content -LiteralPath $log -Value ((Get-Date -Format s) + ' FAILED: ' + $_.Exception.GetType().Name)
    exit 1
} finally {
    if ($archive -and (Test-Path -LiteralPath $archive)) { Remove-Item -LiteralPath $archive -Force }
}
