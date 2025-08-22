<!--#include file="db_connection.asp"-->
<!--#include file="utils/auth.asp"-->
<%
Response.ContentType = "application/json"

Dim email, senha
email = Trim(Request.Form("email"))
senha = Trim(Request.Form("senha"))

If email = "" Or senha = "" Then
    Response.Write "{""status"":""erro"",""mensagem"":""Todos os campos são obrigatórios!""}"
    Response.End
End If

' ===== Hash SHA256 (igual registro.asp) =====
Dim objSHA256, objEncoding, bytes, hashSenha
Set objSHA256 = CreateObject("System.Security.Cryptography.SHA256Managed")
Set objEncoding = CreateObject("System.Text.UTF8Encoding")

bytes = objEncoding.GetBytes_4(senha)
hashSenha = UCase(Replace(CStr(objSHA256.ComputeHash_2((bytes))), "-", ""))

Set objSHA256 = Nothing
Set objEncoding = Nothing

' ===== Consulta e validação =====
Dim cmd, rs
Set cmd = Server.CreateObject("ADODB.Command")
cmd.ActiveConnection = conn
cmd.CommandType = 1 ' adCmdText
cmd.CommandText = "SELECT Id, Nome FROM Usuarios WHERE Email=? AND Senha=?"
cmd.Parameters.Append cmd.CreateParameter("Email", 200, 1, 255, email) ' adVarChar
cmd.Parameters.Append cmd.CreateParameter("Senha", 200, 1, 64, hashSenha) ' 64 chars do SHA256

On Error Resume Next
Set rs = cmd.Execute
If Err.Number <> 0 Then
    Response.Write "{""status"":""erro"",""mensagem"":""Falha ao consultar o banco: " & Replace(Err.Description, """", "'") & """}"
    On Error GoTo 0
    ' limpeza
    If Not rs Is Nothing Then If rs.State = 1 Then rs.Close
    Set rs = Nothing
    Set cmd = Nothing
    If Not conn Is Nothing Then If conn.State = 1 Then conn.Close : Set conn = Nothing
    Response.End
End If
On Error GoTo 0

If Not rs.EOF Then
    ' ===== Grava sessão =====
    Session("usuarioId") = rs("Id")
    Session("usuarioEmail") = email
    Session("usuarioNome") = rs("Nome")

    Response.Write "{""status"":""sucesso"",""mensagem"":""Login realizado com sucesso!"",""usuario"":""" & rs("Nome") & """}"

    ' encerra aqui para não executar mais nada
    ' limpeza antes de encerrar (defensiva)
    If Not rs Is Nothing Then If rs.State = 1 Then rs.Close
    Set rs = Nothing
    Set cmd = Nothing
    If Not conn Is Nothing Then If conn.State = 1 Then conn.Close : Set conn = Nothing
    Response.End
Else
    Response.Write "{""status"":""erro"",""mensagem"":""Email ou senha inválidos!""}"

    ' limpeza
    If Not rs Is Nothing Then If rs.State = 1 Then rs.Close
    Set rs = Nothing
    Set cmd = Nothing
    If Not conn Is Nothing Then If conn.State = 1 Then conn.Close : Set conn = Nothing
    Response.End
End If

Dim token : token = GerarToken()

sql = "INSERT INTO Tokens (UsuarioId, Token, ExpiraEm) VALUES (?, ?, DATEADD(hour, 8, SYSUTCDATETIME()))"
cmd.CommandText = sql
cmd.CommandType = 1
cmd.Parameters.Append cmd.CreateParameter("@UsuarioId", 3, 1, , usuarioId)
cmd.Parameters.Append cmd.CreateParameter("@Token", 200, 1, 200, token)
cmd.Execute

Response.Write "{""status"":""sucesso"",""token"":""" & token & """}"
%>
