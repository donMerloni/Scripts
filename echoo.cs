using System;
using System.Diagnostics;

class App
{
    static void Main(string[] args)
    {
        var me = Process.GetCurrentProcess().ProcessName;

        Output(me, ConsoleColor.Green);
        Output(" was executed with");
        if (args.Length > 0)
        {
            Output(" arguments: ");
            for (var i = 0; i < args.Length; i++)
            {
                Output("\"");
                Output(args[i], ConsoleColor.Green);
                Output("\"");
                if (i != args.Length - 1) Output(", ");
            }
        }
        else
        {
            Output("out arguments");
        }

        if (HasInput())
        {
            var Input = (fg: ConsoleColor.Blue, bg: ConsoleColor.Black);
            var Special = (fg: ConsoleColor.Red, bg: Input.bg);
            var LineStart = (on: false, c: "|", fg: (ConsoleColor?)null, bg: ConsoleColor.DarkGreen);

            Output("\nInput:\t", ConsoleColor.Green);
            if (LineStart.on) Output(LineStart.c, LineStart.fg, LineStart.bg);
            while (Console.In.Peek() != -1)
            {
                var c = (char)Console.In.Read();
                switch (c)
                {
                    case '\r':
                        Output("\\r", Special.fg, Special.bg);
                        break;

                    case '\t':
                        Output("\\t", Special.fg, Special.bg);
                        break;

                    case '\n':
                        Output("\\n\n", Special.fg, Special.bg);
                        Output("\t");
                        if (LineStart.on) Output(LineStart.c, LineStart.fg, LineStart.bg);
                        break;

                    case ' ':
                        Output("·", Special.fg, Special.bg);
                        break;

                    default:
                        Output(c.ToString(), Input.fg, Input.bg);
                        break;

                }
            }
        }
        Output("\n");
    }

    static bool HasInput() => Console.IsInputRedirected && Console.In.Peek() != -1;

    static void Output(string text, ConsoleColor? fg = null, ConsoleColor? bg = null)
    {
        var oldFg = Console.ForegroundColor;
        var oldBg = Console.BackgroundColor;
        if (fg != null) Console.ForegroundColor = fg.Value;
        if (bg != null) Console.BackgroundColor = bg.Value;
        Console.Write(text);
        Console.ForegroundColor = oldFg;
        Console.BackgroundColor = oldBg;
    }
}