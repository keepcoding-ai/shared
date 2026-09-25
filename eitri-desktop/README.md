# eitri-desktop

App de computador da Eitri — a mesma casa de `https://eitri.keepcoding.app/so/`, numa janela própria.

## Baixar (Mac, Apple Silicon)

[Eitri_0.1.3_aarch64.dmg](https://github.com/keepcoding-ai/shared/releases/download/eitri-desktop-v0.1.3/Eitri_0.1.3_aarch64.dmg)

## Instalar

1. Abra o `.dmg` e arraste **Eitri** para **Aplicativos**.
2. O app ainda **não é assinado pela Apple**. Na primeira vez, o Mac avisa que não pode verificá-lo.
   Clique em **OK**, abra **Ajustes do Sistema → Privacidade e Segurança**, role até o aviso sobre o Eitri
   e clique em **Abrir Mesmo Assim**. Isso só é preciso uma vez.
   Atalho pelo Terminal:
   ```
   xattr -dr com.apple.quarantine /Applications/Eitri.app
   ```
3. Entre com a sua conta da Eitri.

## Versões

| Versão | Plataforma | Release |
|---|---|---|
| 0.1.3 | macOS Apple Silicon (não assinado) — corrige "danificado" | `eitri-desktop-v0.1.3` |
| 0.1.2 | macOS Apple Silicon (não assinado) — ícone na marca | `eitri-desktop-v0.1.2` |
| 0.1.1 | macOS Apple Silicon (não assinado) | `eitri-desktop-v0.1.1` |
