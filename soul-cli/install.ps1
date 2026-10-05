# soul-cli - instalador para Windows
#
# Uso (cole no PowerShell):
#   irm https://raw.githubusercontent.com/keepcoding-ai/shared/main/soul-cli/install.ps1 | iex
#
# Nao precisa de administrador: instala na pasta do usuario e ajusta apenas o
# PATH do usuario. Rodar de novo atualiza a versao instalada.
#
# Qual versao: o instalador pergunta ao GitHub e pega a MAIOR versao publicada
# (soul-cli-v*), o mesmo canal 'latest' que o programa instalado usa para se
# atualizar. Para so' as versoes promovidas depois de uso: $env:SOUL_CLI_CHANNEL
# = 'stable' antes de rodar. Para uma versao exata: $env:SOUL_CLI_VERSION = '0.2.0'.
#
# O arquivo baixado so vira o programa se a soma SHA-256 bater com a do
# SHA256SUMS da release. Sem isso, nada e instalado.
#
# ATENCAO ao editar: este arquivo e' ASCII puro e SEM BOM, de proposito. O BOM
# quebra o `irm | iex`, e acento sem BOM sai corrompido quando o arquivo e'
# salvo em disco e rodado no Windows PowerShell 5.1. ASCII acerta nos dois.

$ErrorActionPreference = 'Stop'

$ApiUrl      = 'https://api.github.com/repos/keepcoding-ai/shared/releases?per_page=100'
$DownloadUrl = 'https://github.com/keepcoding-ai/shared/releases/download'
$Prefixo     = 'soul-cli-v'

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

# --- Qual arquivo baixar -----------------------------------------------------

$arquitetura = $env:PROCESSOR_ARCHITECTURE
if (-not $arquitetura) { $arquitetura = 'AMD64' }

switch ($arquitetura.ToUpper()) {
    'AMD64' { $Asset = 'soul-cli-windows-x64.exe' }
    'ARM64' { $Asset = 'soul-cli-windows-x64.exe' }  # o Windows ARM roda o programa x64
    'X86'   { Fail "este computador e' de 32 bits, e o soul-cli precisa de um Windows de 64 bits." }
    default { Fail "nao reconheci este computador ($arquitetura). Fale com o suporte." }
}

# --- Qual versao -------------------------------------------------------------

$Canal = if ($env:SOUL_CLI_CHANNEL -eq 'stable') { 'stable' } else { 'latest' }

if ($env:SOUL_CLI_VERSION) {
    if ($env:SOUL_CLI_VERSION -notmatch '^\d+\.\d+\.\d+$') { Fail "a versao pedida ($($env:SOUL_CLI_VERSION)) nao tem o formato 0.2.0." }
    $Version = $env:SOUL_CLI_VERSION
} else {
    try {
        $progressoAntigo = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        $releases = Invoke-RestMethod -Uri $ApiUrl -Headers @{ 'User-Agent' = 'soul-cli-install'; 'Accept' = 'application/vnd.github+json' } -UseBasicParsing
        $ProgressPreference = $progressoAntigo
    } catch {
        Fail "nao consegui perguntar ao GitHub qual e' a versao mais nova. Verifique sua conexao com a internet e tente de novo."
    }
    $melhor = $null
    foreach ($r in @($releases)) {
        if ($r.draft) { continue }
        if ($r.prerelease -and $Canal -ne 'latest') { continue }
        if ($r.tag_name -notmatch '^soul-cli-v(\d+\.\d+\.\d+)$') { continue }
        $nomes = @($r.assets | ForEach-Object { $_.name })
        if (($nomes -notcontains $Asset) -or ($nomes -notcontains 'SHA256SUMS')) { continue }
        $v = [version]$Matches[1]
        if ((-not $melhor) -or ($v -gt $melhor)) { $melhor = $v }
    }
    if (-not $melhor) {
        if ($Canal -eq 'latest') { Fail "ainda nao ha nenhuma versao publicada do soul-cli para este computador." }
        Fail "ainda nao ha versao estavel do soul-cli. Para instalar a mais nova, rode de novo sem `$env:SOUL_CLI_CHANNEL."
    }
    $Version = $melhor.ToString()
}

$Tag     = "$Prefixo$Version"
$BaseUrl = "$DownloadUrl/$Tag"

Write-Host ""
Write-Host "  Instalando o soul-cli $Version" -ForegroundColor Cyan
Write-Host ""

# --- Onde instalar -----------------------------------------------------------

$Destino  = Join-Path $env:LOCALAPPDATA 'Programs\soul-cli'
$Programa = Join-Path $Destino 'soul-cli.exe'

try {
    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
} catch {
    Fail "nao consegui criar a pasta de instalacao em $Destino."
}

# --- Baixar e conferir -------------------------------------------------------

$Temporario = Join-Path $Destino 'soul-cli.exe.baixando'
$Url = "$BaseUrl/$Asset"

try {
    $progressoAntigo = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    $somas = (Invoke-WebRequest -Uri "$BaseUrl/SHA256SUMS" -UseBasicParsing).Content
    if ($somas -is [byte[]]) { $somas = [Text.Encoding]::ASCII.GetString($somas) }
    $ProgressPreference = $progressoAntigo
} catch {
    Fail "nao consegui baixar a lista de conferencia (SHA256SUMS) da versao $Version."
}

$esperada = $null
foreach ($linha in ($somas -split "`n")) {
    if ($linha.Trim() -match '^([0-9a-fA-F]{64})\s+\*?(.+?)\s*$' -and $Matches[2] -eq $Asset) { $esperada = $Matches[1].ToLower() }
}
if (-not $esperada) { Fail "a versao $Version nao tem arquivo para este computador." }

Write-Host "  Baixando... (sao cerca de 120 MB, pode levar um minuto)"

try {
    $progressoAntigo = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $Url -OutFile $Temporario -UseBasicParsing
    $ProgressPreference = $progressoAntigo
} catch {
    Remove-Item $Temporario -Force -ErrorAction SilentlyContinue
    Fail "nao consegui baixar o programa. Verifique sua conexao com a internet e tente de novo."
}

if (-not (Test-Path $Temporario) -or (Get-Item $Temporario).Length -lt 1MB) {
    Remove-Item $Temporario -Force -ErrorAction SilentlyContinue
    Fail "o download veio incompleto. Tente de novo daqui a pouco."
}

# O UNICO PORTAO: bytes que nao batem com a soma publicada nao viram programa.
$obtida = (Get-FileHash -Path $Temporario -Algorithm SHA256).Hash.ToLower()
if ($obtida -ne $esperada) {
    Remove-Item $Temporario -Force -ErrorAction SilentlyContinue
    Fail "o arquivo baixado nao confere com a soma de verificacao publicada. Nada foi instalado. Tente de novo daqui a pouco."
}

# --- Colocar no lugar --------------------------------------------------------

try {
    Move-Item -Path $Temporario -Destination $Programa -Force
} catch {
    Remove-Item $Temporario -Force -ErrorAction SilentlyContinue
    Fail "o soul-cli parece estar aberto agora. Feche a janela dele e rode esta instalacao de novo."
}

# --- Deixar o nome 'soul-cli' disponivel no terminal -------------------------

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
        foreach ($nome in @('soul-cli.exe', 'soul-cli.cmd', 'soul-cli.bat')) {
            $candidato = Join-Path $pasta $nome
            if (Test-Path -LiteralPath $candidato -PathType Leaf) { return $candidato }
        }
    }
    return $null
}

# SOUL_CLI_SKIP_PATH=1 existe so para a prova do instalador (nao mexer no PATH
# de quem testa). Quem instala de verdade nunca precisa dele.
$vencedor = $null
if ($env:SOUL_CLI_SKIP_PATH -ne '1') {
    $atual  = PathDoUsuario
    $jaEsta = Entradas $atual | Where-Object { $_.Trim().TrimEnd('\') -ieq $Destino.TrimEnd('\') }

    if (-not $jaEsta) {
        try {
            [Environment]::SetEnvironmentVariable('Path', ((@(Entradas $atual) + @($Destino)) -join ';'), 'User')
        } catch {
            Fail "instalei o programa, mas nao consegui deixa-lo acessivel pelo nome. Fale com o suporte."
        }
    }

    # Outra copia do soul-cli pode estar ganhando de nos (o instalador antigo, uma
    # copia por npm). "Pronto, instalado" na tela e programa velho no terminal e'
    # a pior falha: calada, e com mensagem de sucesso na frente. A pasta
    # %LOCALAPPDATA%\Programs\soul-cli e' so nossa (um unico arquivo), entao
    # move-la para a frente do PATH do usuario so pode sombrear o comando
    # 'soul-cli' - que e' o que quem colou a linha pediu. O resto do PATH fica
    # na mesma ordem. Se ainda assim perdermos (copia no PATH da MAQUINA, que
    # exige administrador), nao insistimos: avisamos.
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
Write-Host "  Pronto. soul-cli $Version instalado." -ForegroundColor Green

$conflito = $vencedor -and (Split-Path $vencedor -Parent).TrimEnd('\') -ine $Destino.TrimEnd('\')

if ($conflito) {
    Write-Host ""
    Write-Host "  Atencao: existe outra copia do soul-cli neste computador, e e' ela" -ForegroundColor Yellow
    Write-Host "  que o terminal abre:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "      $vencedor"
    Write-Host ""
    Write-Host "  Enquanto esse arquivo existir, voce nao vai usar a versao que"
    Write-Host "  acabou de ser instalada. Peca ao suporte para remover esse arquivo."
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "  Abra uma janela NOVA do terminal e digite:"
    Write-Host ""
    Write-Host "      soul-cli" -ForegroundColor Cyan
    Write-Host ""
}
