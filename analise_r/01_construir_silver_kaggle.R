# ============================================================
# Projeto Burnout - Grupo 6 / UNIFEOB
# Etapa 2: construcao da Silver a partir do Kaggle (train.csv)
#
# Entrada:  data/bronze/kaggle/train.csv
# Saida:    data/silver/dados_burnout_kaggle_tratados.csv
# Auditoria: resultados_r/kaggle/
#
# ATENCAO: o alvo Burn Rate ausente NAO e imputado.
# ============================================================

if (!requireNamespace("readr", quietly = TRUE)) {
  stop('O pacote readr nao esta instalado. Execute install.packages("readr").')
}

arquivo_bronze <- file.path("data", "bronze", "kaggle", "train.csv")
arquivo_silver <- file.path("data", "silver", "dados_burnout_kaggle_tratados.csv")
pasta_resultados <- file.path("resultados_r", "kaggle")

if (!file.exists(arquivo_bronze)) {
  stop("Arquivo nao encontrado: ", arquivo_bronze,
       ". Abra o RStudio na raiz de Projeto_Burnout_DataScience.")
}

# Tipos definidos explicitamente para nao converter IDs em numeros.
tipos <- readr::cols(
  `Employee ID` = readr::col_character(),
  `Date of Joining` = readr::col_character(),
  `Gender` = readr::col_character(),
  `Company Type` = readr::col_character(),
  `WFH Setup Available` = readr::col_character(),
  `Designation` = readr::col_double(),
  `Resource Allocation` = readr::col_double(),
  `Mental Fatigue Score` = readr::col_double(),
  `Burn Rate` = readr::col_double()
)

bronze <- readr::read_csv(
  arquivo_bronze,
  col_types = tipos,
  na = c("", "NA", "N/A", "NULL", "null"),
  show_col_types = FALSE
)

esperadas <- c("Employee ID", "Date of Joining", "Gender", "Company Type",
               "WFH Setup Available", "Designation", "Resource Allocation",
               "Mental Fatigue Score", "Burn Rate")
faltantes <- setdiff(esperadas, names(bronze))
if (length(faltantes) > 0) {
  stop("Colunas obrigatorias ausentes: ", paste(faltantes, collapse = ", "))
}

problemas_leitura <- readr::problems(bronze)
if (nrow(problemas_leitura) > 0) {
  stop("O CSV apresenta problemas de leitura/tipos. Verifique readr::problems(bronze).")
}

# Cada linha do train.csv corresponde a um colaborador; manter os IDs textuais.
ids <- trimws(bronze[["Employee ID"]])
if (any(is.na(ids) | ids == "")) {
  stop("Existem IDs ausentes ou vazios; revise a Bronze antes de continuar.")
}
if (anyDuplicated(ids) > 0L) {
  stop("Foram identificados IDs repetidos no dataset Kaggle. Rever antes de tratar.")
}

# Datas ISO e categorias originais padronizadas, sem inventar informacoes.
datas <- as.Date(bronze[["Date of Joining"]], format = "%Y-%m-%d")
if (any(is.na(datas))) stop("Existem datas de admissao invalidas.")

traduzir <- function(x, traducoes, nome_campo) {
  x <- trimws(x)
  invalidos <- unique(x[is.na(x) | !(x %in% names(traducoes))])
  if (length(invalidos) > 0L) {
    stop("Categoria inesperada em ", nome_campo, ": ",
         paste(invalidos, collapse = ", "))
  }
  unname(traducoes[x])
}

if (any(is.na(bronze[["Designation"]])) ||
    any(bronze[["Designation"]] != floor(bronze[["Designation"]]), na.rm = TRUE)) {
  stop("O nivel do cargo contem valores ausentes ou nao inteiros.")
}

silver <- data.frame(
  id_colaborador = ids,
  data_admissao = datas,
  genero = traduzir(bronze[["Gender"]],
                    c(Female = "Feminino", Male = "Masculino"), "Gender"),
  tipo_empresa = traduzir(bronze[["Company Type"]],
                          c(Service = "Servico", Product = "Produto"), "Company Type"),
  home_office_disponivel = traduzir(bronze[["WFH Setup Available"]],
                                    c(Yes = "Sim", No = "Nao"), "WFH Setup Available"),
  nivel_cargo = as.integer(bronze[["Designation"]]),
  alocacao_recursos = bronze[["Resource Allocation"]],
  fadiga_mental = bronze[["Mental Fatigue Score"]],
  taxa_burnout = bronze[["Burn Rate"]],
  stringsAsFactors = FALSE
)

# Auditoria antes do tratamento: os valores ausentes do alvo sao preservados.
nulos_alocacao <- sum(is.na(silver$alocacao_recursos))
nulos_fadiga <- sum(is.na(silver$fadiga_mental))
nulos_alvo <- sum(is.na(silver$taxa_burnout))

# Registrar quais preditores foram originalmente imputados.
silver$alocacao_recursos_imputada <- is.na(silver$alocacao_recursos)
silver$fadiga_mental_imputada <- is.na(silver$fadiga_mental)
silver$taxa_burnout_disponivel <- !is.na(silver$taxa_burnout)

# Imputar apenas preditores com mediana por (tipo de empresa, nivel do cargo),
# usando a mediana geral como alternativa, sem consultar a taxa de burnout.
imputar_mediana_por_grupo <- function(x, grupos) {
  mediana_geral <- median(x, na.rm = TRUE)
  if (!is.finite(mediana_geral)) stop("Sem valores suficientes para imputacao.")
  resultado <- x
  for (grupo in unique(grupos)) {
    idx <- which(grupos == grupo)
    mediana_grupo <- median(x[idx], na.rm = TRUE)
    if (!is.finite(mediana_grupo)) mediana_grupo <- mediana_geral
    idx_ausentes <- idx[is.na(resultado[idx])]
    resultado[idx_ausentes] <- mediana_grupo
  }
  resultado
}

grupos <- paste(silver$tipo_empresa, silver$nivel_cargo, sep = "|")
silver$alocacao_recursos <- imputar_mediana_por_grupo(silver$alocacao_recursos, grupos)
silver$fadiga_mental <- imputar_mediana_por_grupo(silver$fadiga_mental, grupos)

# Regras de dominio baseadas nos valores e na documentacao das colunas.
validacoes <- data.frame(
  verificacao = c("nivel_cargo fora de 0 a 5",
                  "alocacao_recursos fora de 1 a 10",
                  "fadiga_mental fora de 0 a 10",
                  "taxa_burnout fora de 0 a 1",
                  "preditores numericos ainda ausentes",
                  "IDs duplicados"),
  quantidade = c(
    sum(silver$nivel_cargo < 0 | silver$nivel_cargo > 5, na.rm = TRUE),
    sum(silver$alocacao_recursos < 1 | silver$alocacao_recursos > 10, na.rm = TRUE),
    sum(silver$fadiga_mental < 0 | silver$fadiga_mental > 10, na.rm = TRUE),
    sum(silver$taxa_burnout < 0 | silver$taxa_burnout > 1, na.rm = TRUE),
    sum(is.na(silver$alocacao_recursos)) + sum(is.na(silver$fadiga_mental)),
    sum(duplicated(silver$id_colaborador))
  ),
  stringsAsFactors = FALSE
)
if (any(validacoes$quantidade > 0)) {
  print(validacoes)
  stop("Validacoes falharam. Nenhuma Silver foi exportada.")
}

relatorio <- data.frame(
  indicador = c("Registros na Bronze Kaggle (train.csv)",
                "Registros na Silver Kaggle", "IDs distintos",
                "Duplicatas exatas identificadas",
                "Nulos originais em alocacao_recursos",
                "Nulos originais em fadiga_mental",
                "Nulos originais em taxa_burnout",
                "Valores imputados em alocacao_recursos",
                "Valores imputados em fadiga_mental",
                "Taxa burnout observada (disponivel)",
                "Taxa burnout ausente (preservada)"),
  valor = c(nrow(bronze), nrow(silver), length(unique(silver$id_colaborador)),
            sum(duplicated(bronze)), nulos_alocacao, nulos_fadiga, nulos_alvo,
            sum(silver$alocacao_recursos_imputada),
            sum(silver$fadiga_mental_imputada),
            sum(silver$taxa_burnout_disponivel),
            sum(!silver$taxa_burnout_disponivel)),
  stringsAsFactors = FALSE
)

# So gera os novos arquivos Kaggle; nao sobrescreve a Silver simulada anterior.
dir.create(dirname(arquivo_silver), recursive = TRUE, showWarnings = FALSE)
dir.create(pasta_resultados, recursive = TRUE, showWarnings = FALSE)
readr::write_csv(silver, arquivo_silver, na = "")
readr::write_csv(relatorio,
                 file.path(pasta_resultados, "relatorio_qualidade_silver_kaggle.csv"))
readr::write_csv(validacoes,
                 file.path(pasta_resultados, "validacoes_silver_kaggle.csv"))

cat("\nSilver Kaggle criada com sucesso!\n")
cat("Bronze Kaggle:", nrow(bronze), "registros\n")
cat("Silver Kaggle:", nrow(silver), "registros\n")
cat("IDs distintos:", length(unique(silver$id_colaborador)), "\n")
cat("Alocacao de recursos imputada:", nulos_alocacao, "\n")
cat("Fadiga mental imputada:", nulos_fadiga, "\n")
cat("Burn Rate disponivel:", sum(silver$taxa_burnout_disponivel), "\n")
cat("Burn Rate ausente (preservado):", nulos_alvo, "\n")
cat("Arquivo:", arquivo_silver, "\n")
cat("Auditorias:", pasta_resultados, "\n")
