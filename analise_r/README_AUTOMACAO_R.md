# Automacao da etapa R - Projeto Burnout

## O que inclui

- `analise_r/00_executar_pipeline.R`: orquestra os dois scripts ja existentes, valida a Silver e verifica as saidas da AED.
- `executar_pipeline_R.bat`: executa a etapa R com um clique no Windows; cria um log no perfil local do usuario.

## Instalacao

Copie os arquivos para a raiz do repositorio `Projeto_Burnout_DataScience`, mantendo a subpasta `analise_r`.
Nao substitua `01_construir_silver.R` nem `02_aed.R`. O pacote so acrescenta um novo script e um arquivo .bat.

## Executar

1. Certifique-se de que o R e os pacotes `readr`, `dplyr`, `stringr`, `tidyr`, `ggplot2` e `tibble` estejam instalados.
2. Verifique que existe `data/bronze/burnout_bruto.csv`.
3. Execute `executar_pipeline_R.bat` com duplo clique.
4. Confira `data/silver/dados_burnout_tratados.csv`, `resultados_r/` e o log em `%LOCALAPPDATA%\Projeto_Burnout_Logs\ultima_execucao_r.log`.

Alternativamente, da raiz do repositorio no RStudio:

```r
source("analise_r/00_executar_pipeline.R")
```

Ou no terminal com Rscript disponivel:

```bash
Rscript analise_r/00_executar_pipeline.R
```

## Agendar no Windows

No Agendador de Tarefas, crie uma tarefa para executar o programa `executar_pipeline_R.bat`, passando `--agendado` como argumento. Configure a pasta raiz do projeto como 'Iniciar em' para facilitar a manutencao. A tarefa nao deve executar em paralelo consigo mesma.

## Cuidados

- O pipeline reutiliza a Bronze existente; ele nao inicia o simulador Python.
- A Silver existente sera sobrescrita pelo primeiro script.
- Os graficos e relatorios de `resultados_r/` tambem sao atualizados; alguns sao versionados pelo Git e podem aparecer como modificados no `git status`.
- `data/silver/` esta no `.gitignore`: a Silver precisa ser disponibilizada separadamente ao Spark em Google Colab ou outro ambiente.
- O runner **nao** integra automaticamente Spark, Hadoop, API ou Docker. A imagem Docker atual e baseada em Python e nao inclui R.
- Este pacote nao modifica os arquivos existentes; inclua-o por branch/PR e teste primeiro localmente.
