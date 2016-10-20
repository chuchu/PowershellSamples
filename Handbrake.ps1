﻿param(
    [string] $sourceFolder,
    [string] $targetFolder,
    [string] $handbrakeCLI = "E:\Program Files\Handbrake\HandBrakeCLI.exe"
)

if ( -Not ( Test-Path $targetFolder ) )
{
	md -Path $targetFolder
}

function GetMatchOrEmptyStringFromFile([string]$file, [string]$regex)
{
    $matches = select-string -path $file -pattern $regex -AllMatches

    if( $matches.Matches.Count -gt 0 )
    {
        if( $matches.Matches[0].Count -gt 0 )
        {
            if( $matches.Matches[0].Groups.Count -gt 1 )
            {
                $matches.Matches[0].Groups[1].Value
            }
        }
    }
}

$temp_file = "$($env:temp)\$([System.Guid]::NewGuid().ToString()).txt"

& $handbrakeCLI --input $sourceFolder --scan *>&1 > "$($temp_file)"

$titles = GetMatchOrEmptyStringFromFile $temp_file ".*has (\d*) title.*"

for( $i=1; $i -le $titles; $i++ )
{
    & $handbrakeCLI --input $sourceFolder --scan --title $i *>&1 > "$($temp_file)"    

    $german_index = GetMatchOrEmptyStringFromFile $temp_file ".*\+\s(\d*),\sDeutsch.*ch.*"

    if( !$german_index )
    {
        continue;
    }

    $chapter_file = "$($env:temp)\$([System.Guid]::NewGuid().ToString()).csv"
    
    & $handbrakeCLI -i $sourceFolder -t $i --angle 1 -c 1-2 -o "$($targetFolder)\$($i).mp4"  -f mp4  --deinterlace="slow" -w 720 --crop 0:2:0:0 --loose-anamorphic  --modulus 2 -e x264 -q 25 --vfr -a $german_index -E av_aac -6 dpl2 -R Auto -B 160 -D 0 --gain 0 --audio-fallback ac3 --markers=$chapter_file --encoder-preset=veryfast  --encoder-level="4.0"  --encoder-profile=main

    If (test-path $chapter_file)
    {
	    remove-item $chapter_file
    }
}

If (test-path $temp_file)
{
	remove-item $temp_file
}