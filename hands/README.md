# hands

O **hands** deixa você conversar com o seu agente direto do computador, e dá a
ele acesso às pastas que você escolher desta máquina. Assim o agente consegue
ler, escrever e organizar os seus arquivos enquanto vocês conversam.

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

## Conectar no agente

Digite `hands` e aperte Enter. Na primeira vez ele faz três perguntas:

1. **O endereço** do seu Atrium — quem cuida do sistema passa esse endereço
   para você.
2. **Entrar na sua conta** — ele mostra um código e um endereço na tela, e
   costuma abrir o seu navegador sozinho. Se não abrir, digite esse endereço
   no navegador. Informe o código lá e volte para a tela do `hands`.
3. **Com qual agente falar** — ele mostra a lista e você escolhe.

Depois disso é só digitar `hands` e conversar. Para emprestar uma pasta
específica, escreva o nome dela na frente:

```
hands Documentos/Contratos
```

## Atualizar

Não é preciso fazer nada. O `hands` confere sozinho se há versão nova e, quando
há, ela entra na próxima vez que você abrir o programa.

Se o computador estiver sem internet, ele abre normalmente na versão que já tem.
