# Cursor — pasta AppData, tamanho e limpeza segura

Documento de referência sobre a pasta de dados do **Cursor** no Windows: para que serve, o que pode ser apagado e como liberar espaço sem perder tudo por engano.

**Caminho principal (Roaming):**  
`C:\Users\<seu-usuário>\AppData\Roaming\Cursor`

**Exemplo medido (maio/2026):** ~17 GB, sendo ~16 GB em `User\globalStorage` (`state.vscdb` + backup).

---

## 1. Para que serve essa pasta?

É o **perfil de dados do Cursor** no Windows — o mesmo conceito do VS Code em `AppData\Roaming\Code`. O editor grava aqui tudo que precisa persistir entre aberturas:

| Pasta / arquivo | Função |
|-----------------|--------|
| `User\settings.json` | Configurações do usuário |
| `User\keybindings.json` | Atalhos de teclado |
| `User\snippets\` | Snippets personalizados |
| `User\workspaceStorage\` | Estado por projeto (layout, extensões por workspace) |
| `User\globalStorage\` | Estado global das extensões e do Cursor |
| `User\globalStorage\state.vscdb` | Banco SQLite com histórico de chat, estado interno, dados de extensões |
| `User\History\` | Histórico local de arquivos editados |
| `CachedData\`, `Cache\`, `GPUCache\` | Cache do Electron/Chromium |
| `logs\` | Logs do editor |
| Extensões (dados) | Ex.: Java (Red Hat), Laravel, checkpoints do Cursor |

**Não é pasta temporária do Windows.** Apagar tudo equivale a um **reset do Cursor** (configurações e histórico locais), não a uma “limpeza de disco” genérica.

Há também dados em **Local** (outro perfil):

`C:\Users\<seu-usuário>\AppData\Local\Cursor`

Costuma concentrar cache maior, atualizações e binários. Este guia foca em **Roaming**, que foi onde se observou ~17 GB.

---

## 2. Onde está o espaço (exemplo real)

Análise típica quando a pasta cresce muito:

| Local | Tamanho aprox. | Observação |
|-------|----------------|------------|
| `User\globalStorage\state.vscdb` | ~9 GB | Banco principal de estado |
| `User\globalStorage\state.vscdb.backup` | ~7 GB | Cópia de backup do mesmo banco |
| `User\workspaceStorage\` | ~1 GB | Estado por pasta/projeto |
| `CachedData\` | ~200 MB | Cache de versões do editor |
| Demais (extensões, checkpoints, etc.) | variável | Ex.: `anysphere.cursor-commits`, Red Hat Java |

Ou seja: na maioria dos casos o “vilão” são **`state.vscdb`** e seu **`.backup`**, não os projetos em `C:\Hamden\...` ou outros repositórios.

---

## 3. Posso apagar a pasta inteira?

| Pergunta | Resposta |
|----------|----------|
| Apagar `Roaming\Cursor` inteira? | **Sim**, com Cursor **totalmente fechado** |
| Afeta o Windows ou meus projetos? | **Não** — projetos ficam onde você os salvou |
| O que perco? | Settings, keybindings, histórico de chat local, estado de workspaces, dados de extensões |
| O que acontece depois? | O Cursor **recria** a pasta na próxima abertura (como instalação nova de perfil) |

**Não apague com o Cursor aberto** — risco de corrupção do `state.vscdb`.

**Não é recomendado** como manutenção rotineira; use as opções graduais da seção 5.

---

## 4. Antes de qualquer limpeza

1. **Salve** arquivos abertos no editor.
2. **Feche o Cursor** (File → Exit ou Alt+F4).
3. Confirme na **bandeja do sistema** que não há processo `Cursor.exe`.
4. Opcional: faça **backup** da pasta inteira ou só de `User\` se quiser poder restaurar settings.

Verificar se o Cursor está fechado (PowerShell):

```powershell
Get-Process Cursor -ErrorAction SilentlyContinue
```

Se não retornar nada, pode prosseguir.

---

## 5. Opções de limpeza (do mais seguro ao mais agressivo)

### Opção A — Só cache (ganho pequeno, risco baixo)

Remove caches que o editor recria sozinho. No exemplo medido, libera poucos MB/GB comparado ao banco.

**Pastas (com Cursor fechado):**

- `%APPDATA%\Cursor\CachedData`
- `%APPDATA%\Cursor\Cache`
- `%APPDATA%\Cursor\GPUCache`
- `%APPDATA%\Cursor\Code Cache`

**PowerShell:**

```powershell
$base = "$env:APPDATA\Cursor"
@('CachedData','Cache','GPUCache','Code Cache') | ForEach-Object {
  $p = Join-Path $base $_
  if (Test-Path $p) { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "Removido: $p" }
}
```

---

### Opção B — Apagar só o backup do banco (~7 GB, risco moderado)

Remove `state.vscdb.backup`. O arquivo principal `state.vscdb` permanece.

- **Ganho:** ~7 GB (no exemplo medido).
- **Risco:** se o `state.vscdb` principal estiver corrompido, você perde essa cópia de recuperação.
- **Recomendado** quando o disco está cheio e você aceita esse trade-off.

**PowerShell:**

```powershell
$backup = "$env:APPDATA\Cursor\User\globalStorage\state.vscdb.backup"
if (Test-Path $backup) {
  Remove-Item $backup -Force
  Write-Host "Backup removido: $backup"
} else {
  Write-Host "Arquivo nao encontrado."
}
```

---

### Opção C — Reset do banco de estado (~16 GB, perde histórico interno)

Remove o banco e o backup. O Cursor cria um `state.vscdb` novo e vazio na próxima abertura.

- **Ganho:** ~16 GB (no exemplo medido).
- **Perde:** grande parte do histórico de chat Agent, estado interno acumulado, alguns dados de extensões no global storage.
- **Mantém** (se não apagar outras pastas): `settings.json`, `keybindings.json`, `snippets`, muitas coisas em `workspaceStorage`.

**PowerShell:**

```powershell
$gs = "$env:APPDATA\Cursor\User\globalStorage"
@('state.vscdb','state.vscdb.backup','state.vscdb-shm','state.vscdb-wal') | ForEach-Object {
  $f = Join-Path $gs $_
  if (Test-Path $f) { Remove-Item $f -Force; Write-Host "Removido: $f" }
}
```

Opcional: compactar checkpoints do Cursor (ganho menor):

```powershell
$commits = "$env:APPDATA\Cursor\User\globalStorage\anysphere.cursor-commits"
if (Test-Path $commits) {
  Remove-Item $commits -Recurse -Force
  Write-Host "Checkpoints removidos."
}
```

---

### Opção D — Reset completo do perfil Roaming (~17 GB)

Equivalente a “desinstalar o perfil” do Cursor no usuário Windows.

1. Feche o Cursor.
2. Renomeie a pasta (mais seguro que apagar de uma vez):

```powershell
$src = "$env:APPDATA\Cursor"
$dst = "$env:APPDATA\Cursor_backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
if (Test-Path $src) {
  Rename-Item $src $dst
  Write-Host "Pasta renomeada para: $dst"
  Write-Host "Abra o Cursor para criar perfil novo. Se estiver ok, apague o backup depois."
}
```

3. Abra o Cursor — ele recria `Cursor` do zero.
4. Depois de confirmar que está tudo certo, pode apagar `Cursor_backup_*` para liberar o disco.

---

## 6. O que NÃO fazer

- Não apagar `Roaming\Cursor` com o editor aberto.
- Não confundir com a pasta do **projeto** (ex.: `FileReadThread-2\Src`) — projetos não ficam em AppData.
- Não apagar `AppData\Local\Cursor` sem saber o conteúdo — pode incluir instalador/cache diferente; avalie tamanho antes (`Get-ChildItem` + tamanho).
- Não esperar que limpar cache sozinho resolva 17 GB se o problema for `state.vscdb`.

---

## 7. Verificar tamanho antes e depois

**Tamanho total da pasta Roaming:**

```powershell
$path = "$env:APPDATA\Cursor"
if (Test-Path $path) {
  $bytes = (Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  [PSCustomObject]@{
    Path = $path
    SizeGB = [math]::Round($bytes / 1GB, 2)
  }
}
```

**Top pastas dentro de `Cursor`:**

```powershell
Get-ChildItem "$env:APPDATA\Cursor" -Directory | ForEach-Object {
  $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  [PSCustomObject]@{ Name = $_.Name; SizeGB = [math]::Round($size / 1GB, 2) }
} | Sort-Object SizeGB -Descending
```

**Arquivos grandes em `globalStorage`:**

```powershell
Get-ChildItem "$env:APPDATA\Cursor\User\globalStorage" -Recurse -File -ErrorAction SilentlyContinue |
  Sort-Object Length -Descending |
  Select-Object -First 15 @{N='SizeMB';E={[math]::Round($_.Length/1MB,1)}}, FullName
```

---

## 8. Manutenção preventiva

- Fechar o Cursor periodicamente permite que ele finalize o SQLite corretamente.
- Se o histórico de chat não for importante, **Opção B** ou **C** evita crescimento descontrolado do `.backup`.
- Revisar extensões pesadas (ex.: Java, PHP/Laravel) em `globalStorage` — caches de extensão somam MB, não costumam ser os 16 GB.
- Dentro do Cursor: **Settings** → procurar opções de limpar histórico / dados locais (varia conforme versão).

---

## 9. Resumo rápido

| Objetivo | Ação sugerida |
|----------|----------------|
| Liberar ~7 GB com risco moderado | Opção B — apagar `state.vscdb.backup` |
| Liberar ~16 GB, manter settings | Opção C — apagar `state.vscdb` + backup |
| Começar do zero no Cursor | Opção D — renomear/apagar pasta `Roaming\Cursor` |
| Só “limpar lixo” leve | Opção A — cache |
| Não perder nada | Não apagar; só monitorar tamanho |

---

## 10. Referências de caminho

| Caminho | Conteúdo típico |
|---------|-----------------|
| `%APPDATA%\Cursor` | Perfil Roaming (este documento) |
| `%LOCALAPPDATA%\Cursor` | Cache local, instalador, dados Local |
| Projetos (ex.) | `C:\Hamden\Sistemas\...` — **independente** do AppData do Cursor |

---

*Documento gerado para referência interna. Ajuste `<seu-usuário>` e os tamanhos conforme nova medição no seu PC.*
