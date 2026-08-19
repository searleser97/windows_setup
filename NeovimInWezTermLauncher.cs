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
            string neovim = FindExecutable(
                Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                    "scoop",
                    "shims",
                    "nvim.exe"),
                "nvim.exe");

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
            CopyRequiredUserEnvironmentVariable(startInfo, "NVIM_COPILOT_CMD");
            CopyRequiredUserEnvironmentVariable(startInfo, "NVIM_AI_PROMPTS_PATH");
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
            startInfo.ArgumentList.Add(neovim);
            if (target != null)
            {
                startInfo.ArgumentList.Add(target);
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

    private static void CopyRequiredUserEnvironmentVariable(
        ProcessStartInfo startInfo,
        string name)
    {
        string? value = Environment.GetEnvironmentVariable(
            name,
            EnvironmentVariableTarget.User);
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new InvalidOperationException(
                $"Required user environment variable '{name}' is not configured. Rerun run.bat.");
        }

        startInfo.Environment[name] = value;
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
