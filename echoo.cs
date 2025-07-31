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
            var LineStart = (on: true, c: "|", fg: ConsoleColor.DarkGray, bg: (ConsoleColor?)null, count: 0);

            void _lineStart()
            {
                if (!LineStart.on) return;
                LineStart.count++;
                var ln = LineStart.count.ToString();
                Output(new string('\b', ln.Length) + ln + LineStart.c, LineStart.fg, LineStart.bg);
            }

            Output("\nInput:\t", ConsoleColor.Green);
            _lineStart();
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
                        _lineStart();
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

    static ConsoleColor InitFg = Console.ForegroundColor;
    static ConsoleColor InitBg = Console.BackgroundColor;
    static ConsoleColor Fg = Console.ForegroundColor;
    static ConsoleColor Bg = Console.BackgroundColor;
    static void Output(string text, ConsoleColor? fg = null, ConsoleColor? bg = null)
    {
        fg = fg ?? InitFg;
        bg = bg ?? InitBg;
        if (fg != Fg) Console.ForegroundColor = Fg = fg.Value;
        if (bg != Bg) Console.BackgroundColor = Bg = bg.Value;
        Console.Write(text);
    }
}
