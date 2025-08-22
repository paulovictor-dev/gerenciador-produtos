<!--#include file="db_connection.asp"-->
<%
Dim nome, email, senha
nome = Trim(Request.Form("nome"))
email = Trim(Request.Form("email"))
senha = Trim(Request.Form("senha"))

If nome <> "" And email <> "" And senha <> "" Then
    Dim cmd
    Set cmd = Server.CreateObject("ADODB.Command")
    cmd.ActiveConnection = conn
    cmd.CommandType = 1 ' adCmdText

    Dim objSHA256, objEncoding, bytes, hashSenha
    Set objSHA256 = CreateObject("System.Security.Cryptography.SHA256Managed")
    Set objEncoding = CreateObject("System.Text.UTF8Encoding")

    ' Converte a senha para bytes e gera hash
    bytes = objEncoding.GetBytes_4(senha)
    hashSenha = UCase(Replace(CStr(objSHA256.ComputeHash_2((bytes))), "-", ""))

    ' Fecha objetos de hash
    Set objSHA256 = Nothing
    Set objEncoding = Nothing

    cmd.CommandText = "INSERT INTO Usuarios (Nome, Email, Senha) VALUES (?, ?, ?)"
    cmd.Parameters.Append cmd.CreateParameter("Nome", 200, 1, 255, nome)
    cmd.Parameters.Append cmd.CreateParameter("Email", 200, 1, 255, email)
    cmd.Parameters.Append cmd.CreateParameter("Senha", 200, 1, 40, hashSenha)

    On Error Resume Next
    cmd.Execute
    If Err.Number = 0 Then
        Response.Write "{""status"":""sucesso"",""mensagem"":""Usuário registrado com sucesso!""}"
    Else
        Response.Write "{""status"":""erro"",""mensagem"":""Erro ao registrar usuário: " & Err.Description & """}"
    End If
    On Error GoTo 0

    Set cmd = Nothing
Else
    Response.Write "{""status"":""erro"",""mensagem"":""Todos os campos são obrigatórios!""}"
End If

If Not conn Is Nothing Then
    If conn.State = 1 Then conn.Close
    Set conn = Nothing
End If
%>
