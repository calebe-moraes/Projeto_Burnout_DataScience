# Projeto Burnout

## Monitoramento de Clima Organizacional e Prevenção Preditiva de Burnout Operacional

Projeto Integrado desenvolvido pelo **Grupo 6 — UNIFEOB**, para a disciplina de **Análise de Dados**.

---

## Integrantes

| RA | Nome |
|---|---|
| 24000974 | Calebe Matheus Moreira Moraes |
| 24001964 | Leandro Jose de Carvalho Coelho |
| 24000092 | Lucas Vigo Calio |
| 24000308 | Mateus Oliveira Milane |

---

## Sobre o projeto

O **Projeto Burnout** consiste no desenvolvimento de uma plataforma de inteligência de dados voltada ao **Capital Humano**, com o objetivo de utilizar dados operacionais para identificar sinais relacionados à sobrecarga e exaustão dos colaboradores.

A solução trabalha com indicadores como:

- Horas extras;
- Marcações de ponto;
- Tickets e atividades realizados fora do horário de trabalho;
- Dados de pesquisas de clima organizacional.

A partir desses dados, o projeto busca calcular indicadores de exaustão e estimar o risco de **burnout e turnover por departamento**, possibilitando a identificação de situações que possam exigir atenção preventiva.

O projeto também está relacionado ao **ODS 8 — Trabalho Decente e Crescimento Econômico**, da Organização das Nações Unidas.

> **Nota:** por se tratar de uma atividade acadêmica, os dados utilizados neste projeto são fictícios/simulados e destinados exclusivamente a fins de estudo e demonstração.

---

## Objetivos

O projeto tem como principais objetivos:

- Organizar e processar dados relacionados ao clima organizacional;
- Identificar padrões e indicadores de exaustão;
- Estruturar os dados utilizando conceitos de Data Lake e Data Warehouse;
- Aplicar técnicas de análise de dados;
- Preparar uma infraestrutura reproduzível utilizando Docker;
- Disponibilizar um ambiente padronizado para execução do projeto;
- Gerar dados brutos simulados para utilização nas etapas de análise e tratamento.

---

## Etapas do projeto

O desenvolvimento do projeto está organizado nas seguintes etapas:

### 1. Análise Exploratória de Dados (AED)

Análise dos dados para identificação de padrões, tendências, distribuições, correlações e possíveis pontos fora do comportamento esperado.

**Relatório:**

`docs/relatorios/AED_Burnout_Relatorio_Completo.pdf`

### 2. Data Warehouse e Data Lake

Organização dos dados nas camadas **Bronze, Silver e Gold**, além da estruturação do modelo dimensional utilizado no projeto.

**Relatório:**

`docs/relatorios/DW_DL_Burnout_Relatorio.pdf`

### 3. DevOps — Infraestrutura e Ambiente Reproduzível

Preparação e padronização do ambiente de execução utilizando **Docker, Docker Compose, Python e PostgreSQL**, permitindo que a infraestrutura seja criada e reconstruída de maneira padronizada.

**Relatório:**

`docs/relatorios/DevOps_Infraestrutura_Burnout_Relatorio.pdf`

### 4. DevOps — Simulador Gerador de Dados

Desenvolvimento de um simulador responsável pela geração automática dos dados brutos utilizados no projeto.

O simulador produz dados compatíveis com a situação-problema do projeto, incluindo informações relacionadas a:

- Colaboradores;
- Departamentos;
- Horas extras;
- Horas trabalhadas;
- Tickets realizados fora do horário;
- Horários de atendimento;
- Indicadores de clima organizacional.

Também são inseridos problemas de qualidade de forma controlada, como:

- Valores ausentes;
- Registros duplicados;
- Categorias divergentes;
- Formatos inconsistentes.

O simulador está localizado em:

`src/gerador/gerar_dados.py`

Para executar o simulador utilizando o ambiente Docker:

```bash
docker compose run --rm app python src/gerador/gerar_dados.py