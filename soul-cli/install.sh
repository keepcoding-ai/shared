#!/bin/sh
# soul-cli — instalador para Mac e Linux
#
# Uso (cole no terminal):
#   curl -fsSL https://raw.githubusercontent.com/keepcoding-ai/shared/main/soul-cli/install.sh | sh
#
# Não precisa de administrador: instala na pasta do usuário. Rodar de novo
# atualiza a versão instalada.
#
# Qual versão: o instalador pergunta ao GitHub e pega a MAIOR versão publicada
# (soul-cli-v*), o mesmo canal `latest` que o programa instalado usa para se
# atualizar. Para só as versões promovidas depois de uso: SOUL_CLI_CHANNEL=stable
# antes de rodar. Para uma versão exata: SOUL_CLI_VERSION=0.2.0.
#
# O arquivo baixado só vira o programa se a soma SHA-256 bater com a do
# SHA256SUMS da release. Sem isso, nada é instalado.

set -eu

API_URL="https://api.github.com/repos/keepcoding-ai/shared/releases?per_page=100"
DOWNLOAD_URL="https://github.com/keepcoding-ai/shared/releases/download"
PREFIXO="soul-cli-v"

falhou() {
  printf '\n  Não deu certo: %s\n\n' "$1" >&2
  exit 1
}

baixar() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -H 'User-Agent: soul-cli-install' "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --header='User-Agent: soul-cli-install' "$1" -O "$2"
  else
    falhou "este computador não tem as ferramentas de download (curl ou wget). Fale com o suporte."
  fi
}

soma_de() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d ' ' -f 1
  else
    falhou "este computador não tem sha256sum nem shasum para conferir o download. Fale com o suporte."
  fi
}

# --- Qual arquivo baixar -----------------------------------------------------

sistema="$(uname -s 2>/dev/null || echo desconhecido)"
maquina="$(uname -m 2>/dev/null || echo desconhecida)"

case "$sistema" in
  Darwin)
    case "$maquina" in
      arm64|aarch64) ASSET="soul-cli-macos-arm64" ;;
      x86_64)        ASSET="soul-cli-macos-x64" ;;
      *) falhou "não reconheci este Mac ($maquina). Fale com o suporte." ;;
    esac
    ;;
  Linux)
    case "$maquina" in
      x86_64|amd64)  ASSET="soul-cli-linux-x64" ;;
      aarch64|arm64) ASSET="soul-cli-linux-arm64" ;;
      *) falhou "não reconheci este computador ($maquina). Fale com o suporte." ;;
    esac
    ;;
  *)
    falhou "este sistema ($sistema) não é suportado. Fale com o suporte."
    ;;
esac

TMP_DIR="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/soul-cli-install.$$")"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

# --- Qual versão -------------------------------------------------------------

CANAL="latest"
[ "${SOUL_CLI_CHANNEL:-}" = "stable" ] && CANAL="stable"

if [ -n "${SOUL_CLI_VERSION:-}" ]; then
  case "$SOUL_CLI_VERSION" in
    *[!0-9.]*|""|.*|*.) falhou "a versão pedida (${SOUL_CLI_VERSION}) não tem o formato 0.2.0." ;;
  esac
  VERSION="$SOUL_CLI_VERSION"
else
  baixar "$API_URL" "$TMP_DIR/releases.json" \
    || falhou "não consegui perguntar ao GitHub qual é a versão mais nova. Verifique sua conexão com a internet e tente de novo."
  # A resposta do GitHub é um JSON indentado: os campos de cada release ficam a
  # 4 espaços, os dos arquivos dela mais fundo. Lemos só os de 4 espaços.
  VERSION="$(
    awk -v canal="$CANAL" -v prefixo="$PREFIXO" '
      function fecha() {
        if (tag != "" && !draft && (canal == "latest" || !pre) && tag ~ ("^" prefixo "[0-9]+\\.[0-9]+\\.[0-9]+$")) print substr(tag, length(prefixo) + 1)
        tag = ""; draft = 0; pre = 0
      }
      /^  \{/ { fecha() }
      /^    "tag_name":/ { tag = $2; gsub(/[",]/, "", tag) }
      /^    "draft":/ { draft = ($2 ~ /true/) }
      /^    "prerelease":/ { pre = ($2 ~ /true/) }
      END { fecha() }
    ' "$TMP_DIR/releases.json" | sort -t . -k1,1n -k2,2n -k3,3n | tail -n 1
  )"
  if [ -z "$VERSION" ]; then
    if [ "$CANAL" = "latest" ]; then
      falhou "ainda não há nenhuma versão publicada do soul-cli."
    fi
    falhou "ainda não há versão estável do soul-cli. Para instalar a mais nova, rode de novo sem SOUL_CLI_CHANNEL."
  fi
fi

TAG="${PREFIXO}${VERSION}"
BASE_URL="${DOWNLOAD_URL}/${TAG}"

printf '\n  Instalando o soul-cli %s\n\n' "$VERSION"

# --- Conferência: a soma esperada ---------------------------------------------

baixar "${BASE_URL}/SHA256SUMS" "$TMP_DIR/SHA256SUMS" \
  || falhou "não consegui baixar a lista de conferência (SHA256SUMS) da versão ${VERSION}."

ESPERADA="$(awk -v a="$ASSET" '{ n = $2; sub(/^\*/, "", n); if (n == a && length($1) == 64) print tolower($1) }' "$TMP_DIR/SHA256SUMS" | head -n 1)"
[ -n "$ESPERADA" ] || falhou "a versão ${VERSION} não tem arquivo para este computador."

# --- Onde instalar -----------------------------------------------------------

DESTINO="${HOME}/.local/bin"
PROGRAMA="${DESTINO}/soul-cli"

mkdir -p "$DESTINO" 2>/dev/null || falhou "não consegui criar a pasta de instalação em $DESTINO."

# --- Baixar e conferir -------------------------------------------------------

TEMPORARIO="${PROGRAMA}.baixando"
rm -f "$TEMPORARIO" 2>/dev/null || true

printf '  Baixando... (são cerca de 120 MB, pode levar um minuto)\n'

if ! baixar "${BASE_URL}/${ASSET}" "$TEMPORARIO"; then
  rm -f "$TEMPORARIO" 2>/dev/null || true
  falhou "não consegui baixar o programa. Verifique sua conexão com a internet e tente de novo."
fi

tamanho="$(wc -c < "$TEMPORARIO" 2>/dev/null || echo 0)"
if [ "$tamanho" -lt 1000000 ]; then
  rm -f "$TEMPORARIO" 2>/dev/null || true
  falhou "o download veio incompleto. Tente de novo daqui a pouco."
fi

# O ÚNICO PORTÃO: bytes que não batem com a soma publicada não viram programa.
OBTIDA="$(soma_de "$TEMPORARIO")"
if [ "$OBTIDA" != "$ESPERADA" ]; then
  rm -f "$TEMPORARIO" 2>/dev/null || true
  falhou "o arquivo baixado não confere com a soma de verificação publicada. Nada foi instalado. Tente de novo daqui a pouco."
fi

# --- Colocar no lugar --------------------------------------------------------

chmod +x "$TEMPORARIO" 2>/dev/null || true

# No Mac, o sistema marca tudo que veio da internet como suspeito.
if [ "$sistema" = "Darwin" ] && command -v xattr >/dev/null 2>&1; then
  xattr -d com.apple.quarantine "$TEMPORARIO" >/dev/null 2>&1 || true
fi

mv -f "$TEMPORARIO" "$PROGRAMA" 2>/dev/null \
  || falhou "o soul-cli parece estar aberto agora. Feche a janela dele e rode esta instalação de novo."

# --- Deixar o nome 'soul-cli' disponível no terminal --------------------------

precisa_reabrir=0
case ":${PATH}:" in
  *":${DESTINO}:"*) ;;
  *)
    precisa_reabrir=1
    linha="export PATH=\"\$HOME/.local/bin:\$PATH\""
    for perfil in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
      [ -f "$perfil" ] || continue
      grep -qF '.local/bin' "$perfil" 2>/dev/null && continue
      printf '\n# soul-cli\n%s\n' "$linha" >> "$perfil" 2>/dev/null || true
    done
    # Se o usuário não tinha nenhum desses arquivos, cria o mais básico.
    if [ ! -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.profile" ]; then
      printf '\n# soul-cli\n%s\n' "$linha" >> "$HOME/.profile" 2>/dev/null || true
    fi
    ;;
esac

# --- Outra cópia do soul-cli pode estar ganhando de nós -----------------------
#
# Aqui NÃO reordenamos o PATH de ninguém: ~/.local/bin é uma pasta compartilhada
# com outros programas do usuário, e colocá-la na frente mudaria qual versão ele
# abre de TUDO o que estiver lá dentro. Detectamos e avisamos, nomeando o
# arquivo que está ganhando. O PATH que vale é o da PRÓXIMA janela: se acabamos
# de escrever a linha no perfil, ~/.local/bin entra na frente e nós ganhamos.

if [ "$precisa_reabrir" = "1" ]; then
  PATH_PREVISTO="${DESTINO}:${PATH}"
else
  PATH_PREVISTO="${PATH}"
fi

vencedor=""
ifs_antigo="$IFS"
IFS=':'
for pasta in $PATH_PREVISTO; do
  [ -n "$pasta" ] || continue
  candidato="${pasta}/soul-cli"
  [ -f "$candidato" ] || continue
  # O nosso programa conta por existir; a conferência `--version` logo abaixo é
  # que prova que ele executa.
  if [ "$candidato" = "$PROGRAMA" ] || [ -x "$candidato" ]; then
    vencedor="$candidato"
    break
  fi
done
IFS="$ifs_antigo"

conflito=0
if [ -n "$vencedor" ] && [ "$vencedor" != "$PROGRAMA" ]; then
  conflito=1
fi

# --- Conferir ----------------------------------------------------------------

instalada="$("$PROGRAMA" --version 2>/dev/null || true)"

if [ -z "$instalada" ]; then
  falhou "o programa foi instalado mas não respondeu. Tente de novo, ou fale com o suporte."
fi

printf '\n  Pronto. soul-cli %s instalado.\n' "$VERSION"

if [ "$conflito" = "1" ]; then
  printf '\n  Atenção: existe outra cópia do soul-cli neste computador, e é ela\n'
  printf '  que o terminal abre:\n\n      %s\n\n' "$vencedor"
  printf '  Enquanto esse arquivo existir, você não vai usar a versão que\n'
  printf '  acabou de ser instalada. Peça ao suporte para remover esse arquivo.\n\n'
elif [ "$precisa_reabrir" = "1" ]; then
  printf '\n  Abra uma janela NOVA do terminal e digite:\n\n      soul-cli\n\n'
else
  printf '\n  Para começar, digite:\n\n      soul-cli\n\n'
fi
