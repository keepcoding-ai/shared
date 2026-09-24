# hands - instalador para Windows
#
# Uso (cole no PowerShell):
#   irm https://raw.githubusercontent.com/keepcoding-ai/shared/main/hands/install.ps1 | iex
#
# Nao precisa de administrador: instala na pasta do usuario e ajusta apenas o
# PATH do usuario. Rodar de novo atualiza a versao instalada.
#
# ATENCAO ao editar: este arquivo e' ASCII puro e SEM BOM, de proposito. O BOM
# quebra o `irm | iex`, e acento sem BOM sai corrompido quando o arquivo e'
# salvo em disco e rodado no Windows PowerShell 5.1. ASCII acerta nos dois.

$ErrorActionPreference = 'Stop'

# A versao publicada. Para instalar outra: $env:HANDS_VERSION = '0.2.0' antes de rodar.
$Version = if ($env:HANDS_VERSION) { $env:HANDS_VERSION } else { '0.1.0' }
$Tag     = "hands-v$Version"
$BaseUrl = "https://github.com/keepcoding-ai/shared/releases/download/$Tag"

function Fail($mensagem) {
    Write-Host ""
    Write-Host "  Nao deu certo: $mensagem" -ForegroundColor Red
    Write-Host ""
    exit 1
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    # PowerShell moderno ja usa TLS 1.2; se falhar aqui, segue em frente.
}

Write-Host ""
Write-Host "  Instalando o hands $Version" -ForegroundColor Cyan
Write-Host ""

# --- Qual arquivo baixar -----------------------------------------------------

$arquitetura = $env:PROCESSOR_ARCHITECTURE
if (-not $arquitetura) { $arquitetura = 'AMD64' }

switch ($arquitetura.ToUpper()) {
    'AMD64' { $Asset = 'hands-windows-x64.exe' }
    'ARM64' { $Asset = 'hands-windows-x64.exe' }  # o Windows ARM roda o programa x64
    'X86'   { Fail "este computador e' de 32 bits, e o hands precisa de um Windows de 64 bits." }
    default { Fail "nao reconheci este computador ($arquitetura). Fale com o suporte." }
}

# --- Onde instalar -----------------------------------------------------------

$Destino  = Join-Path $env:LOCALAPPDATA 'Programs\hands'
$Programa = Join-Path $Destino 'hands.exe'

try {
    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
} catch {
    Fail "nao consegui criar a pasta de instalacao em $Destino."
}

# --- Baixar ------------------------------------------------------------------

$Temporario = Join-Path $Destino 'hands.exe.baixando'
$Url = "$BaseUrl/$Asset"

Write-Host "  Baixando... (sao cerca de 80 MB, pode levar um minuto)"

try {
    $progressoAntigo = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $Url -OutFile $Temporario -UseBasicParsing
    $ProgressPreference = $progressoAntigo
} catch {
    Fail "nao consegui baixar o programa. Verifique sua conexao com a internet e tente de novo."
}

if (-not (Test-Path $Temporario) -or (Get-Item $Temporario).Length -lt 1MB) {
    Remove-Item $Temporario -Force -ErrorAction SilentlyContinue
    Fail "o download veio incompleto. Tente de novo daqui a pouco."
}

# --- Colocar no lugar --------------------------------------------------------

try {
    Move-Item -Path $Temporario -Destination $Programa -Force
} catch {
    Remove-Item $Temporario -Force -ErrorAction SilentlyContinue
    Fail "o hands parece estar aberto agora. Feche a janela dele e rode esta instalacao de novo."
}

# --- Deixar o nome 'hands' disponivel no terminal ----------------------------

$PathDoUsuario = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $PathDoUsuario) { $PathDoUsuario = '' }

$jaEsta = $PathDoUsuario.Split(';') | Where-Object { $_.TrimEnd('\') -ieq $Destino.TrimEnd('\') }

if (-not $jaEsta) {
    try {
        $novo = if ($PathDoUsuario.Trim()) { "$($PathDoUsuario.TrimEnd(';'));$Destino" } else { $Destino }
        [Environment]::SetEnvironmentVariable('Path', $novo, 'User')
    } catch {
        Fail "instalei o programa, mas nao consegui deixa-lo acessivel pelo nome. Fale com o suporte."
    }
}

$env:Path = "$env:Path;$Destino"

# --- Conferir ----------------------------------------------------------------

try {
    $instalada = (& $Programa --version) 2>$null
} catch {
    $instalada = $null
}

if (-not $instalada) {
    Fail "o programa foi instalado mas nao respondeu. Tente de novo, ou fale com o suporte."
}

Write-Host ""
Write-Host "  Pronto. hands $($instalada.Trim()) instalado." -ForegroundColor Green
Write-Host ""
Write-Host "  Abra uma janela NOVA do terminal e digite:"
Write-Host ""
Write-Host "      hands" -ForegroundColor Cyan
Write-Host ""
