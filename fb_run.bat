@echo off

cd .\prg

::set "MEM=none"
::set "MEM=3k"
set "MEM=8k"
C:\Users\spwil\Documents\VICE\GTK3VICE-3.10-win64\bin\xvic.exe -model vic20pal -memory %MEM%
::C:\Users\spwil\Documents\VICE\GTK3VICE-3.10-win64\bin\xplus4.exe -model c16pal
::C:\Users\spwil\Documents\VICE\GTK3VICE-3.10-win64\bin\x64sc.exe

cd ..
