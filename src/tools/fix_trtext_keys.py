# -*- coding: utf-8 -*-
"""Replace TrText keys that use Portuguese/mojibake with English keys matching uI18n.pas."""
import re
import os

SRC = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (old_substring_pattern, new_literal) - regex on TrText argument only
REPLACEMENTS = [
    (r"TrText\('Copiar apenas um intervalo espec.{1,6}fico de linhas do arquivo de origem'\)",
     "TrText('Copy only a specific range of lines from source')"),
    (r"TrText\('Da linha:'\)", "TrText('From line:')"),
    (r"TrText\('At.{1,6} a linha:'\)", "TrText('To line:')"),
    (r"TrText\('Erro: \"Da linha\" n.{1,6}o pode estar vazia\.'\)",
     "TrText('Error: \"From line\" cannot be empty.')"),
    (r"TrText\('Erro: \"At.{1,6} a linha\" n.{1,6}o pode estar vazia\.'\)",
     "TrText('Error: \"To line\" cannot be empty.')"),
    (r"TrText\('Erro: \"Da linha\" deve ser um n.{1,6}mero v.{1,6}lido\.'\)",
     "TrText('Error: \"From line\" must be a valid number.')"),
    (r"TrText\('Erro: \"At.{1,6} a linha\" deve ser um n.{1,6}mero v.{1,6}lido\.'\)",
     "TrText('Error: \"To line\" must be a valid number.')"),
    (r"TrText\('Erro: \"Da linha\" deve ser pelo menos 1\.'\)",
     "TrText('Error: \"From line\" must be at least 1.')"),
    (r"TrText\('Erro: \"At.{1,6} a linha\" deve ser pelo menos 1\.'\)",
     "TrText('Error: \"To line\" must be at least 1.')"),
    (r"TrText\('Erro: \"Da linha\" \(%d\) n.{1,6}o pode ser maior que \"At.{1,6} a linha\" \(%d\)\.'\)",
     "TrText('Error: \"From line\" (%d) cannot be greater than \"To line\" (%d).')"),
    (r"TrText\('Erro: Arquivo de origem n.{1,6}o encontrado: %s'\)",
     "TrText('Error: Source file not found: %s')"),
    (r"TrText\('Erro: N.{1,6}o foi poss.{1,6}vel ler o arquivo de origem para validar o total de linhas\.'\)",
     "TrText('Error: Could not read source file to validate line count.')"),
    (r"TrText\('Erro: \"Da linha\" \(%d\) excede o total de linhas no arquivo de origem \(%d\)\.'\)",
     "TrText('Error: \"From line\" (%d) exceeds total lines in source file (%d).')"),
    (r"TrText\('Erro: \"At.{1,6} a linha\" \(%d\) excede o total de linhas no arquivo de origem \(%d\)\.'\)",
     "TrText('Error: \"To line\" (%d) exceeds total lines in source file (%d).')"),
    (r"TrText\('Erro ao validar o intervalo de linhas: '\)",
     "TrText('Error validating line range: ')"),
    (r"TrText\('Ir para linha'\)", "TrText('Go to line')"),
    (r"TrText\('Numero da linha \(1\.\.'\)",
     "TrText('Line number (1..')"),
]

OTHER_FILES = [
    'uSmoothLoading.pas',
    'uCompareMergeUI.pas',
]

SMOOTH_REPLACEMENTS = [
    (r"TrText\('Mesclando arquivos\.\.\.'\)", "TrText('Merging files...')"),
    (r"TrText\('Mesclagem de arquivos conclu.{1,4}da em: %s milissegundos\.'\)",
     "TrText('Merge files completed in: %s millisecs.')"),
    (r"TrText\('Erro ao mesclar arquivos: '\)", "TrText('Merge files error: ')"),
    (r"Exception\.Create\('N.{1,6}o foi poss.{1,6}vel substituir o arquivo de destino\.'\)",
     "Exception.Create(TrText('Could not replace destination file.'))"),
    (r"Exception\.Create\('N.{1,6}o foi poss.{1,6}vel finalizar a opera.{1,6}.{1,6}o de renomea.{1,6}.{1,6}o do arquivo mesclado\.'\)",
     "Exception.Create(TrText('Could not finalize merge file rename operation.'))"),
]

COMPARE_REPLACEMENTS = [
    (r"TrText\('Ir para linha'\)", "TrText('Go to line')"),
    (r"TrText\('Numero da linha \(1\.\.'\)", "TrText('Line number (1..')"),
]


def fix_file(path, patterns):
    for enc in ('cp1252', 'latin-1', 'utf-8'):
        try:
            with open(path, 'r', encoding=enc) as f:
                text = f.read()
            file_enc = enc
            break
        except UnicodeDecodeError:
            text = None
    if text is None:
        with open(path, 'r', encoding='utf-8', errors='replace') as f:
            text = f.read()
        file_enc = 'utf-8'
    orig = text
    for pat, repl in patterns:
        text, n = re.subn(pat, repl, text)
        if n:
            print(f'  {os.path.basename(path)}: {pat[:50]}... -> {n}')
    if text != orig:
        with open(path, 'w', encoding=file_enc, newline='\r\n') as f:
            f.write(text)
        print(f'  saved as {file_enc}')
        return True
    return False


def main():
    main_path = os.path.join(SRC, 'MainUnit.pas')
    print('MainUnit.pas')
    fix_file(main_path, REPLACEMENTS)

    print('Other units')
    for name in OTHER_FILES:
        p = os.path.join(SRC, name)
        if not os.path.exists(p):
            continue
        pats = SMOOTH_REPLACEMENTS if 'Smooth' in name else COMPARE_REPLACEMENTS
        if fix_file(p, pats):
            print(f'  updated {name}')

    # Report remaining TrText Erro in MainUnit
    with open(main_path, 'r', encoding='cp1252', errors='replace') as f:
        t = f.read()
    bad = re.findall(r"TrText\('Erro[^']*'\)", t)
    print(f'Remaining TrText Erro* in MainUnit: {len(bad)}')
    for b in bad[:5]:
        print(' ', b[:80])


if __name__ == '__main__':
    main()
