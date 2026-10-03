# -*- coding: cp1252 -*-
"""Add proper PT-BR accents (#$) to GTextPortuguese line/merge/delete UI strings in uI18n.pas."""
import re
import os

PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'uI18n.pas')

# key substring in line -> new Portuguese value (with #$ escapes only)
PT_BR = {
    "'Copy only a specific range of lines from source'] := 'Copiar apenas um intervalo especifico":
        "'Copy only a specific range of lines from source'] := 'Copiar apenas um intervalo espec'#237'fico de linhas do arquivo de origem'",
    "'From line:'] := 'Da linha:'":
        "'From line:'] := 'Da linha:'",  # ok
    "'To line:'] := 'Ate a linha:'":
        "'To line:'] := 'At'#233' a linha:'",
    "'Error: \"From line\" cannot be empty.'] := 'Erro: \"Da linha\" nao pode estar vazia.'":
        "'Error: \"From line\" cannot be empty.'] := 'Erro: \"Da linha\" n'#227'o pode estar vazia.'",
    "'Error: \"To line\" cannot be empty.'] := 'Erro: \"Ate a linha\" nao pode estar vazia.'":
        "'Error: \"To line\" cannot be empty.'] := 'Erro: \"At'#233' a linha\" n'#227'o pode estar vazia.'",
    "'Error: \"From line\" must be a valid number.'] := 'Erro: \"Da linha\" deve ser um numero valido.'":
        "'Error: \"From line\" must be a valid number.'] := 'Erro: \"Da linha\" deve ser um n'#250'mero v'#225'lido.'",
    "'Error: \"To line\" must be a valid number.'] := 'Erro: \"Ate a linha\" deve ser um numero valido.'":
        "'Error: \"To line\" must be a valid number.'] := 'Erro: \"At'#233' a linha\" deve ser um n'#250'mero v'#225'lido.'",
    "'Error: \"From line\" must be at least 1.'] := 'Erro: \"Da linha\" deve ser pelo menos 1.'":
        "'Error: \"From line\" must be at least 1.'] := 'Erro: \"Da linha\" deve ser pelo menos 1.'",
    "'Error: \"To line\" must be at least 1.'] := 'Erro: \"Ate a linha\" deve ser pelo menos 1.'":
        "'Error: \"To line\" must be at least 1.'] := 'Erro: \"At'#233' a linha\" deve ser pelo menos 1.'",
    "'Error: \"From line\" (%d) cannot be greater than \"To line\" (%d).'] := 'Erro: \"Da linha\" (%d) nao pode ser maior que \"Ate a linha\" (%d).'":
        "'Error: \"From line\" (%d) cannot be greater than \"To line\" (%d).'] := 'Erro: \"Da linha\" (%d) n'#227'o pode ser maior que \"At'#233' a linha\" (%d).'",
    "'Error: Source file not found: %s'] := 'Erro: Arquivo de origem nao encontrado: %s'":
        "'Error: Source file not found: %s'] := 'Erro: Arquivo de origem n'#227'o encontrado: %s'",
    "'Error: Could not read source file to validate line count.'] := 'Erro: Nao foi possivel ler o arquivo de origem para validar o total de linhas.'":
        "'Error: Could not read source file to validate line count.'] := 'Erro: N'#227'o foi poss'#237'vel ler o arquivo de origem para validar o total de linhas.'",
    "'Error: \"From line\" (%d) exceeds total lines in source file (%d).'] := 'Erro: \"Da linha\" (%d) excede o total de linhas no arquivo de origem (%d).'":
        "'Error: \"From line\" (%d) exceeds total lines in source file (%d).'] := 'Erro: \"Da linha\" (%d) excede o total de linhas no arquivo de origem (%d).'",
    "'Error: \"To line\" (%d) exceeds total lines in source file (%d).'] := 'Erro: \"Ate a linha\" (%d) excede o total de linhas no arquivo de origem (%d).'":
        "'Error: \"To line\" (%d) exceeds total lines in source file (%d).'] := 'Erro: \"At'#233' a linha\" (%d) excede o total de linhas no arquivo de origem (%d).'",
    "'Error validating line range: '] := 'Erro ao validar o intervalo de linhas: '":
        "'Error validating line range: '] := 'Erro ao validar o intervalo de linhas: '",
    "'Merging files...'] := 'Mesclando arquivos...'":
        "'Merging files...'] := 'Mesclando arquivos...'",
    "'Merge files completed in: %s millisecs.'] := 'Mesclagem de arquivos concluida em: %s millisecs.'":
        "'Merge files completed in: %s millisecs.'] := 'Mesclagem de arquivos conclu'#237'da em: %s milissegundos.'",
    "'Could not replace destination file.'] := 'Nao foi possivel substituir o arquivo de destino.'":
        "'Could not replace destination file.'] := 'N'#227'o foi poss'#237'vel substituir o arquivo de destino.'",
    "'Could not finalize merge file rename operation.'] := 'Nao foi possivel finalizar a operacao de renomeacao do arquivo mesclado.'":
        "'Could not finalize merge file rename operation.'] := 'N'#227'o foi poss'#237'vel finalizar a opera'#231#227'o de renomea'#231#227'o do arquivo mesclado.'",
    "'Merge files error: '] := 'Erro ao mesclar arquivos: '":
        "'Merge files error: '] := 'Erro ao mesclar arquivos: '",
    "'Go to line'] := 'Ir para linha'":
        "'Go to line'] := 'Ir para linha'",
    "'Line number (1..'] := 'Numero da linha (1..'":
        "'Line number (1..'] := 'N'#250'mero da linha (1..'",
}

def main():
    with open(PATH, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()
    out_enc = 'utf-8'
    changed = 0
    for i, line in enumerate(lines):
        if 'GTextPortuguese.Values[' not in line:
            continue
        for old_part, new_line_fragment in PT_BR.items():
            if old_part in line:
                # rebuild line keeping prefix
                prefix = line.split(':=', 1)[0] + ':= '
                suffix = new_line_fragment.split(':= ', 1)[1]
                if not suffix.endswith('\n'):
                    suffix += ';\n'
                elif not suffix.endswith(';'):
                    suffix = suffix.rstrip() + ';\n'
                new_line = prefix + suffix
                if new_line != line:
                    lines[i] = new_line
                    changed += 1
                break
    print('Updated', changed, 'GTextPortuguese lines')
    if changed:
        with open(PATH, 'w', encoding=out_enc, newline='\r\n') as f:
            f.writelines(lines)

if __name__ == '__main__':
    main()
