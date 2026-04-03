# avaliador_llms

Aplicação web para avaliação de erros cometidos por LLMs em questões de múltipla escolha.

## Como usar

1. Abra o site publicado no GitHub Pages.
2. Navegue pelas avaliações e marque as categorias de erro.
3. Clique em Exportar Resultados (CSV).
4. Envie o CSV exportado para o coordenador da pesquisa.

## Estrutura

- index.html: SPA principal.
- questões/: imagens das questões.
- dados_avaliacao.json: dataset extraído (referência).
- extrair_dataset.ps1: script para regenerar dataset.

## Publicar no GitHub Pages

1. Crie um repositório chamado avaliador_llms no GitHub.
2. Conecte o remoto local ao repositório criado.
3. Faça push da branch main.
4. Em Settings > Pages, configure:
   - Source: Deploy from a branch
   - Branch: main
   - Folder: /(root)
5. Acesse a URL gerada pelo GitHub Pages.

## URL esperada

https://SEU-USUARIO.github.io/avaliador_llms/
