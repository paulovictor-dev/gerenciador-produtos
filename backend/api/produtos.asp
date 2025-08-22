<!--#include virtual="/GerenciadorProdutos/backend/db_connection.asp"-->
<!--#include virtual="GerenciadorProdutos/backend/utils/auth.asp"-->
<%
Response.ContentType = "application/json"

' --- Autenticação por sessão ---
If IsEmpty(Session("usuarioId")) Or Session("usuarioId") = "" Then
    Response.Write "{""status"":""erro"",""mensagem"":""Usuário não autenticado""}"
    Response.End
End If

' --- Entrada via x-www-form-urlencoded ---
Dim acao, id, nome, preco
acao = LCase(Trim(Request("acao")))
If acao = "" Then acao = LCase(Trim(Request("action")))

id = Trim(Request("id"))
nome = Trim(Request("nome"))
preco = Trim(Request("preco"))

nomeProd = Trim(Request("nomeProd"))
precoMin = Trim(Request("min"))
precoMax = Trim(Request("max"))

If acao = "" Then
    Response.Write "{""status"":""erro"",""mensagem"":""Ação não informada""}"
    Response.End
End If

Dim cmd, rs, sql
Set cmd = Server.CreateObject("ADODB.Command")
cmd.ActiveConnection = conn
cmd.CommandType = 1 ' adCmdText

On Error Resume Next

Select Case acao

    Case "create"
        If nome = "" Or preco = "" Then
            Response.Write "{""status"":""erro"",""mensagem"":""Campos obrigatórios: nome, preco""}"
        Else
            If InStr(preco, ".") > 0 Then
                preco = Replace(preco, ".", ",")
            End If
            preco = CDbl(preco)

            cmd.CommandType = 4
            cmd.CommandText = "dbo.PS_CriarProdutos"
            ' @Nome
            cmd.Parameters.Append cmd.CreateParameter("@Nome", 200, 1, 255, nome) ' adVarChar
            ' @Preco (DECIMAL 10,2)
            cmd.Parameters.Append cmd.CreateParameter("@Preco", 5, 1, , preco)

            Set rs = cmd.Execute
            If Err.Number = 0 Then
                Response.Write "{""status"":""sucesso"",""mensagem"":""Produto criado com sucesso""}"
            Else
                Response.Write "{""status"":""erro"",""mensagem"":""Erro ao criar (proc): " & Replace(Err.Description, """", "'") & """}"
            End If
        End If


    Case "read"
        cmd.CommandType = 4 
        cmd.CommandText = "dbo.PS_ConsultarProdutos"
        If id <> "" Then
            cmd.Parameters.Append cmd.CreateParameter("@Id", 3, 1, , CLng(id))
        Else
            cmd.Parameters.Append cmd.CreateParameter("@Id", 3, 1, , Null)
        End If        

        If nomeProd = "" Then
            cmd.Parameters.Append cmd.CreateParameter("@Nome", 200, 1, 255, Null)
        Else
            cmd.Parameters.Append cmd.CreateParameter("@Nome", 200, 1, 255, nomeProd)
        End If
        
        cmd.Parameters.Append cmd.CreateParameter("@PrecoMin", 131, 1)
        cmd.Parameters("@PrecoMin").Precision = 10
        cmd.Parameters("@PrecoMin").NumericScale = 2
        If precoMin <> "" Then
            cmd.Parameters("@PrecoMin").Value = CDbl(Replace(precoMin, ".", ","))
        Else
            cmd.Parameters("@PrecoMin").Value = Null
        End If

        cmd.Parameters.Append cmd.CreateParameter("@PrecoMax", 131, 1)
        cmd.Parameters("@PrecoMax").Precision = 10
        cmd.Parameters("@PrecoMax").NumericScale = 2
        If precoMax <> "" Then
            cmd.Parameters("@PrecoMax").Value = CDbl(Replace(precoMax, ".", ","))
        Else
            cmd.Parameters("@PrecoMax").Value = Null
        End If
                
        cmd.Parameters.Append cmd.CreateParameter("@Pagina", 3, 1, , 1)
        cmd.Parameters.Append cmd.CreateParameter("@Tamanho", 3, 1, , 1000)

        Set rs = cmd.Execute
        If Err.Number <> 0 Then
            Response.Write "{""status"":""erro"",""mensagem"":""Erro ao consultar: " & Replace(Err.Description, """", "'") & """}"
        Else
            Dim json, first
            json = "["
            first = True

            If id = "" Then
                If Not rs Is Nothing Then
                    ' (se quiser ler o total, leia aqui)
                    Set rs = rs.NextRecordset()
                End If
            End If

            If Not rs Is Nothing Then
                Do While Not rs.EOF
                    If Not first Then
                        json = json & ","
                    Else
                        first = False
                    End If

                    Dim precoOut, nomeOut
                    precoOut = Replace(CStr(rs("Preco")), ",", ".")
                    nomeOut  = Replace(CStr(rs("Nome")), """", "\""")

                    json = json & "{""id"":" & rs("Id") & ",""nome"":""" & nomeOut & """,""preco"":" & precoOut & "}"
                    rs.MoveNext
                Loop
            End If

            json = json & "]"
            Response.Write json
        End If

        If Not rs Is Nothing Then If rs.State = 1 Then rs.Close
        Set rs = Nothing

    Case "update"
        If id = "" Or nome = "" Or preco = "" Then
            Response.Write "{""status"":""erro"",""mensagem"":""Campos obrigatórios: nome, preco""}"
        Else

            If InStr(preco, ".") > 0 Then
                preco = Replace(preco, ".", ",")
            End If
            preco = CDbl(preco)

            cmd.CommandType = 4
            cmd.CommandText = "dbo.PS_AlterarProdutos"
            cmd.Parameters.Append cmd.CreateParameter("@Id", 3, 1, , CLng(id))
            cmd.Parameters.Append cmd.CreateParameter("@Nome", 200, 1, 255, nome)
            cmd.Parameters.Append cmd.CreateParameter("@Preco", 5, 1, , preco)
            cmd.Execute
            If Err.Number = 0 Then
                Response.Write "{""status"":""sucesso"",""mensagem"":""Produto atualizado com sucesso""}"
            Else
                Response.Write "Valores recebidos → Nome: " & nome & " | Id: " & id & " | Preco: " & preco
                Response.Write "{""status"":""erro"",""mensagem"":""Erro ao atualizar: " & Replace(Err.Description, """", "'") & """}"
            End If
        End If


    Case "delete"
        If id = "" Then
            Response.Write "{""status"":""erro"",""mensagem"":""Campo obrigatório: id""}"
        Else
            cmd.CommandType = 4
            cmd.CommandText = "dbo.PS_ExcluirProdutos"
            cmd.Parameters.Append cmd.CreateParameter("Id", 3, 1, , CLng(id))
            cmd.Execute
            If Err.Number = 0 Then
                Response.Write "{""status"":""sucesso"",""mensagem"":""Produto excluído com sucesso""}"
            Else
                Response.Write "{""status"":""erro"",""mensagem"":""Erro ao excluir: " & Replace(Err.Description, """", "'") & """}"
            End If
        End If

    Case "external_list"
        Dim token : token = GetBearerToken()
        If token = "" Or Not TokenValido(conn, token) Then
            Response.Status = "401 Unauthorized"
            Response.Write "{""status"":""erro"",""mensagem"":""Token inválido""}"
            Response.End
        End If

        ' --- Se chegou aqui, token é válido ---
        Set cmd = Server.CreateObject("ADODB.Command")
        Set cmd.ActiveConnection = conn
        cmd.CommandType = 4 ' adCmdStoredProc
        cmd.CommandText = "dbo.PS_ConsultarProdutos"

        Set rs = cmd.Execute

        If Not rs Is Nothing Then
            If rs.Fields.Count = 1 Then
                Dim f0 : f0 = LCase(rs.Fields(0).Name)
                If f0 = "total" Then
                    Set rs = rs.NextRecordset()
                End If
            End If
        End If
        
        Dim jsonExt
        jsonExt = "["

        Do Until rs.EOF
            jsonExt = jsonExt & "{""id"":" & rs("Id") & _
                    ",""nome"":""" & rs("Nome") & """,""preco"":" & Replace(CStr(rs("Preco")), ",", ".") & "},"
            rs.MoveNext
        Loop
        If Right(jsonExt,1) = "," Then jsonExt = Left(jsonExt, Len(jsonExt)-1)
        jsonExt = jsonExt & "]"

        Response.Write "{""status"":""sucesso"",""produtos"":" & jsonExt & "}"
        rs.Close : Set rs = Nothing : Set cmd = Nothing
    
    Case "external_create"
        Dim token2 : token2 = GetBearerToken()
        If token2 = "" Or Not TokenValido(conn, token2) Then
            Response.Status = "401 Unauthorized"
            Response.Write "{""status"":""erro"",""mensagem"":""Token inválido ou ausente""}"
            Response.End
        End If

        ' --- Se chegou aqui, token é válido ---
        If nome = "" Or preco = "" Then
            Response.Write "{""status"":""erro"",""mensagem"":""Campos obrigatórios: nome, preco""}"
        Else
            If InStr(preco, ".") > 0 Then
                preco = Replace(preco, ".", ",")
            End If
            preco = CDbl(preco)

            Set cmd = Server.CreateObject("ADODB.Command")
            Set cmd.ActiveConnection = conn
            cmd.CommandType = 4 ' adCmdStoredProc
            cmd.CommandText = "dbo.PS_CriarProdutos"
            cmd.Parameters.Append cmd.CreateParameter("@Nome", 200, 1, 255, nome)
            cmd.Parameters.Append cmd.CreateParameter("@Preco", 5, 1, , preco)

            cmd.Execute
            If Err.Number = 0 Then
                Response.Write "{""status"":""sucesso"",""mensagem"":""Produto criado com sucesso via API externa""}"
            Else
                Response.Write "{""status"":""erro"",""mensagem"":""Erro ao criar produto externo: " & Replace(Err.Description, """", "'") & """}"
            End If

            Set cmd = Nothing

        End If
    Case "external_token"
        Dim userId, userNome
        userId = Session("usuarioId") 
        userNome = Session("usuarioNome")

        If IsEmpty(userId) Or userId = "" Then
            Response.Status = "401 Unauthorized"
            Response.Write "{""status"":""erro"",""mensagem"":""Não logado""}"
            Response.End
        End If

        Dim tokenNovo
        tokenNovo = GerarToken()

        Set cmd = Server.CreateObject("ADODB.Command")
        Set cmd.ActiveConnection = conn
        cmd.CommandType = 1 
        cmd.CommandText = "INSERT INTO dbo.Tokens (UsuarioId, Token, ExpiraEm) VALUES (?, ?, DATEADD(HOUR, 12, SYSUTCDATETIME()))"
        cmd.Parameters.Append cmd.CreateParameter("", 3,   1,    , CLng(userId))   
        cmd.Parameters.Append cmd.CreateParameter("", 200, 1, 200, tokenNovo)      
        cmd.Execute
        Set cmd = Nothing

        Response.Clear
        Response.Buffer = True
        Response.CodePage = 65001
        Response.Charset = "utf-8"
        Response.ContentType = "application/json; charset=utf-8"

        Dim safeToken, payload
        safeToken = CStr(tokenNovo)
        safeToken = Replace(safeToken, "{", "")
        safeToken = Replace(safeToken, "}", "")
        safeToken = Replace(safeToken, """", "")
        safeToken = Replace(safeToken, vbCrLf, "")
        safeToken = Replace(safeToken, vbCr, "")
        safeToken = Replace(safeToken, vbLf, "")
        safeToken = Trim(safeToken)
        If Len(safeToken) > 36 Then safeToken = Left(safeToken, 36) ' GUID tem 36

        payload = "{""status"":""sucesso"",""token"":""" & safeToken & """,""expiraEmHoras"":12}"

        'estava tendo o seguinte erro no console: Parse do external_token falhou. Resposta crua: {"status":"sucesso","token":"EB120DD6-3668-4C93-9235-1044CA30E709 SyntaxError: Unterminated string in JSON at position 65
        'tentei várias formas e precisei escrever em binário pra evitar qualquer truncamento de string
        Dim stm, bytes
        Set stm = Server.CreateObject("ADODB.Stream")
        stm.Type = 2                ' texto
        stm.Charset = "utf-8"
        stm.Open
        stm.WriteText payload
        stm.Position = 0
        stm.Type = 1                ' binário
        bytes = stm.Read
        stm.Close
        Set stm = Nothing

        Response.BinaryWrite bytes
        Response.Flush
        Response.End        
    Case "history"
        cmd.CommandType = 1
        cmd.CommandText = "SELECT TOP 100 ProdutoId, Operacao, nomeAntigo, precoAntigo, nomeNovo, precoNovo, usuarioLogin, dataLog FROM ProdutosLog ORDER BY dataLog DESC"

        Set rs = cmd.Execute

        Dim jsonHist, firstHist
        jsonHist = "["
        firstHist = True
        Do While Not rs.EOF
            ' If Not firstHist Then jsonHist = jsonHist & "," Else firstHist = False
            If firstHist Then
                firstHist = False
            End If

            jsonHist = jsonHist & "{""produtoId"":" & rs("ProdutoId") & _
                                ",""operacao"":""" & rs("Operacao") & """" & _
                                ",""nomeAntigo"":""" & Replace(CStr(rs("nomeAntigo")),"""","\""") & """" & _
                                ",""precoAntigo"":""" & Replace(CStr(rs("precoAntigo")),"""","\""") & """" & _
                                ",""nomeNovo"":""" & Replace(CStr(rs("nomeNovo")),"""","\""") & """" & _
                                ",""precoNovo"":""" & Replace(CStr(rs("precoNovo")),"""","\""") & """" & _
                                ",""usuarioLogin"":""" & Replace(CStr(rs("usuarioLogin")),"""","\""") & """" & _
                                ",""dataLog"":""" & Replace(CStr(rs("dataLog")),"""","\""") & """},"
            rs.MoveNext
        Loop
        If Right(jsonHist,1) = "," Then
            jsonHist = Left(jsonHist, Len(jsonHist)-1)
        End If
        jsonHist = jsonHist & "]"
        Response.Write jsonHist

    Case Else
        Response.Write "{""status"":""erro"",""mensagem"":""Ação inválida!""}"
End Select

On Error GoTo 0
Set cmd = Nothing
If Not conn Is Nothing Then If conn.State = 1 Then conn.Close : Set conn = Nothing
%>
