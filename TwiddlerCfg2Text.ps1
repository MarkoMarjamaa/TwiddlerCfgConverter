 param (
    [string]$InputFilename = $(throw "Input filename is required."),
    [string]$OutputFilename = $(throw "Output filename is required."),
    [string]$KeyCodeMapFileName = "Us.hid.txt"
 )

$ChordMap = @{}
$ChordMap."000"=@("O")
$ChordMap."001"=@("R")
$ChordMap."010"=@("M")
$ChordMap."100"=@("L")

If (!$(Test-Path $KeyCodeMapFileName)) {
	Write-Output "HID key file not found!"
	exit 1;
}

# Read hid key map 
$KeyCodeMap =  ((get-content $KeyCodeMapFileName -encoding Unicode ) -Replace "\\" , "\\" ) -Join"`r`n" | ConvertFrom-StringData

#Read config file 
try {
    [system.io.stream]$stream = [system.io.File]::OpenRead($InputFilename)
    try {
      [byte[]]$InputFile = New-Object byte[] $stream.length
      [void] $stream.Read($InputFile, 0, $stream.Length);
      #$filebytes
    } 
	finally {
		  $stream.Close();
		}
	}
catch {
    Write-Error "Error reading file $fileItem - $_"
    return
	}
   
Set-Content -Path $OutputFilename -Encoding UTF8 "#ConfigFormatVersion : $($InputFile[0])"
$ChordMapOffset = $InputFile[1]+256*$InputFile[2]
Add-Content -Path $OutputFilename -Encoding UTF8  "#ChordMapOffset : $($ChordMapOffset)"
$MouseChordMapOffset = $InputFile[3]+256*$InputFile[4]
Add-Content -Path $OutputFilename -Encoding UTF8 "#MouseChordMapOffset : $($MouseChordMapOffset)"
$StringTableOffset = $InputFile[5]+256*$InputFile[6]
Add-Content -Path $OutputFilename -Encoding UTF8 "#StringTableOffset : $($StringTableOffset)"
$MouseModeTime = $InputFile[7]+256*$InputFile[8]
Add-Content -Path $OutputFilename -Encoding UTF8 "#MouseModeTime : $($MouseModeTime)"
$MouseJumpTime = $InputFile[9]+256*$InputFile[10]
Add-Content -Path $OutputFilename -Encoding UTF8 "#MouseJumpTime : $($MouseJumpTime)"
$NormalMouseStartingSpeed = $InputFile[11]
Add-Content -Path $OutputFilename -Encoding UTF8 "#NormalMouseStartingSpeed : $($NormalMouseStartingSpeed)"
$MouseJumpModeStartingSpeed = $InputFile[12]
Add-Content -Path $OutputFilename -Encoding UTF8 "#MouseJumpModeStartingSpeed : $($MouseJumpModeStartingSpeed)"
$MouseAccelerationFactor = $InputFile[13]
Add-Content -Path $OutputFilename -Encoding UTF8 "#MouseAccelerationFactor : $($MouseAccelerationFactor)"
$DelayOnKeyRepeat = $InputFile[14]
Add-Content -Path $OutputFilename -Encoding UTF8 "#DelayOnKeyRepeat : $($DelayOnKeyRepeat)"
$Options = $InputFile[15]
Add-Content -Path $OutputFilename -Encoding UTF8 "#Options : $($Options)"
$CrrntKeyOffset = 16

# Read Mouse table 
#$CrrntKeyOffset = $MouseChordMapOffset
#while ( $InputFile[$CrrntKeyOffset] -ne 0 -or $InputFile[$CrrntKeyOffset+1] -ne 0 -or $InputFile[$CrrntKeyOffset+2] -ne 0 ){
#
#	Write-Output "($($InputFile[$CrrntKeyOffset]),$($InputFile[$CrrntKeyOffset+1]),$($InputFile[$CrrntKeyOffset+2])"
#	$CrrntKeyOffset += 3
#}


# Read string table 
$StringMap = @{}
$StringKeyMap = @{}
$CrrntString = 0
$StringTablePointer = $StringTableOffset
while ( $InputFile[$StringTablePointer] -ne 0 -or $InputFile[$StringTablePointer+1] -ne 0){
	$EntryLen = $InputFile[$StringTablePointer] + 256*$InputFile[$StringTablePointer+1]
	$StringLen = ($EntryLen-2)/2

	$String =""
	$StringKey =""
	for($i=0; $i -le $StringLen-1; $i++){
		$Modifier = $InputFile[$StringTablePointer+2+2*$i]
		$KeyCode  = $InputFile[$StringTablePointer+2+2*$i+1]
		$ModKey = "$("{0:X2}" -f $Modifier)$("{0:X2}" -f $KeyCode)"
		if (!$KeyCodeMap.ContainsKey($ModKey)){
			$KeyCodeChr ="<NULL>" 
		} else { 
			$KeyCodeChr = $KeyCodeMap[$ModKey]
		};
		$String += $KeyCodeChr
		$StringKey += "$($ModKey),"
	}
	$StringKey = $StringKey.Substring(0,$StringKey.Length-1)

	$StringMap[[Convert]::ToString($CrrntString,10)] = @($String)
	$StringKeyMap[[Convert]::ToString($CrrntString,10)] = @($StringKey)

	$StringTablePointer += $EntryLen
	$CrrntString += 1
}

Add-Content -Path $OutputFilename -Encoding UTF8 "-- Chords --"
# Read chords
$CrrntKeyOffset = 16
while ( $InputFile[$CrrntKeyOffset] -ne 0 -or $InputFile[$CrrntKeyOffset+1] -ne 0 -or $InputFile[$CrrntKeyOffset+2] -ne 0 -or $InputFile[$CrrntKeyOffset+3] -ne 0  ){

$Chord = $InputFile[$CrrntKeyOffset] + 256*$InputFile[$CrrntKeyOffset+1]
$Modifier = $InputFile[$CrrntKeyOffset+2]
$KeyCode = $InputFile[$CrrntKeyOffset+3]

$ModKey = "$("{0:X2}" -f $Modifier)$("{0:X2}" -f $KeyCode)"

$ChordBit = $([Convert]::ToString($Chord,2).PadLeft(16,'0'))
$ChordBit1 = "$($ChordMap[$ChordBit.Substring(12,3)])$($ChordMap[$ChordBit.Substring(8,3)])$($ChordMap[$ChordBit.Substring(4,3)])$($ChordMap[$ChordBit.Substring(0,3)])"
$ChordBit2S = switch ( $ChordBit.Substring(3,1)){"1" {"S"};default {""}}
$ChordBit2C = switch ( $ChordBit.Substring(7,1)){"1" {"C"};default {""}}
$ChordBit2A = switch ( $ChordBit.Substring(11,1)){"1" {"A"};default {""}}
$ChordBit2N = switch ( $ChordBit.Substring(15,1)){"1" {"N"};default {""}}
$ChordBit2 = "$($ChordBit2S)$($ChordBit2C)$($ChordBit2A)$($ChordBit2N)"
$ChordBit2 = switch($ChordBit2 ){"" {"O"};default {$_}}

if( $Modifier -eq 255 ){
	Add-Content -Path $OutputFilename -Encoding UTF8 "$($ChordBit2.PadLeft(4,' ')) $ChordBit1 $($StringKeyMap[[Convert]::ToString($KeyCode,10)]) $($StringMap[[Convert]::ToString($KeyCode,10)])"
} else {
	if (!$KeyCodeMap.ContainsKey($ModKey)){
		$KeyCodeChr ="<NULL>" 
	} else { 
		$KeyCodeChr = $KeyCodeMap[$ModKey]
	};
	
	Add-Content -Path $OutputFilename -Encoding UTF8 "$($ChordBit2.PadLeft(4,' ')) $ChordBit1 $ModKey $KeyCodeChr" 
	}
	$CrrntKeyOffset += 4
}

