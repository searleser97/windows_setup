# windows_setup

## Quick Start

```
winget install Git.Git --source winget
```

Open a **new terminal**, then:

```
git clone https://github.com/searleser97/windows_setup; cd windows_setup; .\run.bat
```

## Notes

To have a wezterm shortcut that opens up WSL directly we need to right click on the windows desktop
and select "new" -> "shortcut" option, then in the field "location" we should put the following
(notice the quotes and the wezterm-gui.exe program, we shouldn't use wezterm.exe here)

`"C:\Program Files\WezTerm\wezterm-gui.exe" start wsl.exe ~`

" ~ " symbol tells wsl to start in $HOME dir instead of windows home directory

example:

![image](https://github.com/user-attachments/assets/e8d04493-a902-47c2-aa40-3782de02954e)
