using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.ComponentModel;

class TempFile : IDisposable
{
    public string Path;
    public TempFile(string path = null) => Path = path ?? System.IO.Path.GetTempFileName();
    public void Dispose() => File.Delete(Path);
}

class CLPreprocessor : IDisposable
{
    public Process Process = new Process();
    public TempFile InFile = new TempFile();
    public TempFile OutFile;
    public string StandardError;
    bool Debug;
    int TimeoutMs;

    public CLPreprocessor(string input, string flags, bool debug, int timeoutMs)
    {
        OutFile = new TempFile(InFile.Path + ".preprocessed");
        File.WriteAllText(InFile.Path, input);
        Process.StartInfo = new ProcessStartInfo
        {
            FileName = "cl.exe",
            Arguments = $@"/nologo ""{InFile.Path}"" /P /Fi""{OutFile.Path}"" {flags}",
            UseShellExecute = false,
            RedirectStandardError = true,
            CreateNoWindow = !Debug,
        };
        Debug = debug;
        TimeoutMs = timeoutMs;
    }

    public void Dispose()
    {
        InFile.Dispose();
        OutFile.Dispose();
    }

    public bool Execute()
    {
        try
        {
            if (Debug)
                Console.WriteLine($"Invoking cl.exe {Process.StartInfo.Arguments}");
            Process.Start();
        }
        catch
        {
            Console.WriteLine("Error: Could not find cl.exe");
            return false;
        }

        if (TimeoutMs > 0)
            Process.WaitForExit(TimeoutMs);
        else
            Process.WaitForExit();
        StandardError = Process.StandardError.ReadToEnd();

        return true;
    }
}

class Macro
{
    public string UserInput;
    public bool UserIsInvocation;

    public string Name;
    public string Head;
    public string Body;
    public string Expanded;
    public bool IsFunction => Body != null;
    public bool IsDefined => Expanded != null;
    public bool IsValidIdentifier;

    public Macro(string value)
    {
        UserInput = value;
        var braceStart = value.IndexOf('(');
        if (braceStart != -1)
        {
            UserIsInvocation = true;
            value = value.Remove(braceStart);
        }
        Name = value;
        IsValidIdentifier = Regex.IsMatch(Name, "^[a-z_][a-z0-9_]*$", RegexOptions.IgnoreCase);
    }
}

class App
{
    enum ExitCode
    {
        Success = 0,
        Failure = 1,
        CLFailed = 8,
        Help = 9,
    }

    static Dictionary<string, Macro> MacrosToCheck = new Dictionary<string, Macro>();
    static List<string> HeadersToInclude = new List<string>();
    static bool Debug;
    static int TimeoutMs = 0;
    static string CompilerFlags = "";
    static bool RequireAll = true;
    static bool CollapseIntoSingleLine = false;

    static int Main(string[] argarray)
    {
        //
        // Parse arguments
        //
        var args = new List<string>(argarray);
        while (args.Count > 0)
        {
            if (ParseOption(args, "C"))
            {
                CollapseIntoSingleLine = true;
            }
            else if (ParseOption(args, "D", out var D))
            {
                CompilerFlags += $"-D{D} ";
            }
            else if (ParseOption(args, "F", out var F))
            {
                CompilerFlags += $"{F} ";
            }
            else if (ParseOption(args, "I", out var I))
            {
                HeadersToInclude.Add(I);
            }
            else if (ParseOption(args, "L", out var L))
            {
                if (File.Exists(L))
                {
                    args.InsertRange(0, File.ReadAllLines(L).Where(line => !string.IsNullOrWhiteSpace(line)));
                }
            }
            else if (ParseOption(args, "R", out var R))
            {
                if (R.Equals("all", StringComparison.InvariantCultureIgnoreCase))
                    RequireAll = true;
                else if (R.Equals("any", StringComparison.InvariantCultureIgnoreCase))
                    RequireAll = false;
            }
            else if (ParseOption(args, "T", out var T))
            {
                int.TryParse(T, out TimeoutMs);
            }
            else if (ParseOption(args, "V"))
            {
                Debug = true;
            }
            else
            {
                var m = new Macro(args[0]);
                MacrosToCheck[m.Name] = m;
                args.RemoveAt(0);
            }
        }

        //
        // Show help
        //
        if (MacrosToCheck.Count == 0)
        {
            var me = Process.GetCurrentProcess().ProcessName;

#if true
            Console.WriteLine($@"Returns the value of any preprocessor define
note: Microsoft C/C++ Compiler (cl.exe) must be in environment PATH
usage: {me} [options] <DEFINE>...
where:
    DEFINE                    A preprocessor define name (Example: _WIN32)
options:
    -C                        Collapse multi-line macros into a single line
    -D <name>{{=|#}}<text>    #define <name> <text> (Example: -D N=42)
    -F <flags>                Additional compiler flags to use (Example: -F \""/D_DEBUG /Zi\"")
    -I <header>               #include <header> (Example: -I Windows.h)
    -L <commandfile>          File containing a whitespace separated list of command line arguments to use
                              (Example: -L commands.txt)
    -R {{all|any}}            Criteria for when to return 0 (success code). Defaults to ""all"", which
                              means every define name must be defined
    -T <milliseconds>         Timeout in milliseconds for the preprocessor (Example: -T 1000)
    -V                        Show verbose/debug messages");
#else
            Console.WriteLine("Returns the value of any preprocessor define");
            Console.WriteLine("note: Microsoft C/C++ Compiler (cl.exe) must be in environment PATH");
            Console.WriteLine($"usage: {me} [options] <DEFINE>...");
            Console.WriteLine("where:");
            Console.WriteLine("    DEFINE                  A preprocessor define name (Example: _WIN32)");
            Console.WriteLine("options:");
            //Console.WriteLine("    -X <batchscript>        Executes a batch script");
            Console.WriteLine("    -C                      Collapse multi-line macros into a single line");
            Console.WriteLine("    -D <name>{=|#}<text>    #define <name> <text> (Example: -D N=42)");
            Console.WriteLine("    -F <flags>              Additional compiler flags to use (Example: -F \"/D_DEBUG /Zi\")");
            Console.WriteLine("    -I <header>             #include <header> (Example: -I Windows.h)");
            Console.WriteLine("    -L <commandfile>        File containing a whitespace separated list of command line arguments to use");
            Console.WriteLine("                            (Example: -L commands.txt)");
            Console.WriteLine("    -R {all|any}            Criteria for when to return 0 (success code). Defaults to \"all\", which");
            Console.WriteLine("                            means every define name must be defined");
            Console.WriteLine("    -T <milliseconds>       Timeout in milliseconds for the preprocessor (Example: -T 1000)");
            Console.WriteLine("    -V                      Show verbose/debug messages");
#endif

            return (int)ExitCode.Help;
        }

        //
        // Build text to preprocess
        //
        StringBuilder sb = new StringBuilder();
        foreach (var h in HeadersToInclude) sb.AppendLine($"#include <{h}>");
        foreach (var kvp in MacrosToCheck)
        {
            var m = kvp.Value;
            if (!m.IsValidIdentifier)
                continue;
            sb.AppendLine($"#ifdef {m.Name}");
            sb.AppendLine($@"""{m.Name}""={m.UserInput}");
            sb.AppendLine($"#endif");
            sb.AppendLine($"#define {m.Name}");
        }

        using (var cl = new CLPreprocessor(sb.ToString(), CompilerFlags, Debug, TimeoutMs))
        {   
            //
            // Execute preprocessor
            //
            if (!cl.Execute()) return (int)ExitCode.CLFailed;

            if (cl.Process.ExitCode != 0 || Debug)
                Console.WriteLine(cl.StandardError);

            //
            // Find out which macros are defined and get their expansions
            //
            var outputLines = File.ReadAllLines(cl.OutFile.Path)
                .Reverse()
                .TakeWhile(L => !(L.StartsWith("#line") && L.IndexOf(cl.InFile.Path.Replace(@"\", @"\\"), StringComparison.OrdinalIgnoreCase) == -1))
                .Reverse();

            if (Debug)
            {
                Console.WriteLine("Input:");
                TypeTextBlock(File.ReadAllText(cl.InFile.Path));
                Console.WriteLine("Output:");
                TypeTextBlock(string.Join(Environment.NewLine, outputLines));
                Console.WriteLine($"cl.exe exited with code {cl.Process.ExitCode}");
            }

            foreach (var line in outputLines)
            {
                var index = line.IndexOf('=');
                if (index != -1 && line.StartsWith("\""))
                {
                    var key = line.Substring(1, index - 2);
                    var value = line.Substring(index + 1);
                    MacrosToCheck[key].Expanded = value;
                }
            }

            //
            // Find out which macros are functions and get their bodies
            //
            var files = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);
            var regex = new Regex($@"^(?!{Regex.Escape(cl.InFile.Path)}\() (?<file>.+?) \( (?<line>\d+) \): .* previous.definition .* '(?<macro>.+)'", RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.Multiline | RegexOptions.ExplicitCapture | RegexOptions.IgnorePatternWhitespace);
            foreach (var match in cl.StandardError.Split(new[] { '\r', '\n' }).Select(s => regex.Match(s)).Where(m => m.Success))
            {
                var macro = match.Groups["macro"].Value;
                if (!MacrosToCheck.ContainsKey(macro))
                    continue;
                var file = match.Groups["file"].Value;
                var line = int.Parse(match.Groups["line"].Value);

                // cache files i guess
                if (!files.TryGetValue(file, out var lines))
                    files.Add(file, lines = File.ReadLines(file).ToArray());

                // get the entire macro definition, which could be multi-line
                // Microsoft's C/C++ compiler (tested version 19.28.29336) outputs the very last line-number for multi-line macros, so the code walks the line array backwards
                var definition = "";
                var i = -1;
                while (i == -1 && definition.IndexOf("#define", StringComparison.OrdinalIgnoreCase) == -1)
                {
                    definition = lines[line-- - 1] + "\n" + definition;
                    i = definition.IndexOf(macro);
                }

                if (CollapseIntoSingleLine)
                {
                    definition = Regex.Replace(definition, @"\\\n", "");
                    definition = Regex.Replace(definition, @"\s+", " ");
                    i = definition.IndexOf(macro);
                }

                // now split the definition into macro head and body
                var j = definition[i + macro.Length] == '(' ? definition.IndexOf(')', i) : -1;
                if (i <= j)
                {
                    MacrosToCheck[macro].Head = definition.Substring(i, j - i + 1);
                    MacrosToCheck[macro].Body = definition.Substring(j + 1).Trim();
                }
            }
        }

        //
        // Output the results to the user
        //
        foreach (var kvp in MacrosToCheck)
        {
            var m = kvp.Value;
            if (m.IsDefined)
            {
                Console.WriteLine($"#define {m.Head ?? m.Name} {(m.Body ?? m.Expanded)}");
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"{m.Name} is {(m.IsValidIdentifier ? "undefined" : "not a valid identifier")}");
                Console.ResetColor();
            }
        }

        //
        // we're finally done!
        //
        int nDefined = MacrosToCheck.Count(kvp => kvp.Value.IsDefined);
        if (nDefined == MacrosToCheck.Count)
            return (int)ExitCode.Success;
        else if (nDefined > 0)
            return (int)(RequireAll ? ExitCode.Failure : ExitCode.Success);
        else
            return (int)ExitCode.Failure;
    }

    static void TypeTextBlock(string textBlock, ConsoleColor fg = ConsoleColor.Gray, ConsoleColor bg = ConsoleColor.Black)
    {
        var lines = textBlock.Split('\n').Select(l => l.Trim('\r')).ToArray();
        var blockWidth = lines.Max(l => l.Length);
        var lineNumberWidth = lines.Length.ToString().Length;
        for (int i = 0; i < lines.Length; i++)
        {
            Console.ResetColor();
            Console.Write($"{(i + 1).ToString().PadLeft(lineNumberWidth)} | ");
            Console.ForegroundColor = fg;
            Console.BackgroundColor = bg;
            Console.WriteLine(lines[i].PadRight(blockWidth));
        }
        Console.ResetColor();
    }

    static bool ParseOption(List<string> args, string option, bool remove = true)
    {
        if (args.Count == 0) return false;
        if (Regex.IsMatch(args[0], $"^[/-]{option}", RegexOptions.IgnoreCase))
        {
            if (remove) args.RemoveAt(0);
            return true;
        }
        return false;
    }

    static bool ParseOption(List<string> args, string option, out string value, bool remove = true)
    {
        value = "";
        if (ParseOption(args, option, false))
        {
            value = args[0].Substring(option.Length + 1);
            if (value == "" && args.Count > 1)
            {
                value = args[1];
                if (remove) args.RemoveAt(1);
            }
            if (remove) args.RemoveAt(0);
            return true;
        }
        return false;
    }
}
