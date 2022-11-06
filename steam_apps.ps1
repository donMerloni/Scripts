#requires -version 5.1.19041.1320
param (
    # Display a lot more Steam metadata
    [Parameter()][switch]$Full
)

function Parse-Vdf {
    $m = $Input | sls "`"(?<key>.+?)`"(?:\s{1,}`"(?<value>(.|`n)*?)(?<!\\)`")?|}" -AllMatches
    [System.Collections.Stack] $stack = @([ordered]@{})
    $level = 0
    $m.matches | % {
        $k = $_.groups['key'].value;
        $v = $_.groups['value']
        $cur = $stack.Peek()
        if ($_ -like '*}') {
            $null = $stack.Pop()
            $level--
        } elseif ($v.Success) {
            $cur[$k] = $v.Value
        } else {
            $cur[$k] = [ordered]@{}
            $stack.Push($cur[$k])
            $level++
        }
    }
    $stack.Peek()
}

function Steam-Apps {
    $Steam = (gp registry::HKCU\SOFTWARE\Valve\Steam SteamPath).SteamPath
    $libraryfolders = (cat (Join-Path $Steam "steamapps\libraryfolders.vdf") -raw | Parse-Vdf)["libraryfolders"]
    $libraryfolders.keys | % {
        if ($_ -match "\d+") {
            $libraryfolders[$_] | % {
                pushd (Join-Path $_["path"] "steamapps")
                dir -File *.acf | % {
                    $app = (cat $_ -raw | Parse-Vdf)["AppState"]
                    $app["dir"] = Join-Path $pwd "common/$($app.installdir)"
                    $app["sizeondisk"] /= 1
                    [PSCustomObject]$app
                }
                popd
            }
        }
    }
}

function PrettyFileSize($bytes) {
    $sizes = [ordered]@{ TB = 1TB; GB = 1GB; MB = 1MB; kB = 1KB; B = 1; }
    $formats = @{ TB = 'f2'; GB = 'f2'; MB = 'f2'; kB = 'f1'; B = ''; }

    foreach ($prefix in $sizes.keys) {
        $size = $sizes[$prefix]
        $format = $formats[$prefix]
        if ($bytes / $size -ge 1) { return "$($prefix.PadLeft(2)) $(($bytes/$size).ToString($format))" }
    }
    "empty"
}

$apps = Steam-Apps
$apps | sort -Property SizeOnDisk -Descending | ft appid, name, @{N = "size"; E = { PrettyFileSize $_.SizeOnDisk } }, dir -AutoSize
"Total: $(PrettyFileSize ($apps | measure -sum SizeOnDisk).Sum)"

if ($Full) {
    $apps | % {
        $_.PSObject.Properties | % {
            try {
                $_.Value = [int]$_.Value
            } catch {}
        }
        $_
    } | Out-GridView -Title "List of Steam apps"
}
