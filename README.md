# shared

Arquivos públicos compartilhados da equipe.

## Projetos

- **[hands](hands/)** — conversar com o seu agente pelo computador, emprestando a ele as suas pastas.

## Como funciona

Cada projeto tem uma pasta com o nome dele e publica suas versões em releases
com o mesmo prefixo — `hands/` publica em `hands-v0.1.0`. Uma tag nunca é
reescrita: versão nova, tag nova.

```
https://github.com/keepcoding-ai/shared/releases/download/<tag>/<arquivo>
```

O link é estável e aberto — navegador, `curl`, `wget`, `gh release download`.

```
gh release create <tag> --repo keepcoding-ai/shared --title "<titulo>" --notes "<o que e>"
gh release upload <tag> --repo keepcoding-ai/shared <arquivo>
```

## Limites

2 GB por arquivo, sem teto de banda, sem login para baixar.

**É público.** Nada de segredo, credencial ou dado de cliente aqui.
