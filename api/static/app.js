// Front-end do Painel Burnout: consome a API REST em /api.

const API = "/api";

const CAMPOS = {
  id_colaborador:       { inteiro: true, min: 1000, max: 9999 },
  departamento:         { lista: true },
  horas_extras:         { min: 0, max: 100 },
  horas_trabalhadas:    { min: 0, max: 24 },
  tickets_fora_horario: { inteiro: true, min: 0, max: 100 },
  nivel_clima:          { inteiro: true, min: 1, max: 10 },
};

const $ = (sel) => document.querySelector(sel);
const form = $("#form-registro");
let editandoId = null;

// ------------------------------------------------------------ chamadas HTTP

class ErroApi extends Error {
  constructor(status, corpo) {
    super(corpo?.detail || `Erro ${status}`);
    this.status = status;
    this.erros = corpo?.erros || {};
  }
}

async function api(caminho, opcoes = {}) {
  let resp;
  try {
    resp = await fetch(API + caminho, {
      headers: { "Content-Type": "application/json" },
      ...opcoes,
      body: opcoes.body ? JSON.stringify(opcoes.body) : undefined,
    });
  } catch {
    throw new ErroApi(0, { detail: "Sem conexão com a API. Ela está rodando?" });
  }
  if (resp.status === 204) return null;
  const corpo = await resp.json().catch(() => null);
  if (!resp.ok) throw new ErroApi(resp.status, corpo);
  return corpo;
}

// ------------------------------------------------------------ avisos

let temporizador;
function avisar(texto, tipo = "ok") {
  const el = $("#aviso");
  el.textContent = texto;
  el.className = "visivel" + (tipo === "erro" ? " erro-aviso" : "");
  clearTimeout(temporizador);
  temporizador = setTimeout(() => (el.className = ""), 3500);
}

// ------------------------------------------------------------ validacao

function limparErros(raiz = document) {
  raiz.querySelectorAll(".erro").forEach((e) => (e.textContent = ""));
  raiz.querySelectorAll(".invalido").forEach((e) => e.classList.remove("invalido"));
}

function mostrarErros(erros) {
  for (const [campo, msg] of Object.entries(erros)) {
    const alvo = document.querySelector(`[data-erro="${campo}"]`);
    if (alvo) alvo.textContent = msg;
    document.getElementById(campo)?.classList.add("invalido");
  }
}

function validarRegistro() {
  const dados = {};
  const erros = {};
  for (const [campo, regra] of Object.entries(CAMPOS)) {
    const bruto = form.elements[campo].value.trim();
    if (bruto === "") { erros[campo] = "Campo obrigatório."; continue; }
    if (regra.lista) { dados[campo] = bruto; continue; }
    const n = Number(bruto);
    if (!Number.isFinite(n)) erros[campo] = "Informe um número.";
    else if (regra.inteiro && !Number.isInteger(n)) erros[campo] = "Informe um número inteiro.";
    else if (n < regra.min) erros[campo] = `Deve ser maior ou igual a ${regra.min}.`;
    else if (n > regra.max) erros[campo] = `Deve ser menor ou igual a ${regra.max}.`;
    else dados[campo] = n;
  }
  return { dados, erros };
}

// ------------------------------------------------------------ renderizacao

function celula(texto, classe) {
  const td = document.createElement("td");
  td.textContent = texto;
  if (classe) td.className = classe;
  return td;
}

function botao(texto, classe, acao) {
  const b = document.createElement("button");
  b.type = "button";
  b.className = classe;
  b.textContent = texto;
  b.addEventListener("click", acao);
  return b;
}

function linhaVazia(corpo, colunas, texto) {
  corpo.replaceChildren();
  const tr = document.createElement("tr");
  const td = celula(texto, "vazio");
  td.colSpan = colunas;
  tr.append(td);
  corpo.append(tr);
}

function renderizarRegistros(registros) {
  const corpo = $("#tabela-registros");
  if (!registros.length) return linhaVazia(corpo, 9, "Nenhum registro. Cadastre um ou use o simulador.");
  corpo.replaceChildren(...registros.map((r) => {
    const tr = document.createElement("tr");
    if (r.id_registro === editandoId) tr.className = "editando";
    const acoes = document.createElement("td");
    acoes.append(
      botao("Editar", "link", () => iniciarEdicao(r)),
      botao("Excluir", "link perigo", () => excluir(r)),
    );
    tr.append(
      celula(r.id_colaborador, "num"),
      celula(r.departamento),
      celula(r.horas_extras.toFixed(1), "num"),
      celula(r.horas_trabalhadas.toFixed(1), "num"),
      celula(r.tickets_fora_horario, "num"),
      celula(r.nivel_clima, "num"),
      celula(r.risco_burnout === "medio" ? "médio" : r.risco_burnout, `risco ${r.risco_burnout}`),
      celula(r.data_hora_geracao.replace("T", " ")),
      acoes,
    );
    return tr;
  }));
}

function renderizarIndicadores(ind) {
  $("#ind-total").textContent = ind.total;
  $("#ind-alto").textContent = ind.por_risco.alto;
  $("#ind-medio").textContent = ind.por_risco.medio;
  $("#ind-baixo").textContent = ind.por_risco.baixo;

  const corpo = $("#tabela-departamentos");
  if (!ind.por_departamento.length) return linhaVazia(corpo, 5, "Sem dados.");
  corpo.replaceChildren(...ind.por_departamento.map((d) => {
    const tr = document.createElement("tr");
    tr.append(
      celula(d.departamento),
      celula(d.total, "num"),
      celula(d.media_horas_extras.toFixed(1), "num"),
      celula(d.media_clima.toFixed(1), "num"),
      celula(d.alto, "num risco alto"),
    );
    return tr;
  }));
}

// ------------------------------------------------------------ operacoes

async function atualizarTela() {
  const params = new URLSearchParams();
  const depto = $("#filtro-departamento").value;
  const risco = $("#filtro-risco").value;
  if (depto) params.set("departamento", depto);
  if (risco) params.set("risco", risco);
  try {
    const [registros, ind] = await Promise.all([
      api(`/registros?${params}`),
      api("/indicadores"),
    ]);
    renderizarRegistros(registros);
    renderizarIndicadores(ind);
  } catch (e) {
    linhaVazia($("#tabela-registros"), 9, e.message);
    avisar(e.message, "erro");
  }
}

function iniciarEdicao(r) {
  editandoId = r.id_registro;
  for (const campo of Object.keys(CAMPOS)) form.elements[campo].value = r[campo];
  limparErros(form);
  $("#form-titulo").textContent = `Editando colaborador ${r.id_colaborador}`;
  $("#btn-salvar").textContent = "Salvar alterações";
  $("#btn-cancelar").hidden = false;
  document.querySelectorAll("#tabela-registros tr").forEach((tr) => tr.classList.remove("editando"));
  form.scrollIntoView({ behavior: "smooth", block: "start" });
  form.elements.id_colaborador.focus();
  atualizarTela();
}

function sairEdicao() {
  editandoId = null;
  form.reset();
  limparErros(form);
  $("#form-titulo").textContent = "Novo registro";
  $("#btn-salvar").textContent = "Cadastrar";
  $("#btn-cancelar").hidden = true;
}

async function salvar(evento) {
  evento.preventDefault();
  limparErros(form);
  const { dados, erros } = validarRegistro();
  if (Object.keys(erros).length) {
    mostrarErros(erros);
    return avisar("Corrija os campos destacados.", "erro");
  }
  const btn = $("#btn-salvar");
  btn.disabled = true;
  try {
    const r = editandoId
      ? await api(`/registros/${editandoId}`, { method: "PUT", body: dados })
      : await api("/registros", { method: "POST", body: dados });
    avisar(`${editandoId ? "Registro atualizado" : "Registro cadastrado"}: risco ${r.risco_burnout}.`);
    sairEdicao();
    await atualizarTela();
  } catch (e) {
    mostrarErros(e.erros);
    if (e.status === 404) sairEdicao();
    avisar(e.message, "erro");
  } finally {
    btn.disabled = false;
  }
}

async function excluir(r) {
  if (!confirm(`Excluir o registro do colaborador ${r.id_colaborador}?`)) return;
  try {
    await api(`/registros/${r.id_registro}`, { method: "DELETE" });
    if (editandoId === r.id_registro) sairEdicao();
    avisar("Registro excluído.");
  } catch (e) {
    avisar(e.message, "erro");
  }
  await atualizarTela();
}

async function simular(evento) {
  evento.preventDefault();
  const caixa = $("#form-simulacao");
  limparErros(caixa.parentElement);
  const quantidade = Number($("#quantidade").value);
  if (!Number.isInteger(quantidade) || quantidade < 10 || quantidade > 500) {
    mostrarErros({ quantidade: "Informe um inteiro entre 10 e 500." });
    return;
  }
  const btn = $("#btn-simular");
  btn.disabled = true;
  btn.textContent = "Gerando…";
  try {
    const r = await api("/simulacoes", { method: "POST", body: { quantidade } });
    avisar(`${r.gerados} registros gerados pelo simulador.`);
    await atualizarTela();
  } catch (e) {
    mostrarErros(e.erros);
    avisar(e.message, "erro");
  } finally {
    btn.disabled = false;
    btn.textContent = "Gerar registros";
  }
}

// ------------------------------------------------------------ inicio

async function iniciar() {
  try {
    const departamentos = await api("/departamentos");
    for (const sel of [$("#departamento"), $("#filtro-departamento")]) {
      sel.append(...departamentos.map((d) => new Option(d, d)));
    }
  } catch (e) {
    avisar(e.message, "erro");
  }
  form.addEventListener("submit", salvar);
  $("#btn-cancelar").addEventListener("click", sairEdicao);
  $("#form-simulacao").addEventListener("submit", simular);
  $("#filtro-departamento").addEventListener("change", atualizarTela);
  $("#filtro-risco").addEventListener("change", atualizarTela);
  await atualizarTela();
}

iniciar();
