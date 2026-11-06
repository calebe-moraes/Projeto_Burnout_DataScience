# ============================================================
# Projeto Burnout - Analise Exploratoria de Dados (AED) em R
# Entrada: data/silver/dados_burnout_tratados.csv
# Saidas: resultados_r/
# ============================================================

pacotes <- c("readr", "dplyr", "tidyr", "ggplot2")
faltantes <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes) > 0) {
  stop("Instale os pacotes faltantes: ",
       paste(faltantes, collapse = ", "))
}

library(dplyr)
library(ggplot2)

arquivo_silver <- file.path("data", "silver", "dados_burnout_tratados.csv")
pasta_resultados <- "resultados_r"
if (!file.exists(arquivo_silver)) {
  stop("Silver nao encontrada. Execute primeiro analise_r/01_construir_silver.R.")
}
dir.create(pasta_resultados, recursive = TRUE, showWarnings = FALSE)

silver <- readr::read_csv(arquivo_silver, show_col_types = FALSE)

# Estatisticas descritivas gerais.
variaveis_numericas <- c(
  "horas_extras", "horas_trabalhadas",
  "tickets_fora_horario", "nivel_clima"
)

estatisticas <- silver %>%
  summarise(
    across(
      all_of(variaveis_numericas),
      list(
        media = ~mean(.x, na.rm = TRUE),
        mediana = ~median(.x, na.rm = TRUE),
        desvio_padrao = ~sd(.x, na.rm = TRUE),
        minimo = ~min(.x, na.rm = TRUE),
        q1 = ~quantile(.x, 0.25, na.rm = TRUE),
        q3 = ~quantile(.x, 0.75, na.rm = TRUE),
        maximo = ~max(.x, na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    )
  )
readr::write_csv(estatisticas, file.path(pasta_resultados, "estatisticas_gerais.csv"))

# Resumo por departamento.
resumo_departamento <- silver %>%
  group_by(departamento) %>%
  summarise(
    colaboradores = n_distinct(id_colaborador),
    media_horas_extras = mean(horas_extras, na.rm = TRUE),
    mediana_horas_extras = median(horas_extras, na.rm = TRUE),
    media_horas_trabalhadas = mean(horas_trabalhadas, na.rm = TRUE),
    media_tickets_fora_horario = mean(tickets_fora_horario, na.rm = TRUE),
    media_nivel_clima = mean(nivel_clima, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(media_horas_extras))
readr::write_csv(resumo_departamento,
                 file.path(pasta_resultados, "resumo_por_departamento_r.csv"))

# Matriz de correlacao: associacao linear, nao causalidade.
matriz_correlacao <- cor(
  silver %>% select(all_of(variaveis_numericas)),
  use = "pairwise.complete.obs",
  method = "pearson"
)
readr::write_csv(
  as.data.frame(matriz_correlacao) %>% tibble::rownames_to_column("variavel"),
  file.path(pasta_resultados, "matriz_correlacao.csv")
)

# Graficos.
p1 <- ggplot(silver, aes(x = horas_extras)) +
  geom_histogram(binwidth = 2, boundary = 0, color = "white") +
  labs(
    title = "Distribuicao de horas extras",
    x = "Horas extras",
    y = "Quantidade de colaboradores"
  ) +
  theme_minimal()

ggsave(file.path(pasta_resultados, "01_distribuicao_horas_extras.png"),
       p1, width = 8, height = 5, dpi = 300)

p2 <- ggplot(silver, aes(x = reorder(departamento, horas_extras, FUN = median),
                         y = horas_extras)) +
  geom_boxplot() +
  coord_flip() +
  labs(
    title = "Horas extras por departamento",
    x = "Departamento",
    y = "Horas extras"
  ) +
  theme_minimal()

ggsave(file.path(pasta_resultados, "02_horas_extras_por_departamento.png"),
       p2, width = 8, height = 5, dpi = 300)

p3 <- ggplot(silver, aes(x = tickets_fora_horario, y = nivel_clima)) +
  geom_jitter(alpha = 0.35, width = 0.15, height = 0.15) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(
    title = "Chamados fora do horario e nivel de clima",
    subtitle = "Associacao exploratoria; nao indica causalidade",
    x = "Tickets fora do horario",
    y = "Nivel de clima (0 a 10)"
  ) +
  theme_minimal()

ggsave(file.path(pasta_resultados, "03_tickets_vs_clima.png"),
       p3, width = 8, height = 5, dpi = 300)

cat("\nAED concluida.\n")
cat("Registros analisados:", nrow(silver), "\n")
cat("Departamentos:", dplyr::n_distinct(silver$departamento), "\n")
cat("Resultados salvos em:", pasta_resultados, "\n")
