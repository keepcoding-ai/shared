# hands

O **hands** é o terminal dos agentes do Atrium: você conversa com o agente da
sua organização direto da linha de comando, e empresta a ele as pastas deste
computador em que ele pode trabalhar.

## Instalar

**Windows** — abra o *PowerShell*, cole a linha abaixo e aperte Enter:

```powershell
irm https://raw.githubusercontent.com/keepcoding-ai/shared/main/hands/install.ps1 | iex
```

**Mac ou Linux** — abra o *Terminal*, cole a linha abaixo e aperte Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/keepcoding-ai/shared/main/hands/install.sh | sh
```

Quando terminar, feche essa janela e abra uma nova.

> Por enquanto só há versão para **Windows**. Mac e Linux entram em breve.

## Começar

Digite `hands` e aperte Enter. Na primeira vez ele te recebe e pergunta, passo a passo:

1. **O endereço do servidor** — o Atrium da sua organização. Quem cuida do Atrium
   aí passa esse endereço para você.
2. **Quem é você** — o hands mostra um código e pede para abrir uma página no
   navegador; você entra na sua conta lá e confirma o código.
3. **Com qual agente quer conversar** — escolha na lista.

Depois é só digitar `hands` e conversar. Nas próximas vezes ele reconecta sozinho ao
mesmo servidor e ao mesmo agente, sem perguntar de novo.

Para ver a versão que você tem: `hands --version`.

## Emprestar uma pasta ao agente

O agente só mexe nos arquivos que você empresta. Por padrão, o hands empresta a
**pasta em que você está** quando o abre. O jeito mais simples:

1. No terminal, entre na pasta do trabalho (por exemplo `cd Documentos\proposta`).
2. Digite `hands`.

Para emprestar outra pasta, sem precisar entrar nela, use `-w`:

```
hands -w "C:\Users\voce\Documentos\proposta"
```

Pode emprestar mais de uma, repetindo o `-w`. Para o agente **só ler** e nunca
alterar, termine o caminho com `:ro`:

```
hands -w "C:\Users\voce\Documentos\proposta:ro"
```

Para abrir sem emprestar nenhuma pasta: `hands --no-hands`.

## Atualizar

Não é preciso fazer nada. O `hands` confere sozinho, em segundo plano, se há
versão nova e, quando há, ela entra na próxima vez que você abrir o programa.
Se o computador estiver sem internet, ele abre normalmente na versão que já tem.

Para atualizar agora: `hands update`.

Para desligar a atualização automática, ou escolher o canal, use o `/config`
dentro do `hands`:

- **Auto-updates** — liga e desliga.
- **Auto-update channel** — `stable` recebe só as versões que já provaram bem em
  uso; `latest` recebe toda versão nova, assim que sai.

## Algo não funciona?

Digite `hands doctor`: ele confere a instalação e diz o que está errado.

## Canal das versões mais novas

A linha de instalação acima instala a versão **estável**. Quem quer a mais nova
cola, antes da linha, no PowerShell:

```powershell
$env:HANDS_CHANNEL = 'latest'
```

e no Terminal:

```sh
export HANDS_CHANNEL=latest
```
