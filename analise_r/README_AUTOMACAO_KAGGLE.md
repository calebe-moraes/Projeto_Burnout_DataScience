# Automacao do pipeline Kaggle em R - Projeto Burnout

Este pacote adiciona uma automacao **separada** da versao simulada anterior. Nao substitua os scripts R existentes e nao execute o `.bat` antigo para tratar a base Kaggle.

## Copiar para o repositorio

Na raiz de `Projeto_Burnout_DataScience`:

- Copie `analise_r/00_executar_pipeline_kaggle.R` para `analise_r/`.
- Copie `executar_pipeline_Kaggle.bat` e `README_AUTOMACAO_KAGGLE.md` para a raiz.

Os scripts `analise_r/01_construir_silver_kaggle.R` e `analise_r/02_aed_kaggle.R` devem estar presentes (foram validados nas etapas anteriores).

A entrada deve existir em `data/bronze/kaggle/train.csv`. Instale R e os pacotes necessarios, se ainda faltarem:

```r
install.packages(c("readr", "dplyr", "ggplot2", "tibble"))
```

## Executar no Windows

1. Faca uma copia de `data/silver/dados_burnout_kaggle_tratados.csv` e da pasta `resultados_r/kaggle/` se precisar preservar as versoes atuais. O pipeline atualiza esses arquivos.
2. Abra a pasta raiz do projeto. Execute `executar_pipeline_Kaggle.bat` com dois cliques.
3. Alternativamente, abra o Prompt de Comando nessa pasta e execute `executar_pipeline_Kaggle.bat`.
4. Confirme as mensagens `Validacao OK:` e `PIPELINE KAGGLE CONCLUIDO COM SUCESSO.`
5. Confira que as datas de modificacao de arquivos na pasta `resultados_r/kaggle/` foram atualizadas.

O log da execucao fica em `%LOCALAPPDATA%\Projeto_Burnout_Logs\ultima_execucao_kaggle.log` e e separado do log do pipeline anterior.

## Executar diretamente com Rscript

A partir da raiz do repositorio:

```bash
Rscript analise_r/00_executar_pipeline_kaggle.R
```

A automacao:

1. Constroi a Silver Kaggle com `01_construir_silver_kaggle.R`.
2. Verifica IDs unicos, colunas, ausencia de NAs inesperados, e faixas de valores.
3. **Preserva os Burn Rate ausentes**: a variavel-alvo nao recebe imputacao.
4. Executa `02_aed_kaggle.R`.
5. Confere a presenca dos sete relatorios CSV e quatro graficos PNG.

## Restricoes e integracao

- Nao modifica a Bronze, a Silver simulada anterior, os scripts antigos ou os modulos Spark/Hadoop.
- A Silver Kaggle e salva em `data/silver/dados_burnout_kaggle_tratados.csv`.
- Os resultados sao salvos em `resultados_r/kaggle/`.
- Este pacote **nao automatiza Spark, Hadoop, Docker ou AWS**; essas etapas serao integradas separadamente.
- Se `data/bronze/*` ou `data/silver/*` estiverem no `.gitignore`, um novo clone nao recebera os CSVs ignorados. Documente a obtencao da Bronze conforme a licenca da fonte.
- Para futuros modelos preditivos, a imputacao deve ser ajustada apenas nos dados de treino, evitando vazamento de informacoes para validacao/teste. A Silver atual serve a AED e a integracao inicial.

Teste localmente antes de enviar esses arquivos ao GitHub.
