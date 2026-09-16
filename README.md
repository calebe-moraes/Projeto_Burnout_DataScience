# Projeto Burnout — Monitoramento de Clima Organizacional e Prevenção Preditiva de Burnout Operacional

Projeto Integrado desenvolvido pelo **Grupo 6** — UNIFEOB, para a disciplina de Análise de Dados.

## Integrantes

| RA | Nome |
|---|---|
| 24000974 | Calebe Matheus Moreira Moraes |
| 24001964 | Leandro Jose de Carvalho Coelho |
| 24000092 | Lucas Vigo Calio |
| 24000308 | Mateus Oliveira Milane |

## Sobre o projeto

Plataforma de inteligência de dados voltada ao Capital Humano: coleta e processa
indicadores operacionais dos colaboradores (horas extras, ponto, tickets fora do
horário, pesquisas de clima) para calcular indicadores de exaustão e estimar o
risco de burnout e turnover por departamento, alinhado ao ODS 8 da ONU.

> **Nota:** por se tratar de uma atividade acadêmica, os dados utilizados neste
> projeto são fictícios/simulados, gerados para fins de estudo.

## Etapas do projeto

1. **Análise Exploratória de Dados (AED)** — `docs/relatorios/AED_Burnout_Relatorio_Completo.pdf`
2. **Data Warehouse e Data Lake** — `docs/relatorios/DW_DL_Burnout_Relatorio.pdf`
3. **DevOps — Infraestrutura e Ambiente Reproduzível** — `docs/relatorios/DevOps_Infraestrutura_Burnout_Relatorio.pdf`

## Estrutura do repositório

```
projeto-burnout/
├── README.md
├── requirements.txt
├── docker-compose.yml
├── Dockerfile
├── .gitignore
├── data/
│   ├── bronze/     # dados brutos (Data Lake)
│   ├── silver/     # dados tratados
│   └── gold/       # modelo dimensional (Data Warehouse)
├── src/
│   ├── etl/
│   │   ├── extract.py
│   │   ├── transform.py
│   │   └── load.py
│   └── modelos/
│       └── esquema_estrela.py
├── notebooks/
│   └── AED_burnout.ipynb
└── docs/
    └── relatorios/
```

## Como rodar o projeto

Pré-requisitos: [Git](https://git-scm.com/) e [Docker](https://www.docker.com/) instalados.

```bash
# 1. Clonar o repositório
git clone https://github.com/SEU-USUARIO/projeto-burnout.git
cd projeto-burnout

# 2. Construir e subir os contêineres
docker-compose up --build

# 3. Executar o pipeline de ETL dentro do contêiner
docker-compose exec app python src/etl/extract.py
docker-compose exec app python src/etl/transform.py
docker-compose exec app python src/etl/load.py

# 4. Encerrar o ambiente ao finalizar
docker-compose down
```

## Tecnologias utilizadas

Python · Pandas · Matplotlib · PostgreSQL · SQLAlchemy · Docker · Git

## Branches

| Branch | Finalidade |
|---|---|
| `main` | Versão estável, usada para gerar os entregáveis finais |
| `feature/aed` | Desenvolvimento da Análise Exploratória de Dados |
| `feature/dw-dl` | Desenvolvimento do modelo de Data Warehouse e Data Lake |
| `feature/devops` | Configuração do ambiente, Docker e scripts de infraestrutura |
