<%
Function GerarToken()
  Randomize
  GerarToken = Replace(CreateObject("Scriptlet.TypeLib").Guid, "{", "")
  GerarToken = Replace(GerarToken, "}", "")
End Function

' Function GetBearerToken()
'   Dim auth, parts
'   auth = Request.ServerVariables("HTTP_AUTHORIZATION")
'   If auth = "" Then auth = Request.ServerVariables("HTTP_AUTHENTICATION")
'   If auth <> "" Then
'     parts = Split(auth, " ")
'     If UBound(parts) = 1 And LCase(parts(0)) = "bearer" Then
'       GetBearerToken = parts(1)
'       Exit Function
'     End If
'   End If
'   GetBearerToken = ""
' End Function

Function GetBearerToken()
  Dim auth, parts, t

  t = Trim(Request.QueryString("token"))
  If t <> "" Then GetBearerToken = t : Exit Function
  t = Trim(Request.Form("token"))
  If t <> "" Then GetBearerToken = t : Exit Function

  auth = Request.ServerVariables("HTTP_AUTHORIZATION")
  If auth = "" Then auth = Request.ServerVariables("Authorization")
  If auth = "" Then auth = Request.ServerVariables("HTTP_X_ORIGINAL_AUTHORIZATION")
  If auth = "" Then auth = Request.ServerVariables("HTTP_AUTHENTICATION")

  If auth <> "" Then
    parts = Split(auth, " ")
    If UBound(parts) = 1 And LCase(parts(0)) = "bearer" Then
      GetBearerToken = parts(1)
      Exit Function
    End If
  End If

  GetBearerToken = ""
End Function

Function TokenValido(conn, token)
  Dim rs, cmd, ok
  Set cmd = Server.CreateObject("ADODB.Command")
  Set cmd.ActiveConnection = conn
  cmd.CommandType = 1 ' adCmdText
  cmd.CommandText = "SELECT CAST(dbo.fn_ValidarToken(?) AS INT) AS Ok"
  cmd.Parameters.Append cmd.CreateParameter("", 202, 1, 200, token) ' 202 = adVarWChar (NVARCHAR)

  Set rs = cmd.Execute
  If Not rs.EOF Then
    ok = rs("Ok")
    TokenValido = (Not IsNull(ok) And CInt(ok) <> 0)
  Else
    TokenValido = False
  End If

  rs.Close : Set rs = Nothing : Set cmd = Nothing
End Function
%>