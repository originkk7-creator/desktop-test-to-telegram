# Desktop folder → Telegram

Archives the **тест** folder on your own Desktop and sends the ZIP to your Telegram bot chat. Uses Windows PowerShell 5.1 / .NET or built-in macOS Bash, zip and curl. No Python, Git or pip needed on the sending computer.

## Setup

Download `windows.ps1` (Windows) or `mac.command` (macOS). In the same directory create `token.txt` containing your BotFather token and `chat-id.txt` containing your private chat ID. Send `/start` to your bot first. Keep both configuration files private; they are excluded by `.gitignore`.

Windows PowerShell:
```
powershell.exe -NoProfile -File .\windows.ps1
```

macOS Terminal:
```
bash ./mac.command
```

Each command starts one background upload and returns to the terminal. You can close the terminal afterward. It does not terminate an existing shell. Results are recorded in `transfer.log` next to the script. Download the resulting ZIP from the same Telegram chat on your other computer.

## Limits

- ZIP size: at most 49,000,000 bytes; larger archives fail without uploading.
- Files must be available locally. Windows rejects links and cloud placeholders. macOS stores symlinks without following them.
- macOS may ask for Terminal access to Desktop. Windows execution policy may disallow unsigned scripts; the program does not change system policies.
- Keep source files unchanged during archiving. No automatic extraction or syncing on the receiving device.
- There is no startup persistence, incoming command handler or folder monitoring.

Syntax was checked for PowerShell. End-to-end uploads and native macOS execution have not been tested.

The repository contains no bot token or destination chat ID. Personalized launch commands should be kept private and never committed.
