FastFile regression checks (primeira onda: save atomico, snapshot disco, replace limitado, busca com progresso em bytes)

Automatizado (sem IDE Delphi):
  cd RegressionTests
  python test_snapshot_logic.py

Manual (apos compilar o projeto no Delphi 7):
  1) Abrir um ficheiro pequeno, editar uma linha, gravar: verificar que o conteudo no disco corresponde e que nao ficou ficheiro ff_* .tmp na pasta do exe.
  2) Com o mesmo ficheiro aberto, alterar o ficheiro com Notepad noutro processo; tentar editar linha no FastFile: deve surgir o aviso "File changed on disk".
  3) Ctrl+F, Find Next num ficheiro grande: a barra de estado deve mostrar "Searching ... X / Y B" a atualizar durante a busca.
  4) Replace All num ficheiro de teste com mais de 5 ocorrencias: deve concluir; se precisar de testar o limite de 5.000.000 ocorrencias, usar ficheiro sintetico dedicado.
