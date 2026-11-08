# Projeto Burnout - Orquestrador da etapa R
# Executar a partir da raiz do repositorio (diretamente ou via .bat).
# Nao executa o simulador Python, Spark ou Hadoop.

executar_pipeline <- function() {
  entrada <- file.path("data", "bronze", "burnout_bruto.csv")
  saida <- file.path("data", "silver", "dados_burnout_tratados.csv")
  script_silver <- file.path("analise_r", "01_construir_silver.R")
  script_aed <- file.path("analise_r", "02_aed.R")

  if (!file.exists(entrada)) {
    stop("Bronze nao encontrada em: ", entrada,
         ". Confira se voce esta na raiz do repositorio.")
  }
  if (!file.exists(script_silver) || !file.exists(script_aed)) {
    stop("Scripts R nao encontrados. Execute a partir da raiz do repositorio.")
  }

  cat("\n========== PIPELINE R - PROJETO BURNOUT ==========\n")
  cat("Inicio: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")
  if (file.exists(saida)) {
    cat("Aviso: a Silver existente sera atualizada pelo script.\n")
  }

  # Etapa 1: geracao da Silver a partir da Bronze
  source(script_silver, local = TRUE)
  if (!file.exists(saida)) stop("O script nao produziu a Silver esperada: ", saida)

  # Checagens antes de liberar a analise exploratoria
  silver <- readr::read_csv(saida, show_col_types = FALSE)
  if (nrow(silver) == 0L) stop("A Silver foi criada vazia.")
  if (!("id_colaborador" %in% names(silver))) stop("Silver sem id_colaborador.")
  if (anyNA(silver)) stop("Silver ainda possui valores ausentes (NA).")
  if (anyDuplicated(silver$id_colaborador) > 0L) {
    stop("Silver ainda possui IDs duplicados.")
  }
  cat("Validacao OK: ", nrow(silver), " registros, ",
      length(unique(silver$id_colaborador)), " IDs distintos, sem NA.\n", sep = "")

  # Etapa 2: AED, graficos, estatisticas e correlacoes
  source(script_aed, local = TRUE)

  esperados <- file.path("resultados_r", c(
    "estatisticas_gerais.csv",
    "resumo_por_departamento_r.csv",
    "matriz_correlacao.csv",
    "01_distribuicao_horas_extras.png",
    "02_horas_extras_por_departamento.png",
    "03_tickets_vs_clima.png"
  ))
  faltantes <- esperados[!file.exists(esperados)]
  if (length(faltantes) > 0L) {
    stop("Saidas da AED nao encontradas: ", paste(faltantes, collapse = ", "))
  }

  cat("\nPIPELINE R CONCLUIDO COM SUCESSO.\n")
  cat("Silver: ", saida, "\n", sep = "")
  cat("Analises: resultados_r/\n")
  cat("Fim: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")
}

executar_pipeline()
