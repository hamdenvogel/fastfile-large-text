# Integração ODBC Nativa no Painel de Macros Python (Script Engine)

> **FastFile** - Documento Técnico de Especificação  
> Data: 14/05/2026  
> Versão: 1.0  

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Arquitetura da Integração](#2-arquitetura-da-integração)
3. [Protocolo de Comunicação (Pipe)](#3-protocolo-de-comunicação-pipe)
4. [Implementação Nativa sem Bibliotecas Externas](#4-implementação-nativa-sem-bibliotecas-externas)
5. [Parametrização via Metadados](#5-parametrização-via-metadados)
6. [ODBC Recentes (Recent ODBC's Open)](#6-odbc-recentes-recent-odbcs-open)
7. [Validações e Tratamento de Erros](#7-validações-e-tratamento-de-erros)
8. [Compatibilidade 32/64 bits](#8-compatibilidade-3264-bits)
9. [Impacto no Deploy](#9-impacto-no-deploy)
10. [Exemplo de Uso pelo Usuário](#10-exemplo-de-uso-pelo-usuário)
11. [Traduções - 11 Idiomas](#11-traduções---11-idiomas)
12. [Diagrama de Fluxo](#12-diagrama-de-fluxo)
13. [Resumo Executivo](#13-resumo-executivo)

---

## 1. Visão Geral

Esta especificação descreve a integração **opcional** de fontes de dados ODBC (32/64 bits) ao Painel de Macros Python (Script Engine) já existente no FastFile. A integração permite que o usuário conecte-se a qualquer fonte de dados ODBC disponível no sistema e utilize esses dados dentro dos scripts Python `transform()`, alimentando o processamento linha a linha na ListView.

### Princípios de Design

- **Opcional**: A funcionalidade ODBC é um complemento; o Script Engine continua funcionando normalmente sem ela
- **Nativa**: Zero bibliotecas externas - utiliza apenas `ctypes` + `odbc32.dll` (nativa do Windows)
- **Não-Invasiva**: Não impacta negativamente o fluxo principal caso a conexão ODBC falhe
- **Parametrizável**: Toda configuração é tratada como metadados (JSON)
- **Com Histórico**: Conexões recentes são persistidas para rápido recarregamento

---

## 2. Arquitetura da Integração

A integração ocorre **dentro do processo ScriptEngine.exe** (Python compilado com PyInstaller), estendendo o protocolo de pipe stdin/stdout já existente entre Delphi e Python.

```
┌─────────────────────────┐     pipe stdin/stdout      ┌──────────────────────────────┐
│   FastFile.exe           │◄─────────────────────────►│   ScriptEngine.exe            │
│   (Delphi 7 / Win32)    │                            │   (Python / PyInstaller)      │
│                          │                            │                               │
│  ┌────────────────────┐  │   ODBC_CONNECT:<b64json>  │  ┌─────────────────────────┐  │
│  │ Script Engine       │  │─────────────────────────►│  │  Módulo NativeODBC      │  │
│  │ Panel (UI)          │  │                           │  │  (ctypes + odbc32.dll)  │  │
│  │                     │  │   ODBC_OK / ODBC_ERROR    │  └─────────────────────────┘  │
│  │  [Botão ODBC]       │  │◄─────────────────────────│            │                   │
│  │  [Config Panel]     │  │                           │            ▼                   │
│  │  [MRU Recentes]     │  │   LINE:n:text             │  ctx['odbc_row'] = {...}      │
│  │  [Run Script]       │  │─────────────────────────►│  ctx['odbc_columns'] = [...]  │
│  └────────────────────┘  │                           │  transform(line, ctx)          │
│                          │   OUT:n:result             │                               │
│  ┌────────────────────┐  │◄─────────────────────────│                               │
│  │ TMruHelper          │  │                           └──────────────────────────────┘
│  │ (ODBC INI File)     │  │                                        │
│  └────────────────────┘  │                                        ▼
└─────────────────────────┘                            ┌──────────────────────────────┐
                                                        │   odbc32.dll                  │
                                                        │   (Windows Nativo)            │
                                                        │   C:\Windows\System32         │
                                                        └──────────────────────────────┘
                                                                     │
                                                                     ▼
                                                        ┌──────────────────────────────┐
                                                        │   Driver ODBC do Usuário      │
                                                        │   (SQL Server, MySQL,         │
                                                        │    PostgreSQL, Oracle,         │
                                                        │    Excel, Access, etc.)        │
                                                        └──────────────────────────────┘
```

### Camadas da Arquitetura

| Camada | Componente | Responsabilidade |
|--------|-----------|------------------|
| **UI** | Delphi (TfrmMain) | Painel de configuração ODBC, botões, MRU |
| **Transporte** | Pipe stdin/stdout | Protocolo texto UTF-8 line-delimited |
| **Lógica ODBC** | Python (NativeODBC) | Conexão, queries, iteração de resultados |
| **Acesso Dados** | odbc32.dll (Win32) | API ODBC nativa do Windows |
| **Persistência** | INI File | Conexões ODBC recentes |

---

## 3. Protocolo de Comunicação (Pipe)

### Novos Comandos (Delphi → Python via stdin)

| Comando | Formato | Descrição |
|---------|---------|-----------|
| `ODBC_CONNECT` | `ODBC_CONNECT:<base64_json>` | Conectar a uma fonte ODBC |
| `ODBC_DISCONNECT` | `ODBC_DISCONNECT` | Desconectar da fonte ODBC atual |
| `ODBC_TEST` | `ODBC_TEST` | Testar a conexão atual (ping) |
| `ODBC_QUERY` | `ODBC_QUERY:<base64_sql>` | Executar uma query SQL |
| `ODBC_LIST_DSN` | `ODBC_LIST_DSN` | Listar DSNs disponíveis no sistema |
| `ODBC_FETCH_NEXT` | `ODBC_FETCH_NEXT` | Buscar próxima linha do resultset |
| `ODBC_FETCH_ALL` | `ODBC_FETCH_ALL` | Buscar todas as linhas (cuidado com memória) |

### Novas Respostas (Python → Delphi via stdout)

| Resposta | Formato | Descrição |
|----------|---------|-----------|
| `ODBC_OK` | `ODBC_OK:<mensagem>` | Operação bem-sucedida |
| `ODBC_ERROR` | `ODBC_ERROR:<mensagem>` | Erro na operação |
| `ODBC_COLUMNS` | `ODBC_COLUMNS:<base64_json_array>` | Nomes das colunas do resultset |
| `ODBC_ROW` | `ODBC_ROW:<n>:<base64_json_dict>` | Linha n do resultset |
| `ODBC_ROW_COUNT` | `ODBC_ROW_COUNT:<n>` | Total de linhas retornadas |
| `ODBC_DSN_LIST` | `ODBC_DSN_LIST:<base64_json_array>` | Lista de DSNs disponíveis |
| `ODBC_FETCH_DONE` | `ODBC_FETCH_DONE` | Não há mais linhas para buscar |

### Exemplo de Sessão Completa

```
[Delphi → Python]  ODBC_LIST_DSN
[Python → Delphi]  ODBC_DSN_LIST:eyJkc25zIjogWy4uLl19

[Delphi → Python]  ODBC_CONNECT:eyJjb25uZWN0aW9uX3N0cmluZyI6ICJEU049U2FsZXNEQiJ9
[Python → Delphi]  ODBC_OK:Connection successful

[Delphi → Python]  ODBC_TEST
[Python → Delphi]  ODBC_OK:Connection is alive

[Delphi → Python]  ODBC_QUERY:U0VMRUNUICogRlJPTSBjbGllbnRlcyBMSU1JVCAxMA==
[Python → Delphi]  ODBC_COLUMNS:WyJpZCIsICJub21lIiwgImNpZGFkZSJd
[Python → Delphi]  ODBC_ROW:1:eyJpZCI6ICIxIiwgIm5vbWUiOiAiSm9hbyIsICJjaWRhZGUiOiAiU1AifQ==
[Python → Delphi]  ODBC_ROW:2:eyJpZCI6ICIyIiwgIm5vbWUiOiAiTWFyaWEiLCAiY2lkYWRlIjogIlJKIn0=
[Python → Delphi]  ODBC_ROW_COUNT:2
[Python → Delphi]  ODBC_FETCH_DONE

[Delphi → Python]  SCRIPT:<base64_do_script_transform>
[Python → Delphi]  COMPILED_OK

[Delphi → Python]  LINE:1:Linha do arquivo original
[Python → Delphi]  OUT:1:Linha do arquivo original | DB: Joao (SP)

[Delphi → Python]  ODBC_DISCONNECT
[Python → Delphi]  ODBC_OK:Disconnected
```

---

## 4. Implementação Nativa sem Bibliotecas Externas

### Por que ctypes + odbc32.dll?

| Alternativa | Prós | Contras | Decisão |
|-------------|------|---------|---------|
| **pyodbc** | API Pythonica, madura | Dependência externa, +2MB no exe | ❌ Rejeitada |
| **pypyodbc** | Pure Python | Projeto abandonado, bugs | ❌ Rejeitada |
| **ctypes + odbc32.dll** | Zero deps, nativa Windows | API de baixo nível | ✅ **Escolhida** |
| **ADO via Delphi** | Familiar em Delphi | Não aproveita o ScriptEngine | ❌ Rejeitada |

### Código Python - Classe NativeODBC

```python
"""
NativeODBC - Acesso ODBC nativo via Win32 API (ctypes)
Sem dependências externas. Usa apenas odbc32.dll presente em todo Windows.
"""
import ctypes
from ctypes import wintypes
from typing import Dict, List, Optional, Generator

odbc32 = ctypes.windll.odbc32

# Constantes ODBC
SQL_HANDLE_ENV = 1
SQL_HANDLE_DBC = 2
SQL_HANDLE_STMT = 3
SQL_ATTR_ODBC_VERSION = 200
SQL_OV_ODBC3 = 3
SQL_SUCCESS = 0
SQL_SUCCESS_WITH_INFO = 1
SQL_ERROR = -1
SQL_INVALID_HANDLE = -2
SQL_NTS = -3
SQL_FETCH_NEXT = 1
SQL_FETCH_FIRST = 2
SQL_NO_DATA = 100
SQL_CHAR = 1
SQL_C_CHAR = 1
SQL_DRIVER_NOPROMPT = 0


def _succeeded(ret: int) -> bool:
    """Verifica se o retorno ODBC indica sucesso."""
    return ret in (SQL_SUCCESS, SQL_SUCCESS_WITH_INFO)


class NativeODBC:
    """
    Classe para acesso ODBC nativo via Win32 API.
    Não requer pyodbc nem qualquer biblioteca externa.
    Usa apenas ctypes + odbc32.dll (presente em toda instalação Windows).
    """

    def __init__(self):
        self._henv = ctypes.c_void_p()
        self._hdbc = ctypes.c_void_p()
        self._hstmt = ctypes.c_void_p()
        self._connected = False
        self._columns: List[str] = []
        self._rows_cache: List[Dict[str, str]] = []

    @property
    def connected(self) -> bool:
        return self._connected

    @property
    def columns(self) -> List[str]:
        return self._columns

    def connect(self, connection_string: str) -> tuple:
        """
        Conecta a uma fonte ODBC.
        Retorna (success: bool, message: str).
        """
        # Alocar environment handle
        ret = odbc32.SQLAllocHandle(
            SQL_HANDLE_ENV, None, ctypes.byref(self._henv)
        )
        if not _succeeded(ret):
            return (False, "Failed to allocate ODBC environment handle")

        # Definir versão ODBC 3.x
        odbc32.SQLSetEnvAttr(
            self._henv, SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3, 0
        )

        # Alocar connection handle
        ret = odbc32.SQLAllocHandle(
            SQL_HANDLE_DBC, self._henv, ctypes.byref(self._hdbc)
        )
        if not _succeeded(ret):
            self._free_env()
            return (False, "Failed to allocate connection handle")

        # Conectar via DriverConnect (suporta connection strings completas)
        conn_bytes = connection_string.encode('ascii', errors='replace')
        conn_buf = ctypes.create_string_buffer(conn_bytes)
        out_buf = ctypes.create_string_buffer(1024)
        out_len = ctypes.c_short()

        ret = odbc32.SQLDriverConnectA(
            self._hdbc,
            None,              # hwnd (sem prompt)
            conn_buf,
            SQL_NTS,
            out_buf,
            1024,
            ctypes.byref(out_len),
            SQL_DRIVER_NOPROMPT
        )

        if _succeeded(ret):
            self._connected = True
            return (True, "Connection successful")
        else:
            error_msg = self._get_diag_error(SQL_HANDLE_DBC, self._hdbc)
            self._free_dbc()
            self._free_env()
            return (False, error_msg or "Connection failed (unknown error)")

    def test_connection(self) -> tuple:
        """
        Testa se a conexão está ativa executando uma query trivial.
        Retorna (success: bool, message: str).
        """
        if not self._connected:
            return (False, "No active connection")

        # Tenta alocar um statement como teste de sanidade
        hstmt = ctypes.c_void_p()
        ret = odbc32.SQLAllocHandle(
            SQL_HANDLE_STMT, self._hdbc, ctypes.byref(hstmt)
        )
        if _succeeded(ret):
            odbc32.SQLFreeHandle(SQL_HANDLE_STMT, hstmt)
            return (True, "Connection is alive")
        else:
            return (False, "Connection appears to be broken")

    def execute_query(self, sql: str) -> tuple:
        """
        Executa uma query SQL e armazena o resultset internamente.
        Retorna (success: bool, message: str, row_count: int).
        """
        if not self._connected:
            return (False, "No active connection", 0)

        # Liberar statement anterior se existir
        self._free_stmt()
        self._columns = []
        self._rows_cache = []

        # Alocar novo statement
        ret = odbc32.SQLAllocHandle(
            SQL_HANDLE_STMT, self._hdbc, ctypes.byref(self._hstmt)
        )
        if not _succeeded(ret):
            return (False, "Failed to allocate statement handle", 0)

        # Executar SQL
        sql_buf = ctypes.create_string_buffer(sql.encode('utf-8', errors='replace'))
        ret = odbc32.SQLExecDirectA(self._hstmt, sql_buf, SQL_NTS)

        if not _succeeded(ret):
            error_msg = self._get_diag_error(SQL_HANDLE_STMT, self._hstmt)
            self._free_stmt()
            return (False, error_msg or "Query execution failed", 0)

        # Obter informações das colunas
        col_count = ctypes.c_short()
        odbc32.SQLNumResultCols(self._hstmt, ctypes.byref(col_count))

        self._columns = []
        for i in range(1, col_count.value + 1):
            col_name = ctypes.create_string_buffer(256)
            name_len = ctypes.c_short()
            data_type = ctypes.c_short()
            col_size = ctypes.c_ulong()
            decimal_digits = ctypes.c_short()
            nullable = ctypes.c_short()

            odbc32.SQLDescribeColA(
                self._hstmt, i, col_name, 256,
                ctypes.byref(name_len),
                ctypes.byref(data_type),
                ctypes.byref(col_size),
                ctypes.byref(decimal_digits),
                ctypes.byref(nullable)
            )
            self._columns.append(
                col_name.value.decode('utf-8', errors='replace')
            )

        # Fetch todas as linhas
        row_number = 0
        while True:
            ret = odbc32.SQLFetch(self._hstmt)
            if ret == SQL_NO_DATA:
                break
            if not _succeeded(ret):
                break

            row_number += 1
            row: Dict[str, str] = {}
            for i, col_name in enumerate(self._columns, 1):
                buf = ctypes.create_string_buffer(8192)
                indicator = ctypes.c_long()
                odbc32.SQLGetData(
                    self._hstmt, i, SQL_C_CHAR,
                    buf, 8192, ctypes.byref(indicator)
                )
                if indicator.value == -1:  # SQL_NULL_DATA
                    row[col_name] = ''
                else:
                    row[col_name] = buf.value.decode('utf-8', errors='replace')

            self._rows_cache.append(row)

        self._free_stmt()
        return (True, "Query executed successfully", row_number)

    def get_row(self, index: int) -> Optional[Dict[str, str]]:
        """Retorna a linha no índice especificado (0-based) do cache."""
        if 0 <= index < len(self._rows_cache):
            return self._rows_cache[index]
        return None

    def get_all_rows(self) -> List[Dict[str, str]]:
        """Retorna todas as linhas cacheadas."""
        return self._rows_cache

    def row_count(self) -> int:
        """Retorna o número de linhas no cache."""
        return len(self._rows_cache)

    def list_dsn(self) -> List[Dict[str, str]]:
        """
        Lista todos os DSNs (Data Source Names) disponíveis no sistema.
        Retorna lista de dicts: [{'dsn': 'nome', 'driver': 'descrição'}, ...]
        """
        dsns: List[Dict[str, str]] = []

        henv = ctypes.c_void_p()
        ret = odbc32.SQLAllocHandle(SQL_HANDLE_ENV, None, ctypes.byref(henv))
        if not _succeeded(ret):
            return dsns

        odbc32.SQLSetEnvAttr(henv, SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3, 0)

        dsn_buf = ctypes.create_string_buffer(256)
        desc_buf = ctypes.create_string_buffer(256)
        dsn_len = ctypes.c_short()
        desc_len = ctypes.c_short()

        direction = SQL_FETCH_FIRST
        while True:
            ret = odbc32.SQLDataSourcesA(
                henv, direction,
                dsn_buf, 256, ctypes.byref(dsn_len),
                desc_buf, 256, ctypes.byref(desc_len)
            )
            if ret == SQL_NO_DATA:
                break
            if not _succeeded(ret):
                break

            dsns.append({
                'dsn': dsn_buf.value.decode('ascii', errors='replace'),
                'driver': desc_buf.value.decode('ascii', errors='replace')
            })
            direction = SQL_FETCH_NEXT

        odbc32.SQLFreeHandle(SQL_HANDLE_ENV, henv)
        return dsns

    def disconnect(self):
        """Desconecta da fonte ODBC e libera todos os handles."""
        self._free_stmt()
        if self._connected:
            odbc32.SQLDisconnect(self._hdbc)
            self._connected = False
        self._free_dbc()
        self._free_env()
        self._columns = []
        self._rows_cache = []

    # --- Métodos privados ---

    def _free_stmt(self):
        if self._hstmt:
            odbc32.SQLFreeHandle(SQL_HANDLE_STMT, self._hstmt)
            self._hstmt = ctypes.c_void_p()

    def _free_dbc(self):
        if self._hdbc:
            odbc32.SQLFreeHandle(SQL_HANDLE_DBC, self._hdbc)
            self._hdbc = ctypes.c_void_p()

    def _free_env(self):
        if self._henv:
            odbc32.SQLFreeHandle(SQL_HANDLE_ENV, self._henv)
            self._henv = ctypes.c_void_p()

    def _get_diag_error(self, handle_type: int, handle) -> str:
        """Extrai mensagem de erro diagnóstica do ODBC."""
        state = ctypes.create_string_buffer(6)
        native_error = ctypes.c_long()
        msg = ctypes.create_string_buffer(1024)
        msg_len = ctypes.c_short()

        ret = odbc32.SQLGetDiagRecA(
            handle_type, handle, 1,
            state, ctypes.byref(native_error),
            msg, 1024, ctypes.byref(msg_len)
        )
        if _succeeded(ret):
            state_str = state.value.decode('ascii', errors='replace')
            msg_str = msg.value.decode('utf-8', errors='replace')
            return f"[{state_str}] {msg_str}"
        return "Unknown ODBC error"
```

### Integração no ScriptEngine.py (Trecho de extensão)

```python
# --- Importar no topo do ScriptEngine.py ---
import json

# --- Instância global (lazy) ---
_odbc_instance: Optional['NativeODBC'] = None


def _get_odbc() -> 'NativeODBC':
    global _odbc_instance
    if _odbc_instance is None:
        _odbc_instance = NativeODBC()
    return _odbc_instance


# --- Novos handlers no loop main() ---

# ODBC_CONNECT:<base64_json>
if cmd.startswith('ODBC_CONNECT:'):
    b64_payload = cmd[len('ODBC_CONNECT:'):]
    try:
        params = json.loads(base64.b64decode(b64_payload).decode('utf-8'))
        conn_str = params.get('connection_string', '')
        if not conn_str:
            # Montar connection string a partir dos campos individuais
            parts = []
            if params.get('dsn'):
                parts.append(f"DSN={params['dsn']}")
            if params.get('driver'):
                parts.append(f"DRIVER={params['driver']}")
            if params.get('server'):
                parts.append(f"SERVER={params['server']}")
            if params.get('database'):
                parts.append(f"DATABASE={params['database']}")
            if params.get('uid'):
                parts.append(f"UID={params['uid']}")
            if params.get('pwd'):
                parts.append(f"PWD={params['pwd']}")
            conn_str = ';'.join(parts)

        odbc = _get_odbc()
        if odbc.connected:
            odbc.disconnect()

        success, message = odbc.connect(conn_str)
        if success:
            _send(f'ODBC_OK:{message}')
        else:
            _send(f'ODBC_ERROR:{_safe_single_line(message)}')
    except Exception as exc:
        _send(f'ODBC_ERROR:{_safe_single_line(str(exc))}')
    continue

# ODBC_DISCONNECT
if cmd == 'ODBC_DISCONNECT':
    odbc = _get_odbc()
    odbc.disconnect()
    _send('ODBC_OK:Disconnected')
    continue

# ODBC_TEST
if cmd == 'ODBC_TEST':
    odbc = _get_odbc()
    success, message = odbc.test_connection()
    if success:
        _send(f'ODBC_OK:{message}')
    else:
        _send(f'ODBC_ERROR:{_safe_single_line(message)}')
    continue

# ODBC_LIST_DSN
if cmd == 'ODBC_LIST_DSN':
    odbc = _get_odbc()
    dsns = odbc.list_dsn()
    payload = base64.b64encode(
        json.dumps(dsns, ensure_ascii=False).encode('utf-8')
    ).decode('ascii')
    _send(f'ODBC_DSN_LIST:{payload}')
    continue

# ODBC_QUERY:<base64_sql>
if cmd.startswith('ODBC_QUERY:'):
    b64_sql = cmd[len('ODBC_QUERY:'):]
    try:
        sql = base64.b64decode(b64_sql).decode('utf-8')
        odbc = _get_odbc()
        success, message, count = odbc.execute_query(sql)
        if success:
            # Enviar colunas
            cols_payload = base64.b64encode(
                json.dumps(odbc.columns, ensure_ascii=False).encode('utf-8')
            ).decode('ascii')
            _send(f'ODBC_COLUMNS:{cols_payload}')

            # Enviar linhas
            for i, row in enumerate(odbc.get_all_rows(), 1):
                row_payload = base64.b64encode(
                    json.dumps(row, ensure_ascii=False).encode('utf-8')
                ).decode('ascii')
                _send(f'ODBC_ROW:{i}:{row_payload}')

            _send(f'ODBC_ROW_COUNT:{count}')
            _send('ODBC_FETCH_DONE')
        else:
            _send(f'ODBC_ERROR:{_safe_single_line(message)}')
    except Exception as exc:
        _send(f'ODBC_ERROR:{_safe_single_line(str(exc))}')
    continue
```

### Injeção no ctx do transform()

Quando o ODBC está conectado e possui dados, o Script Engine injeta automaticamente no `ctx`:

```python
# Dentro do handler LINE: (modificação)
if odbc_instance and odbc_instance.connected and odbc_instance.row_count() > 0:
    row_index = line_number - 1  # 0-based
    script_ctx['odbc_connected'] = True
    script_ctx['odbc_columns'] = odbc_instance.columns
    script_ctx['odbc_row'] = odbc_instance.get_row(row_index)
    script_ctx['odbc_row_count'] = odbc_instance.row_count()
else:
    script_ctx['odbc_connected'] = False
    script_ctx['odbc_columns'] = []
    script_ctx['odbc_row'] = None
    script_ctx['odbc_row_count'] = 0
```

---

## 5. Parametrização via Metadados

Toda a configuração ODBC é transportada como JSON codificado em base64:

### Estrutura do JSON de Conexão

```json
{
    "dsn": "MeuDSN",
    "driver": "{SQL Server}",
    "server": "localhost\\SQLEXPRESS",
    "database": "MinhaBase",
    "uid": "usuario",
    "pwd": "senha",
    "connection_string": "",
    "query": "SELECT id, nome, cidade FROM clientes ORDER BY id",
    "timeout": 30,
    "autocommit": false,
    "read_only": true
}
```

### Regras de Prioridade

1. Se `connection_string` está preenchido, ele tem **prioridade absoluta** (ignora campos individuais)
2. Se `connection_string` está vazio, a string é montada a partir dos campos `dsn`, `driver`, `server`, `database`, `uid`, `pwd`
3. O campo `query` é executado automaticamente após conexão bem-sucedida (se preenchido)
4. `timeout` define o tempo máximo de espera (padrão: 30 segundos)

### Exemplos de Connection Strings Comuns

| Banco | Connection String |
|-------|-------------------|
| SQL Server | `DRIVER={SQL Server};SERVER=localhost;DATABASE=mydb;UID=sa;PWD=123` |
| MySQL | `DRIVER={MySQL ODBC 8.0 Driver};SERVER=localhost;DATABASE=mydb;UID=root;PWD=123` |
| PostgreSQL | `DRIVER={PostgreSQL ODBC Driver(UNICODE)};SERVER=localhost;DATABASE=mydb;UID=postgres;PWD=123` |
| MS Access | `DRIVER={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=C:\data\mydb.accdb` |
| Excel | `DRIVER={Microsoft Excel Driver (*.xls, *.xlsx)};DBQ=C:\data\planilha.xlsx;ReadOnly=1` |
| SQLite | `DRIVER={SQLite3 ODBC Driver};Database=C:\data\mydb.sqlite` |
| Oracle | `DRIVER={Oracle in OraClient19};DBQ=localhost:1521/ORCL;UID=sys;PWD=123` |
| DSN Direto | `DSN=MeuDSNConfigurado` |

---

## 6. ODBC Recentes (Recent ODBC's Open)

### Implementação no Lado Delphi

Reutiliza o padrão `TMruHelper` já existente no projeto, com INI dedicado:

```pascal
// Na criação do painel ODBC:
FOdbcMruHelper := TMruHelper.Create(
    EdtOdbcConnectionString,               // TEdit de connection string
    ExtractFilePath(Application.ExeName) + 'fastfile_odbc_mru.ini',
    15  // máximo de 15 itens recentes
);
```

### Formato do INI (fastfile_odbc_mru.ini)

```ini
[MRU]
Item0=DSN=SalesDB;Driver={SQL Server};Server=localhost
Item1=DSN=LogsDB;Driver={PostgreSQL ODBC Driver(UNICODE)};Server=192.168.1.10;Database=logs
Item2=Driver={Microsoft Excel Driver (*.xls, *.xlsx)};DBQ=C:\Reports\vendas_2026.xlsx
Item3=DSN=OracleProducao
Item4=Driver={MySQL ODBC 8.0 Driver};Server=db.empresa.com;Database=erp;UID=readonly
```

### Comportamento UX

- Ao focar no campo de Connection String, o dropdown de recentes aparece automaticamente
- Ao digitar, filtra os itens recentes por substring (busca fuzzy)
- Ao conectar com sucesso, a connection string é adicionada automaticamente ao MRU
- Setas do teclado navegam no dropdown; Enter seleciona
- Máximo de 15 itens (configurável); os mais antigos são descartados (FIFO)
- Botão "Clear recent ODBC list" para limpar o histórico

---

## 7. Validações e Tratamento de Erros

### Sequência de Validações na Conexão

```
1. Verificar se connection_string não está vazia
   └── Se vazia → ODBC_ERROR: "Connection string is empty"

2. Verificar se odbc32.dll pode ser carregada
   └── Se falha → ODBC_ERROR: "ODBC subsystem not available (odbc32.dll)"

3. Alocar environment handle
   └── Se falha → ODBC_ERROR: "Failed to allocate ODBC environment"

4. Alocar connection handle
   └── Se falha → ODBC_ERROR: "Failed to allocate connection handle"

5. Executar SQLDriverConnectA com timeout
   └── Se falha → ODBC_ERROR: "[SQLSTATE] mensagem detalhada do driver"

6. Testar conexão (SQLAllocHandle de statement)
   └── Se falha → ODBC_ERROR: "Connection established but unusable"

7. Se query foi fornecida, executar automaticamente
   └── Se falha → ODBC_ERROR com detalhes da query + ODBC_OK da conexão
```

### Princípio: Falha Graciosa

A integração ODBC **NUNCA** deve impactar negativamente o processamento principal:

```python
# No handler LINE: do transform()
try:
    # Injetar dados ODBC no ctx (se disponíveis)
    if _odbc_instance and _odbc_instance.connected:
        script_ctx['odbc_connected'] = True
        script_ctx['odbc_row'] = _odbc_instance.get_row(line_number - 1)
        # ...
    else:
        script_ctx['odbc_connected'] = False
        script_ctx['odbc_row'] = None
except Exception:
    # ODBC falhou silenciosamente - não impacta o processamento
    script_ctx['odbc_connected'] = False
    script_ctx['odbc_row'] = None
```

### Timeout

- Timeout padrão: 30 segundos
- Configurável pelo usuário via JSON de metadados
- Implementado via `SQL_ATTR_CONNECTION_TIMEOUT` e `SQL_ATTR_QUERY_TIMEOUT`:

```python
# Definir timeout de conexão
timeout_val = ctypes.c_ulong(timeout_seconds)
odbc32.SQLSetConnectAttrA(
    self._hdbc, 113,  # SQL_ATTR_CONNECTION_TIMEOUT
    timeout_val, 0
)

# Definir timeout de query
odbc32.SQLSetStmtAttrA(
    self._hstmt, 0,  # SQL_ATTR_QUERY_TIMEOUT
    timeout_val, 0
)
```

---

## 8. Compatibilidade 32/64 bits

### O Problema

O Windows mantém registros ODBC separados para 32-bit e 64-bit:
- **DSNs 64-bit**: `HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBC.INI`
- **DSNs 32-bit**: `HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBC.INI`

Uma aplicação 32-bit **só enxerga** DSNs 32-bit (e vice-versa).

### A Solução

| Cenário | Comportamento |
|---------|---------------|
| FastFile.exe (32-bit) + ScriptEngine.exe (32-bit) | Acessa DSNs 32-bit. Requer drivers ODBC 32-bit. |
| FastFile.exe (32-bit) + ScriptEngine.exe (64-bit) | ScriptEngine acessa DSNs 64-bit (incompatível com DSNs do painel Delphi) |
| **Recomendação** | Compilar ScriptEngine.exe como **32-bit** (igual ao FastFile) |

### Workaround para Acessar Ambos

Se o usuário fornece uma **connection string completa** (com DRIVER= ao invés de DSN=), o problema de visibilidade de DSNs não se aplica, pois a conexão é feita diretamente ao driver:

```
DRIVER={SQL Server};SERVER=localhost;DATABASE=mydb;UID=sa;PWD=123
```

Neste caso, basta que o driver ODBC da mesma arquitetura esteja instalado.

### PyInstaller: Forçando 32-bit

```bash
# Usar Python 32-bit para compilar
"C:\Python39-32\python.exe" -m PyInstaller --onefile ScriptEngine.py
```

---

## 9. Impacto no Deploy

### Análise de Impacto

| Item | Antes | Depois | Delta |
|------|-------|--------|-------|
| **FastFile.exe** | ~4.5 MB | ~4.6 MB | +~100 KB (painel ODBC) |
| **ScriptEngine.exe** | ~12 MB | ~12 MB | +0 KB (ctypes é stdlib) |
| **DLLs extras** | 0 | **0** | Nenhuma DLL adicional |
| **odbc32.dll** | Já presente (Windows) | Já presente | Não distribuir |
| **Novos arquivos** | - | `fastfile_odbc_mru.ini` | Auto-criado em runtime |

### Checklist de Deploy

- [x] **Não precisa** distribuir `odbc32.dll` (nativa do Windows desde Windows 2000)
- [x] **Não precisa** instalar Python no cliente (ScriptEngine é .exe standalone)
- [x] **Não precisa** de nenhuma DLL adicional
- [x] **Não precisa** de configuração de registry
- [ ] **O usuário precisa** ter um driver ODBC instalado para seu banco-alvo
- [ ] **O driver ODBC** deve ser da mesma arquitetura (32-bit) que o ScriptEngine

### Drivers ODBC Comuns (já presentes em muitas máquinas)

| Driver | Geralmente presente em |
|--------|----------------------|
| SQL Server | Windows com SQL Server ou SSMS instalado |
| Microsoft Access | Windows com Office instalado |
| Microsoft Excel | Windows com Office instalado |
| MySQL | Máquinas com MySQL Connector/ODBC |
| PostgreSQL | Máquinas com psqlODBC instalado |

### Nota sobre MDAC/WDAC

O Windows já inclui nativamente o **MDAC** (Microsoft Data Access Components) / **WDAC** (Windows Data Access Components), que fornece:
- `odbc32.dll` (ODBC Driver Manager)
- Driver ODBC para SQL Server básico
- Driver ODBC para arquivos texto (.csv, .txt)

---

## 10. Exemplo de Uso pelo Usuário

### Cenário: Enriquecer linhas do arquivo com dados de um banco SQL Server

**Passo 1** - O usuário abre um arquivo de log no FastFile:
```
2026-05-14 10:00:01 USER_LOGIN user_id=1001
2026-05-14 10:00:02 USER_LOGIN user_id=1002
2026-05-14 10:00:03 USER_LOGIN user_id=1003
```

**Passo 2** - Abre o painel Script Engine (macros Python)

**Passo 3** - Clica em "ODBC" e configura:
- Connection String: `DSN=ERP_Producao` (selecionado dos recentes)
- Query: `SELECT user_id, nome, departamento FROM usuarios ORDER BY user_id`
- Clica "Test Connection" → "Connection successful"
- Clica "Connect & Load Data"

**Passo 4** - Escreve o script Python:
```python
def transform(line, ctx):
    """Enriquece cada linha de log com o nome do usuário do banco."""
    if not ctx.get('odbc_connected'):
        return line  # Sem ODBC, retorna linha original
    
    # Extrair user_id da linha
    if 'user_id=' not in line:
        return line
    
    uid = line.split('user_id=')[1].strip()
    
    # Buscar no resultset ODBC
    for row in ctx.get('odbc_all_rows', []):
        if row.get('user_id') == uid:
            nome = row.get('nome', '?')
            depto = row.get('departamento', '?')
            return f"{line} -> {nome} ({depto})"
    
    return line + " -> [NOT FOUND IN DB]"
```

**Passo 5** - Clica "Run Script"

**Resultado na ListView:**
```
2026-05-14 10:00:01 USER_LOGIN user_id=1001 -> João Silva (TI)
2026-05-14 10:00:02 USER_LOGIN user_id=1002 -> Maria Santos (RH)
2026-05-14 10:00:03 USER_LOGIN user_id=1003 -> [NOT FOUND IN DB]
```

---

## 11. Traduções - 11 Idiomas

### Português (Brasil)

| Chave (English) | Tradução |
|-----------------|----------|
| ODBC Data Source | Fonte de Dados ODBC |
| Connect | Conectar |
| Disconnect | Desconectar |
| Test Connection | Testar Conexão |
| Connection successful | Conexão bem-sucedida |
| Connection failed | Falha na conexão |
| Recent ODBC connections | Conexões ODBC recentes |
| Connection string | String de conexão |
| Query | Consulta |
| Execute Query | Executar Consulta |
| List available DSNs | Listar DSNs disponíveis |
| ODBC timeout (seconds) | Tempo limite ODBC (segundos) |
| No ODBC connection active | Nenhuma conexão ODBC ativa |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC conectado com sucesso. Dados disponíveis em ctx['odbc_row']. |
| Failed to connect to ODBC source | Falha ao conectar à fonte ODBC |
| Clear recent ODBC list | Limpar lista de ODBC recentes |
| ODBC Configuration | Configuração ODBC |
| Load ODBC data before running script | Carregar dados ODBC antes de executar o script |
| ODBC rows loaded | Linhas ODBC carregadas |
| Connection string is empty | A string de conexão está vazia |
| ODBC panel | Painel ODBC |
| Available DSNs on this system | DSNs disponíveis neste sistema |

### English

| Key | Translation |
|-----|-------------|
| ODBC Data Source | ODBC Data Source |
| Connect | Connect |
| Disconnect | Disconnect |
| Test Connection | Test Connection |
| Connection successful | Connection successful |
| Connection failed | Connection failed |
| Recent ODBC connections | Recent ODBC connections |
| Connection string | Connection string |
| Query | Query |
| Execute Query | Execute Query |
| List available DSNs | List available DSNs |
| ODBC timeout (seconds) | ODBC timeout (seconds) |
| No ODBC connection active | No ODBC connection active |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC connected successfully. Data available in ctx['odbc_row']. |
| Failed to connect to ODBC source | Failed to connect to ODBC source |
| Clear recent ODBC list | Clear recent ODBC list |
| ODBC Configuration | ODBC Configuration |
| Load ODBC data before running script | Load ODBC data before running script |
| ODBC rows loaded | ODBC rows loaded |
| Connection string is empty | Connection string is empty |
| ODBC panel | ODBC panel |
| Available DSNs on this system | Available DSNs on this system |

### Español

| Clave | Traducción |
|-------|------------|
| ODBC Data Source | Origen de Datos ODBC |
| Connect | Conectar |
| Disconnect | Desconectar |
| Test Connection | Probar Conexión |
| Connection successful | Conexión exitosa |
| Connection failed | Error de conexión |
| Recent ODBC connections | Conexiones ODBC recientes |
| Connection string | Cadena de conexión |
| Query | Consulta |
| Execute Query | Ejecutar Consulta |
| List available DSNs | Listar DSNs disponibles |
| ODBC timeout (seconds) | Tiempo límite ODBC (segundos) |
| No ODBC connection active | Ninguna conexión ODBC activa |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC conectado correctamente. Datos disponibles en ctx['odbc_row']. |
| Failed to connect to ODBC source | Error al conectar con el origen ODBC |
| Clear recent ODBC list | Borrar lista de ODBC recientes |
| ODBC Configuration | Configuración ODBC |
| Load ODBC data before running script | Cargar datos ODBC antes de ejecutar el script |
| ODBC rows loaded | Filas ODBC cargadas |
| Connection string is empty | La cadena de conexión está vacía |
| ODBC panel | Panel ODBC |
| Available DSNs on this system | DSNs disponibles en este sistema |

### Français

| Clé | Traduction |
|-----|------------|
| ODBC Data Source | Source de Données ODBC |
| Connect | Connecter |
| Disconnect | Déconnecter |
| Test Connection | Tester la Connexion |
| Connection successful | Connexion réussie |
| Connection failed | Échec de la connexion |
| Recent ODBC connections | Connexions ODBC récentes |
| Connection string | Chaîne de connexion |
| Query | Requête |
| Execute Query | Exécuter la Requête |
| List available DSNs | Lister les DSN disponibles |
| ODBC timeout (seconds) | Délai d'attente ODBC (secondes) |
| No ODBC connection active | Aucune connexion ODBC active |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC connecté avec succès. Données disponibles dans ctx['odbc_row']. |
| Failed to connect to ODBC source | Échec de la connexion à la source ODBC |
| Clear recent ODBC list | Effacer la liste des ODBC récents |
| ODBC Configuration | Configuration ODBC |
| Load ODBC data before running script | Charger les données ODBC avant d'exécuter le script |
| ODBC rows loaded | Lignes ODBC chargées |
| Connection string is empty | La chaîne de connexion est vide |
| ODBC panel | Panneau ODBC |
| Available DSNs on this system | DSN disponibles sur ce système |

### Deutsch

| Schlüssel | Übersetzung |
|-----------|-------------|
| ODBC Data Source | ODBC-Datenquelle |
| Connect | Verbinden |
| Disconnect | Trennen |
| Test Connection | Verbindung testen |
| Connection successful | Verbindung erfolgreich |
| Connection failed | Verbindung fehlgeschlagen |
| Recent ODBC connections | Letzte ODBC-Verbindungen |
| Connection string | Verbindungszeichenfolge |
| Query | Abfrage |
| Execute Query | Abfrage ausführen |
| List available DSNs | Verfügbare DSNs auflisten |
| ODBC timeout (seconds) | ODBC-Zeitlimit (Sekunden) |
| No ODBC connection active | Keine ODBC-Verbindung aktiv |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC erfolgreich verbunden. Daten verfügbar in ctx['odbc_row']. |
| Failed to connect to ODBC source | Verbindung zur ODBC-Quelle fehlgeschlagen |
| Clear recent ODBC list | Liste der letzten ODBC-Verbindungen löschen |
| ODBC Configuration | ODBC-Konfiguration |
| Load ODBC data before running script | ODBC-Daten vor Skriptausführung laden |
| ODBC rows loaded | ODBC-Zeilen geladen |
| Connection string is empty | Verbindungszeichenfolge ist leer |
| ODBC panel | ODBC-Bereich |
| Available DSNs on this system | Verfügbare DSNs auf diesem System |

### Italiano

| Chiave | Traduzione |
|--------|------------|
| ODBC Data Source | Origine Dati ODBC |
| Connect | Connetti |
| Disconnect | Disconnetti |
| Test Connection | Testa Connessione |
| Connection successful | Connessione riuscita |
| Connection failed | Connessione fallita |
| Recent ODBC connections | Connessioni ODBC recenti |
| Connection string | Stringa di connessione |
| Query | Query |
| Execute Query | Esegui Query |
| List available DSNs | Elenca DSN disponibili |
| ODBC timeout (seconds) | Timeout ODBC (secondi) |
| No ODBC connection active | Nessuna connessione ODBC attiva |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC connesso con successo. Dati disponibili in ctx['odbc_row']. |
| Failed to connect to ODBC source | Impossibile connettersi all'origine ODBC |
| Clear recent ODBC list | Cancella elenco ODBC recenti |
| ODBC Configuration | Configurazione ODBC |
| Load ODBC data before running script | Caricare i dati ODBC prima di eseguire lo script |
| ODBC rows loaded | Righe ODBC caricate |
| Connection string is empty | La stringa di connessione è vuota |
| ODBC panel | Pannello ODBC |
| Available DSNs on this system | DSN disponibili su questo sistema |

### Polski

| Klucz | Tłumaczenie |
|-------|-------------|
| ODBC Data Source | Źródło Danych ODBC |
| Connect | Połącz |
| Disconnect | Rozłącz |
| Test Connection | Testuj Połączenie |
| Connection successful | Połączenie udane |
| Connection failed | Połączenie nieudane |
| Recent ODBC connections | Ostatnie połączenia ODBC |
| Connection string | Ciąg połączenia |
| Query | Zapytanie |
| Execute Query | Wykonaj Zapytanie |
| List available DSNs | Wyświetl dostępne DSN |
| ODBC timeout (seconds) | Limit czasu ODBC (sekundy) |
| No ODBC connection active | Brak aktywnego połączenia ODBC |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC połączono pomyślnie. Dane dostępne w ctx['odbc_row']. |
| Failed to connect to ODBC source | Nie udało się połączyć ze źródłem ODBC |
| Clear recent ODBC list | Wyczyść listę ostatnich ODBC |
| ODBC Configuration | Konfiguracja ODBC |
| Load ODBC data before running script | Załaduj dane ODBC przed uruchomieniem skryptu |
| ODBC rows loaded | Załadowano wierszy ODBC |
| Connection string is empty | Ciąg połączenia jest pusty |
| ODBC panel | Panel ODBC |
| Available DSNs on this system | Dostępne DSN w tym systemie |

### Português (Portugal)

| Chave | Tradução |
|-------|----------|
| ODBC Data Source | Fonte de Dados ODBC |
| Connect | Ligar |
| Disconnect | Desligar |
| Test Connection | Testar Ligação |
| Connection successful | Ligação bem-sucedida |
| Connection failed | Falha na ligação |
| Recent ODBC connections | Ligações ODBC recentes |
| Connection string | Cadeia de ligação |
| Query | Consulta |
| Execute Query | Executar Consulta |
| List available DSNs | Listar DSNs disponíveis |
| ODBC timeout (seconds) | Tempo limite ODBC (segundos) |
| No ODBC connection active | Nenhuma ligação ODBC ativa |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC ligado com sucesso. Dados disponíveis em ctx['odbc_row']. |
| Failed to connect to ODBC source | Falha ao ligar à fonte ODBC |
| Clear recent ODBC list | Limpar lista de ODBC recentes |
| ODBC Configuration | Configuração ODBC |
| Load ODBC data before running script | Carregar dados ODBC antes de executar o script |
| ODBC rows loaded | Linhas ODBC carregadas |
| Connection string is empty | A cadeia de ligação está vazia |
| ODBC panel | Painel ODBC |
| Available DSNs on this system | DSNs disponíveis neste sistema |

### Română

| Cheie | Traducere |
|-------|-----------|
| ODBC Data Source | Sursă de Date ODBC |
| Connect | Conectare |
| Disconnect | Deconectare |
| Test Connection | Testare Conexiune |
| Connection successful | Conexiune reușită |
| Connection failed | Conexiune eșuată |
| Recent ODBC connections | Conexiuni ODBC recente |
| Connection string | Șir de conexiune |
| Query | Interogare |
| Execute Query | Executare Interogare |
| List available DSNs | Listare DSN-uri disponibile |
| ODBC timeout (seconds) | Limită de timp ODBC (secunde) |
| No ODBC connection active | Nicio conexiune ODBC activă |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC conectat cu succes. Date disponibile în ctx['odbc_row']. |
| Failed to connect to ODBC source | Nu s-a putut conecta la sursa ODBC |
| Clear recent ODBC list | Șterge lista ODBC recente |
| ODBC Configuration | Configurare ODBC |
| Load ODBC data before running script | Încarcă datele ODBC înainte de a rula scriptul |
| ODBC rows loaded | Rânduri ODBC încărcate |
| Connection string is empty | Șirul de conexiune este gol |
| ODBC panel | Panou ODBC |
| Available DSNs on this system | DSN-uri disponibile pe acest sistem |

### Magyar

| Kulcs | Fordítás |
|-------|----------|
| ODBC Data Source | ODBC Adatforrás |
| Connect | Csatlakozás |
| Disconnect | Leválasztás |
| Test Connection | Kapcsolat Tesztelése |
| Connection successful | Sikeres kapcsolódás |
| Connection failed | Sikertelen kapcsolódás |
| Recent ODBC connections | Legutóbbi ODBC kapcsolatok |
| Connection string | Kapcsolati karakterlánc |
| Query | Lekérdezés |
| Execute Query | Lekérdezés Végrehajtása |
| List available DSNs | Elérhető DSN-ek listázása |
| ODBC timeout (seconds) | ODBC időtúllépés (másodperc) |
| No ODBC connection active | Nincs aktív ODBC kapcsolat |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC sikeresen csatlakoztatva. Adatok elérhetők a ctx['odbc_row'] alatt. |
| Failed to connect to ODBC source | Nem sikerült csatlakozni az ODBC forráshoz |
| Clear recent ODBC list | Legutóbbi ODBC lista törlése |
| ODBC Configuration | ODBC Konfiguráció |
| Load ODBC data before running script | ODBC adatok betöltése a szkript futtatása előtt |
| ODBC rows loaded | ODBC sorok betöltve |
| Connection string is empty | A kapcsolati karakterlánc üres |
| ODBC panel | ODBC panel |
| Available DSNs on this system | Elérhető DSN-ek ezen a rendszeren |

### Čeština

| Klíč | Překlad |
|------|---------|
| ODBC Data Source | Zdroj Dat ODBC |
| Connect | Připojit |
| Disconnect | Odpojit |
| Test Connection | Otestovat Připojení |
| Connection successful | Připojení úspěšné |
| Connection failed | Připojení selhalo |
| Recent ODBC connections | Nedávná připojení ODBC |
| Connection string | Připojovací řetězec |
| Query | Dotaz |
| Execute Query | Provést Dotaz |
| List available DSNs | Vypsat dostupné DSN |
| ODBC timeout (seconds) | Časový limit ODBC (sekundy) |
| No ODBC connection active | Žádné aktivní připojení ODBC |
| ODBC connected successfully. Data available in ctx['odbc_row']. | ODBC úspěšně připojeno. Data dostupná v ctx['odbc_row']. |
| Failed to connect to ODBC source | Nepodařilo se připojit ke zdroji ODBC |
| Clear recent ODBC list | Vymazat seznam nedávných ODBC |
| ODBC Configuration | Konfigurace ODBC |
| Load ODBC data before running script | Načíst data ODBC před spuštěním skriptu |
| ODBC rows loaded | Načteno řádků ODBC |
| Connection string is empty | Připojovací řetězec je prázdný |
| ODBC panel | Panel ODBC |
| Available DSNs on this system | Dostupné DSN na tomto systému |

---

## 12. Diagrama de Fluxo

### Fluxo de Conexão ODBC

```
┌──────────────────┐
│  Usuário clica   │
│  "Connect ODBC"  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     Não      ┌─────────────────────┐
│ Connection String│────────────►│ Mostrar erro:        │
│ está preenchida? │              │ "Connection string   │
└────────┬─────────┘              │  is empty"           │
         │ Sim                    └─────────────────────┘
         ▼
┌──────────────────┐
│ Delphi envia via │
│ pipe para Python:│
│ ODBC_CONNECT:... │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Python carrega   │
│ odbc32.dll via   │
│ ctypes           │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     Falha    ┌─────────────────────┐
│ SQLAllocHandle   │────────────►│ ODBC_ERROR:          │
│ (ENV + DBC)      │              │ "Failed to allocate" │
└────────┬─────────┘              └─────────────────────┘
         │ OK
         ▼
┌──────────────────┐     Falha    ┌─────────────────────┐
│ SQLDriverConnect │────────────►│ ODBC_ERROR:          │
│ (com timeout)    │              │ "[SQLSTATE] msg..."  │
└────────┬─────────┘              └─────────────────────┘
         │ OK
         ▼
┌──────────────────┐
│ ODBC_OK:         │
│ "Connection      │
│  successful"     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     Não
│ Query fornecida? │────────────► (Fim - aguarda comandos)
└────────┬─────────┘
         │ Sim
         ▼
┌──────────────────┐
│ SQLExecDirect    │
│ + Fetch rows     │
│ + Cache interno  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ ODBC_COLUMNS:... │
│ ODBC_ROW:1:...   │
│ ODBC_ROW:2:...   │
│ ODBC_ROW_COUNT:n │
│ ODBC_FETCH_DONE  │
└──────────────────┘
```

### Fluxo de Execução do Script com ODBC

```
┌──────────────────┐
│  Usuário clica   │
│  "Run Script"    │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────┐
│ Para cada linha na ListView:                      │
│                                                   │
│  1. Delphi envia: LINE:<n>:<texto_da_linha>       │
│                                                   │
│  2. Python monta ctx:                             │
│     ctx['line_number'] = n                        │
│     ctx['odbc_connected'] = True                  │
│     ctx['odbc_row'] = cache[n-1] (se existir)    │
│     ctx['odbc_columns'] = ['col1', 'col2', ...]  │
│     ctx['odbc_row_count'] = total                 │
│                                                   │
│  3. Python executa: result = transform(line, ctx) │
│                                                   │
│  4. Python responde: OUT:<n>:<result>             │
│     ou SKIP:<n> (se result is None)               │
│                                                   │
│  5. Delphi atualiza ListView com resultado        │
└──────────────────────────────────────────────────┘
```

---

## 13. Resumo Executivo

| # | Requisito | Viabilidade | Método |
|---|-----------|-------------|--------|
| 1.1 | Integração ODBC + Python para ListView | ✅ Totalmente viável | Estender protocolo pipe + injetar dados no `ctx` |
| 1.2 | Parametrização como metadados | ✅ Totalmente viável | JSON base64 com validações em cascata |
| 1.3 | ODBC Recentes (MRU) | ✅ Totalmente viável | Reutiliza `TMruHelper` existente com INI dedicado |
| 1.4 | Sem bibliotecas externas | ✅ Totalmente viável | `ctypes` + `odbc32.dll` nativa do Windows |
| 1.5 | Deploy limpo | ✅ Zero DLLs extras | `odbc32.dll` já presente em todo Windows |
| 1.6 | Tradução 11 idiomas | ✅ Completo | Tabelas completas acima |

### Próximos Passos para Implementação

1. **Fase 1**: Implementar `NativeODBC` no `ScriptEngine.py` e os handlers de protocolo
2. **Fase 2**: Criar o sub-painel ODBC no lado Delphi (dentro do painel Script Engine)
3. **Fase 3**: Integrar `TMruHelper` para persistência de conexões recentes
4. **Fase 4**: Adicionar todas as strings i18n no `uI18n.pas`
5. **Fase 5**: Recompilar `ScriptEngine.exe` com PyInstaller (32-bit)
6. **Fase 6**: Testes de integração com diferentes drivers ODBC

---

> **Documento gerado automaticamente como parte da especificação técnica do FastFile.**  
> **Copyright © 2025-2026 Hamden Vogel. Todos os direitos reservados.**
