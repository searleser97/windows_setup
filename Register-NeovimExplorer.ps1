[CmdletBinding()]
param(
    [string[]]$Extensions = @(
        ".txt", ".md", ".markdown", ".log", ".csv", ".tsv",
        ".gitconfig", ".gitignore", ".gitattributes", ".gitmodules",
        ".npmrc", ".yarnrc", ".editorconfig", ".env",
        ".prettierrc", ".eslintrc", ".babelrc",
        ".dockerignore", ".rgignore",
        ".json", ".jsonc", ".yaml", ".yml", ".toml", ".ini", ".cfg", ".conf",
        ".xml", ".lua", ".vim", ".ps1", ".psm1", ".psd1", ".bat", ".cmd",
        ".sh", ".bash", ".zsh", ".fish", ".py", ".pyi",
        ".js", ".mjs", ".cjs", ".jsx", ".ts", ".mts", ".cts", ".tsx",
        ".css", ".scss", ".sass", ".less", ".html", ".htm", ".sql",
        ".graphql", ".gql", ".c", ".h", ".cpp", ".hpp", ".cc",
        ".cs", ".java", ".kt", ".kts", ".rs", ".go", ".rb", ".php", ".pl", ".r"
    )
)

$Extensions = @(
    $Extensions |
        ForEach-Object { if ($_.StartsWith(".")) { $_ } else { ".$_" } } |
        Sort-Object -Unique
)

$progId = "Neovim.WezTerm"
$installDirectory = Join-Path $env:LOCALAPPDATA "Programs\NeovimInWezTerm"
$launcherProject = Join-Path $PSScriptRoot "NeovimInWezTermLauncher.csproj"
$launcherPath = Join-Path $installDirectory "Neovim.exe"
$installedIconPath = Join-Path $installDirectory "neovim.ico"
$backupPath = Join-Path $installDirectory "association-backup.json"
$shimHiddenMarker = Join-Path $installDirectory "scoop-nvim-shim-hidden"
$startMenuDirectory = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$startMenuShortcut = Join-Path $startMenuDirectory "Neovim.lnk"
$nvimAliasShortcut = Join-Path $startMenuDirectory "nvim.lnk"
$previousStartMenuShortcuts = @(
    (Join-Path $startMenuDirectory "Neovim (nvim) in WezTerm.lnk"),
    (Join-Path $startMenuDirectory "Neovim in WezTerm.lnk")
)

if (!(Test-Path -LiteralPath $launcherProject)) {
    throw "Launcher project not found: $launcherProject"
}

Write-Host "[1/6] Installing the Neovim in WezTerm launcher..."
$null = Get-Command pwsh.exe -ErrorAction Stop
$neovim = Get-Command nvim.exe -ErrorAction SilentlyContinue
$neovimPath = if ($neovim) {
    $neovim.Source
} else {
    Join-Path $env:USERPROFILE "scoop\shims\nvim.exe"
}
if (!(Test-Path -LiteralPath $neovimPath)) {
    throw "nvim.exe was not found. Install Neovim before registering Explorer integration."
}
$normalizedNeovimPath = [IO.Path]::GetFullPath($neovimPath)
$normalizedShimDirectory = [IO.Path]::GetFullPath(
    (Join-Path $env:USERPROFILE "scoop\shims")
)
if (
    $normalizedNeovimPath.StartsWith(
        "$normalizedShimDirectory\",
        [StringComparison]::OrdinalIgnoreCase
    ) -and
    !([IO.File]::GetAttributes($normalizedNeovimPath).HasFlag([IO.FileAttributes]::Hidden))
) {
    [IO.File]::SetAttributes(
        $normalizedNeovimPath,
        [IO.File]::GetAttributes($normalizedNeovimPath) -bor [IO.FileAttributes]::Hidden
    )
    New-Item -ItemType File -Path $shimHiddenMarker -Force | Out-Null
}
$neovimIconPath = @(
    (Join-Path $env:USERPROFILE "scoop\apps\neovim-nightly\current\bin\nvim.exe"),
    (Join-Path $env:USERPROFILE "scoop\apps\neovim\current\bin\nvim.exe"),
    $neovimPath
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
$neovimInstallRoot = Split-Path -Parent (Split-Path -Parent $neovimIconPath)
$neovimIconFile = @(
    (Join-Path $neovimInstallRoot "share\nvim\runtime\neovim.ico"),
    (Join-Path $env:USERPROFILE "scoop\apps\neovim-nightly\current\share\nvim\runtime\neovim.ico"),
    (Join-Path $env:USERPROFILE "scoop\apps\neovim\current\share\nvim\runtime\neovim.ico")
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

$wezTerm = Get-Command wezterm.exe -ErrorAction SilentlyContinue
$wezTermPath = if ($wezTerm) {
    $wezTerm.Source
} else {
    Join-Path $env:ProgramFiles "WezTerm\wezterm.exe"
}
if (!(Test-Path -LiteralPath $wezTermPath)) {
    throw "wezterm.exe was not found. Install WezTerm before registering Explorer integration."
}
$wezTermGuiPath = Join-Path (Split-Path -Parent $wezTermPath) "wezterm-gui.exe"
if (!(Test-Path -LiteralPath $wezTermGuiPath)) {
    throw "wezterm-gui.exe was not found beside wezterm.exe."
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
$null = Get-Command dotnet.exe -ErrorAction Stop
$runtimeIdentifier = switch (
    [Runtime.InteropServices.RuntimeInformation]::OSArchitecture
) {
    "X64" { "win-x64" }
    "Arm64" { "win-arm64" }
    "X86" { "win-x86" }
    default { throw "Unsupported Windows architecture: $_" }
}
$publishArguments = @(
    "publish",
    $launcherProject,
    "--configuration", "Release",
    "--runtime", $runtimeIdentifier,
    "--self-contained", "false",
    "--output", $installDirectory,
    "--nologo",
    "--verbosity", "quiet"
)
if ($neovimIconFile) {
    $publishArguments += "-p:ApplicationIcon=$neovimIconFile"
}
dotnet @publishArguments
if ($LASTEXITCODE -ne 0) {
    throw "Failed to build the Neovim GUI launcher."
}
if ($neovimIconFile) {
    Copy-Item -LiteralPath $neovimIconFile -Destination $installedIconPath -Force
    $icon = "$installedIconPath,0"
} else {
    $icon = "$launcherPath,0"
}
$legacyLauncherPaths = @(
    (Join-Path $installDirectory "Open-NeovimInWezTerm.ps1"),
    (Join-Path $installDirectory "NeovimInWezTerm.exe"),
    (Join-Path $installDirectory "nvim.exe"),
    (Join-Path $installDirectory "nvim.dll"),
    (Join-Path $installDirectory "nvim.deps.json"),
    (Join-Path $installDirectory "nvim.runtimeconfig.json")
)
foreach ($legacyLauncherPath in $legacyLauncherPaths) {
    if (Test-Path -LiteralPath $legacyLauncherPath) {
        Remove-Item -LiteralPath $legacyLauncherPath -Force
        Write-Host "Removed legacy Neovim launcher: $legacyLauncherPath"
    }
}

$command = "`"$launcherPath`" `"%1`""

function Set-RegistryDefault {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,
        [Parameter(Mandatory)]
        [string]$Value
    )

    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($RelativePath)
    try {
        $key.SetValue("", $Value, [Microsoft.Win32.RegistryValueKind]::String)
    } finally {
        $key.Dispose()
    }
}

function Set-RegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($RelativePath)
    try {
        $key.SetValue($Name, $Value, [Microsoft.Win32.RegistryValueKind]::String)
    } finally {
        $key.Dispose()
    }
}

function Set-ShellCommand {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,
        [Parameter(Mandatory)]
        [string]$Label,
        [Parameter(Mandatory)]
        [string]$Command
    )

    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($RelativePath)
    try {
        $key.SetValue("", $Label, [Microsoft.Win32.RegistryValueKind]::String)
        $key.SetValue("Icon", $icon, [Microsoft.Win32.RegistryValueKind]::String)
    } finally {
        $key.Dispose()
    }
    Set-RegistryDefault -RelativePath "$RelativePath\command" -Value $Command
}

if (!("ShortcutPropertyStore" -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ShortcutPropertyStore
{
    [DllImport("shell32.dll")]
    private static extern void SHChangeNotify(
        uint eventId,
        uint flags,
        IntPtr item1,
        IntPtr item2);

    [DllImport("shell32.dll", CharSet = CharSet.Unicode, EntryPoint = "SHChangeNotify")]
    private static extern void SHChangeNotifyPath(
        uint eventId,
        uint flags,
        string item1,
        IntPtr item2);

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    private struct PropertyKey
    {
        public Guid FormatId;
        public uint PropertyId;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PropVariant
    {
        public ushort VariantType;
        public ushort Reserved1;
        public ushort Reserved2;
        public ushort Reserved3;
        public IntPtr PointerValue;
        public IntPtr ReservedPointer;
    }

    [ComImport]
    [Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IPropertyStore
    {
        [PreserveSig]
        int GetCount(out uint propertyCount);

        [PreserveSig]
        int GetAt(uint propertyIndex, out PropertyKey key);

        [PreserveSig]
        int GetValue(ref PropertyKey key, out PropVariant value);

        [PreserveSig]
        int SetValue(ref PropertyKey key, ref PropVariant value);

        [PreserveSig]
        int Commit();
    }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern int SHGetPropertyStoreFromParsingName(
        string path,
        IntPtr bindContext,
        uint flags,
        ref Guid interfaceId,
        out IntPtr propertyStore);

    [DllImport("ole32.dll")]
    private static extern int PropVariantClear(ref PropVariant value);

    [DllImport("propsys.dll", CharSet = CharSet.Unicode)]
    private static extern int InitPropVariantFromStringVector(
        [In, MarshalAs(UnmanagedType.LPArray, ArraySubType = UnmanagedType.LPWStr)]
        string[] values,
        uint valueCount,
        out PropVariant value);

    public static void SetAppUserModelId(string shortcutPath, string appUserModelId)
    {
        SetStringProperty(
            shortcutPath,
            new PropertyKey {
                FormatId = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"),
                PropertyId = 5
            },
            appUserModelId);
    }

    public static void SetKeywords(string shortcutPath, string[] keywords)
    {
        IPropertyStore propertyStore = OpenPropertyStore(shortcutPath);
        var key = new PropertyKey {
            FormatId = new Guid("F29F85E0-4FF9-1068-AB91-08002B27B3D9"),
            PropertyId = 5
        };
        PropVariant value;
        Marshal.ThrowExceptionForHR(
            InitPropVariantFromStringVector(
                keywords,
                (uint)keywords.Length,
                out value));

        try {
            Marshal.ThrowExceptionForHR(propertyStore.SetValue(ref key, ref value));
            Marshal.ThrowExceptionForHR(propertyStore.Commit());
        } finally {
            PropVariantClear(ref value);
            Marshal.FinalReleaseComObject(propertyStore);
        }
    }

    public static string[] GetKeywords(string shortcutPath)
    {
        IPropertyStore propertyStore = OpenPropertyStore(shortcutPath);
        var key = new PropertyKey {
            FormatId = new Guid("F29F85E0-4FF9-1068-AB91-08002B27B3D9"),
            PropertyId = 5
        };
        PropVariant value;
        Marshal.ThrowExceptionForHR(propertyStore.GetValue(ref key, out value));

        try {
            if (value.VariantType != 0x101F) {
                return Array.Empty<string>();
            }

            int count = unchecked((int)(value.PointerValue.ToInt64() & 0xFFFFFFFF));
            var keywords = new string[count];
            for (int index = 0; index < count; index++) {
                IntPtr stringPointer = Marshal.ReadIntPtr(
                    value.ReservedPointer,
                    index * IntPtr.Size);
                keywords[index] = Marshal.PtrToStringUni(stringPointer) ?? "";
            }
            return keywords;
        } finally {
            PropVariantClear(ref value);
            Marshal.FinalReleaseComObject(propertyStore);
        }
    }

    private static void SetStringProperty(
        string shortcutPath,
        PropertyKey key,
        string propertyValue)
    {
        IPropertyStore propertyStore = OpenPropertyStore(shortcutPath);

        var value = new PropVariant {
            VariantType = 31,
            PointerValue = Marshal.StringToCoTaskMemUni(propertyValue)
        };

        try {
            Marshal.ThrowExceptionForHR(propertyStore.SetValue(ref key, ref value));
            Marshal.ThrowExceptionForHR(propertyStore.Commit());
        } finally {
            PropVariantClear(ref value);
            Marshal.FinalReleaseComObject(propertyStore);
        }
    }

    private static IPropertyStore OpenPropertyStore(string shortcutPath)
    {
        Guid propertyStoreId = typeof(IPropertyStore).GUID;
        IntPtr propertyStorePointer;
        Marshal.ThrowExceptionForHR(
            SHGetPropertyStoreFromParsingName(
                shortcutPath,
                IntPtr.Zero,
                2,
                ref propertyStoreId,
                out propertyStorePointer));

        if (propertyStorePointer == IntPtr.Zero)
        {
            throw new InvalidOperationException("Windows returned an empty shortcut property store.");
        }

        try {
            return (IPropertyStore)Marshal.GetObjectForIUnknown(propertyStorePointer);
        } finally {
            Marshal.Release(propertyStorePointer);
        }
    }

    public static void NotifyAssociationsChanged()
    {
        SHChangeNotify(0x08000000, 0, IntPtr.Zero, IntPtr.Zero);
    }

    public static void NotifyItemDeleted(string path)
    {
        SHChangeNotifyPath(0x00000004, 0x00001005, path, IntPtr.Zero);
    }

    public static void NotifyItemUpdated(string path)
    {
        SHChangeNotifyPath(0x00002000, 0x00001005, path, IntPtr.Zero);
    }
}
'@
}

Write-Host "[2/6] Registering Explorer context menus..."
$progIdPath = "Software\Classes\$progId"
Set-RegistryDefault -RelativePath $progIdPath -Value "Neovim"
Set-RegistryDefault -RelativePath "$progIdPath\DefaultIcon" -Value $icon
Set-ShellCommand -RelativePath "$progIdPath\shell\open" -Label "Open in Neovim" -Command $command

Set-ShellCommand `
    -RelativePath "Software\Classes\*\shell\NeovimInWezTerm" `
    -Label "Open in Neovim" `
    -Command $command
Set-ShellCommand `
    -RelativePath "Software\Classes\Directory\shell\NeovimInWezTerm" `
    -Label "Open in Neovim" `
    -Command $command
Set-ShellCommand `
    -RelativePath "Software\Classes\Drive\shell\NeovimInWezTerm" `
    -Label "Open in Neovim" `
    -Command $command

$backgroundCommand = $command.Replace('"%1"', '"%V"')
Set-ShellCommand `
    -RelativePath "Software\Classes\Directory\Background\shell\NeovimInWezTerm" `
    -Label "Open Neovim here" `
    -Command $backgroundCommand

Write-Host "[3/6] Registering Neovim as a Windows application..."
$capabilitiesPath = "Software\searleser97\Neovim\Capabilities"
$fileAssociationsPath = "$capabilitiesPath\FileAssociations"
$applicationPath = "Software\Classes\Applications\Neovim.exe"
[Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($fileAssociationsPath, $false)
[Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($applicationPath, $false)
$legacyApplicationPaths = @(
    "Software\Classes\Applications\NeovimInWezTerm.exe",
    "Software\Classes\Applications\nvim.exe"
)
foreach ($legacyApplicationPath in $legacyApplicationPaths) {
    if (Test-Path "HKCU:\$legacyApplicationPath") {
        [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree(
            $legacyApplicationPath,
            $false
        )
        Write-Host "Removed legacy Neovim application registration: HKCU:\$legacyApplicationPath"
    }
}
Set-RegistryValue `
    -RelativePath "Software\RegisteredApplications" `
    -Name "Neovim" `
    -Value $capabilitiesPath
Set-RegistryValue -RelativePath $capabilitiesPath -Name "ApplicationName" -Value "Neovim"
Set-RegistryValue -RelativePath $capabilitiesPath -Name "SetupVersion" -Value "7"
Set-RegistryValue `
    -RelativePath $capabilitiesPath `
    -Name "ApplicationDescription" `
    -Value "Edit text and source-code files with Neovim in WezTerm."
Set-RegistryValue -RelativePath $capabilitiesPath -Name "ApplicationIcon" -Value $icon
Set-RegistryValue -RelativePath $applicationPath -Name "FriendlyAppName" -Value "Neovim"
Set-RegistryValue -RelativePath $applicationPath -Name "ApplicationIcon" -Value $icon
Set-RegistryDefault -RelativePath "$applicationPath\DefaultIcon" -Value $icon
Set-RegistryDefault -RelativePath "$applicationPath\shell\open\command" -Value $command
foreach ($extension in $Extensions) {
    Set-RegistryValue `
        -RelativePath $fileAssociationsPath `
        -Name $extension `
        -Value $progId
    Set-RegistryValue `
        -RelativePath "$applicationPath\SupportedTypes" `
        -Name $extension `
        -Value ""
}

Write-Host "[4/6] Creating the Start menu shortcuts..."
foreach ($legacyShortcut in $previousStartMenuShortcuts) {
    if (Test-Path -LiteralPath $legacyShortcut) {
        Remove-Item -LiteralPath $legacyShortcut -Force
        Write-Host "Removed legacy Start-menu shortcut: $legacyShortcut"
    }
    [ShortcutPropertyStore]::NotifyItemDeleted($legacyShortcut)
}
$shortcutShell = New-Object -ComObject WScript.Shell
foreach ($shortcutPath in @($startMenuShortcut, $nvimAliasShortcut)) {
    $shortcut = $shortcutShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $launcherPath
    $shortcut.Arguments = ""
    $shortcut.WorkingDirectory = $env:USERPROFILE
    $shortcut.IconLocation = $icon
    $shortcut.Description = "Open Neovim in WezTerm"
    $shortcut.Save()
    [ShortcutPropertyStore]::SetAppUserModelId($shortcutPath, "searleser97.Neovim")
    [ShortcutPropertyStore]::SetKeywords(
        $shortcutPath,
        [string[]]@("Neovim", "nvim")
    )
    $shortcutKeywords = [ShortcutPropertyStore]::GetKeywords($shortcutPath)
    if ($shortcutKeywords -notcontains "nvim") {
        throw "The nvim search keyword was not saved to $shortcutPath."
    }
}

$backup = @{}
if (Test-Path -LiteralPath $backupPath) {
    $storedBackup = Get-Content -LiteralPath $backupPath -Raw | ConvertFrom-Json -AsHashtable
    foreach ($entry in $storedBackup.GetEnumerator()) {
        $backup[$entry.Key] = $entry.Value
    }
}

foreach ($entry in @($backup.GetEnumerator())) {
    if ($Extensions -contains $entry.Key) {
        continue
    }

    $extensionPath = "HKCU:\Software\Classes\$($entry.Key)"
    if (Test-Path $extensionPath) {
        $extensionKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey(
            "Software\Classes\$($entry.Key)",
            $true
        )
        try {
            if ($extensionKey.GetValue("") -eq $progId) {
                if ($null -eq $entry.Value) {
                    $extensionKey.DeleteValue("", $false)
                } else {
                    $extensionKey.SetValue("", $entry.Value, [Microsoft.Win32.RegistryValueKind]::String)
                }
            }
        } finally {
            $extensionKey.Dispose()
        }

        Remove-ItemProperty `
            -LiteralPath (Join-Path $extensionPath "OpenWithProgids") `
            -Name $progId `
            -ErrorAction SilentlyContinue
        Remove-Item `
            -LiteralPath (Join-Path $extensionPath "OpenWithList\NeovimInWezTerm.exe") `
            -Force `
            -ErrorAction SilentlyContinue
        Remove-Item `
            -LiteralPath (Join-Path $extensionPath "OpenWithList\nvim.exe") `
            -Force `
            -ErrorAction SilentlyContinue
        Remove-Item `
            -LiteralPath (Join-Path $extensionPath "OpenWithList\Neovim.exe") `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

Write-Host "[5/6] Registering $($Extensions.Count) file extensions..."
for ($index = 0; $index -lt $Extensions.Count; $index++) {
    $extension = $Extensions[$index]
    Write-Progress `
        -Activity "Registering Neovim file associations" `
        -Status $extension `
        -PercentComplete (($index + 1) * 100 / $Extensions.Count)

    $extensionPath = "HKCU:\Software\Classes\$extension"
    if (!$backup.ContainsKey($extension)) {
        $previousDefault = if (Test-Path $extensionPath) {
            (Get-Item -Path $extensionPath).GetValue("")
        } else {
            $null
        }
        $backup[$extension] = $previousDefault
    }

    Set-RegistryDefault -RelativePath "Software\Classes\$extension" -Value $progId
    $openWithPath = Join-Path $extensionPath "OpenWithProgids"
    New-Item -Path $openWithPath -Force | Out-Null
    New-ItemProperty -Path $openWithPath -Name $progId -Value "" -PropertyType String -Force | Out-Null
    Remove-Item `
        -LiteralPath (Join-Path $extensionPath "OpenWithList\NeovimInWezTerm.exe") `
        -Force `
        -ErrorAction SilentlyContinue
    Remove-Item `
        -LiteralPath (Join-Path $extensionPath "OpenWithList\nvim.exe") `
        -Force `
        -ErrorAction SilentlyContinue
    New-Item `
        -Path (Join-Path $extensionPath "OpenWithList\Neovim.exe") `
        -Force |
        Out-Null
}
Write-Progress -Activity "Registering Neovim file associations" -Completed

$backup | ConvertTo-Json | Set-Content -LiteralPath $backupPath -Encoding utf8

Write-Host "[6/6] Checking for protected Windows default-app choices..."
$userChoiceOverrides = foreach ($extension in $Extensions) {
    $userChoicePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$extension\UserChoice"
    $userChoice = Get-ItemProperty -Path $userChoicePath -ErrorAction SilentlyContinue
    if ($userChoice -and $userChoice.ProgId -ne $progId) {
        [pscustomobject]@{
            Extension = $extension
            CurrentApp = $userChoice.ProgId
        }
    }
}

Write-Host "Registered Neovim for $($Extensions.Count) extensions and Explorer context menus."
if ($userChoiceOverrides) {
    Write-Warning "Windows has protected default-app choices for some extensions. Neovim is available under Open with, but these choices must be changed in Settings:"
    $userChoiceOverrides | Format-Table -AutoSize
    $registeredAppName = [Uri]::EscapeDataString("Neovim")
    $defaultAppsUri = "ms-settings:defaultapps?registeredAppUser=$registeredAppName"
    Write-Host "Opening Neovim's Default Apps page for confirmation..."
    Start-Process $defaultAppsUri
}

[ShortcutPropertyStore]::NotifyItemUpdated($startMenuShortcut)
[ShortcutPropertyStore]::NotifyItemUpdated($nvimAliasShortcut)
[ShortcutPropertyStore]::NotifyItemUpdated($normalizedNeovimPath)
[ShortcutPropertyStore]::NotifyAssociationsChanged()
