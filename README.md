# shared

Arquivos públicos compartilhados da equipe.

Cada arquivo é um asset de release. O link é estável e aberto:

```
https://github.com/keepcoding-ai/shared/releases/download/<tag>/<arquivo>
```

Baixe como preferir — navegador, `curl`, `wget`, `gh release download`. Não há
formato obrigatório nem índice a manter.

## Publicar

```
gh release create <tag> --repo keepcoding-ai/shared --title "<titulo>" --notes "<o que e>"
gh release upload <tag> --repo keepcoding-ai/shared <arquivo>
```

Uma tag nunca é reescrita: versão nova, tag nova.

## Limites

2 GB por arquivo, sem teto de banda, sem login para baixar.

**É público.** Nada de segredo, credencial ou dado de cliente aqui.
