# windows_setup

## Quick Start

Paste the entire block below into Windows Terminal (allow multiline paste when prompted):

```powershell
winget install Git.Git --source winget
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
git clone https://github.com/searleser97/windows_setup; cd windows_setup; .\run.bat

```

## Safe reruns

Every program and setting is checked directly before it is installed or
configured. Rerunning `run.bat` skips items that are already present and
continues with anything missing; no checkpoint files or extra flags are used.
Repository-owned configuration files are copied on every run so local
destinations always receive the latest versions.

Rerunning the setup also detects and removes legacy Neovim launcher files,
registrations, and duplicate Start-menu shortcuts from older script versions.
The migration reports removed shortcuts and notifies Windows Shell so Explorer
and Start Search refresh without restarting Explorer.

## Notes

To have a wezterm shortcut that opens up WSL directly we need to right click on the windows desktop
and select "new" -> "shortcut" option, then in the field "location" we should put the following
(notice the quotes and the wezterm-gui.exe program, we shouldn't use wezterm.exe here)

`"C:\Program Files\WezTerm\wezterm-gui.exe" start wsl.exe ~`

" ~ " symbol tells wsl to start in $HOME dir instead of windows home directory

example:

![image](https://github.com/user-attachments/assets/e8d04493-a902-47c2-aa40-3782de02954e)

## Neovim Explorer integration

`logic.ps1` registers **Neovim** as the per-user default for common
text and source-code extensions, including dotfiles such as `.gitconfig`,
`.npmrc`, `.editorconfig`, and `.env`. It also adds:

- A Windows application-capabilities registration for **Open with** and
  **Default apps** discovery.
- One searchable **Neovim** Start-menu application backed by `Neovim.exe`.
- **Open in Neovim** for files, directories, and drives.
- **Open Neovim here** when right-clicking a directory background.

The GUI launcher is compiled and installed to
`%LOCALAPPDATA%\Programs\NeovimInWezTerm`, so the integration continues to work
if this repository is moved or removed. Rerun the registration script after
pulling launcher updates:

```powershell
.\Register-NeovimExplorer.ps1
```

Windows may retain protected `UserChoice` defaults that scripts cannot safely
replace. The registration script reports those extensions and opens Neovim's
dedicated **Default Apps** Settings page; select **Neovim** for the remaining
extensions there.

Windows 11 shows classic registry context-menu commands under **Show more
options**. Associated files can be opened directly by double-clicking them; the
Start-menu application opens Neovim in the user home directory.

The Scoop `nvim.exe` shim is marked hidden so Windows Search favors these
shortcuts. This does not affect running `nvim` from a terminal.

To customize the associated extensions:

```powershell
.\Register-NeovimExplorer.ps1 -Extensions '.txt', '.md', '.json', '.lua', '.ps1'
```

Normal folder double-click navigation remains unchanged. To remove the
integration and restore the per-user extension defaults captured during the
first registration:

```powershell
.\Unregister-NeovimExplorer.ps1
```
