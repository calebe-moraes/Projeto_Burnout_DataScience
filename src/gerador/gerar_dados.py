import pandas as pd
import numpy as np
import random
from faker import Faker
from pathlib import Path

# Configuração
fake = Faker("pt_BR")
random.seed(42)
np.random.seed(42)

QUANTIDADE_REGISTROS = 1000

# Caminho de saída
PASTA_SAIDA = Path("data/bronze")
ARQUIVO_SAIDA = PASTA_SAIDA / "burnout_bruto.csv"

# Departamentos com algumas categorias propositalmente divergentes
departamentos = [
    "TI",
    "ti",
    "Tecnologia da Informação",
    "RH",
    "Recursos Humanos",
    "Financeiro",
    "Comercial",
    "Operações",
    "Operacoes"
]

# Geração dos dados
dados = []

for i in range(QUANTIDADE_REGISTROS):
    horas_extras = round(max(0, np.random.normal(12, 6)), 1)
    horas_trabalhadas = round(np.random.normal(8.5, 1.5), 1)
    tickets_fora_horario = np.random.poisson(3)
    nivel_clima = random.randint(1, 10)

    # Horário de ticket
    hora_ticket = random.randint(0, 23)
    minuto_ticket = random.randint(0, 59)

    if random.random() < 0.5:
        horario_ticket = f"{hora_ticket:02d}:{minuto_ticket:02d}"
    else:
        horario_ticket = f"{hora_ticket:02d}h{minuto_ticket:02d}"

    registro = {
        "id_colaborador": 1000 + i,
        "nome": fake.name(),
        "departamento": random.choice(departamentos),
        "horas_extras": horas_extras,
        "horas_trabalhadas": horas_trabalhadas,
        "tickets_fora_horario": tickets_fora_horario,
        "horario_ticket": horario_ticket,
        "nivel_clima": nivel_clima
    }

    dados.append(registro)

df = pd.DataFrame(dados)

# ============================================================
# INSERÇÃO CONTROLADA DE PROBLEMAS DE QUALIDADE
# ============================================================

# 1. Valores ausentes
quantidade_nulos = int(len(df) * 0.05)

indices_nulos_horas = np.random.choice(
    df.index,
    quantidade_nulos,
    replace=False
)

df.loc[indices_nulos_horas, "horas_extras"] = np.nan

indices_nulos_clima = np.random.choice(
    df.index,
    quantidade_nulos,
    replace=False
)

df.loc[indices_nulos_clima, "nivel_clima"] = np.nan

# 2. Duplicidades
duplicados = df.sample(20, random_state=42)
df = pd.concat([df, duplicados], ignore_index=True)

# 3. Categorias divergentes
# Já inseridas através das variações:
# TI / ti / Tecnologia da Informação
# RH / Recursos Humanos
# Operações / Operacoes

# 4. Valores ausentes em horário de ticket
indices_nulos_horario = np.random.choice(
    df.index,
    int(len(df) * 0.03),
    replace=False
)

df.loc[indices_nulos_horario, "horario_ticket"] = None

# Embaralha os registros
df = df.sample(frac=1, random_state=42).reset_index(drop=True)

# Cria a pasta Bronze
PASTA_SAIDA.mkdir(parents=True, exist_ok=True)

# Salva o arquivo bruto
df.to_csv(
    ARQUIVO_SAIDA,
    index=False,
    encoding="utf-8-sig"
)

# Relatório da geração
print("=" * 60)
print("SIMULADOR DE DADOS — PROJETO BURNOUT")
print("=" * 60)

print(f"Registros gerados: {len(df)}")
print(f"Arquivo gerado: {ARQUIVO_SAIDA}")
print()

print("Valores ausentes:")
print(df.isnull().sum())

print()
print(f"Duplicidades encontradas: {df.duplicated().sum()}")

print()
print("Departamentos encontrados:")
print(df["departamento"].value_counts())

print()
print("Geração concluída com sucesso!")