 param (
    [string]$InputFilename = $(throw "Input filename is required."),
    [string]$OutputFilename = $(throw "Output filename is required.")
 )

$ChordMap = @{}
$ChordMap."O"=@("000")
$ChordMap."R"=@("001")
$ChordMap."M"=@("010")
$ChordMap."L"=@("100")

$ChordModMap = @{}
$ChordModMap."O"=@("0000000000000000")
$ChordModMap."S"=@("0001000000000000")
$ChordModMap."C"=@("0000000100000000")
$ChordModMap."A"=@("0000000000010000")
$ChordModMap."N"=@("0000000000000001")

$Chords = @()
$Strings =@()

$Section="Settings"

$InputLines = Get-Content $InputFilename 
foreach ($InputLine in $InputLines) {
	try {

		if($InputLine -eq "-- Chords --" ){
			$Section="Chords"
			continue 
		}

		# If empty line 
		if($InputLine.TrimStart() -eq "" ){
			continue 
		}

		# If comment line 
		if($InputLine.Substring(0,1) -eq "#" ){
			continue 
		}

		if($Section -eq "Chords" ){
			$NewChord =@()
			$ChordValue = 0L
			$InputArray = $InputLine.TrimStart().Split(" ")
			# Chord Modifiers
			for($i=0; $i -le $InputArray[0].Length-1; $i++){
				$ChordValue +=  [convert]::ToInt32($ChordModMap[$InputArray[0].Substring($i,1)],2)
			}
			# Chords
			for($i=0; $i -le $InputArray[1].Length-1; $i++){
				$ChordKey = $ChordMap[$InputArray[1].Substring($i,1)][0]
				$ChordValue +=  [convert]::ToInt32( "$($ChordKey)$("000000000000000".Substring(0,$i*4+1))"   ,2)
			}
			$ChordValueHex = [Convert]::ToString($ChordValue,16).PadLeft(4,"0")
			$NewChord += [byte][Convert]::ToInt32($ChordValueHex.Substring(2,2),16)
			$NewChord += [byte][Convert]::ToInt32($ChordValueHex.Substring(0,2),16)
			
			# Read keys 
			$KeyArray = $InputArray[2].TrimStart().Split(",")
			if(@($KeyArray).length -eq 1 ){
				$ModKey = $KeyArray[0]
			} else {
				#Create String
				$Length = [Convert]::ToString([int32](@($KeyArray).Length*2+2),16).PadLeft(4,"0")
				$NewString = @( [byte][Convert]::ToInt32($Length.Substring(2,2), 16),[byte][Convert]::ToInt32($Length.Substring(0,2), 16))
				for($i=0; $i -le @($KeyArray).Length-1; $i++){
					$NewString += [byte][Convert]::ToInt32($KeyArray[$i].Substring(0,2),16)
					$NewString += [byte][Convert]::ToInt32($KeyArray[$i].Substring(2,2),16)
				}
				$Strings += , $NewString
				$ModKey = "ff$([Convert]::ToString((@($Strings).length-1),16).PadLeft(2,"0"))"
			}
			$NewChord += [byte][Convert]::ToInt32($ModKey.Substring(0,2),16)
			$NewChord += [byte][Convert]::ToInt32($ModKey.Substring(2,2),16)
			
			$Chords += , $NewChord
		}
	}
	catch {
		Write-Output "$InputLine"
		Write-Error "Error reading line $InputLine - $_"
		continue
	}

}

[byte[]]$OutputFile = @()

#ConfigFormatVersion
$HeaderSize = 16
$OutputFile += [byte]4

#ChordMapOffset 
$ChordMapSize = @($Chords).Length*4+4
$OutputFile += [byte]$HeaderSize
$OutputFile += [byte]0

#MouseChordMapOffset
$MouseChordMapSize = 39
$MouseChordMapOffset = [Convert]::ToString($HeaderSize + $ChordMapSize,16).PadLeft(4,"0")
$OutputFile += [byte][Convert]::ToInt32($MouseChordMapOffset.Substring(2,2),16)
$OutputFile += [byte][Convert]::ToInt32($MouseChordMapOffset.Substring(0,2),16)

#StringTableOffset
$StringTableOffset = [Convert]::ToString($HeaderSize + $ChordMapSize+$MouseChordMapSize,16).PadLeft(4,"0")
$OutputFile += [byte][Convert]::ToInt32($StringTableOffset.Substring(2,2),16)
$OutputFile += [byte][Convert]::ToInt32($StringTableOffset.Substring(0,2),16)

#MouseModeTime 1500 
$OutputFile += [byte]220
$OutputFile += [byte]5

#MouseJumpTime 383
$OutputFile += [byte]127
$OutputFile += [byte]1

#NormalMouseStartingSpeed 3 
$OutputFile += [byte]3

#MouseJumpModeStartingSpeed 6
$OutputFile += [byte]6

#MouseAccelerationFactor 
$OutputFile += [byte]10

#DelayOnKeyRepeat 100 
$OutputFile += [byte]100

#Options : 5
$OutputFile += [byte]5

# ChordMap
foreach ($Chord in $Chords) {
	$OutputFile += $Chord
 }
 
$OutputFile += [byte]0
$OutputFile += [byte]0
$OutputFile += [byte]0
$OutputFile += [byte]0

#MouseChordMap
$MouseChordMap = [Byte[]] (8,0,2,4,0,4,2,0,1,128,0,130,64,0,132,32,0,129,0,8,33,0,4,17,0,2,65,0,128,161,0,64,10,0,32,9,0,0,0)
#$OutputFile += [byte]0
#$OutputFile += [byte]0
#$OutputFile += [byte]0
$OutputFile += $MouseChordMap

#StringTable
foreach ($String in $Strings) {
	$OutputFile += $String
}
$OutputFile += [byte]0
$OutputFile += [byte]0

[io.file]::WriteAllBytes($OutputFilename,$OutputFile)
