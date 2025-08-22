const API_PRODUTOS = "/GerenciadorProdutos/backend/api/produtos.asp";
// crud interno
function apiConsultarProdutos(params = {}) {
  return $.ajax({
    url: API_PRODUTOS,
    method: "GET",
    data: Object.assign({ action: "read" }, params),
    dataType: "json",
  }).fail(function(xhr){
    console.error("apiConsultarProdutos FAIL:", {
      status: xhr.status,
      statusText: xhr.statusText,
      url: xhr.responseURL || (API_PRODUTOS + "?action=read"),
      responseText: xhr.responseText
    });
  });
}
function apiCriarProdutos(data) {
  return $.ajax({ url: API_PRODUTOS + "?action=create", method: "POST", data, dataType: "json" });
}
function apiAlterarProdutos(data) {
  return $.ajax({ url: API_PRODUTOS + "?action=update", method: "POST", data, dataType: "json" });
}
function apiExcluirProdutos(id) {
  return $.ajax({ url: API_PRODUTOS, method: "POST", data: { action: "delete", id }, dataType: "json" });
}

// rotas externas (bearer)
function apiExternalList(token) {
  return $.ajax({
    url: API_PRODUTOS + "?action=external_list",
    method: "GET",
    dataType: "json",
    beforeSend: (xhr) => xhr.setRequestHeader("Authorization", "Bearer " + token)
  });
}
function apiExternalCreate(token, data) {
  return $.ajax({
    url: API_PRODUTOS + "?action=external_create",
    method: "POST",
    dataType: "json",
    data,
    beforeSend: (xhr) => xhr.setRequestHeader("Authorization", "Bearer " + token)
  });
}

function apiConsultarHistorico() {
  return $.ajax({
    url: API_PRODUTOS,
    method: "GET",
    data: { action: "history" },
    dataType: "text" // <- em vez de "json"
  }).then(function (txt) {
    try {
      return JSON.parse(txt);  // parse manual tolera Content-Type/BOM/etc.
    } catch (e) {
      console.error("Parse do histórico falhou. Resposta crua:", txt);
      throw e;
    }
  }).fail(function(xhr){
    console.error("apiConsultarHistorico FAIL:", {
      status: xhr.status,
      statusText: xhr.statusText,
      url: xhr.responseURL || (API_PRODUTOS + "?action=history"),
      responseText: xhr.responseText
    });
  });
}

