# soul-cli — notas internas (time)

Não referenciado pela página do `soul-cli`. É aqui que mora o que o time
precisa saber e o usuário final não. O código vive em `workspace/soul-cli`; o
plano e as decisões, em `mind/effort/on/soul-cli/distribuicao-plano.md`.

## Como os arquivos são gerados

Tudo por um comando, a partir de `workspace/soul-cli` (padrão: ensaio, não publica):

```sh
bun scripts/release.ts                # ensaio: faz tudo local e IMPRIME os comandos que escreveriam no GitHub
bun scripts/release.ts --execute      # publica
```

**Sempre assinado (regra da casa, o método não varia).** O `.exe` sai com Authenticode, igual ao
desktop e ao instalador do Codium. A variável de assinatura (`ATRIUM_SIGN_THUMBPRINT`, ou
`ATRIUM_SIGN_COMMAND` para o Azure Trusted Signing no futuro) vive no cofre, então o release roda
sob o dotenvx:

```sh
dotenvx run -f <atrium>/so/.env -- bun scripts/release.ts --out <pasta>            # ensaio, assinando de verdade
dotenvx run -f <atrium>/so/.env -- bun scripts/release.ts --execute               # publica
```

Passo 4 do script: `Set-AuthenticodeSignature` (SHA256, timestamp `timestamp.digicert.com`) entre o
`bun build --compile` e o `SHA256SUMS`; o `SHA256SUMS` é calculado DEPOIS de assinar. Portão: o
`--execute` recusa publicar se `Get-AuthenticodeSignature` não trouxer `SignerCertificate`
(self-signed mostra `Status=UnknownError` na máquina que não confia na raiz: isso É assinado). Sem a
variável, o ensaio avisa e segue sem assinar; o `--execute` aborta nas pré-checagens. Não existe
`--allow-unsigned` aqui (o `publish-desktop` também não tem: só o build local do desktop tem).
Nunca imprimir nem ler o `.env`/thumbprint em log.

**Licenças.** O passo 6 gera `THIRD-PARTY-NOTICES.md` (`scripts/third-party-notices.ts`) a partir dos
pacotes que REALMENTE entraram no bundle (os comentários `// ...node_modules/<pkg>/...` que o Bun deixa
antes de cada módulo, inclusive os do motor, que já vem pré-empacotado), lendo `package.json` e `LICENSE*`
de cada um. O cabeçalho (renderer e yoga, derivados de código-fonte) vem do `THIRD-PARTY-NOTICES.md`
versionado no repo. O arquivo vai como asset da release e entra no `SHA256SUMS`. Pacotes sem arquivo de
licença (hoje 5, todos declaram MIT/Apache-2.0) aparecem só com o id SPDX.

Por baixo:

```sh
bun run scripts/build.ts --embed --outdir <pasta>/build        # um .mjs COM o motor (soul/sdk) dentro
bun build --compile --target=bun-<alvo> \
  --external @aws-sdk/client-bedrock --external @aws-sdk/client-sts \
  <pasta>/build/cli-embed.mjs --outfile <saida>
```

O `--embed` é o conserto da prova de F0: sem ele o `import('soul/sdk')` é
dinâmico, fica FORA do bundle e o `.exe` não acha o motor. Os dois `@aws-sdk/*`
são externos (o motor só os carrega para Bedrock/STS). O catálogo de
provedores (`/provider`) também entra pelo bundle, não por `createRequire`.

Alvos e nomes dos arquivos (contrato com os instaladores E com o atualizador do
próprio programa, `src/update/release.ts` — mudar aqui sem mudar lá faz o
cliente parar de se atualizar em silêncio):

| `--target`         | arquivo publicado           |
|--------------------|-----------------------------|
| `bun-windows-x64`  | `soul-cli-windows-x64.exe`  |
| `bun-darwin-arm64` | `soul-cli-macos-arm64`      |
| `bun-darwin-x64`   | `soul-cli-macos-x64`        |
| `bun-linux-x64`    | `soul-cli-linux-x64`        |
| `bun-linux-arm64`  | `soul-cli-linux-arm64`      |

Binários crus, sem compactação. Toda release leva um `SHA256SUMS` (formato
`sha256sum`, dois espaços, um arquivo por linha). Windows ARM64 não tem build
próprio: o `install.ps1` instala o x64, que o Windows executa por emulação.

**Bun 1.3.14 compila só o alvo nativo (Windows x64).** Os outros exigem
**bun >= 1.4** (no 1.3.14 o download do runtime de outra plataforma falha com
`Failed to extract executable`). O `release.ts` já tem os cinco alvos e pula os
que não dá, com aviso.

Tamanho: ~117 MB por binário. Primeira tela ~1,25 s.

## Canais: latest e stable

Um canal é só uma regra de leitura da lista de releases — não existe tag nem
pasta de canal.

| canal    | o que enxerga                                   |
|----------|-------------------------------------------------|
| `latest` | toda release que não é rascunho                 |
| `stable` | idem, **sem** a marca de pré-lançamento         |

- **Publicar** = `--prerelease --latest=false`: nasce em `latest` só.
- **Promover** = tirar a marca de pré-lançamento (`bun scripts/promote.ts <v> --execute`):
  passa a valer em `stable` também. Critério de promoção: decisão de produto em aberto.
- **Retirar** = virar rascunho (`bun scripts/yank.ts <v> --execute`): nenhum canal
  oferece. `--undo` devolve. Cópia já instalada não é tocada: para tirar gente de
  uma versão ruim, publique uma nova (ou use o `minimumVersion` do usuário).
- **Sempre `--latest=false`**: o selo "Latest" do repositório shared não pode ser
  roubado por um soul-cli — ele guarda outros projetos.

Os instaladores resolvem a versão pela API (maior `soul-cli-v*` do canal), então
**publicar não exige mexer em instalador nem commitar na `main`** — ao contrário do
`hands`, que tem a versão escrita no `install.ps1`.

## Pré-checagens do release.ts

Árvore limpa · seção `## <versão>` no CHANGELOG · tag inexistente (uma tag nunca é
reescrita) · `gh auth` ativo. No ensaio viram avisos; no `--execute`, abortam.

Depois de publicar ele confere: a release existe, é pré-lançamento, não é rascunho,
tem todos os arquivos, **não** virou a "latest" do repositório, e o `SHA256SUMS`
que o GitHub serve é idêntico ao gerado.

## Atualização automática (no programa)

Código em `src/update/`. Molde: o do `hands`, com canais.

- Checagem anônima (sem credencial, sem identificador) em segundo plano, 3 s depois
  de a tela aparecer, no máximo uma a cada 6 h. Fora de `--print`, `--host`, sem
  terminal e `serve`.
- Baixa para `.soul-cli-update.part` ao lado do binário; confere; renomeia; grava um
  sidecar. **A troca acontece na abertura seguinte**, antes de qualquer tela
  (`src/update/handoff.ts`): o binário atual é renomeado para `.soul-cli-retired`
  (o Windows permite renomear um `.exe` em uso), o novo toma o nome, e o processo
  entrega a vez ao novo. O `.soul-cli-retired` é apagado na abertura seguinte.
- Configurações (`~/.soul-local/client.json`): `autoUpdates` (padrão ligado),
  `autoUpdatesChannel` (padrão `latest`), `minimumVersion`. Duas travas de uma vez:
  `SOUL_CLI_NO_UPDATE=1`, ou `autoUpdates:false`.
- `/config` → **Auto-updates** e **Auto-update channel**. Trocar `latest` -> `stable`
  abre o diálogo da E9.6: *Allow possible downgrade* (canal stable) ou *Stay on
  current version (X) until stable catches up* (canal stable **e** `minimumVersion` = a
  versão atual: nada abaixo dela).
- `soul-cli update [--channel latest|stable]`: olha agora, sem throttle, mesmo com
  `autoUpdates` desligado; troca na hora. `--channel` vale só para aquela execução e
  nunca autoriza descer de versão.
- Descer de versão só acontece com o canal **stable gravado** e a versão do canal
  mais antiga que a em uso (e ainda >= `minimumVersion`).

### Segurança

1. **Origem fixa**: `github.com/keepcoding-ai/shared`. Nenhuma variável, flag ou
   configuração a muda. Os endereços de download são montados no cliente a partir da
   tag e do nome do arquivo — nunca lidos da resposta da API. Só a PROVA aponta para
   outro lugar, e só por parâmetro de função.
2. **Três conferências de sha256**: no download (contra o `SHA256SUMS`, e contra o
   `digest` que o GitHub registra do arquivo, quando existe: duas testemunhas); na troca
   (o arquivo estagiado contra o sidecar); depois da troca (o arquivo no lugar contra o
   sidecar, com volta atrás se não bater).
3. **Nunca se atualiza rodando por node/npm/bun**: só o binário compilado, com nome
   `soul-cli*`. Senão `process.execPath` seria o Node de alguém.
4. Release sem `SHA256SUMS` não é instalada.
5. Falha de atualização é silêncio. Só o `soul-cli update` explica.

## O que o código pode saber em runtime

Igual ao `hands` (medido sob `bun --compile`): `process.execPath` é o próprio
binário, `typeof Bun === 'object'`, `process.argv[1]` aponta para uma raiz virtual
(`B:/~BUN/root/...`) que não existe no disco. Para trocar o executável, use
`process.execPath`. O motor embutido também usa `process.execPath`; a prova de F0
(turno, Bash, MCP stdio, subagente, `/context`, hook, Grep/Glob) mostrou que isso não
quebra nada do que o soul-cli usa.

## Instaladores: lições herdadas do hands

- `install.ps1`: **ASCII puro e sem BOM** (o BOM quebra `irm | iex`; acento sem BOM
  corrompe no PowerShell 5.1). Mensagens sem acento, de propósito.
- `install.sh`: `.gitattributes` já força `eol=lf` para `*.sh`.
- Colisão de PATH: uma cópia antiga que ganha de nós faz o terminal abrir a versão
  velha com "Pronto" na tela. No Windows reordenamos o PATH do usuário (a pasta é só
  nossa); no Unix só avisamos (`~/.local/bin` é compartilhada).
- Os dois conferem o sha256 do download contra o `SHA256SUMS` ANTES de instalar.
- `SOUL_CLI_SKIP_PATH=1` (só `install.ps1`) não mexe no PATH: existe para a prova do
  instalador não sujar o PATH de quem testa.
- Instala em `%LOCALAPPDATA%\Programs\soul-cli\soul-cli.exe` (Windows) e
  `~/.local/bin/soul-cli` (Unix).

## macOS: Gatekeeper

Os arquivos de Mac **não são assinados nem notarizados**. O `install.sh` remove a
marca de quarentena logo após o download, o que basta para quem instala pela linha
de comando; quem baixar pelo navegador esbarra no aviso do Gatekeeper. No Windows o
`.exe` É assinado (Authenticode, self-signed hoje): o SmartScreen ainda pode avisar
até haver reputação ou assinatura de cadeia confiável (Azure Trusted Signing, depois).

## Antes de publicar de verdade (pendências de decisão)

- O repositório shared é **público**: o binário embute o motor e dependências de
  terceiros. `THIRD-PARTY-NOTICES.md` agora acompanha a release (gerado, ver acima; o
  dono aprovou publicar com ele). A licença do soul-cli segue `SEE LICENSE IN LICENSE.md`.
- Perguntas de produto em aberto no plano: canal padrão de instalações novas, quem
  promove a `stable` e com qual critério, atualização ligada por padrão e aviso ou
  silêncio, publicar todo bump ou só versões curadas.
