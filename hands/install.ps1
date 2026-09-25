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

function Entradas($texto) {
    if (-not $texto) { return @() }
    $texto.Split(';') | Where-Object { $_ -and $_.Trim() }
}

function PathDoUsuario {
    $v = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($v) { $v } else { '' }
}

# Quem o terminal REALMENTE abre numa janela nova. Nao usamos $env:Path porque a
# sessao atual pode estar suja; o Windows compoe primeiro as entradas da maquina
# e depois as do usuario, e e' essa ordem que vale.
function QuemGanha {
    $todas = @()
    $todas += Entradas ([Environment]::GetEnvironmentVariable('Path', 'Machine'))
    $todas += Entradas (PathDoUsuario)
    foreach ($entrada in $todas) {
        $pasta = [Environment]::ExpandEnvironmentVariables($entrada.Trim()).TrimEnd('\')
        if (-not $pasta) { continue }
        foreach ($nome in @('hands.exe', 'hands.cmd', 'hands.bat')) {
            $candidato = Join-Path $pasta $nome
            if (Test-Path -LiteralPath $candidato -PathType Leaf) { return $candidato }
        }
    }
    return $null
}

$atual  = PathDoUsuario
$jaEsta = Entradas $atual | Where-Object { $_.Trim().TrimEnd('\') -ieq $Destino.TrimEnd('\') }

if (-not $jaEsta) {
    try {
        [Environment]::SetEnvironmentVariable('Path', ((@(Entradas $atual) + @($Destino)) -join ';'), 'User')
    } catch {
        Fail "instalei o programa, mas nao consegui deixa-lo acessivel pelo nome. Fale com o suporte."
    }
}

# --- Outra copia do hands pode estar ganhando de nos -------------------------
#
# Achado em teste real: quem ja tinha o hands instalado por npm (%APPDATA%\npm)
# continuava abrindo a copia ANTIGA, porque aquela pasta vem antes no PATH.
# "Pronto, instalado" na tela e binario velho no terminal e' a pior falha que
# existe: calada, e com mensagem de sucesso na frente.
#
# Resposta: mover a NOSSA pasta para a frente do PATH do usuario. E' seguro
# porque essa pasta e' exclusivamente nossa e so tem o hands.exe dentro, entao o
# unico comando que ela pode sombrear e' o 'hands' - que e' exatamente o que
# quem colou a linha de instalacao pediu. A ordem relativa de todo o resto do
# PATH fica intacta.
#
# Se ainda assim perdermos (a outra copia esta' no PATH da MAQUINA, que exige
# administrador para mexer), nao insistimos: avisamos, nomeando o caminho.

$vencedor = QuemGanha

if ($vencedor -and (Split-Path $vencedor -Parent).TrimEnd('\') -ine $Destino.TrimEnd('\')) {
    try {
        $outras = Entradas (PathDoUsuario) | Where-Object { $_.Trim().TrimEnd('\') -ine $Destino.TrimEnd('\') }
        [Environment]::SetEnvironmentVariable('Path', ((@($Destino) + @($outras)) -join ';'), 'User')
    } catch {
        # Nao conseguimos reordenar; o aviso no fim ainda sai.
    }
    $vencedor = QuemGanha
}

$env:Path = "$Destino;$env:Path"

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

$conflito = $vencedor -and (Split-Path $vencedor -Parent).TrimEnd('\') -ine $Destino.TrimEnd('\')

if ($conflito) {
    Write-Host ""
    Write-Host "  Atencao: existe outra copia do hands neste computador, mais antiga," -ForegroundColor Yellow
    Write-Host "  e e' ela que o terminal abre:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "      $vencedor"
    Write-Host ""
    Write-Host "  Enquanto esse arquivo existir, voce nao vai usar a versao que"
    Write-Host "  acabou de ser instalada, e ela nao se atualiza sozinha."
    Write-Host ""
    $pastaVencedora = Split-Path $vencedor -Parent
    $temNodeModules = Test-Path -LiteralPath (Join-Path $pastaVencedora 'node_modules\hands')
    if ($temNodeModules -or $vencedor -match '\\npm\\' -or $vencedor -match '\\node_modules\\') {
        Write-Host "  Para remover, cole esta linha e aperte Enter:"
        Write-Host ""
        Write-Host "      npm uninstall -g hands" -ForegroundColor Cyan
    } else {
        Write-Host "  Peca ao suporte para remover esse arquivo."
    }
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "  Abra uma janela NOVA do terminal e digite:"
    Write-Host ""
    Write-Host "      hands" -ForegroundColor Cyan
    Write-Host ""
}
