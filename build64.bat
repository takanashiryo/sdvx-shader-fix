@echo off
setlocal
cd /d "%~dp0"
echo Building sdvx_shader_fix_64bit.dll...
echo Build log: "%~dp0build64.log"
echo.
call :build %* >"%~dp0build64.log" 2>&1
set "BUILD64_RESULT=%ERRORLEVEL%"
type "%~dp0build64.log"
echo.
if "%BUILD64_RESULT%"=="0" (
  echo Build succeeded.
  echo DLL: "%~dp0sdvx_shader_fix_64bit.dll"
  echo PDB: "%~dp0sdvx_shader_fix_64bit.pdb"
) else (
  echo Build FAILED with exit code %BUILD64_RESULT%.
)
echo Log: "%~dp0build64.log"
if not "%BUILD64_NO_PAUSE%"=="1" (
  echo Press any key to close this window...
  pause >nul
)
exit /b %BUILD64_RESULT%

:build
if not exist "%~dp0tools\msvc_env.bat" (
  echo Missing build helper: tools\msvc_env.bat. Restore it from the repository.
  exit /b 1
)
call "%~dp0tools\msvc_env.bat" || exit /b 1
cd /d "%~dp0"

if not defined MINHOOK_DIR set "MINHOOK_DIR=..\minhook"
if not exist "%MINHOOK_DIR%\include\MinHook.h" set "MINHOOK_DIR=build\deps\minhook"
if not exist "%MINHOOK_DIR%\include\MinHook.h" (
  echo MinHook not found. Set MINHOOK_DIR or clone v1.3.4 into build\deps\minhook.
  exit /b 1
)

echo Generating fxc bytecode...
python shaders\gen_bytecode.py %* || exit /b 1

if not exist obj64 mkdir obj64

cl /nologo /O2 /Zi /W3 /utf-8 /MT /EHs- /GS- /I "%MINHOOK_DIR%\include" /I . ^
  /Foobj64\ /Fdobj64\sdvx_shader_fix_64bit.pdb ^
  sdvx_shader_fix.cpp ^
  "%MINHOOK_DIR%\src\buffer.c" "%MINHOOK_DIR%\src\hook.c" ^
  "%MINHOOK_DIR%\src\trampoline.c" "%MINHOOK_DIR%\src\hde\hde64.c" ^
  /link /DLL /DEBUG:FULL /MACHINE:X64 /OUT:sdvx_shader_fix_64bit.dll /PDB:sdvx_shader_fix_64bit.pdb ^
  user32.lib /OPT:REF /OPT:ICF /INCREMENTAL:NO || exit /b 1

echo Built sdvx_shader_fix_64bit.dll
exit /b 0
