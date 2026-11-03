"""API REST - Projeto Burnout (Grupo 6, UNIFEOB).

Expoe os registros de indicadores de exaustao (gerados pelo simulador ou
cadastrados pelo formulario) e serve o front-end em /.

Uso:
    pip install -r api/requirements.txt
    uvicorn api.app:app --reload            # http://127.0.0.1:8000
"""
import os
import sqlite3
import sys
import uuid
from contextlib import asynccontextmanager, closing
from datetime import datetime
from pathlib import Path
from typing import Literal, Optional

import numpy as np
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import FileResponse, JSONResponse, Response
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ / "simulador"))
from simulador import DEPARTAMENTOS, classificar_risco, gerar_registro  # noqa: E402

STATIC = Path(__file__).resolve().parent / "static"
Departamento = Literal["TI", "RH", "Financeiro", "Comercial", "Operacoes"]
Risco = Literal["baixo", "medio", "alto"]


def caminho_banco() -> Path:
    return Path(os.environ.get("BURNOUT_DB", RAIZ / "dados" / "burnout.db"))


def conectar() -> sqlite3.Connection:
    con = sqlite3.connect(caminho_banco())
    con.row_factory = sqlite3.Row
    return con


def criar_tabela() -> None:
    caminho_banco().parent.mkdir(parents=True, exist_ok=True)
    with closing(conectar()) as con, con:
        con.execute("""
            CREATE TABLE IF NOT EXISTS registros (
                id_registro          TEXT PRIMARY KEY,
                id_colaborador       INTEGER NOT NULL,
                departamento         TEXT NOT NULL,
                horas_extras         REAL NOT NULL,
                horas_trabalhadas    REAL NOT NULL,
                tickets_fora_horario INTEGER NOT NULL,
                nivel_clima          INTEGER NOT NULL,
                risco_burnout        TEXT NOT NULL,
                data_hora_geracao    TEXT NOT NULL
            )""")


def inserir(con: sqlite3.Connection, r: dict) -> None:
    con.execute(
        "INSERT INTO registros VALUES (:id_registro, :id_colaborador, :departamento, :horas_extras, "
        ":horas_trabalhadas, :tickets_fora_horario, :nivel_clima, :risco_burnout, :data_hora_geracao)", r)


@asynccontextmanager
async def ciclo_de_vida(_app: FastAPI):
    criar_tabela()
    yield


app = FastAPI(title="API Projeto Burnout", version="1.0.0", lifespan=ciclo_de_vida)


# ---------------------------------------------------------------- modelos

class RegistroEntrada(BaseModel):
    id_colaborador: int = Field(ge=1000, le=9999)
    departamento: Departamento
    horas_extras: float = Field(ge=0, le=100)
    horas_trabalhadas: float = Field(ge=0, le=24)
    tickets_fora_horario: int = Field(ge=0, le=100)
    nivel_clima: int = Field(ge=1, le=10)


class Registro(RegistroEntrada):
    id_registro: str
    risco_burnout: Risco
    data_hora_geracao: str


class SimulacaoEntrada(BaseModel):
    quantidade: int = Field(default=20, ge=10, le=500)


# ------------------------------------------- erros de validacao em portugues

def numero(valor) -> str:
    return f"{valor:g}" if isinstance(valor, (int, float)) else str(valor)


def traduzir(erro: dict) -> str:
    ctx = erro.get("ctx", {})
    return {
        "missing": "Campo obrigatório.",
        "greater_than_equal": f"Deve ser maior ou igual a {numero(ctx.get('ge'))}.",
        "less_than_equal": f"Deve ser menor ou igual a {numero(ctx.get('le'))}.",
        "int_parsing": "Informe um número inteiro.",
        "int_from_float": "Informe um número inteiro.",
        "float_parsing": "Informe um número.",
        "literal_error": "Valor inválido.",
    }.get(erro["type"], erro["msg"])


@app.exception_handler(RequestValidationError)
async def erro_validacao(_req: Request, exc: RequestValidationError):
    erros = {str(e["loc"][-1]): traduzir(e) for e in exc.errors()}
    return JSONResponse(status_code=422, content={"detail": "Dados inválidos.", "erros": erros})


# --------------------------------------------------------------- endpoints

@app.get("/api/departamentos", response_model=list[str])
def listar_departamentos():
    return DEPARTAMENTOS


@app.get("/api/registros", response_model=list[Registro])
def listar_registros(departamento: Optional[Departamento] = None, risco: Optional[Risco] = None,
                     limite: int = Query(default=100, ge=1, le=1000)):
    sql, params = "SELECT * FROM registros WHERE 1=1", []
    if departamento:
        sql += " AND departamento = ?"
        params.append(departamento)
    if risco:
        sql += " AND risco_burnout = ?"
        params.append(risco)
    sql += " ORDER BY data_hora_geracao DESC, rowid DESC LIMIT ?"
    params.append(limite)
    with closing(conectar()) as con:
        return [dict(r) for r in con.execute(sql, params)]


@app.get("/api/registros/{id_registro}", response_model=Registro)
def obter_registro(id_registro: str):
    with closing(conectar()) as con:
        r = con.execute("SELECT * FROM registros WHERE id_registro = ?", (id_registro,)).fetchone()
    if r is None:
        raise HTTPException(404, "Registro não encontrado.")
    return dict(r)


@app.post("/api/registros", response_model=Registro, status_code=201)
def criar_registro(entrada: RegistroEntrada):
    r = entrada.model_dump()
    r["id_registro"] = uuid.uuid4().hex[:12]
    r["risco_burnout"] = classificar_risco(r["horas_extras"], r["tickets_fora_horario"], r["nivel_clima"])
    r["data_hora_geracao"] = datetime.now().isoformat(timespec="seconds")
    with closing(conectar()) as con, con:
        inserir(con, r)
    return r


@app.put("/api/registros/{id_registro}", response_model=Registro)
def atualizar_registro(id_registro: str, entrada: RegistroEntrada):
    r = entrada.model_dump()
    r["id_registro"] = id_registro
    r["risco_burnout"] = classificar_risco(r["horas_extras"], r["tickets_fora_horario"], r["nivel_clima"])
    with closing(conectar()) as con, con:
        cur = con.execute(
            "UPDATE registros SET id_colaborador=:id_colaborador, departamento=:departamento, "
            "horas_extras=:horas_extras, horas_trabalhadas=:horas_trabalhadas, "
            "tickets_fora_horario=:tickets_fora_horario, nivel_clima=:nivel_clima, "
            "risco_burnout=:risco_burnout WHERE id_registro=:id_registro", r)
        if cur.rowcount == 0:
            raise HTTPException(404, "Registro não encontrado.")
    return obter_registro(id_registro)


@app.delete("/api/registros/{id_registro}", status_code=204)
def excluir_registro(id_registro: str):
    with closing(conectar()) as con, con:
        cur = con.execute("DELETE FROM registros WHERE id_registro = ?", (id_registro,))
    if cur.rowcount == 0:
        raise HTTPException(404, "Registro não encontrado.")
    return Response(status_code=204)


@app.post("/api/simulacoes", status_code=201)
def simular(entrada: SimulacaoEntrada):
    rng = np.random.default_rng()
    registros = [gerar_registro(rng) for _ in range(entrada.quantidade)]
    with closing(conectar()) as con, con:
        for r in registros:
            inserir(con, r)
    return {"gerados": len(registros)}


@app.get("/api/indicadores")
def indicadores():
    with closing(conectar()) as con:
        total = con.execute("SELECT COUNT(*) FROM registros").fetchone()[0]
        por_risco = {r: 0 for r in ("baixo", "medio", "alto")}
        for linha in con.execute("SELECT risco_burnout, COUNT(*) FROM registros GROUP BY risco_burnout"):
            por_risco[linha[0]] = linha[1]
        por_departamento = [dict(r) for r in con.execute("""
            SELECT departamento,
                   COUNT(*)                                        AS total,
                   ROUND(AVG(horas_extras), 1)                     AS media_horas_extras,
                   ROUND(AVG(nivel_clima), 1)                      AS media_clima,
                   SUM(CASE WHEN risco_burnout = 'alto' THEN 1 ELSE 0 END) AS alto
            FROM registros GROUP BY departamento ORDER BY alto DESC, departamento""")]
    return {"total": total, "por_risco": por_risco, "por_departamento": por_departamento}


# --------------------------------------------------------------- front-end

app.mount("/static", StaticFiles(directory=STATIC), name="static")


@app.get("/", include_in_schema=False)
def pagina_inicial():
    return FileResponse(STATIC / "index.html")
