# soul-cli

O **soul-cli** é o terminal dos agentes do Atrium: você conversa com o seu
agente direto da linha de comando, e ele trabalha nas pastas desta máquina.

## Instalar

**Windows** — abra o *PowerShell*, cole a linha abaixo e aperte Enter:

```powershell
irm https://raw.githubusercontent.com/keepcoding-ai/shared/main/soul-cli/install.ps1 | iex
```

**Mac ou Linux** — abra o *Terminal*, cole a linha abaixo e aperte Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/keepcoding-ai/shared/main/soul-cli/install.sh | sh
```

Quando terminar, feche essa janela e abra uma nova.

> Por enquanto só há versão para **Windows**. Mac e Linux entram em breve.

## Começar

Digite `soul-cli` e aperte Enter. Na primeira vez ele te recebe e pede o que
precisa para conversar com o agente. Depois é só digitar `soul-cli` e conversar.

Para ver a versão que você tem: `soul-cli --version`.

## Atualizar

Não é preciso fazer nada. O `soul-cli` confere sozinho, em segundo plano, se há
versão nova e, quando há, ela entra na próxima vez que você abrir o programa.
Se o computador estiver sem internet, ele abre normalmente na versão que já tem.

Para atualizar agora: `soul-cli update`.

Para desligar a atualização automática, ou escolher o canal, use o `/config`
dentro do `soul-cli`:

- **Auto-updates** — liga e desliga.
- **Auto-update channel** — `stable` recebe só as versões que já provaram bem em
  uso; `latest` recebe toda versão nova, assim que sai.

## Canal das versões mais novas

A linha de instalação acima instala a versão **estável**. Quem quer a mais nova
cola, antes da linha, no PowerShell:

```powershell
$env:SOUL_CLI_CHANNEL = 'latest'
```

e no Terminal:

```sh
export SOUL_CLI_CHANNEL=latest
```
