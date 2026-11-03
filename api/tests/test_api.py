"""Testes da API. Rodar na raiz do projeto: python -m pytest api/tests -q"""
import pytest
from fastapi.testclient import TestClient

VALIDO = {"id_colaborador": 1234, "departamento": "TI", "horas_extras": 20.5,
          "horas_trabalhadas": 10, "tickets_fora_horario": 6, "nivel_clima": 2}


@pytest.fixture()
def cliente(tmp_path, monkeypatch):
    monkeypatch.setenv("BURNOUT_DB", str(tmp_path / "teste.db"))
    from api.app import app
    with TestClient(app) as c:
        yield c


def test_crud_completo(cliente):
    r = cliente.post("/api/registros", json=VALIDO)
    assert r.status_code == 201
    criado = r.json()
    assert criado["risco_burnout"] == "alto"
    rid = criado["id_registro"]

    assert [x["id_registro"] for x in cliente.get("/api/registros").json()] == [rid]

    r = cliente.put(f"/api/registros/{rid}", json={**VALIDO, "horas_extras": 0, "tickets_fora_horario": 0,
                                                    "nivel_clima": 10})
    assert r.status_code == 200 and r.json()["risco_burnout"] == "baixo"

    assert cliente.delete(f"/api/registros/{rid}").status_code == 204
    assert cliente.get(f"/api/registros/{rid}").status_code == 404
    assert cliente.delete(f"/api/registros/{rid}").status_code == 404


def test_validacao_em_portugues(cliente):
    r = cliente.post("/api/registros", json={**VALIDO, "nivel_clima": 11, "departamento": "Marketing",
                                             "horas_trabalhadas": None})
    assert r.status_code == 422
    erros = r.json()["erros"]
    assert erros["nivel_clima"] == "Deve ser menor ou igual a 10."
    assert erros["departamento"] == "Valor inválido."
    assert "horas_trabalhadas" in erros


def test_simulacao_filtros_e_indicadores(cliente):
    assert cliente.post("/api/simulacoes", json={"quantidade": 5}).status_code == 422
    assert cliente.post("/api/simulacoes", json={"quantidade": 30}).json() == {"gerados": 30}

    ind = cliente.get("/api/indicadores").json()
    assert ind["total"] == 30 and sum(ind["por_risco"].values()) == 30

    altos = cliente.get("/api/registros", params={"risco": "alto"}).json()
    assert len(altos) == ind["por_risco"]["alto"]
    assert all(x["risco_burnout"] == "alto" for x in altos)


def test_front_end_servido(cliente):
    r = cliente.get("/")
    assert r.status_code == 200 and "Painel Burnout" in r.text
    assert cliente.get("/static/app.js").status_code == 200
