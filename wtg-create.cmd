@echo off
net.exe session 1>NUL 2>NUL || (echo Please run this script as an administrator! && pause && exit /b 1)

:home
cls
title wtg-create by @aaviator42
echo ------------------------
echo ==WindowsToGo Creator==
echo v0.3
echo by --@aaviator42
echo ------------------------


echo Select an option:
echo 1. Create WTG disk
echo 2. Help
echo 3. Exit

choice /c 123 /n

if errorlevel==3 title  && exit /b 0
if errorlevel==2 goto :help
if errorlevel==1 goto :start

:help
cls
echo For help and troubleshooting, see "readme.txt".
echo:
pause
goto :home


:start
cls
echo What do you want to create a WTG disk from?

echo 1. Windows ISO File ["windows.iso"]
echo 2. WIM image        ["install.wim"]
echo 3. [cancel]
choice /c 123 /n

if errorlevel==3 goto :home
if errorlevel==2 (
	set mode=wim
	set "file=%~dp0install.wim"
)

if errorlevel==1 (
	set mode=iso 
	set "file=%~dp0windows.iso"
)

if not exist "%~dp0imagex.exe" (
	echo:
	echo [ERROR]
	echo imagex.exe not found! 
	echo See help for more info

	pause
	goto :home
)

echo:
cls
echo Checking for file...

if not exist "%file%" (
	echo [ERROR]
	echo File "%file%" not found! 
	echo See help for more info

	pause
	goto :home
)


echo File found!
echo File is : %file%
echo Mode is : %mode%

echo:
echo -------
echo:
echo Listing drives...

echo LIST DISK >diskpart.txt
diskpart /s diskpart.txt
echo:
echo Select a drive number:
echo (press just enter to cancel)
set /p disk=

if "%disk%"=="" (
	echo Operation cancelled!
	pause
	goto :home
)

echo:
echo Selected disk is "%disk%"
echo [!!] DISK WILL BE FORMATTED
echo [!!] ALL PREVIOUS DATA AND PARTITIONS WILL BE ERASED
echo [!!] PLEASE RE-CHECK AND CONFIRM
echo Do you wish to proceed? (y/n)

choice /c yn /n
if errorlevel==2 (
	echo Operation cancelled!
	pause
	goto :home
)
echo:
echo Formatting disk...

echo select disk %disk% >diskpart.txt
echo clean >>diskpart.txt
echo create partition primary >>diskpart.txt
echo format fs=ntfs quick label=wtg >>diskpart.txt
echo select partition 1 >>diskpart.txt
echo active >>diskpart.txt
echo assign letter=R >>diskpart.txt
diskpart /s diskpart.txt

if not errorlevel==0 (
	echo [ERROR]
	echo Disk format failed!
	echo Operation cancelled!
	pause
	goto :home
)


echo Format successful!
del diskpart.txt


if %mode%==iso (
	echo:
	echo -------
	echo:
	echo Extracting "install.wim" from ISO...
	if not exist "%~dp07z.exe" (
		echo:
		echo [ERROR]
		echo 7z.exe not found! 
		echo See help for more info

		pause
		goto :home
	)

	"%~dp07z.exe" e "%file%" "-o%~dp0" install.wim  -r
	set "file=%~dp0install.wim"
	if not errorlevel==0 (
		echo [ERROR]
		echo "install.wim" extraction failed!
		echo Operation cancelled!
		pause
		goto :home
	)
	
)

echo:
echo -------
echo:


echo Applying wim file to drive...
echo THIS MAY TAKE A LONG TIME!
echo:

"%~dp0imagex.exe" /apply "%file%" 1 R:\

if not errorlevel==0 (
	echo [ERROR]
	echo Couldn't extract files to drive!
	echo Operation cancelled!
	pause
	goto :home
)

echo:
echo Files extracted to drive! 

echo:
echo -------
echo:

echo Creating boot entries...
R:
cd Windows\System32
bcdboot.exe R:\Windows /s R: /f ALL

if not errorlevel==0 (
	echo [ERROR]
	echo Couldn't create boot entires!
	echo Operation cancelled!
	pause
	goto :home
)

echo ALL DONE! Your WTG drive is ready!
echo Drive mounted at "R:"
echo Have fun!
echo:
echo -------
echo:

echo WindowsToGo drive created with wtg-create >> R:\__info.txt
echo @aaviator42 >> R:\__info.txt
pause

:eof
