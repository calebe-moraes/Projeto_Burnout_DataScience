"""Simulador de dados - Projeto Burnout (Grupo 6, UNIFEOB).

Gera registros sinteticos de indicadores de exaustao por colaborador e os
acrescenta (append) a um arquivo CSV, sem apagar execucoes anteriores.

Uso:
    python simulador.py [--quantidade 20] [--saida ./dados/dados_burnout.csv]

Sem interface grafica e sem caminhos fixos da maquina hospedeira: o destino
padrao e a pasta "dados" ao lado da pasta do simulador (ou a variavel de
ambiente BURNOUT_DADOS_DIR).
"""
import argparse
import csv
import os
import uuid
from datetime import datetime
from pathlib import Path

import numpy as np

CAMPOS = [
    "id_registro",
    "id_colaborador",
    "departamento",
    "horas_extras",
    "horas_trabalhadas",
    "tickets_fora_horario",
    "nivel_clima",
    "risco_burnout",
    "data_hora_geracao",
]

DEPARTAMENTOS = ["TI", "RH", "Financeiro", "Comercial", "Operacoes"]


def pasta_padrao() -> Path:
    env = os.environ.get("BURNOUT_DADOS_DIR")
    if env:
        return Path(env)
    return Path(__file__).resolve().parent.parent / "dados"


def classificar_risco(horas_extras, tickets, clima) -> str:
    # Clima (1-10) baixo aumenta o risco; horas extras e tickets fora do horario tambem.
    pontos = horas_extras / 6 + tickets / 2 + (10 - clima) / 3
    if pontos >= 7:
        return "alto"
    if pontos >= 4.5:
        return "medio"
    return "baixo"


def gerar_registro(rng: np.random.Generator) -> dict:
    horas_extras = round(float(max(0.0, rng.normal(12, 6))), 1)
    horas_trabalhadas = round(float(np.clip(rng.normal(8.5, 1.5), 4, 14)), 1)
    tickets = int(rng.poisson(3))
    clima = int(rng.integers(1, 11))
    return {
        "id_registro": uuid.uuid4().hex[:12],
        "id_colaborador": int(rng.integers(1000, 2000)),
        "departamento": str(rng.choice(DEPARTAMENTOS)),
        "horas_extras": horas_extras,
        "horas_trabalhadas": horas_trabalhadas,
        "tickets_fora_horario": tickets,
        "nivel_clima": clima,
        "risco_burnout": classificar_risco(horas_extras, tickets, clima),
        "data_hora_geracao": datetime.now().isoformat(timespec="seconds"),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Simulador de dados de burnout")
    parser.add_argument("--quantidade", type=int, default=20,
                        help="registros por execucao (minimo 10)")
    parser.add_argument("--saida", type=Path, default=None,
                        help="arquivo CSV de saida (append)")
    args = parser.parse_args()

    if args.quantidade < 10:
        parser.error("--quantidade deve ser >= 10")

    saida = args.saida or pasta_padrao() / "dados_burnout.csv"
    saida.parent.mkdir(parents=True, exist_ok=True)
    novo = not saida.exists() or saida.stat().st_size == 0

    rng = np.random.default_rng()
    registros = [gerar_registro(rng) for _ in range(args.quantidade)]

    with saida.open("a", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=CAMPOS)
        if novo:
            w.writeheader()
        w.writerows(registros)

    total = sum(1 for _ in saida.open(encoding="utf-8")) - 1
    print(f"{len(registros)} registros gerados em {saida} (total no arquivo: {total})")


if __name__ == "__main__":
    main()
