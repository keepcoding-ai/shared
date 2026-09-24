# hands — notas internas (time)

Não referenciado pela página do `hands`. É aqui que mora o que o time precisa
saber e o usuário final não.

## Como os arquivos são gerados

A partir de `workspace/hands/repo`:

```sh
npm run build                                  # esbuild → dist/cli.mjs (bundle único)
bun build --compile --minify --target=bun-<alvo> dist/cli.mjs --outfile <saida>
```

Alvos e nomes dos arquivos:

| `--target`         | arquivo publicado       |
|--------------------|-------------------------|
| `bun-windows-x64`  | `hands-windows-x64.exe` |
| `bun-darwin-arm64` | `hands-macos-arm64`     |
| `bun-darwin-x64`   | `hands-macos-x64`       |
| `bun-linux-x64`    | `hands-linux-x64`       |
| `bun-linux-arm64`  | `hands-linux-arm64`     |

Os instaladores **e o atualizador automatico do cliente** dependem exatamente
desses nomes. Sao binarios crus, sem compactacao — nada de `.zip`/`.tar.gz`.

Toda release carrega tambem um `SHA256SUMS` (formato `sha256sum`, dois espacos,
um asset por linha) para conferencia antes de trocar o executavel:

```sh
sha256sum hands-* > SHA256SUMS
```

Exige **bun >= 1.4** para compilar de forma cruzada: no 1.3.14 o download dos
runtimes de outra plataforma falha com `Failed to extract executable`.

Não há build para Windows ARM64 — o `install.ps1` instala o x64 nessas
máquinas, que o Windows executa por emulação.

## Tarball npm (caminho interno)

```sh
npm pack --pack-destination <dir>     # hands-<versao>.tgz
npm install -g hands-<versao>.tgz     # exige Node >= 20 na máquina
```

Vai como asset da mesma release, e **não aparece na página** — o usuário final
não tem Node e escolher entre dois caminhos só o confunde.

O tarball carrega só `bin/`, `dist/cli.mjs` e `README.md`; o `dist/cli.mjs` já
é autocontido. As dependências `@atrium/*` declaradas como `file:../../…`
viram symlinks quebrados na instalação — inofensivos, porque nada é resolvido
em runtime, mas vale limpar o `dependencies` do `package.json` numa próxima.

## Publicar uma versão

Tag com prefixo do projeto, uma tag por versão, nunca reescrita:

```sh
gh release create hands-v<versao> --repo keepcoding-ai/shared \
  --title "hands <versao>" --notes "<o que mudou>"
gh release upload hands-v<versao> --repo keepcoding-ai/shared \
  hands-windows-x64.exe hands-macos-arm64 hands-macos-x64 hands-linux-x64 hands-linux-arm64 hands-<versao>.tgz SHA256SUMS
```

Depois, atualizar `$Version` no `install.ps1` e `VERSION` no `install.sh`, e
commitar na `main` — os instaladores são servidos pelo `raw.githubusercontent`
da `main`, então é o commit que faz a versão nova virar a instalada.

## O que o codigo pode saber em runtime

Medido numa sonda compilada, nao deduzido. Vale para quem for mexer em
atualizacao automatica ou em qualquer coisa que precise se localizar no disco:

| expressao | sob `bun --compile` |
|---|---|
| `process.execPath` | o **proprio binario**, caminho real no disco |
| `process.argv[0]`  | a string `"bun"` |
| `process.argv[1]`  | `B:/~BUN/root/<nome>` — raiz **virtual**, nao existe no disco |
| `typeof Bun`       | `'object'` |

Ou seja: para trocar o executavel, use `process.execPath`. `process.argv[1]`
nao serve para nada em disco.

**Armadilha:** o mesmo codigo tambem roda sob Node puro, pelo tarball npm, e la
`process.execPath` e' o `node.exe` — nao o hands. Quem for se autoatualizar
precisa checar `typeof Bun !== 'undefined'` primeiro e **nao tentar** na
instalacao npm, sob pena de sobrescrever o Node do usuario.

Outra: no Windows nao da' para sobrescrever um `.exe` em execucao. O
`install.ps1` baixa para `hands.exe.baixando` ao lado e faz `Move-Item -Force`
— funciona com o hands fechado, e falha com mensagem pedindo para fechar
quando esta' aberto. Atualizacao automatica precisa de troca adiada (renomear
o atual para `.old`, que o Windows permite mesmo em uso, mover o novo e apagar
o `.old` no proximo boot). No Unix o `rename(2)` sobre o binario em uso e'
atomico e funciona direto. O nome `hands.exe.baixando` e' do instalador —
quem implementar a troca adiada use outro.

## macOS: Gatekeeper

Os arquivos de Mac **não são assinados nem notarizados**. O `install.sh`
remove a marca de quarentena logo após o download, o que basta para quem
instala pela linha de comando. Quem baixar o arquivo pelo navegador vai
esbarrar no aviso do Gatekeeper. Assinar exige conta de desenvolvedor Apple
paga — decisão de custo, não de engenharia.
