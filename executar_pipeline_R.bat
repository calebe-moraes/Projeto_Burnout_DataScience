@echo off
setlocal
REM Executa a etapa R usando a raiz do repositorio, mesmo com duplo clique.
cd /d "%~dp0"

set "RSCRIPT="
for /f "delims=" %%I in ('where Rscript.exe 2^>nul') do if not defined RSCRIPT set "RSCRIPT=%%I"
if not defined RSCRIPT (
    for /d %%D in ("%ProgramFiles%\R\R-*") do (
        if exist "%%~fD\bin\Rscript.exe" set "RSCRIPT=%%~fD\bin\Rscript.exe"
    )
)

if not defined RSCRIPT (
    echo ERRO: Nao foi possivel localizar o Rscript.exe.
    echo Confirme a instalacao do R e se o executavel Rscript.exe esta disponivel.
    if /I not "%~1"=="--agendado" pause
    exit /b 1
)

set "LOGDIR=%LOCALAPPDATA%\Projeto_Burnout_Logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

"%RSCRIPT%" "analise_r\00_executar_pipeline.R" > "%LOGDIR%\ultima_execucao_r.log" 2>&1
set "CODIGO=%ERRORLEVEL%"
type "%LOGDIR%\ultima_execucao_r.log"
echo.
echo Log salvo em: %LOGDIR%\ultima_execucao_r.log

if not "%CODIGO%"=="0" (
    echo O pipeline falhou. Veja o erro no log acima.
) else (
    echo Pipeline executado com sucesso.
)
if /I not "%~1"=="--agendado" pause
exit /b %CODIGO%
