# windows_setup

Run setup.ps1 in an admin terminal

To have a wezterm shortcut that opens up WSL directly we need to right click on the windows desktop
and select "new" -> "shortcut" option, then in the field "location" we should put the following
(notice the quotes and the wezterm-gui.exe program, we shouldn't use wezterm.exe here)

`"C:\Program Files\WezTerm\wezterm-gui.exe" start wsl.exe`

example:

![image](https://github.com/user-attachments/assets/e8d04493-a902-47c2-aa40-3782de02954e)
