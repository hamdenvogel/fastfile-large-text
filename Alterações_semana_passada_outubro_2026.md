# Implementações da última semana de outubro de 2026

**Período:** 26 a 31 de outubro de 2026  
**Projeto:** FastFile (Delphi 7 / Delphi 10.4.2 Win64)  
**Versão mais recente registrada:** 3.0.5.261

Este documento resume as implementações registradas no projeto durante o período. Os detalhes e o histórico completo estão no [changelog de implementações](src/CHANGELOG_IMPLEMENTACOES.md).

## 26 de outubro — barras de ferramentas

- As barras **Localizar**, **Filtro** e **Marcadores** passaram a abrir em formato compacto, com alça inferior para ajustar a altura.
- O botão **Fechar** foi colocado ao lado de **Limpar**.

## 27 de outubro — glob/grep e assistência por IA

- Os comandos recentes de glob/grep passaram a usar uma lista MRU persistida no projeto, com opções para pesquisar, remover itens e limpar o histórico.
- Foram acrescentados exemplos de busca e opções para CSV, subpastas, limite de resultados, maiúsculas/minúsculas, OU, inversão, palavra inteira, grupos nomeados e marcadores.
- **Perguntar à IA** passou a abrir junto à página ativa.

## 28 de outubro — divisão por linhas e limites

- A divisão por linhas ganhou campos de intervalo, prévia, estado vazio e ferramentas para copiar, limpar, exportar, traduzir e descaracterizar.
- A gravação percorre o arquivo original e escreve o intervalo em um novo arquivo, sem montar todas as linhas em memória.
- As Preferências passaram a mostrar limites e valores padrão para operações como mesclar, traduzir, exportar, inserir e dividir; os diálogos também informam os limites aplicáveis.

## 29 de outubro — regex, idiomas e layout RTL

- Foram adicionados exemplos de regex e sugestões da IA que propõem padrões sem executá-los automaticamente.
- A lista de idiomas passou a priorizar idiomas usados recentemente, permitir pesquisa e exibir bandeiras.
- Árabe e hebraico passaram a ser suportados com layout da direita para a esquerda (RTL), incluindo formulários, diálogos, menus e listas. O texto de arquivos e código continua da esquerda para a direita.
- A interface chegou a 16 idiomas nesta etapa.

## 30 de outubro — divisão em partes iguais, localização e guia

- A ação **Partes iguais** foi adicionada à barra principal e continua disponível em **Mais ferramentas**, com atalho `Ctrl+Shift+P`.
- A divisão percorre blocos MMF e grava os trechos correspondentes sem carregar o arquivo inteiro em memória; após a operação, a aba de divisão permanece ativa.
- O menu de contexto do editor passou a acompanhar o idioma selecionado, e os rótulos do histórico de sessão foram revisados.
- A interface foi expandida de 16 para 22 idiomas.
- Após a leitura de um arquivo, um guia passou a sugerir próximos passos. A opção para não o exibir pode ser alterada nas Preferências.

## 31 de outubro — ajustes no guia e nas Preferências

- O painel do guia passou a ser associado ao formulário antes da criação de seus controles, evitando erro de inicialização.
- O redesenho repetido durante o redimensionamento foi removido para reduzir cintilação; o painel também recebeu ajustes visuais.
- As Preferências foram reformuladas e ganharam o botão **Mostrar guia agora**, permitindo reabrir o guia sob demanda.

## Resultado

As entregas da semana aprimoraram a ergonomia das barras e das Preferências, ampliaram os recursos de busca, divisão e assistência, e expandiram a localização do FastFile. As operações de divisão foram implementadas para processar o conteúdo em blocos, evitando carregar o arquivo inteiro na memória.
