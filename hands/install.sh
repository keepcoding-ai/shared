#!/bin/sh
# hands — instalador para Mac e Linux
#
# Uso (cole no terminal):
#   curl -fsSL https://raw.githubusercontent.com/keepcoding-ai/shared/main/hands/install.sh | sh
#
# Não precisa de administrador: instala na pasta do usuário. Rodar de novo
# atualiza a versão instalada.

set -eu

# A versão publicada. Para instalar outra: HANDS_VERSION=0.2.0 antes de rodar.
VERSION="${HANDS_VERSION:-0.1.0}"
TAG="hands-v${VERSION}"
BASE_URL="https://github.com/keepcoding-ai/shared/releases/download/${TAG}"

falhou() {
  printf '\n  Não deu certo: %s\n\n' "$1" >&2
  exit 1
}

printf '\n  Instalando o hands %s\n\n' "$VERSION"

# --- Qual arquivo baixar -----------------------------------------------------

sistema="$(uname -s 2>/dev/null || echo desconhecido)"
maquina="$(uname -m 2>/dev/null || echo desconhecida)"

case "$sistema" in
  Darwin)
    case "$maquina" in
      arm64|aarch64) ASSET="hands-macos-arm64" ;;
      x86_64)        ASSET="hands-macos-x64" ;;
      *) falhou "não reconheci este Mac ($maquina). Fale com o suporte." ;;
    esac
    ;;
  Linux)
    case "$maquina" in
      x86_64|amd64)  ASSET="hands-linux-x64" ;;
      aarch64|arm64) ASSET="hands-linux-arm64" ;;
      *) falhou "não reconheci este computador ($maquina). Fale com o suporte." ;;
    esac
    ;;
  *)
    falhou "este sistema ($sistema) não é suportado. Fale com o suporte."
    ;;
esac

# --- Onde instalar -----------------------------------------------------------

DESTINO="${HOME}/.local/bin"
PROGRAMA="${DESTINO}/hands"

mkdir -p "$DESTINO" 2>/dev/null || falhou "não consegui criar a pasta de instalação em $DESTINO."

# --- Baixar ------------------------------------------------------------------

TEMPORARIO="${PROGRAMA}.baixando"
URL="${BASE_URL}/${ASSET}"

printf '  Baixando... (são cerca de 80 MB, pode levar um minuto)\n'

baixar() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$1" -O "$2"
  else
    falhou "este computador não tem as ferramentas de download (curl ou wget). Fale com o suporte."
  fi
}

rm -f "$TEMPORARIO" 2>/dev/null || true

if ! baixar "$URL" "$TEMPORARIO"; then
  rm -f "$TEMPORARIO" 2>/dev/null || true
  falhou "não consegui baixar o programa. Verifique sua conexão com a internet e tente de novo."
fi

tamanho="$(wc -c < "$TEMPORARIO" 2>/dev/null || echo 0)"
if [ "$tamanho" -lt 1000000 ]; then
  rm -f "$TEMPORARIO" 2>/dev/null || true
  falhou "o download veio incompleto. Tente de novo daqui a pouco."
fi

# --- Colocar no lugar --------------------------------------------------------

chmod +x "$TEMPORARIO" 2>/dev/null || true

# No Mac, o sistema marca tudo que veio da internet como suspeito.
if [ "$sistema" = "Darwin" ] && command -v xattr >/dev/null 2>&1; then
  xattr -d com.apple.quarantine "$TEMPORARIO" >/dev/null 2>&1 || true
fi

mv -f "$TEMPORARIO" "$PROGRAMA" 2>/dev/null \
  || falhou "o hands parece estar aberto agora. Feche a janela dele e rode esta instalação de novo."

# --- Deixar o nome 'hands' disponível no terminal ----------------------------

precisa_reabrir=0
case ":${PATH}:" in
  *":${DESTINO}:"*) ;;
  *)
    precisa_reabrir=1
    linha="export PATH=\"\$HOME/.local/bin:\$PATH\""
    for perfil in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
      [ -f "$perfil" ] || continue
      grep -qF '.local/bin' "$perfil" 2>/dev/null && continue
      printf '\n# hands\n%s\n' "$linha" >> "$perfil" 2>/dev/null || true
    done
    # Se o usuário não tinha nenhum desses arquivos, cria o mais básico.
    if [ ! -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.profile" ]; then
      printf '\n# hands\n%s\n' "$linha" >> "$HOME/.profile" 2>/dev/null || true
    fi
    ;;
esac

# --- Conferir ----------------------------------------------------------------

instalada="$("$PROGRAMA" --version 2>/dev/null || true)"

if [ -z "$instalada" ]; then
  falhou "o programa foi instalado mas não respondeu. Tente de novo, ou fale com o suporte."
fi

printf '\n  Pronto. hands %s instalado.\n\n' "$instalada"

if [ "$precisa_reabrir" = "1" ]; then
  printf '  Abra uma janela NOVA do terminal e digite:\n\n      hands\n\n'
else
  printf '  Para começar, digite:\n\n      hands\n\n'
fi
