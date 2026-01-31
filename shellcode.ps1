#requires -version 5.1.19041.6093
param (
    [Parameter(ValueFromPipeline)]
    $Input,

    [Parameter(Position = 0)]
    [IO.FileInfo]
    $AsmFile,

    [Parameter()]
    [int]
    $LimitCodeBytes = 0,

    [Parameter()]
    [int]
    $LimitDataBytes = 8,

    [Parameter()]
    [switch]
    $AsCharArray,

    [Parameter()]
    [switch]
    $AsDiscordCodeTag,

    [Parameter()]
    [switch]
    $Test
)

$silent = @{ErrorAction = 'SilentlyContinue' }

## Input Handling

if (!(Get-Command nasm @silent)) { throw "Requires nasm.exe" }

if ($PSBoundParameters.ContainsKey("AsmFile")) {
    if (!$AsmFile.Exists) { throw "Input file does not exist: '$AsmFile'" }
}
$ExtraAssembly = $Input -join "`n"

## Prepare Input Files

if (!($AsmFile.Exists -or $ExtraAssembly)) { throw "Need piped nasm assembly instructions and/or 1 input file parameter containing nasm assembly" }
$t3 = New-TemporaryFile
$t2 = New-TemporaryFile
$t1 = if (!$ExtraAssembly) {
    $AsmFile
} else {
    $t1 = New-TemporaryFile
    if ($AsmFile.Exists) {
        Set-Content $t1 ((Get-Content $AsmFile) + "`n" + $ExtraAssembly)
    } else {
        Set-Content $t1 $ExtraAssembly
    }
    $t1
} 

## Invoke NASM

. nasm -f bin $t1 -l $t2 -o $t3
$Lines = Get-Content $t2 
if ($t1 -ne $AsmFile) { Remove-Item $t1 @silent }
Remove-Item $t2 @silent
Remove-Item $t3 @silent
if ($Test) {
    Write-Host ($Lines -join "`n")
}

## Postprocess NASM Listing

# pass1: split lines into fields and find comment indentation start
$Lines = $Lines | ForEach-Object {
    if ($_ -match "^(?:\s*(?'Ln'\d+))(?:\s(?'Addr'[0-9A-F]+))?(?:\s(?'Bytes'[0-9A-F()]+))?(?'Wrap'-)?(?:\s?<rep (?'Rep'[0-9A-F]+h?)>)?(?'Ws'\s*)(?'Comment'.*)") {
        $m = $matches
        $comment = $m['comment']
        $m['Bytes'] = $m['Bytes'] -replace '[()]', [string]::Empty
        $m['CommentIndex'] = if ($comment) { $_.Length - $comment.Length } else { [int]::MaxValue }
        $m['IsData'] = $comment -match '^(.+?:)?(\s*times\s+\w+\s+)?(?:\s*((d[bwdqtoyz])|res[bwdqtoyz]))'
        $m['Original'] = $_
        [PSCustomObject]$m
    }
} | Select-Object Ln, Addr, Bytes, Wrap, Rep, CommentIndex, Comment, Original, IsData

# pass2: get comments with proper indentation
$commentIndex = ($Lines | Measure-Object -Minimum CommentIndex).Minimum
$Lines | ForEach-Object {
    if ($commentIndex -le $_.Original.Length) {
        $_.Comment = $_.Original.Substring($commentIndex)
    }
}

# pass3: main pass, "un-split" byte-row splits done by nasm to later re-split them how we want,
#   also handle nasm repeat thingy and format stuff as C string literal
$Lines = $Lines | ForEach-Object { $prev = $null; $instructionSize = 0 } {
    if ($_.Addr) { $_.Addr = [Convert]::ToInt32($_.Addr, 16) }
    $_.Rep = if ($_.Rep -like '*h') {
        [Convert]::ToInt32($_.Rep.Substring(0, $_.Rep.Length - 1), 16)
    } elseif ($_.Rep) {
        [Convert]::ToInt32($_.Rep, 10)
    } else {
        1
    }

    if ($prev) {
        $_.Bytes = $prev.Bytes + $_.Bytes
        $_.Rep = [Math]::Max($_.Rep, $prev.Rep)
        $_.Comment = $prev.Comment
        $_.IsData = $prev.IsData
        $prev = $null
    }
    if ($_.Wrap) {
        $prev = $_
        return
    }

    $byteRows = if ($_.Bytes) {
        $instructionSize = $_.Bytes.Length / 2
        $_.Bytes = ("\x" + (($_.Bytes -split '(.{2})' | Where-Object { $_ }) -join '\x')) * $_.Rep
        
        $byteLimit = if ($_.IsData -and $LimitDataBytes) {
            $LimitDataBytes
        } elseif (-not $_.IsData) {
            if ($LimitCodeBytes) { $LimitCodeBytes } else { $instructionSize }
        }
        
        $_.Bytes -split "(.{$($byteLimit * 4)})" | Where-Object { $_ }  
    } else {
        @("")
    }
    
    $addr = $_.Addr
    $comment = $_.Comment
    foreach ($row in $byteRows) {
        if ($null -eq $addr) {
            return [PSCustomObject]@{
                Addr    = [string]::Empty    
                Op      = [string]::Empty    
                Comment = $comment
            }
        }

        [PSCustomObject]@{
            Addr    = "/* $($addr.ToString('X8')) */"
            Op      = "`"$($row.Trim())`""
            Comment = $comment
        }
        $addr += $row.Length / 4
        $comment = $comment -replace "(\s*)(.+)", '$1...'
    }
}

## Output

$t = '    '
$maxLen = [int]($Lines.Op | Measure-Object Length -Maximum).Maximum
$content = $Lines | ForEach-Object { 
    "{0,-14} {1,-$maxLen} // {2}" -f $_.Addr, $_.Op, $_.Comment
}

## Optional output formats

$content = $content -join "`n"

if ($AsCharArray) {
    $content = "const char shellcode[] = {`n$t$( $content -split "`n" -join "`n$t" )`n};"
}

if ($AsDiscordCodeTag) {
    $content = "``````c`n$content`n``````"
}

$content
