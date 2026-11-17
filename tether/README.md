# tether

Cada terminal do **tether** lembra qual sessão do Claude Code (ou do soul-cli) está rodando nele e a retoma depois de qualquer reinício: fechou a janela, reiniciou o computador, o agente volta de onde parou.

## Baixar (Windows 64 bits)

[tether-0.1.1-win-x64.exe](https://github.com/keepcoding-ai/shared/releases/download/tether-v0.1.1/tether-0.1.1-win-x64.exe) — instalador

Também há uma versão sem instalador, em [.zip](https://github.com/keepcoding-ai/shared/releases/download/tether-v0.1.1/tether-0.1.1-win-x64.zip): descompacte e abra o `tether.exe`.

## Antes de instalar

- **Node 24 ou mais novo** instalado e no PATH (baixe em https://nodejs.org). Se o Node estiver em outro lugar, a variável `TETHER_NODE` aponta para o `node.exe`.
- **Claude Code** instalado e com login feito: os terminais abrem o `claude`.

## Instalar

1. Abra o `.exe` e siga os passos. Dá para escolher a pasta de instalação.
2. O app ainda **não é assinado**. O Windows mostra o aviso "O Windows protegeu seu computador":
   clique em **Mais informações** e depois em **Executar assim mesmo**. Isso só é preciso uma vez.
3. Abra o **tether** pelo Menu Iniciar. Ele sobe sozinho o serviço que segura os terminais.

Fechar a janela só desconecta: os agentes continuam rodando e voltam ao reabrir o app. Para encerrar tudo, use **Arquivo → Sair e encerrar tudo…** (`Ctrl+Shift+Q`).

## Versões

| Versão | Plataforma | Release |
|---|---|---|
| 0.1.1 | Windows 64 bits (não assinado) — corrige o tetherd que não subia no app instalado | `tether-v0.1.1` |
| 0.1.0 | Windows 64 bits (não assinado) — **não use**: o tetherd não sobe | `tether-v0.1.0` |
