#requires -version 5.1.19041.1320
param(
    # Username to login with
    [Parameter()][string]$Username,

    # Start in GUI mode
    [Parameter()][switch]$Gui,

    # Create desktop shortcut for GUI mode
    [Parameter()][switch]$Install,

    # Update script to latest version
    [Parameter()][switch]$Update,

    # Optionally show SteamID
    [Parameter()][switch]$ShowSteamID = $false,
    
    # Command-line parameters to pass to Steam
    [Parameter()]
    [Alias("Cmd")]
    [string]$SteamParameters
)

end {
    function DoUpdate {
        $githubRepo = 'donMerloni/Scripts'
        $noCache = @{Headers = @{'Cache-Control' = 'no-cache' } }
        $localSha = Git-Sha $PSCommandPath

        $blob = try { iwr "https://api.github.com/repos/$githubRepo/git/blobs/$localSha" @noCache } catch { $_.Exception.Response }
        if ($blob.StatusCode -eq 404) {
            if (0 -ne $Host.UI.PromptForChoice('Update', 'It seems like the script was modified. All changes made will be overwritten! Update anyway?', ('&yes', '&no'), 1)) {
                exit 0
            }
        } else {
            $tree = (irm "https://api.github.com/repos/$githubRepo/git/trees/master" @noCache).tree
            $sha = ($tree | ? path -eq 'login_steam.ps1').sha

            if ($sha -eq $localSha) { write 'Already up to date'; exit 0 }
        }

        write 'Downloading latest version from GitHub'
        $latest = (iwr "https://raw.githubusercontent.com/$githubRepo/master/login_steam.ps1" @noCache).Content

        write 'Replacing self'
        [IO.File]::WriteAllText($PSCommandPath, $latest)

        write 'Update successful'
        exit 0
    }

    function DoInstall {
        $shell = new-object -ComObject WScript.Shell
        $sh = $shell.CreateShortcut((Join-Path $shell.SpecialFolders['Desktop'] 'Steam Account Manager.lnk'))

        if (Test-Path $sh.FullName) {
            if (0 -ne $Host.UI.PromptForChoice($sh.FullName, 'The shortcut exists already. Overwrite it?', ('&yes', '&no'), 1)) {
                exit 0
            }
        }

        $sh.TargetPath = 'powershell.exe'
        $sh.WorkingDirectory = $PSScriptRoot
        $sh.Description = 'Steam Account Manager'
        $sh.Arguments = "-WindowStyle Hidden -File `"$($PSCommandPath)`" -Gui"
        $sh.IconLocation = "$(Join-Path $Steam steam.exe),1"
        $sh.WindowStyle = 7
        $sh.Save()

        write "Shortcut created: $($sh.FullName)"
        exit 0
    }

    try {
        #
        # (Exit 0) Update script to latest version
        #
        if ($Update) { DoUpdate }
    
        $Steam = (gp registry::HKCU\SOFTWARE\Valve\Steam SteamPath).SteamPath
    
        #
        # (Exit 1) Create desktop shortcut for GUI mode
        #
        if ($Install) { DoInstall }
    
        # get the user list
        $Users = @{}
        $ActiveUser = ((gp registry::HKEY_CURRENT_USER\SOFTWARE\Valve\Steam\ActiveProcess ActiveUser).ActiveUser + 0x110000100000000).ToString()
        $ConnectCache = (cat (Join-Path $Steam config/config.vdf) -raw | Parse-Vdf)['InstallConfigStore']['Software']['Valve']['steam']['ConnectCache']
        $LoginUsers = cat (Join-Path $Steam config/loginusers.vdf) -raw | Parse-Vdf
        $LoginUsers['users'].keys | % {
            $user = $LoginUsers['users'][$_]
            $user.SteamID64 = $_
            $user.Cached = $ConnectCache[(Get-Crc32 $user.AccountName).ToString('x') + '1'].Length -gt 16
            $user.Timestamp /= 1 # Convert to number
            $user.LastLogin = DateTo-TimeAgo (DateFrom-UnixSeconds $user.Timestamp)
            $Users[$user.AccountName] = [PSCustomObject]$user
        }
    
        #
        # (Exit 2) Command line login
        #
        if ($Username) { Login $Username; exit 0 }
    
        # build UI view
        $view = @(
            @{N = 'Cached'; E = { if ($_.Cached) { if (!$Gui) { '✓' } else { '✓                  ' } } } }
            @{N = 'Account name'; E = { $_.AccountName } }
            @{N = 'Profile name'; E = { $_.PersonaName } }
            @{N = 'Last login'; E = { $_.LastLogin } }
            @{N = 'Comment'; E = {
                    $loggedIn = if ($_.SteamID64 -eq $ActiveUser) { '(logged in)' }
                    ($loggedIn, $_.Comment | where { $_ }) -join ' '
                } 
            }
            if ($ShowSteamID) {
                @{N = 'Steam3ID'; E = { $_.SteamID64 - 0x110000100000000 } }
                @{N = 'SteamID64'; E = { $_.SteamID64 } }
            }
        )
        $usersView = $Users.values | sort Timestamp -Descending | select $view
    
        #
        # (Exit 3) Command line view
        #
        if (!$Gui) { $usersView | ft; exit 0 }
    
        #
        # (Exit 4) GUI view and login
        #
        $add = '(+) Add'
        $usersView += $add | % { [PSCustomObject]@{$view[0].N = $_ } }
    
        $choice = $usersView | Out-GridView -Title 'Log into account' -OutputMode Single
        if (!$choice) { exit 0 }
    
        switch ($choice.($view[0].N)) {
            $add { Login '' }
            default { Login $choice.($view[1].N) }
        }
    } catch {
        write "⚠️ Error: $($Error[0]) ($($MyInvocation.MyCommand.Name):$($_.InvocationInfo.ScriptLineNumber))"
        exit 1
    }    
}

begin {
    function Login($username) {
        $process = ps Steam -ErrorAction SilentlyContinue

        if (!$username) {
            write 'Please log in' 
        } elseif ($Users[$username].SteamID64 -eq $ActiveUser -and $process) {
            write 'Already logged in'
        
            Add-Type @'
            public class Native {
                [System.Runtime.InteropServices.DllImport("user32.dll")]
                public static extern void ShowWindow(System.IntPtr hWnd, int nCmdShow);
            }
'@
            [Native]::ShowWindow($process.MainWindowHandle, 1)

            if (![string]::IsNullOrWhiteSpace($SteamParameters)) {
                & (Join-Path $Steam steam.exe) ($SteamParameters -split ' ')
            }

            return
        } elseif ($Users[$username].Cached) {
            write "Hello $($Users[$username].PersonaName)" 
        } else {
            write "Please log in for $username" 
        }

        if ($process) {
            $process.Kill()
            $process.WaitForExit()
        }
        sp registry::HKCU\SOFTWARE\Valve\Steam AutoLoginUser $username
        sp registry::HKCU\SOFTWARE\Valve\Steam RememberPassword 1

        & (Join-Path $Steam steam.exe) ($SteamParameters -split ' ')
    }

    function Parse-Vdf {
        param(
            [Parameter(ValueFromPipeline)]
            [string]$Input
        )
        [System.Collections.Stack] $stack = @([ordered]@{})

        $top = $stack.Peek()
        $key = ''
        $strIndex = -1

        $totalLen = $Input.Length
        for ($i = 0; $i -lt $totalLen; $i++) {
            # here lies the switch statement, it was roughly 5 times slower (RIP)

            $ch = $Input[$i]
            if ($ch -eq '"') {
                if ($strIndex -eq -1) {
                    $strIndex = $i + 1
                } else {
                    $len = $i - $strIndex
                    $str = $Input.Substring($strIndex, $len)
                        
                    if ($key -eq '') {
                        $key = $str
                    } else {
                        $top[$key] = $str
                        $key = ''
                    }
                        
                    $strIndex = -1
                }
            } elseif ($ch -eq '{') {
                if ($strIndex -eq -1) {
                    $top = $top[$key] = [ordered]@{}
                    $stack.Push($top)
                    $key = ''
                }
            } elseif ($ch -eq '}') {
                if ($strIndex -eq -1) {
                    $null = $stack.Pop()
                    $top = $stack.Peek()
                }
            } elseif ($ch -eq '\') {
                if ($strIndex -ne -1 -and $Input[$i + 1] -eq '"') {
                    $i++
                }
            }
        }
            
        $top | add-member ScriptMethod ToString {
            function tab($depth) { if ($depth -gt 0) { [string]::new(9, $depth) } }

            function writeDict($dict, $depth) {
                foreach ($k in $dict.PSObject.Properties['Keys'].Value) {
                    $v = $dict[$k]
                    if ($v -is [System.Collections.IDictionary]) {
                        write "$(tab $depth)`"$k`"`n$(tab $depth){"
                        writeDict $v ($depth + 1)
                        write "$(tab $depth)}"
                    } else {
                        write "$(tab $depth)`"$k`"`t`t`"$v`""
                    }
                }
            }

            writeDict $this 0

        } -Force -PassThru
    }

    function DateFrom-UnixSeconds ($seconds) { (get-date 1-1-1970).AddSeconds($seconds).ToLocalTime() }

    function DateTo-TimeAgo($date) {
        function N($n, $s) { if ($n -eq 1) { return "$n $s" } elseif ($n -gt 1) { return "$n $s`s" } }

        $diff = new-timespan $date (get-date)
        $y = [Math]::Floor($diff.days / 365)
        $d = $diff.days - $y * 365
        $h = $diff.hours
        $m = $diff.minutes

        $parts = if ($y -ge 1) {
            N $y 'year'
            N $d 'day'
        } elseif ($d -ge 1) {
            N $d 'day'
        } else {
            N $h 'hr'
            N $m 'min'
        }
        if ($parts) { "$($parts -join ', ') ago" } else { 'now' }
    }

    function Get-Crc32($bytes) {
        if ($bytes -is [string]) { $bytes = [System.Text.Encoding]::UTF8.GetBytes($bytes) }

        $crc = [uint32]'0xFFFFFFFF' # Microsoft strikes again
        foreach ($b in $bytes) {
            $crc = $crc -bxor $b
            for ($i = 0; $i -lt 8; $i++) {
                $mask = -bnot (($crc -band 1) - 1)
                $crc = ($crc -shr 1) -bxor (0xEDB88320 -band $mask)
            }
        }
        -bnot $crc
    }

    function Git-Sha($filepath) {
        $content = get-content $filepath -Encoding Byte
        $size = $content.Length
        $content = [Text.Encoding]::UTF8.GetString($content)

        $str = "blob $size`0$content"
        $bytes = [Text.Encoding]::UTF8.GetBytes($str)
        $stream = [IO.MemoryStream]::new($bytes)

        (get-filehash -InputStream $stream -Algorithm SHA1).Hash.ToLower()
    }
   
    function Benchmark ($title, $repeat, $codeBlock) {
        $totalMs = 0
        for ($i = 0; $i -lt $repeat; $i++) {
            Write-Host "$title ($($i+1)/$repeat)`r" -NoNewline
            $totalMs += (Measure-Command $codeBlock).TotalMilliseconds
        }
        Write-Host "`ntook $($totalMs / $repeat)ms on average"
    }
}
