# hands — notas internas (time)

Não referenciado pela página do `hands`. É aqui que mora o que o time precisa
saber e o usuário final não. O código vive em `workspace/soul-cli` (o hands é uma
variante do mesmo pacote); o plano e as decisões, na frente `hands-cli`.

O que o hands é: o cliente de terminal dos agentes do Atrium para a pessoa comum
de um tenant. Conversa com o agente pela linha de comando e empresta a ele as
pastas da máquina. Está sempre conectado a um servidor (o Atrium da organização):
nunca roda um motor local e nunca gerencia nada.

## Como os arquivos são gerados

Tudo por um comando, a partir de `workspace/soul-cli` (padrão: ensaio, não publica):

```sh
bun scripts/release.ts --variant hands             # ensaio: faz tudo local e IMPRIME os comandos que escreveriam no GitHub
bun scripts/release.ts --variant hands --execute   # publica
```

**A versão é a do pacote**: o hands usa o mesmo `version` do `package.json` do
soul-cli (o `--version` dele diz `hands <versão>`). Não há contagem própria; cada
bump do pacote que se queira publicar como hands vira uma release `hands-v<versão>`,
independente de existir a `soul-cli-v<versão>` correspondente.

**Sempre assinado (regra da casa, o método não varia).** Igual ao soul-cli: o `.exe`
sai com Authenticode (`ATRIUM_SIGN_THUMBPRINT`, ou `ATRIUM_SIGN_COMMAND`), então o
release roda sob o dotenvx:

```sh
dotenvx run -f <atrium>/so/.env -- bun scripts/release.ts --variant hands --out <pasta>   # ensaio, assinando de verdade
dotenvx run -f <atrium>/so/.env -- bun scripts/release.ts --variant hands --execute       # publica
```

O `SHA256SUMS` é calculado DEPOIS de assinar. O `--execute` recusa publicar se
`Get-AuthenticodeSignature` não trouxer `SignerCertificate` (self-signed mostra
`Status=UnknownError` na máquina que não confia na raiz: isso É assinado). Sem a
variável, o ensaio avisa e segue sem assinar; o `--execute` aborta. Nunca imprimir
nem ler o `.env`/thumbprint em log.

**Licenças.** O release gera `THIRD-PARTY-NOTICES.md` (`scripts/third-party-notices.ts`)
a partir dos pacotes que REALMENTE entraram no bundle do hands. O arquivo vai como
asset da release e entra no `SHA256SUMS`.

Por baixo (diferente do soul-cli: **não há motor embutido**, então não há `--embed`
nem pacotes externos; o bundle já é um arquivo só):

```sh
bun run scripts/build.ts --variant hands --outdir <pasta>/build    # <pasta>/build/hands.mjs
bun build --compile --target=bun-<alvo> <pasta>/build/hands.mjs --outfile <saida>
```

O build do hands **falha** se a varredura do bundle (`scripts/bundle-scan.ts`) achar
qualquer coisa do operador dentro dele: é o juiz que impede funções da plataforma de
vazarem para o cliente do tenant. O hands também não embute os ativos do navegador
(`browser setup` é do operador).

Alvos e nomes dos arquivos (contrato com os instaladores E com o atualizador do
próprio programa, `src/update/release.ts` — mudar aqui sem mudar lá faz o cliente
parar de se atualizar em silêncio):

| `--target`         | arquivo publicado           |
|--------------------|-----------------------------|
| `bun-windows-x64`  | `hands-windows-x64.exe`     |
| `bun-darwin-arm64` | `hands-macos-arm64`         |
| `bun-darwin-x64`   | `hands-macos-x64`           |
| `bun-linux-x64`    | `hands-linux-x64`           |
| `bun-linux-arm64`  | `hands-linux-arm64`         |

Toda release leva ainda `SHA256SUMS` (formato `sha256sum`, dois espaços, um arquivo
por linha) e `THIRD-PARTY-NOTICES.md`. Binários crus, sem compactação. Windows ARM64
não tem build próprio: o `install.ps1` instala o x64, que o Windows executa por emulação.

**Bun 1.3.14 compila só o alvo nativo (Windows x64).** Os outros exigem **bun >= 1.4**;
o release pula os que não dá, com aviso. Enquanto for assim, a primeira release só
tem o `.exe`, e a página diz "por enquanto só Windows". Quando os cinco saírem,
tire essa frase do `README.md`.

## Contrato com o atualizador (`src/update/release.ts`)

O atualizador monta tudo a partir de `BRAND` (`src/brand.ts`) e não lê endereço nenhum
da resposta da API:

- prefixo da tag = `BRAND.releaseTagPrefix`, que tem de ser `hands-v`;
- nome do arquivo = `assetNameFor(...)`, que usa `BRAND.slug` e tem de resultar em
  `hands-windows-x64.exe`, `hands-macos-arm64` etc.;
- arquivos laterais ao lado do binário (`.<slug>-update.part`, `.<slug>-update.json`,
  `.<slug>-retired`) saem do mesmo `slug`.

**Estado (já no código, `src/brand.ts`)**: o `BRAND` do hands tem
`releaseTagPrefix: 'hands-v'`, `assetPrefix: 'hands-'`, `installedName: 'hands'`,
`updateMarker: '.hands-update'` (mais `.hands-retired`) e
`repo: 'keepcoding-ai/shared'`. O atualizador lê essa marca e nunca enxerga
`soul-cli-v*` (teste `test/hands/release-brand.test.ts`). O `slug` `hands-cli` ficou só
para o que vai pelo fio: user-agent, origem do Device Flow, nome do cliente no
servidor e completion. O executável no disco precisa começar por `hands`
(`installedName`): o atualizador só se troca se o nome de `process.execPath` bate.

Pré-checagens, publicação e verificação são as do soul-cli: árvore limpa, seção
`## <versão>` no CHANGELOG, tag inexistente, `gh auth`; depois confere que a release
existe, é pré-lançamento, não é a "latest" do repositório, tem todos os arquivos, e
que o `SHA256SUMS` servido é o gerado.

## Canais: latest e stable

Um canal é só uma regra de leitura da lista de releases do repositório, filtrada
pelo prefixo `hands-v`. Não existe tag nem pasta de canal.

| canal    | o que enxerga                                   |
|----------|-------------------------------------------------|
| `latest` | toda release que não é rascunho                 |
| `stable` | idem, **sem** a marca de pré-lançamento         |

- **Publicar** = `--prerelease --latest=false`: nasce em `latest` só.
- **Promover** = tirar a marca de pré-lançamento: passa a valer em `stable` também.
- **Retirar** = virar rascunho: nenhum canal oferece. Cópia já instalada não é tocada:
  para tirar gente de uma versão ruim, publique uma nova.
- **Sempre `--latest=false`**: o selo "Latest" do repositório shared não pode ser
  roubado por um hands, porque ele guarda outros projetos.

Os instaladores resolvem a versão pela API (maior `hands-v*` do canal), então
**publicar não exige mexer em instalador nem commitar na `main`**.

## Atualização automática (no programa)

Código em `src/update/`, o mesmo do soul-cli.

- Checagem anônima (sem credencial, sem identificador) em segundo plano, logo depois
  de a tela aparecer, no máximo uma a cada 6 h. Fora de `--print`, sem terminal e
  `serve`.
- Baixa para um arquivo `.part` ao lado do binário, confere o sha256, renomeia e
  grava um sidecar. **A troca acontece na abertura seguinte**, antes de qualquer
  tela: o binário atual é renomeado para `.…-retired` (o Windows permite renomear um
  `.exe` em uso) e o novo toma o nome. O retired é apagado na abertura seguinte.
- Configuração em `~/.hands/client.json` (a casa do hands, sem nada compartilhado
  com o soul-cli): `autoUpdates` (padrão ligado), `autoUpdatesChannel` (padrão
  `latest`), `minimumVersion`. Pelo `/config`: **Auto-updates** e **Auto-update
  channel**.
- `hands update [--channel latest|stable]`: olha agora, sem throttle, troca na hora.
  `--channel` vale só para aquela execução e nunca autoriza descer de versão.
- Para desligar numa execução só (teste, script): a variável lida pelo código hoje é
  **`SOUL_CLI_NO_UPDATE=1`** (`src/update/policy.ts`), não uma `HANDS_*`. Pendência
  aberta: o hands deveria ter a sua.

### Segurança

1. **Origem fixa**: `github.com/keepcoding-ai/shared`. Nenhuma variável, flag ou
   configuração a muda; os endereços de download são montados no cliente a partir da
   tag e do nome do arquivo.
2. **Três conferências de sha256**: no download (contra o `SHA256SUMS` e contra o
   `digest` que o GitHub registra, quando existe), na troca e depois da troca (com
   volta atrás se não bater).
3. **Nunca se atualiza rodando por node/npm/bun**: só o binário compilado.
4. Release sem `SHA256SUMS` não é instalada.
5. Falha de atualização é silêncio. Só o `hands update` explica.

## O que o código pode saber em runtime

Medido sob `bun --compile`: `process.execPath` é o próprio binário,
`typeof Bun === 'object'`, e `process.argv[1]` aponta para uma raiz virtual
(`B:/~BUN/root/...`) que não existe no disco. Para trocar o executável, use
`process.execPath`.

## Instaladores

- `install.ps1`: **ASCII puro e sem BOM** (o BOM quebra `irm | iex`; acento sem BOM
  corrompe no PowerShell 5.1). Mensagens sem acento, de propósito.
- `install.sh`: LF; o `.gitattributes` da raiz já força `eol=lf` para `*.sh`.
- Colisão de PATH: uma cópia que ganha de nós faz o terminal abrir outra versão com
  "Pronto" na tela. No Windows reordenamos o PATH do usuário (a pasta é só nossa); no
  Unix só avisamos (`~/.local/bin` é compartilhada).
- Os dois conferem o sha256 do download contra o `SHA256SUMS` ANTES de instalar.
- `HANDS_SKIP_PATH=1` (só `install.ps1`) não mexe no PATH: existe para a prova do
  instalador não sujar o PATH de quem testa.
- `HANDS_CHANNEL=latest` e `HANDS_VERSION=x.y.z` escolhem canal e versão exata.
- Instala em `%LOCALAPPDATA%\Programs\hands\hands.exe` (Windows) e `~/.local/bin/hands`
  (Unix).

## macOS: Gatekeeper

Os arquivos de Mac **não são assinados nem notarizados**. O `install.sh` remove a
marca de quarentena logo após o download, o que basta para quem instala pela linha
de comando; quem baixar pelo navegador esbarra no aviso do Gatekeeper. No Windows o
`.exe` É assinado (Authenticode): o SmartScreen ainda pode avisar até haver reputação
ou assinatura de cadeia confiável.

## Antes de publicar de verdade

- O repositório shared é **público**: o binário embute dependências de terceiros, e
  o `THIRD-PARTY-NOTICES.md` acompanha a release.
- `release.ts`, `promote.ts` e `yank.ts` já aceitam `--variant hands` (tag `hands-v<versão>`,
  arquivos `hands-*`, build sem `--embed` e sem externos). O ensaio do hands já rodou de
  ponta a ponta: o `THIRD-PARTY-NOTICES.md` do hands lista 34 pacotes, contra 104 do
  operador.
- A variável de ambiente para desligar a atualização numa execução ainda é a
  `SOUL_CLI_NO_UPDATE`; a decisão sobre as variáveis de ambiente do hands está em aberto.
- Só Windows por enquanto: o bun 1.3.14 compila só o alvo nativo. Com bun >= 1.4 os
  cinco alvos saem, e a frase "por enquanto só Windows" sai do `README.md`.
- Prova de ponta a ponta pendente: instalar pela linha pública numa máquina limpa e
  deixar o atualizador trocar de uma versão para a seguinte.
