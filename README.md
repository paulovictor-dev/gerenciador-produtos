# Gerenciador de Produtos (ASP Clássico + SQL Server + Bootstrap)

Aplicação web para gerenciar produtos com autenticação, CRUD completo, logs por trigger e APIs externas com Bearer token.

## Stack
- **Backend:** ASP Clássico (IIS), ADO
- **DB:** SQL Server
- **Frontend:** HTML + Bootstrap
- **APIs externas:** Bearer token (Tokens em tabela + função `fn_ValidarToken`)

---

## 1) Pré-requisitos
- Windows com **IIS** e **ASP** habilitados (Windows Features → Internet Information Services → World Wide Web Services → Application Development → ASP).
- SQL Server 2016+ (usa `SESSION_CONTEXT` e `DATETIME2`).

## 2) Setup do Banco
- Execute `docs/database.sql` no seu SQL Server (cria tabelas, procs, triggers, função e seeds).
- Ajuste a **connection string** em `backend/db_connection.asp`.

## 3) Configuração do Backend
- `backend/db_connection.asp`: abre a conexão e seta `SESSION_CONTEXT('AppUser')` com `Session("usuarioNome")` (usado nas triggers de log).
- `backend/login.asp` / `backend/registro.asp`: implementam autenticação básica e criam a sessão.
- `backend/api/produtos.asp`: expõe as rotas:
  - `action=read|create|update|delete|history` (internas; usam sessão)
  - `action=external_token` (gera token por 12h)
  - `action=external_list` / `action=external_create` (requerem `Authorization: Bearer <token>` ou query `?token=...`)

**Headers padrão recomendados nos ASPs de API:**
```asp
Response.CodePage = 65001
Response.Charset = "utf-8"
Response.ContentType = "application/json; charset=utf-8"
