# TwiddlerCfgConverter
Converts Twiddler3 keyboard configuration files to human readable format and vice versa

Faster to create new configurations( from existing ones)
Allows using international charactersets and keyboards
Allows writing comments about design decisions. 
Allows making groups of similar chord combinations for easier learning

Convert Twiddler3 cfg to text file 
powershell -file TwiddlerCfg2Text.ps1 inputfilename outputfilename [HID file name]

Examples:
powershell -file TwiddlerCfg2Text.ps1 twiddler_default.cfg twiddler_default.text.cfg
powershell -file TwiddlerCfg2Text.ps1 twiddler_default.cfg twiddler_default.text.cfg Us.hid.txt

Text file format: 

# Starts a comment

Single key: 
modifier chords hid_modifier&key character

Example:
  AN LLOL 0047 <ScrollLock>
   O ROOO 0004 a

Macro keys: 
modifier chords hid_modifier&key,hid_modifier&key2... character1character2

Example:
   O OLOM 000C,0012,0011,002C ion<Space>

Shown characters are fetched from HID key map file. Default file is Us.hid.txt.
Shown characters are only for visualisation, the actual conversion from text file to cfg file is done with hid_modifier&key values. 
HID key map file can be Unicode and output file is always Unicode. 

