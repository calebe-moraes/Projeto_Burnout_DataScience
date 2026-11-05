# Projeto Burnout — Tratamento de dados e Análise Exploratória em R

**Projeto:** Grupo 6 — UNIFEOB  
**Etapa:** Processamento da camada Bronze para Silver e Análise Exploratória de Dados (AED)  
**Base:** Dados sintéticos/simulados de colaboradores  
**Situação:** Scripts executados no RStudio; verificações de qualidade concluídas; três gráficos e matriz de correlação revisados. Integração posterior com Spark pendente.

## 1. Objetivo

Preparar uma base de dados consistente para análise, preservando o conjunto bruto (Bronze), produzindo uma versão tratada (Silver), registrando as transformações e realizando análises estatísticas exploratórias com **R**. O processamento busca identificar comportamentos associados à carga de trabalho e ao clima organizacional nos dados simulados. As variáveis não permitem, por si só, diagnosticar burnout.

## 2. Ferramentas e organização

Foram utilizados R e os pacotes `readr`, `dplyr`, `stringr`, `tidyr`, `ggplot2` e `tibble`. A implementação é composta por dois scripts:

- `analise_r/01_construir_silver.R`: leitura, padronização, deduplicação, imputação, validação e exportação da Silver;
- `analise_r/02_aed.R`: estatísticas, comparações por departamento, correlações e visualizações.

O arquivo de origem é `dados/bronze/burnout_bruto.csv`. O resultado tratado é gravado em `dados/silver/dados_burnout_tratados.csv`, com auditorias, tabelas e gráficos em `resultados_r/`. **O script não sobrescreve o arquivo Bronze.**

## 3. Variáveis analisadas

O conjunto de dados contém as colunas `id_colaborador`, `nome`, `departamento`, `horas_extras`, `horas_trabalhadas`, `tickets_fora_horario`, `horario_ticket` e `nivel_clima`. O ID identifica o colaborador; as demais variáveis descrevem departamento e características da jornada, dos chamados e do clima. A unidade e o período de referência das variáveis de horas devem ser confirmados com o responsável pelo simulador antes de interpretações temporais.

## 4. Transformações da Bronze para a Silver

### 4.1. Registros repetidos

A Bronze continha **1.020 registros**. Foram retiradas **19 duplicatas exatas**, resultando em **1.001 linhas**. Em seguida, foi resolvido **1 registro excedente** de um colaborador cujo ID aparecia mais de uma vez (ID 1740). Quando havia mais de um registro para o mesmo ID, o código manteve aquele com mais campos preenchidos. Assim, a Silver resultou em **1.000 linhas e 1.000 IDs distintos**.

### 4.2. Padronização de categorias

Variações textuais de departamentos, como `ti`/`TI`/`Tecnologia da Informação`, `RH`/`Recursos Humanos` e `Operacoes`/`Operações`, foram unificadas em cinco categorias: **Tecnologia da Informação, Recursos Humanos, Operações, Comercial e Financeiro**.

### 4.3. Valores ausentes

Após a deduplicação, foram encontrados e tratados:

| Campo | Ausentes antes do tratamento | Tratamento |
|---|---:|---|
| `horas_extras` | 50 | Imputação pela mediana do departamento; mediana geral se necessário |
| `nivel_clima` | 50 | Imputação pela mediana do departamento; mediana geral se necessário |
| `horario_ticket` | 29 | Substituição pelo texto `Nao informado` |

A imputação por mediana reduz a influência de valores extremos no preenchimento, mas **não recupera os valores verdadeiros ausentes**. Horários não informados foram identificados explicitamente, sem inventar horários. Horários existentes com representação como `08h24` foram normalizados para `08:24`.

### 4.4. Verificações de qualidade

Os relatórios gerados registraram **zero ocorrências** para as seguintes condições: horas extras negativas, horas trabalhadas menores ou iguais a zero, tickets fora do horário negativos, nível de clima fora do intervalo de 0 a 10 e horários em formato inesperado.

Verificou-se adicionalmente que **nenhuma coluna apresentava valores `NA`**, que havia **1.000 IDs distintos** e **nenhum ID duplicado**. Essas verificações **não significam ausência de todos os tipos possíveis de anomalia**; valores altos, mas dentro das faixas definidas, foram mantidos para análise.

## 5. Análise Exploratória de Dados (AED)

O script `02_aed.R` foi executado sobre a Silver com **1.000 colaboradores** e **5 departamentos**. Foram gerados:

- Estatísticas gerais (média, mediana, desvio-padrão, mínimo, quartis e máximo);
- Resumo por departamento;
- Matriz de correlação de Pearson entre variáveis numéricas;
- Histograma de horas extras;
- Boxplot de horas extras por departamento;
- Gráfico de dispersão entre chamados fora do horário e nível de clima, com ajuste linear ilustrativo.

### 5.1. Resumo descritivo por departamento

| Departamento | Colaboradores | Média de horas extras | Mediana de horas extras | Média de horas trabalhadas | Média de tickets fora do horário | Média de clima |
|---|---:|---:|---:|---:|---:|---:|
| Operações | 211 | 12,29 | 12,30 | 8,69 | 2,90 | 5,32 |
| Tecnologia da Informação | 333 | 12,02 | 11,90 | 8,49 | 3,01 | 5,66 |
| Financeiro | 121 | 11,93 | 11,35 | 8,34 | 2,57 | 5,59 |
| Comercial | 115 | 11,64 | 11,70 | 8,54 | 2,90 | 5,23 |
| Recursos Humanos | 220 | 11,62 | 11,70 | 8,56 | 3,03 | 5,35 |

*Valores arredondados para duas casas decimais, a partir da saída do script R.*

### 5.2. Observações iniciais

**Operações** apresentou a maior média de horas extras (aproximadamente 12,29), enquanto **Recursos Humanos** apresentou a menor (aproximadamente 11,62). Recursos Humanos teve a maior média de tickets fora do horário (aproximadamente 3,03), e Financeiro a menor (aproximadamente 2,57). Tecnologia da Informação apresentou a maior média de clima (aproximadamente 5,66), e Comercial a menor (aproximadamente 5,23).

Essas são **comparações descritivas** em dados simulados. Não foi realizado aqui teste estatístico de diferenças entre departamentos e não se deve interpretar esses números como evidência causal ou diagnóstico médico.

### 5.3. Interpretação dos gráficos

#### 5.3.1. Histograma: distribuição de horas extras

![Histograma de horas extras](figuras/01_distribuicao_horas_extras.png)

O histograma apresenta maior concentração de colaboradores aproximadamente entre **8 e 16 horas extras**, com pico próximo do intervalo de **10 a 14 horas**. Há uma cauda à direita, com registros alcançando valores próximos de 28 horas extras. Essa assimetria e a presença de observações elevadas justificam a inspeção de valores extremos; não determinam, isoladamente, que tais valores estejam errados.

A unidade/período de referência das horas extras não foi documentada nesta etapa e deve ser confirmada com quem desenvolveu o simulador. Não é possível inferir automaticamente sobrecarga semanal ou mensal apenas com os números exibidos.

#### 5.3.2. Boxplot: horas extras por departamento

![Boxplot de horas extras por departamento](figuras/02_horas_extras_por_departamento.png)

Os boxplots mostram **sobreposição substancial** das faixas centrais dos cinco departamentos. A comparação descritiva indica maior **média** de horas extras em **Operações (12,29)** e menor em **Recursos Humanos (11,62)**. As medianas também são próximas: Operações 12,30; TI 11,90; Recursos Humanos 11,70; Comercial 11,70; Financeiro 11,35.

Observam-se alguns valores acima dos limites usuais do boxplot em **Tecnologia da Informação, Recursos Humanos e Comercial**. Como esses registros não violam as regras de faixa definidas no processo de limpeza, foram mantidos para análise. A visualização não estabelece diferenças estatisticamente significativas entre grupos, pois não foram aplicados testes de hipótese.

#### 5.3.3. Dispersão: tickets fora do horário e nível de clima

![Tickets fora do horário e nível de clima](figuras/03_tickets_vs_clima.png)

Os pontos apresentam elevada dispersão e uma linha de regressão com **inclinação ligeiramente negativa**. A associação linear entre `tickets_fora_horario` e `nivel_clima` é, porém, **muito fraca** (*r* = −0,0738). Logo, não há evidência de uma relação linear expressiva entre essas variáveis nesta base simulada. A faixa sombreada mostra a incerteza do ajuste apresentado pelo gráfico e não torna a associação substantivamente forte.

Não se deve interpretar a inclinação da linha como prova de que chamados fora do horário causem pior clima organizacional.

### 5.4. Matriz de correlação de Pearson

A matriz apresenta seis pares distintos de variáveis numéricas, sem contar a diagonal de autocorrelação (*r* = 1):

| Variáveis comparadas | Correlação (*r*) | Leitura descritiva |
|---|---:|---|
| Horas extras × Horas trabalhadas | +0,0239 | Muito fraca, positiva |
| Horas extras × Tickets fora do horário | −0,0463 | Muito fraca, negativa |
| Horas extras × Nível de clima | −0,0448 | Muito fraca, negativa |
| Horas trabalhadas × Tickets fora do horário | +0,0068 | Praticamente nula |
| Horas trabalhadas × Nível de clima | +0,0286 | Muito fraca, positiva |
| Tickets fora do horário × Nível de clima | −0,0738 | Muito fraca, negativa |

**Síntese:** todos os coeficientes têm valor absoluto inferior a 0,075, o que indica **ausência de associações lineares expressivas** entre as variáveis examinadas. Correlação de Pearson não testa relações não lineares e não estabelece causalidade. Como 100 valores numéricos foram imputados por mediana (50 de horas extras e 50 de clima), a imputação pode influenciar a dispersão e os coeficientes.

### 5.5. Limites da interpretação da AED

- Os dados são **sintéticos/simulados**; não representam diagnóstico ou prevalência real de burnout.
- As análises são descritivas e exploratórias; não foram executados testes de significância, modelos causais ou validação clínica.
- As faixas de normalidade foram verificadas apenas segundo as regras programadas; valores altos ainda podem merecer inspeção.
- A mediana de grupo é estratégia de tratamento de ausências e pode reduzir a variabilidade observada.
- É necessário confirmar o período e a unidade das horas com os responsáveis pelo simulador.

## 6. Evidências de execução e arquivos de saída

O console do R exibiu `Silver criada com sucesso!` com **1.020 registros Bronze e 1.000 Silver**, e posteriormente `AED concluida.` com **1.000 registros analisados e 5 departamentos**.

| Arquivo | Finalidade |
|---|---|
| `dados/silver/dados_burnout_tratados.csv` | Base Silver tratada |
| `resultados_r/auditoria_ids_duplicados.csv` | Auditoria dos registros com IDs repetidos |
| `resultados_r/relatorio_qualidade_silver.csv` | Contagens de deduplicação e imputação |
| `resultados_r/validacoes_faixa_silver.csv` | Validação de faixas e formatos |
| `resultados_r/estatisticas_gerais.csv` | Estatísticas descritivas |
| `resultados_r/resumo_por_departamento_r.csv` | Resumo por departamento |
| `resultados_r/matriz_correlacao.csv` | Correlações de Pearson |
| `resultados_r/01_distribuicao_horas_extras.png` | Histograma |
| `resultados_r/02_horas_extras_por_departamento.png` | Boxplot |
| `resultados_r/03_tickets_vs_clima.png` | Dispersão e ajuste linear |

## 7. Reprodutibilidade

Na raiz do projeto, instalar os pacotes necessários uma única vez:

```r
install.packages(c("readr", "dplyr", "stringr", "tidyr", "ggplot2", "tibble"))
```

Depois executar os scripts, na ordem:

```r
source("analise_r/01_construir_silver.R")
source("analise_r/02_aed.R")
```

A execução recria/atualiza a **Silver** e os arquivos em `resultados_r/`. Ela **não altera a Bronze**. Para preservar versões anteriores dos resultados, salvar uma cópia antes de reexecutar.
