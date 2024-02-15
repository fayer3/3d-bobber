@echo off

set "VERSION=v2.1"

echo checking current directory...
if not exist assets (
	echo looks like you executed this patcher in the wrong location.
	echo execute this file next to the 'assets' folder
	pause
	GOTO :EOF
)
if exist pack_temp (
	rmdir /S /Q pack_temp
)
echo copy assets to destination
xcopy /E .\assets .\pack_temp\assets\
echo copy pack files
copy pack.mcmeta .\pack_temp\
copy permissions.txt .\pack_temp\

echo creating fast
call :create_pack pack_fast fast bobber3Dbasic false

echo creating fast line
call :create_pack pack_fast_line fast-with-line bobber3Dbasic true

echo creating fancy
call :create_pack pack_fancy fancy bobber3DcomplexFast false

echo creating fancy line
call :create_pack pack_fancy_line fancy-with-line bobber3DcomplexFast true

echo creating fancy flat
call :create_pack pack_fancy_flat flat bobber3Dflat false

echo creating fancy flat line
call :create_pack pack_fancy_flat_line flat-with-line bobber3Dflat true

GOTO :EOF

:create_pack
copy .\images\%~1.png .\pack_temp\pack.png

if %~4 == true (
	powershell -Command "(gc '.\assets\minecraft\shaders\core\rendertype_entity_cutout.fsh') -replace '#define bobbermode bobber3Dbasic', '#define bobbermode %~3' -replace '//#define bobberString', '#define bobberString'| Out-File -encoding ASCII '.\pack_temp\assets\minecraft\shaders\core\rendertype_entity_cutout.fsh'"
) else (
	powershell -Command "(gc '.\assets\minecraft\shaders\core\rendertype_entity_cutout.fsh') -replace '#define bobbermode bobber3Dbasic', '#define bobbermode %~3'| Out-File -encoding ASCII '.\pack_temp\assets\minecraft\shaders\core\rendertype_entity_cutout.fsh'"
)
d:\Programme\7-Zip\7z.exe a -mmt=on -mx=9 .\3D-fishing-hook-bobber-%VERSION%-%~2.zip .\pack_temp\*
GOTO :EOF
