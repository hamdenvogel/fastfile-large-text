# Assistente IA — Validar fonte (sintaxe)

**Versão de referência:** internos **`v3.0.5.136`–`v3.0.5.137`** (publicada `3.0.5.100` inalterada)  
**Âmbito:** checagem de **sintaxe** de fontes gerados/carregados no Assistente (`Ctrl+Alt+A`). **Não executa** o código.

Documentos relacionados: [`DOC_ZS_ATALHOS.md`](DOC_ZS_ATALHOS.md) §16 / §18 · [`DOC_ASSISTENTE_IA_CHECKLIST_TESTES.md`](DOC_ASSISTENTE_IA_CHECKLIST_TESTES.md) · [`CHANGELOG_IMPLEMENTACOES.md`](CHANGELOG_IMPLEMENTACOES.md)

---

## 1. O que a aplicação valida hoje

| Linguagem | Extensões | Companion |
|-----------|-----------|-----------|
| **Python** | `.py` | `ScriptEngine.exe --validate` |
| **JavaScript** | `.js`, `.mjs`, `.cjs` | `CodeCheck.exe` |
| **JSX** | `.jsx` | `CodeCheck.exe` |
| **TypeScript** | `.ts` | `CodeCheck.exe` |
| **TSX / React** | `.tsx` | `CodeCheck.exe` |

Constante canónica: `VALIDATABLE_SOURCE_EXTS` em `UnConsts.pas` (`.py;.js;.jsx;.ts;.tsx;.mjs;.cjs`).  
Gate partilhado: `IsValidatableComposeSourcePath` em `uFastFileAssistantHost.pas`.

**Fora do âmbito (exemplos):** `.pas`, `.java`, `.go`, `.cpp`, `.cs`, `.md`, `.pdf`, etc. — a app **informa** a lista suportada e **não** chama o companion.

---

## 2. Como o utilizador pede

### 2.1 Botão no aviso do ficheiro gerado

Após `compose_document` com extensão validável, o banner mostra **Validar** (`Assistant.ValidateSource`). Hint lista Python/JS/JSX/TS/TSX.

### 2.2 Chat — validar / carregar

| Pedido (exemplos) | Comportamento |
|-------------------|---------------|
| `carregar o fonte pra validar` / `load source to validate` | Abre diálogo filtrado às extensões suportadas → abre no editor → valida |
| `validar C:\...\script.py` | Confirma extensão **primeiro**; se OK, valida (e pode abrir no Read) |
| `validar o fonte` / `validar o código` | Usa último compose (`FGeneratedFilePath` / `GLastComposePath`) ou ficheiro aberto se validável |
| Extensão não suportada | Mensagem `Assistant.Validate.Unsupported` + lista `Assistant.Validate.SupportedLanguages` |

Action id (IA / mapa): **`validate_source`**.

### 2.3 Chat — perguntar quais linguagens

Pedidos do tipo *«quais linguagens valida?»* / *«which languages can you validate?»* → resposta local com `Assistant.Validate.SupportedLanguages` (sem LLM obrigatório).

A IA também recebe a lista no prompt operacional (regra **8v** / descrição de `validate_source`).

---

## 3. Fluxo técnico (resumo)

```
Pedido Validar / validate_source
        │
        ▼
 Extensão ∈ VALIDATABLE_SOURCE_EXTS ?  ──não──► Unsupported + lista de linguagens
        │ sim
        ▼
 Ficheiro existe?
        │ sim
        ▼
 .py  → ScriptEngine.exe --validate "path"
 outros → CodeCheck.exe "path"
        │
        ▼
 Relatório no MemoReply (OK / ERROR:linha:col:msg)
```

- Timeout: `CODECHECK_VALIDATE_TIMEOUT_MS` (120 s).  
- Download FTP se faltar EXE: `CODECHECK_DOWNLOAD_URL` / `SCRIPTENGINE_DOWNLOAD_URL` (`FASTFILE_EXECUTABLES_BASE_URL`).  
- Fontes companions: `data-lake-duckdb-main\ScriptEngine.py` (`--validate`), `CodeCheck.py`; bats `build_exe_scriptengine.bat` / `build_exe_codecheck.bat`.

**Ordem no chat (v3.0.5.147):** **Enviar** envia NL à IA (`validate_source` ou `intent=explain` com a lista). O botão **Validar** no aviso do ficheiro gerado continua a validar o path sem passar pelo modelo.

---

## 4. i18n (chaves principais)

| Chave | Uso |
|-------|-----|
| `Assistant.ValidateSource` / `ValidateHint` | Botão e hint |
| `Assistant.Validate.Running` / `.Ok` / `.Failed` | Estados |
| `Assistant.Validate.Unsupported` | Tipo não suportado |
| `Assistant.Validate.SupportedLanguages` | Lista actual + dica de chat |
| `Assistant.Validate.NeedPath` / `.PickTitle` / `.Cancelled` | Sem path / diálogo |
| `Assistant.Validate.FileMissing` / `.Timeout` / `.ExeMissing` | Erros |

---

## 5. Deploy

1. Rebuild `ScriptEngine.exe` (modo `--validate`) e `CodeCheck.exe`.  
2. Copiar para pasta do `FastFile.exe` **ou** publicar em `http://hvogel.com.br/fastfile_executables/`.  
3. Testar botão **Validar** após gerar `.py` / `.tsx` e os pedidos de chat da secção 2.

---

## 6. Checklist rápido QA

- [ ] Gerar `.py` → **Validar** → OK ou ERROR com linha  
- [ ] Gerar `.tsx` → **Validar** → CodeCheck  
- [ ] Gerar `.pas` → botão Validar **oculto** (não validável)  
- [ ] Chat: `quais linguagens valida?` → lista Python/JS/JSX/TS/TSX  
- [ ] Chat: `carregar o fonte pra validar` → diálogo só com extensões suportadas  
- [ ] Chat: path `.java` + validar → Unsupported + lista (sem download de companion)  
- [ ] Chat: path `.py` válido → relatório no reply  

---

*Implementação: `uFastFileAssistant.pas` (`TryHandleValidateSourceChat`, `validate_source`), `MainUnit.AssistantCbValidateComposedSource`, `UnConsts` (`CODECHECK`, `VALIDATABLE_SOURCE_EXTS`).*
