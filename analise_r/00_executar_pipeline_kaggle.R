# Projeto Burnout - UNIFEOB / Grupo 6
# Orquestrador independente Kaggle: Bronze -> Silver -> AED
# Execute a partir da raiz do repositorio.

inicio <- Sys.time()
cat("\n========== PIPELINE KAGGLE - PROJETO BURNOUT ==========\n")
cat("Inicio:", format(inicio, "%Y-%m-%d %H:%M:%S"), "\n")
cat("Diretorio:", normalizePath(getwd(), winslash = "/"), "\n")
cat("Aviso: Silver e resultados Kaggle existentes serao atualizados.\n")

bronze <- file.path("data", "bronze", "kaggle", "train.csv")
script_silver <- file.path("analise_r", "01_construir_silver_kaggle.R")
script_aed <- file.path("analise_r", "02_aed_kaggle.R")
arquivo_silver <- file.path("data", "silver", "dados_burnout_kaggle_tratados.csv")
pasta_resultados <- file.path("resultados_r", "kaggle")

necessarios <- c(bronze, script_silver, script_aed)
ausentes <- necessarios[!file.exists(necessarios)]
if (length(ausentes) > 0L) {
  stop("Arquivos obrigatorios nao encontrados: ", paste(ausentes, collapse = "; "),
       ". Execute a partir da raiz do repositorio.", call. = FALSE)
}
if (!requireNamespace("readr", quietly = TRUE)) {
  stop('Pacote readr ausente. Instale com install.packages("readr").', call. = FALSE)
}

executar_script <- function(nome, caminho) {
  cat("\n---", nome, "---\n")
  tryCatch(
    source(caminho, local = new.env(parent = globalenv()), encoding = "UTF-8"),
    error = function(e) stop("Falha em ", caminho, ": ", conditionMessage(e), call. = FALSE)
  )
}

executar_script("Construir Silver Kaggle", script_silver)

if (!file.exists(arquivo_silver)) {
  stop("Silver Kaggle nao gerada: ", arquivo_silver, call. = FALSE)
}
silver <- readr::read_csv(
  arquivo_silver,
  show_col_types = FALSE,
  col_types = readr::cols(id_colaborador = readr::col_character(), .default = readr::col_guess())
)
if (nrow(readr::problems(silver)) > 0L) {
  stop("Problemas de leitura na Silver Kaggle.", call. = FALSE)
}
colunas <- c("id_colaborador", "data_admissao", "genero", "tipo_empresa",
             "home_office_disponivel", "nivel_cargo", "alocacao_recursos",
             "fadiga_mental", "taxa_burnout", "alocacao_recursos_imputada",
             "fadiga_mental_imputada", "taxa_burnout_disponivel")
faltantes <- setdiff(colunas, names(silver))
if (length(faltantes) > 0L) {
  stop("Colunas ausentes na Silver: ", paste(faltantes, collapse = ", "), call. = FALSE)
}
if (nrow(silver) == 0L || anyNA(silver$id_colaborador) ||
    any(trimws(silver$id_colaborador) == "") ||
    anyDuplicated(silver$id_colaborador) > 0L) {
  stop("Silver vazia ou IDs vazios/duplicados.", call. = FALSE)
}

# NAs em taxa_burnout sao intencionais; as demais colunas precisam estar completas.
na_inesperados <- sum(is.na(silver[setdiff(colunas, "taxa_burnout")]))
if (na_inesperados > 0L) {
  stop("Valores ausentes inesperados fora de taxa_burnout: ", na_inesperados, call. = FALSE)
}
if (any(silver$nivel_cargo < 0 | silver$nivel_cargo > 5) ||
    any(silver$alocacao_recursos < 1 | silver$alocacao_recursos > 10) ||
    any(silver$fadiga_mental < 0 | silver$fadiga_mental > 10) ||
    any(silver$taxa_burnout < 0 | silver$taxa_burnout > 1, na.rm = TRUE)) {
  stop("Valores numericos fora das faixas previstas.", call. = FALSE)
}
alvo_disponivel <- !is.na(silver$taxa_burnout)
if (!all(silver$taxa_burnout_disponivel == alvo_disponivel)) {
  stop("Indicador taxa_burnout_disponivel inconsistente.", call. = FALSE)
}
if (sum(alvo_disponivel) == 0L) {
  stop("Nenhum Burn Rate disponivel para AED.", call. = FALSE)
}
cat("\nValidacao OK: ", nrow(silver), " IDs unicos, ", sum(alvo_disponivel),
    " Burn Rate disponiveis, ", sum(!alvo_disponivel),
    " ausentes preservados.\n", sep = "")

executar_script("Analise exploratoria Kaggle", script_aed)

arquivos_esperados <- c(
  "relatorio_qualidade_silver_kaggle.csv",
  "validacoes_silver_kaggle.csv",
  "estatisticas_gerais_kaggle.csv",
  "resumo_por_tipo_empresa_kaggle.csv",
  "resumo_por_home_office_kaggle.csv",
  "resumo_por_nivel_cargo_kaggle.csv",
  "matriz_correlacao_kaggle.csv",
  "01_distribuicao_burn_rate.png",
  "02_fadiga_vs_burn_rate.png",
  "03_burn_rate_por_tipo_empresa.png",
  "04_burn_rate_por_nivel_cargo.png"
)
nao_gerados <- file.path(pasta_resultados, arquivos_esperados)
nao_gerados <- nao_gerados[!file.exists(nao_gerados)]
if (length(nao_gerados) > 0L) {
  stop("Arquivos de resultados ausentes: ",
       paste(nao_gerados, collapse = "; "), call. = FALSE)
}

cat("\nPIPELINE KAGGLE CONCLUIDO COM SUCESSO.\n")
cat("Silver:", arquivo_silver, "\n")
cat("Analises:", paste0(pasta_resultados, "/"), "\n")
cat("Fim:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
