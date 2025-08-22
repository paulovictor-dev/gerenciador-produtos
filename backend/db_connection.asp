<%
Dim conn
Set conn = Server.CreateObject("ADODB.Connection")

' conexao sql server
conn.Open "Provider=SQLOLEDB;" & _
          "Data Source=localhost;" & _
          "Initial Catalog=ProdutosDB;" & _
          "User ID=userDoBanco;" & _
          "Password=senhaDoBanco"

Dim appUser
appUser = Session("usuarioNome") 

If appUser <> "" Then
    Dim cmdCtx
    Set cmdCtx = Server.CreateObject("ADODB.Command")
    Set cmdCtx.ActiveConnection = conn
    cmdCtx.CommandType = 4 
    cmdCtx.CommandText = "sys.sp_set_session_context"
    
    cmdCtx.Parameters.Append cmdCtx.CreateParameter("@key",   200, 1, 128, "AppUser")
    cmdCtx.Parameters.Append cmdCtx.CreateParameter("@value", 200, 1, 256, appUser)

    cmdCtx.Execute
    Set cmdCtx = Nothing
End If
' Response.Write("conexao com sql server ok")

%>
