<%
Response.ContentType = "application/json"
If Session("usuarioNome") = "" Then
    Response.Write "{""logado"":false}"
Else
    Response.Write "{""logado"":true,""usuario"":""" & Session("usuarioNome") & """}"
End If
%>