# ============================================================
# SCRIPT DE PÓS-INSTALAÇÃO AUTOMATIZADA (WINGET)
# ============================================================
# Uso local:  .\instaladorprogramas.ps1
# Uso remoto: irm https://SEU-LINK/instaladorprogramas.ps1 | iex
# ============================================================

# =====================================
# GARANTE EXECUÇÃO COMO ADMINISTRADOR
# =====================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Este script precisa ser executado como Administrador. Reabrindo com elevação..." -ForegroundColor Yellow
    # Troque a URL abaixo pelo link raw do seu script quando for usar via irm
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/yC0D3X/codex-setup/main/bootstrap.ps1 | iex`""
    exit
}

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

# =====================================
# VERIFICA SE TEM WINGET
# =====================================
Write-Host "`nVerificando Winget..." -ForegroundColor Cyan

$winget = Get-Command winget -ErrorAction SilentlyContinue

if (-not $winget) {
    Write-Host "Winget não encontrado. Instalando..." -ForegroundColor Yellow

    $url = "https://aka.ms/getwinget"
    $installer = "$env:TEMP\AppInstaller.msixbundle"

    Invoke-WebRequest -Uri $url -OutFile $installer
    Add-AppxPackage -Path $installer

    Write-Host "Winget instalado com sucesso!" -ForegroundColor Green
    Start-Sleep -Seconds 5
} else {
    Write-Host "Winget já está instalado." -ForegroundColor Green
}

Write-Host "INICIANDO A INSTALAÇÃO AUTOMATIZADA..." -ForegroundColor Red
Write-Host "Por favor, aguarde e não feche esta janela." -ForegroundColor Yellow
Write-Host "Alguns instaladores podem pedir permissão de administrador." -ForegroundColor DarkGray
Start-Sleep -Seconds 3

# =====================================
# OFFICE 2021 — BAIXA TEMPORARIAMENTE E INSTALA
# O instalador NÃO fica salvo permanentemente: vai pra uma pasta
# temporária e é apagado no final do script (bloco de limpeza).
# =====================================
# Troque pela URL do asset no seu GitHub Release, ex:
# https://github.com/SEU-USUARIO/SEU-REPO/releases/download/v1/OFFICE2021.exe
$officeUrl = "https://raw.githubusercontent.com/yC0D3X/codex-setup/main/OFFICE2021.exe"
$officeInstallPath = "C:\Program Files\Microsoft Office"

$tempDir = Join-Path $env:TEMP "InfoprimeSetup"
$officeTempPath = Join-Path $tempDir "OFFICE2021.exe"

if (Test-Path $officeInstallPath) {
    Write-Host "`nOffice já está instalado. Pulando instalação..." -ForegroundColor Green
} else {
    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        Write-Host "`n----------------------------------------"
        Write-Host "Baixando instalador do Office 2021..." -ForegroundColor Magenta
        Write-Host "----------------------------------------`n"
        Invoke-WebRequest -Uri $officeUrl -OutFile $officeTempPath -UseBasicParsing

        Write-Host "Instalando Office 2021... (aguardando o instalador terminar)" -ForegroundColor Magenta
        Start-Process -FilePath $officeTempPath -Wait

        # Alguns instaladores (ex: Click-to-Run) retornam antes de terminar de
        # verdade e continuam em segundo plano. Se for o seu caso, este loop
        # espera até a pasta de instalação aparecer (timeout de 15 min).
        $timeout = (Get-Date).AddMinutes(15)
        while (-not (Test-Path $officeInstallPath) -and (Get-Date) -lt $timeout) {
            Start-Sleep -Seconds 10
        }
    } catch {
        Write-Host "Falha ao baixar/instalar o Office: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =====================================
# LISTA DE PROGRAMAS (WINGET IDs)
# Para remover um programa, coloque um '#' no início da linha.
# =====================================
$programas = @(
    "Google.Chrome",
    "RARLab.WinRAR",
    "Adobe.Acrobat.Reader.64-bit",
    "Oracle.JavaRuntimeEnvironment",

    # ---------- .NET Runtimes ----------
    "Microsoft.DotNet.Runtime.3_1",   # .NET Core 3.1 (fora de suporte)
    "Microsoft.DotNet.Runtime.5",     # .NET 5 (fora de suporte)
    "Microsoft.DotNet.Runtime.6",     # .NET 6 (fora de suporte)
    "Microsoft.DotNet.Runtime.7",     # .NET 7 (fora de suporte)
    "Microsoft.DotNet.Runtime.8",     # .NET 8 (LTS — até nov/2026)
    "Microsoft.DotNet.Runtime.9",     # .NET 9 (STS — até nov/2026)
    "Microsoft.DotNet.Runtime.10"     # .NET 10 (LTS — até nov/2028)
)

# Loop que percorre a lista e instala um por um
foreach ($id in $programas) {
    Write-Host "`n----------------------------------------"
    Write-Host "INSTALANDO: $id" -ForegroundColor Magenta
    Write-Host "----------------------------------------`n"

    winget install -e --id $id --source winget --accept-source-agreements --accept-package-agreements --silent
}

Write-Host "`n========================================"
Write-Host "INSTALAÇÃO FINALIZADA COM SUCESSO!" -ForegroundColor DarkGreen
Write-Host "========================================"

# =====================================
# LIMPEZA — remove o instalador do Office baixado
# =====================================
if (Test-Path $tempDir) {
    Write-Host "`nLimpando arquivos temporários..." -ForegroundColor Cyan
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

# =====================================
# AUTODELEÇÃO — só faz algo se o script foi salvo em disco
# (via irm | iex ele roda só em memória, então isso é ignorado nesse caso)
# =====================================
if ($MyInvocation.MyCommand.Path) {
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -Command Start-Sleep -Seconds 2; Remove-Item -Force '$scriptPath'"
}

# ReadKey só funciona em console interativo; evita erro ao rodar via irm/tarefas agendada
if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Pressione qualquer tecla para sair..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
