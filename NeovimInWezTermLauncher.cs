using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;

internal static class NeovimInWezTermLauncher
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int MessageBoxW(IntPtr window, string text, string caption, uint type);

    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            string wezTerm = FindExecutable(
                Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                    "WezTerm",
                    "wezterm-gui.exe"),
                "wezterm-gui.exe");
            string powerShell = FindExecutable(
                Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "Microsoft",
                    "WindowsApps",
                    "pwsh.exe"),
                "pwsh.exe");

            string? target = args.Length == 0
                ? null
                : Path.GetFullPath(args[0]);
            if (target != null && !File.Exists(target) && !Directory.Exists(target))
            {
                throw new FileNotFoundException("The selected path does not exist.", target);
            }

            string workingDirectory = target == null
                ? Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)
                : Directory.Exists(target)
                    ? target
                    : Path.GetDirectoryName(target) ?? Environment.CurrentDirectory;

            var startInfo = new ProcessStartInfo
            {
                FileName = wezTerm,
                UseShellExecute = false,
                WorkingDirectory = workingDirectory
            };
            string wezTermConfig = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                ".wezterm.lua");
            if (File.Exists(wezTermConfig))
            {
                startInfo.ArgumentList.Add("--config-file");
                startInfo.ArgumentList.Add(wezTermConfig);
            }
            startInfo.ArgumentList.Add("start");
            startInfo.ArgumentList.Add("--always-new-process");
            startInfo.ArgumentList.Add("--cwd");
            startInfo.ArgumentList.Add(workingDirectory);
            startInfo.ArgumentList.Add("--");
            startInfo.ArgumentList.Add(powerShell);
            startInfo.ArgumentList.Add("-NoLogo");
            startInfo.ArgumentList.Add("-Command");
            startInfo.ArgumentList.Add(
                "if ($env:NVIM_LAUNCH_TARGET) " +
                "{ nvim.exe -- $env:NVIM_LAUNCH_TARGET } else { nvim.exe }");
            if (target != null)
            {
                startInfo.Environment["NVIM_LAUNCH_TARGET"] = target;
            }

            Process.Start(startInfo);
            return 0;
        }
        catch (Exception exception)
        {
            MessageBoxW(IntPtr.Zero, exception.Message, "Neovim", 0x10);
            return 1;
        }
    }

    private static string FindExecutable(string preferredPath, string executableName)
    {
        if (File.Exists(preferredPath))
        {
            return preferredPath;
        }

        foreach (string directory in (Environment.GetEnvironmentVariable("PATH") ?? "").Split(Path.PathSeparator))
        {
            if (string.IsNullOrWhiteSpace(directory))
            {
                continue;
            }

            string candidate = Path.Combine(directory.Trim('"'), executableName);
            if (File.Exists(candidate))
            {
                return candidate;
            }
        }

        throw new FileNotFoundException($"{executableName} was not found.");
    }
}
