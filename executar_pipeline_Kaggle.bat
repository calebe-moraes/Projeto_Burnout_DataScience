@echo off
setlocal
REM Executa somente o pipeline Kaggle, a partir da raiz do repositorio.
cd /d "%~dp0"

set "RSCRIPT="
for /f "delims=" %%I in ('where Rscript.exe 2^>nul') do if not defined RSCRIPT set "RSCRIPT=%%I"
if not defined RSCRIPT (
    for /d %%D in ("%ProgramFiles%\R\R-*") do (
        if exist "%%~fD\bin\Rscript.exe" set "RSCRIPT=%%~fD\bin\Rscript.exe"
    )
)
if not defined RSCRIPT (
    for /d %%D in ("%ProgramFiles%\R\R-*") do (
        if exist "%%~fD\bin\x64\Rscript.exe" set "RSCRIPT=%%~fD\bin\x64\Rscript.exe"
    )
)

if not defined RSCRIPT (
    echo ERRO: Nao foi possivel localizar Rscript.exe.
    echo Verifique se o R esta instalado no Windows.
    if /I not "%~1"=="--agendado" pause
    exit /b 1
)

set "LOGDIR=%LOCALAPPDATA%\Projeto_Burnout_Logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

"%RSCRIPT%" "analise_r\00_executar_pipeline_kaggle.R" > "%LOGDIR%\ultima_execucao_kaggle.log" 2>&1
set "CODIGO=%ERRORLEVEL%"
type "%LOGDIR%\ultima_execucao_kaggle.log"
echo.
echo Log salvo em: %LOGDIR%\ultima_execucao_kaggle.log

if not "%CODIGO%"=="0" (
    echo ERRO: Pipeline Kaggle falhou. Confira o log acima.
) else (
    echo Pipeline Kaggle executado com sucesso.
)
if /I not "%~1"=="--agendado" pause
exit /b %CODIGO%
