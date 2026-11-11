# ============================================================
# Projeto Burnout - UNIFEOB / Grupo 6
# Etapa 3: Analise Exploratoria de Dados (AED) - Kaggle
#
# Entrada: data/silver/dados_burnout_kaggle_tratados.csv
# Saidas:  resultados_r/kaggle/
#
# A taxa_burnout ausente e mantida ausente; calculos que dependem
# dela usam somente as observacoes com alvo disponivel.
# ============================================================

pacotes <- c("readr", "dplyr", "ggplot2", "tibble")
faltantes <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes) > 0L) {
  stop("Instale os pacotes ausentes: ", paste(faltantes, collapse = ", "))
}

library(dplyr)
library(ggplot2)

arquivo_silver <- file.path("data", "silver", "dados_burnout_kaggle_tratados.csv")
pasta_resultados <- file.path("resultados_r", "kaggle")

if (!file.exists(arquivo_silver)) {
  stop("Silver Kaggle nao encontrada em ", arquivo_silver,
       ". Execute antes analise_r/01_construir_silver_kaggle.R na raiz do projeto.")
}

silver <- readr::read_csv(arquivo_silver, show_col_types = FALSE)
colunas_necessarias <- c(
  "id_colaborador", "tipo_empresa", "home_office_disponivel", "nivel_cargo",
  "alocacao_recursos", "fadiga_mental", "taxa_burnout"
)
ausentes <- setdiff(colunas_necessarias, names(silver))
if (length(ausentes) > 0L) {
  stop("Colunas ausentes na Silver Kaggle: ", paste(ausentes, collapse = ", "))
}
if (anyDuplicated(silver$id_colaborador) > 0L) {
  stop("A Silver Kaggle contem IDs repetidos. Revise a etapa anterior.")
}
if (any(is.na(silver$alocacao_recursos)) || any(is.na(silver$fadiga_mental))) {
  stop("Ainda ha ausencias nos preditores numericos. Revise a etapa anterior.")
}
if (any(silver$taxa_burnout < 0 | silver$taxa_burnout > 1, na.rm = TRUE)) {
  stop("taxa_burnout contem valores fora da faixa de 0 a 1.")
}

# Os relatorios e graficos novos ficam em uma pasta exclusiva do Kaggle.
dir.create(pasta_resultados, recursive = TRUE, showWarnings = FALSE)

# 1. Estatisticas descritivas, sem imputar a variavel-alvo.
variaveis_numericas <- c("nivel_cargo", "alocacao_recursos", "fadiga_mental", "taxa_burnout")
estatisticas <- lapply(variaveis_numericas, function(nome) {
  x <- silver[[nome]]
  validos <- x[!is.na(x)]
  data.frame(
    variavel = nome,
    total_registros = length(x),
    valores_disponiveis = length(validos),
    valores_ausentes = sum(is.na(x)),
    media = mean(validos),
    mediana = median(validos),
    desvio_padrao = sd(validos),
    minimo = min(validos),
    q1 = unname(quantile(validos, 0.25)),
    q3 = unname(quantile(validos, 0.75)),
    maximo = max(validos)
  )
})
estatisticas <- dplyr::bind_rows(estatisticas)
readr::write_csv(estatisticas, file.path(pasta_resultados, "estatisticas_gerais_kaggle.csv"))

# 2. Resumos por categorias. A media de Burn Rate considera apenas
# colaboradores com taxa_burnout observada (NA ignorado).
resumo_por_grupo <- function(coluna) {
  silver %>%
    group_by(.data[[coluna]]) %>%
    summarise(
      colaboradores = n(),
      burn_rate_disponivel = sum(!is.na(taxa_burnout)),
      burn_rate_ausente = sum(is.na(taxa_burnout)),
      media_taxa_burnout = mean(taxa_burnout, na.rm = TRUE),
      mediana_taxa_burnout = median(taxa_burnout, na.rm = TRUE),
      media_fadiga_mental = mean(fadiga_mental, na.rm = TRUE),
      media_alocacao_recursos = mean(alocacao_recursos, na.rm = TRUE),
      .groups = "drop"
    )
}
readr::write_csv(resumo_por_grupo("tipo_empresa"),
                 file.path(pasta_resultados, "resumo_por_tipo_empresa_kaggle.csv"))
readr::write_csv(resumo_por_grupo("home_office_disponivel"),
                 file.path(pasta_resultados, "resumo_por_home_office_kaggle.csv"))
readr::write_csv(resumo_por_grupo("nivel_cargo"),
                 file.path(pasta_resultados, "resumo_por_nivel_cargo_kaggle.csv"))

# 3. Correlacao de Pearson (associacao linear; nao indica causalidade).
# Correlacoes com taxa_burnout ignoram as observacoes sem esse alvo.
matriz_correlacao <- cor(
  as.data.frame(silver[variaveis_numericas]),
  use = "pairwise.complete.obs",
  method = "pearson"
)
readr::write_csv(
  tibble::rownames_to_column(as.data.frame(matriz_correlacao), "variavel"),
  file.path(pasta_resultados, "matriz_correlacao_kaggle.csv")
)

# A analise visual do alvo nao deve incluir linhas sem Burn Rate.
com_alvo <- silver %>% filter(!is.na(taxa_burnout))
if (nrow(com_alvo) == 0L) stop("Nao ha registros com Burn Rate observado.")

p1 <- ggplot(com_alvo, aes(x = taxa_burnout)) +
  geom_histogram(binwidth = 0.05, boundary = 0, color = "white") +
  labs(
    title = "Distribuicao de Burn Rate (Kaggle)",
    subtitle = "Somente registros com Burn Rate disponivel",
    x = "Burn Rate (0 a 1)",
    y = "Numero de colaboradores"
  ) + theme_minimal()
ggsave(file.path(pasta_resultados, "01_distribuicao_burn_rate.png"),
       p1, width = 8, height = 5, dpi = 300)

p2 <- ggplot(com_alvo, aes(x = fadiga_mental, y = taxa_burnout)) +
  geom_point(alpha = 0.10, size = 0.7) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Fadiga mental e Burn Rate (Kaggle)",
    subtitle = "Associacao exploratoria; nao estabelece causalidade",
    x = "Pontuacao de fadiga mental",
    y = "Burn Rate (0 a 1)"
  ) + theme_minimal()
ggsave(file.path(pasta_resultados, "02_fadiga_vs_burn_rate.png"),
       p2, width = 8, height = 5, dpi = 300)

p3 <- ggplot(com_alvo, aes(x = tipo_empresa, y = taxa_burnout)) +
  geom_boxplot() +
  labs(
    title = "Burn Rate por tipo de empresa (Kaggle)",
    x = "Tipo de empresa",
    y = "Burn Rate (0 a 1)"
  ) + theme_minimal()
ggsave(file.path(pasta_resultados, "03_burn_rate_por_tipo_empresa.png"),
       p3, width = 8, height = 5, dpi = 300)

p4 <- ggplot(com_alvo, aes(x = factor(nivel_cargo), y = taxa_burnout)) +
  geom_boxplot() +
  labs(
    title = "Burn Rate por nivel de cargo (Kaggle)",
    x = "Nivel do cargo",
    y = "Burn Rate (0 a 1)"
  ) + theme_minimal()
ggsave(file.path(pasta_resultados, "04_burn_rate_por_nivel_cargo.png"),
       p4, width = 8, height = 5, dpi = 300)

cat("\nAED Kaggle concluida com sucesso!\n")
cat("Total de registros:", nrow(silver), "\n")
cat("Registros com Burn Rate:", nrow(com_alvo), "\n")
cat("Registros sem Burn Rate:", sum(is.na(silver$taxa_burnout)), "\n")
cat("Relatorios e graficos:", pasta_resultados, "\n")
