@echo off
set rt11exe=C:\bin\rt11\rt11.exe

rem Define ESCchar to use in ANSI escape sequences
rem https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESCchar=%%E"

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "DATESTAMP=%YYYY%:%MM%:%DD%"
for /f %%i in ('git rev-list HEAD --count') do (set REVISION=%%i)
echo REV.%REVISION% %DATESTAMP%

echo 	.ASCII /REV;%REVISION%@%DATESTAMP%/ > VERSIO.MAC

@if exist TILES.OBJ del TILES.OBJ
@if exist HWYENC.LST del HWYENC.LST
@if exist HWYENC.OBJ del HWYENC.OBJ
@if exist HWYENC.MAP del HWYENC.MAP
@if exist HWYENC.SAV del HWYENC.SAV
@if exist HWYENC.COD del HWYENC.COD
@if exist HWYENC.LZS del HWYENC.LZS
@if exist HWBOOT.LST del HWBOOT.LST
@if exist HWBOOT.OBJ del HWBOOT.OBJ
@if exist HWBOOT.SAV del HWBOOT.SAV
@if exist HWYENC.BIN del HWYENC.BIN

%rt11exe% MACRO/LIST:DK: HWYENC.MAC

for /f "delims=" %%a in ('findstr /B "Errors detected" HWYENC.LST') do set "errdet=%%a"
if "%errdet%"=="Errors detected:  0" (
  echo HWYENC COMPILED SUCCESSFULLY
) ELSE (
  findstr /RC:"^[ABDEILMNOPQRTUZ] " HWYENC.LST
  echo ======= %errdet% =======
  goto :Failed
)

%rt11exe% LINK HWYENC /MAP:HWYENC.MAP

for /f "delims=" %%a in ('findstr /B "Undefined globals" HWYENC.MAP') do set "undefg=%%a"
if "%undefg%"=="" (
  type HWYENC.MAP
  echo.
  echo HWYENC LINKED SUCCESSFULLY
) ELSE (
  echo ======= LINK FAILED =======
  goto :Failed
)

rem Get HWYENC.SAV code size and cut off parts we don't need
for /f "delims=" %%a in ('findstr /RC:"High limit = " HWYENC.MAP') do set "codesize=%%a"
set "codesize=%codesize:~49,5%"
rem echo Code limit %codesize% words
set /a codesize="%codesize% * 2"
powershell gc HWYENC.SAV -Encoding byte -TotalCount %codesize% ^| sc HWYENC.CO0 -Encoding byte
set /a codesize="%codesize% - 1024"
powershell gc HWYENC.CO0 -Encoding byte -Tail %codesize% ^| sc HWYENC.COD -Encoding byte
del HWYENC.CO0
rem echo Code size %codesize% bytes
dir /-c HWYENC.COD|findstr /R /C:"HWYENC.COD"

tools\lzsa3.exe HWYENC.COD HWYENC.LZS
dir /-c HWYENC.LZS|findstr /R /C:"HWYENC.LZS"
call :FileSize HWYENC.LZS
set "codelzsize=%fsize%"
rem echo Compressed size %codelzsize%

rem Reuse VERSIO.MAC to pass parameters into HWBOOT.MAC
echo HWLZSZ = %codelzsize%. >> VERSIO.MAC

%rt11exe% MACRO/LIST:DK: HWBOOT.MAC

for /f "delims=" %%a in ('findstr /B "Errors detected" HWBOOT.LST') do set "errdet=%%a"
if "%errdet%"=="Errors detected:  0" (
  echo HWBOOT COMPILED SUCCESSFULLY
) ELSE (
  findstr /RC:"^[ABDEILMNOPQRTUZ] " HWBOOT.LST
  echo ======= %errdet% =======
  goto :Failed
)

%rt11exe% LINK HWBOOT /MAP:HWBOOT.MAP

for /f "delims=" %%a in ('findstr /B "Undefined globals" HWBOOT.MAP') do set "undefg=%%a"
if "%undefg%"=="" (
  type HWBOOT.MAP
  echo.
  echo HWBOOT LINKED SUCCESSFULLY
) ELSE (
  echo ======= LINK FAILED =======
  goto :Failed
)

tools\Sav2BkBin.exe HWBOOT.SAV HWYENC.BIN
dir /-c HWYENC.BIN|findstr /R /C:"HWYENC.BIN"

echo %ESCchar%[92mSUCCESS%ESCchar%[0m
exit

:Failed
@echo off
echo %ESCchar%[91mFAILED%ESCchar%[0m
exit /b

:FileSize
set fsize=%~z1
exit /b 0
