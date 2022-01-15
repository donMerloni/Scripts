#requires -version 5.1.19041.1320
param(
    # Username to login with
    [Parameter()][string]$Username,

    # Start in GUI mode
    [Parameter()][switch]$Gui,

    # Create desktop shortcut for GUI mode
    [Parameter()][switch]$Install,

    # Update script to latest version
    [Parameter()][switch]$Update
)

function DateFrom-UnixSeconds ($seconds) { (get-date 1-1-1970).AddSeconds($seconds).ToLocalTime() }

function DateTo-TimeAgo($date) {
    function N($n, $s) { if ($n -eq 1) { return "$n $s" } elseif ($n -gt 1) { return "$n $s`s" } }

    $diff = new-timespan $date (get-date)
    $y = [Math]::Floor($diff.days / 365)
    $d = $diff.days - $y * 365
    $h = $diff.hours
    $m = $diff.minutes

    $a = @()
    if ($y -ge 1) {
        $a += N $y 'year'
        $a += N $d 'day'
    }
    elseif ($d -ge 1) {
        $a += N $d 'day'
    }
    else {
        $a += N $h 'hr'
        $a += N $m 'min'
    }
    if ($a) { "$($a -join ', ') ago" } else { 'now' }
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

function Parse-Vdf {
    function tab($depth) { if ($depth -gt 0) { [string]::new(9, $depth) } }

    $m = $Input | sls "`"(?<key>.+?)`"(?:\s{1,}`"(?<value>(.|`n)*?)`")?|}" -AllMatches
    [System.Collections.Stack] $stack = @([ordered]@{})
    $level = 0
    $m.matches | % {
        $k = $_.groups['key'].value;
        $v = $_.groups['value']
        $cur = $stack.Peek()
        if ($_ -like '*}') {
            $null = $stack.Pop()
            $level--
        }
        elseif ($v.Success) {
            $cur[$k] = $v.Value
        }
        else {
            $cur[$k] = [ordered]@{}
            $stack.Push($cur[$k])
            $level++
        }
    }
    $stack.Peek() | add-member ScriptMethod ToString {
        function entry($e, $depth) {
            foreach ($k in $e.keys) {
                $v = $e[$k]
                if ($v -is [string]) {
                    write "$(tab $depth)`"$k`"`t`t`"$v`""
                }
                else {
                    write "$(tab $depth)`"$k`"`n$(tab $depth){"
                    entry $v ($depth + 1)
                    write "$(tab $depth)}"
                }
            }
        }

        entry $this 0

    } -Force -PassThru
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

function Login($username) {
    $process = (ps Steam -ErrorAction SilentlyContinue)

    if ($username) {
        if ($Users[$username].SteamID64 -eq $ActiveUser -and $process) {
            write 'Already logged in'
            Add-Type 'public class Native { [System.Runtime.InteropServices.DllImport("user32.dll")] public static extern void ShowWindow(System.IntPtr hWnd, int nCmdShow); }'
            [Native]::ShowWindow($process.MainWindowHandle, 1)
            return
        }

        if ($Users[$username].Cached) { write "Hello $($Users[$username].PersonaName)" }
        else { write "Please log in for $username" }
    }
    else { write 'Please log in' }

    if ($process) { $process.Kill() }
    sp registry::HKCU\SOFTWARE\Valve\Steam AutoLoginUser $username
    sp registry::HKCU\SOFTWARE\Valve\Steam RememberPassword 1
    & (Join-Path $Steam steam.exe)
}

try {
    #
    # (Exit 0) Update script to latest version
    #
    if ($Update) {
        $noCache = @{Headers = @{'Cache-Control' = 'no-cache' } }
        $localSha = Git-Sha $PSCommandPath

        $blob = try { iwr "https://api.github.com/repos/lakatosm/Scripts/git/blobs/$localSha" @noCache } catch { $_.Exception.Response }
        if ($blob.StatusCode -eq 404) {
            if (0 -ne $Host.UI.PromptForChoice('Update', 'It seems like the script was modified. All changes made will be overwritten! Update anyway?', ('&yes', '&no'), 1)) {
                exit 0
            }
        }
        else {
            $tree = (irm 'https://api.github.com/repos/lakatosm/Scripts/git/trees/master' @noCache).tree
            $sha = ($tree | ? path -eq 'login_steam.ps1').sha

            if ($sha -eq $localSha) { write 'Already up to date'; exit 0 }
        }

        write 'Downloading latest version from GitHub'
        $latest = (iwr 'https://raw.githubusercontent.com/lakatosm/Scripts/master/login_steam.ps1' @noCache).Content

        write 'Replacing self'
        [IO.File]::WriteAllText($PSCommandPath, $latest)

        write 'Update successful'
        exit 0
    }

    $Steam = (gp registry::HKCU\SOFTWARE\Valve\Steam SteamPath).SteamPath

    #
    # (Exit 1) Create desktop shortcut for GUI mode
    #
    if ($Install) {
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
        if ($ActiveUser -eq $_) { $user.Comment = "(logged in) $($user.Comment)" }
        $Users[$user.AccountName] = [PSCustomObject]$user
    }

    #
    # (Exit 2) Command line login
    #
    if ($Username) { Login $Username; exit 0 }

    # build UI view
    $view = @(
        @{N = 'Cached'; E = { if ($_.Cached) { return '✓' } } }
        @{N = 'Account name'; E = { $_.AccountName } }
        @{N = 'Profile name'; E = { $_.PersonaName } }
        @{N = 'Last login'; E = { $_.LastLogin } }
        @{N = 'Comment'; E = { $_.Comment } }
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

    switch ($choice.'Account name') {
        $add { Login '' }
        default { Login $choice.'Account name' }
    }
}
catch {
    write "⚠️ Error: $($Error[0]) ($($MyInvocation.MyCommand.Name):$($_.InvocationInfo.ScriptLineNumber))"
    exit 1
}