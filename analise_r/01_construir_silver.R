# ============================================================
# Projeto Burnout - Construcao da camada Silver
# Grupo 06 - UNIFEOB
#
# Entrada:
#   data/bronze/burnout_bruto.csv
#
# Saidas:
#   data/silver/dados_burnout_tratados.csv
#   resultados_r/auditoria_ids_duplicados.csv
#   resultados_r/relatorio_qualidade_silver.csv
#
# IMPORTANTE:
# - Nunca altera a Bronze.
# - Mantem um registro por id_colaborador.
# - Em IDs repetidos, prioriza a linha com mais campos preenchidos.
# - Imputa horas_extras e nivel_clima pela mediana do departamento.
# - horario_ticket ausente fica como "Nao informado"; nao inventa horario.
# ============================================================

pacotes <- c("readr", "dplyr", "stringr", "tidyr", "ggplot2")

faltantes <- pacotes[!vapply(pacotes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes) > 0) {
  stop(
    "Faltam pacotes: ", paste(faltantes, collapse = ", "),
    ". Instale com install.packages(c(",
    paste(sprintf('"%s"', faltantes), collapse = ", "),
    "))."
  )
}

library(dplyr)
library(stringr)

# Execute este script com o diretorio de trabalho na raiz do projeto.
arquivo_bronze <- file.path("data", "bronze", "burnout_bruto.csv")
arquivo_silver <- file.path("data", "silver", "dados_burnout_tratados.csv")
pasta_resultados <- "resultados_r"

if (!file.exists(arquivo_bronze)) {
  stop(
    "Nao encontrei ", arquivo_bronze,
    ". Coloque o CSV bruto nessa pasta ou ajuste 'arquivo_bronze' no script."
  )
}

dir.create(dirname(arquivo_silver), recursive = TRUE, showWarnings = FALSE)
dir.create(pasta_resultados, recursive = TRUE, showWarnings = FALSE)

# 1. Importacao: todos os dados sao lidos sem modificar o arquivo de origem.
bronze <- readr::read_csv(
  arquivo_bronze,
  na = c("", "NA", "N/A", "NULL", "null"),
  show_col_types = FALSE,
  name_repair = "minimal"
)

colunas_esperadas <- c(
  "id_colaborador", "nome", "departamento", "horas_extras",
  "horas_trabalhadas", "tickets_fora_horario", "horario_ticket",
  "nivel_clima"
)

ausentes <- setdiff(colunas_esperadas, names(bronze))
if (length(ausentes) > 0) {
  stop("Colunas ausentes na Bronze: ", paste(ausentes, collapse = ", "))
}

if (any(is.na(bronze$id_colaborador))) {
  stop("Existem IDs de colaborador ausentes. Corrija a origem antes de deduplicar.")
}

# 2. Padronizacao textual dos departamentos.
# A normalizacao ocorre antes da imputacao para agrupar corretamente os setores.
dados <- bronze %>%
  mutate(
    nome = str_squish(as.character(nome)),
    departamento_original = as.character(departamento),
    departamento_chave = str_to_lower(str_squish(as.character(departamento))),
    departamento = case_when(
      departamento_chave %in% c("ti", "tecnologia da informação",
                                "tecnologia da informacao") ~ "Tecnologia da Informação",
      departamento_chave %in% c("rh", "recursos humanos") ~ "Recursos Humanos",
      departamento_chave %in% c("operacoes", "operações") ~ "Operações",
      departamento_chave == "comercial" ~ "Comercial",
      departamento_chave == "financeiro" ~ "Financeiro",
      TRUE ~ NA_character_
    )
  )

if (any(is.na(dados$departamento))) {
  valores <- unique(dados$departamento_original[is.na(dados$departamento)])
  stop(
    "Departamento nao reconhecido: ", paste(valores, collapse = "; "),
    ". Nao descartei essas linhas; revise o mapeamento no script."
  )
}

# 3. Auditoria de duplicatas antes de removê-las.
duplicatas_id <- dados %>%
  group_by(id_colaborador) %>%
  filter(n() > 1) %>%
  mutate(
    quantidade_registros_id = n(),
    campos_preenchidos = rowSums(!is.na(pick(all_of(setdiff(colunas_esperadas, "id_colaborador")))))
  ) %>%
  ungroup() %>%
  arrange(id_colaborador, desc(campos_preenchidos))

readr::write_csv(
  duplicatas_id,
  file.path(pasta_resultados, "auditoria_ids_duplicados.csv")
)

# 4. Remocao de duplicatas exatas e resolucao de IDs repetidos.
# Em caso de empate na completude, mantem a primeira ocorrencia da Bronze.
dados_sem_duplicatas_exatas <- dados %>% distinct()

dados_unicos <- dados_sem_duplicatas_exatas %>%
  mutate(campos_preenchidos = rowSums(!is.na(across(all_of(colunas_esperadas))))) %>%
  arrange(id_colaborador, desc(campos_preenchidos)) %>%
  distinct(id_colaborador, .keep_all = TRUE) %>%
  select(-campos_preenchidos, -departamento_chave, -departamento_original)

# 5. Conversao e validacao de tipos.
colunas_numericas <- c(
  "horas_extras", "horas_trabalhadas",
  "tickets_fora_horario", "nivel_clima"
)

dados_unicos <- dados_unicos %>%
  mutate(
    across(all_of(colunas_numericas), as.numeric),
    id_colaborador = as.integer(id_colaborador),
    horario_ticket = str_to_lower(str_trim(as.character(horario_ticket))),
    horario_ticket = str_replace(horario_ticket, "^(\\d{1,2})h(\\d{2})$", "\\1:\\2")
  )

# 6. Imputacao pela mediana do departamento; fallback para mediana geral.
imputar_mediana_departamento <- function(x, departamento) {
  mediana_geral <- median(x, na.rm = TRUE)
  if (!is.finite(mediana_geral)) {
    stop("Nao ha valores validos suficientes para calcular a mediana geral.")
  }

  resultado <- x
  grupos <- unique(departamento)

  for (grupo in grupos) {
    idx <- which(departamento == grupo)
    mediana_grupo <- median(x[idx], na.rm = TRUE)

    if (!is.finite(mediana_grupo)) {
      mediana_grupo <- mediana_geral
    }

    faltantes_grupo <- idx[is.na(x[idx])]
    resultado[faltantes_grupo] <- mediana_grupo
  }

  resultado
}

n_horas_antes <- sum(is.na(dados_unicos$horas_extras))
n_clima_antes <- sum(is.na(dados_unicos$nivel_clima))
n_horario_antes <- sum(is.na(dados_unicos$horario_ticket) |
                         dados_unicos$horario_ticket == "")

dados_silver <- dados_unicos %>%
  mutate(
    horas_extras = imputar_mediana_departamento(horas_extras, departamento),
    nivel_clima = imputar_mediana_departamento(nivel_clima, departamento),
    horario_ticket = if_else(
      is.na(horario_ticket) | horario_ticket == "",
      "Nao informado",
      horario_ticket
    )
  )

# 7. Validacoes de faixa. Valores suspeitos sao sinalizados, nao apagados.
validacoes <- tibble::tibble(
  verificacao = c(
    "horas_extras negativas",
    "horas_trabalhadas menores ou iguais a zero",
    "tickets_fora_horario negativos",
    "nivel_clima fora de 0 a 10",
    "horarios com formato inesperado"
  ),
  quantidade = c(
    sum(dados_silver$horas_extras < 0, na.rm = TRUE),
    sum(dados_silver$horas_trabalhadas <= 0, na.rm = TRUE),
    sum(dados_silver$tickets_fora_horario < 0, na.rm = TRUE),
    sum(dados_silver$nivel_clima < 0 | dados_silver$nivel_clima > 10, na.rm = TRUE),
    sum(
      dados_silver$horario_ticket != "Nao informado" &
        !str_detect(dados_silver$horario_ticket,
                    "^([01]?[0-9]|2[0-3]):[0-5][0-9]$"),
      na.rm = TRUE
    )
  )
)

# 8. Relatorio de qualidade antes/depois.
relatorio <- tibble::tibble(
  indicador = c(
    "Registros na Bronze",
    "Duplicatas exatas removidas",
    "Registros apos remocao de duplicatas exatas",
    "IDs repetidos resolvidos (registros excedentes)",
    "Registros finais na Silver",
    "IDs distintos na Silver",
    "Nulos originais em horas_extras apos deduplicacao",
    "Nulos originais em nivel_clima apos deduplicacao",
    "Nulos originais em horario_ticket apos deduplicacao",
    "Valores imputados em horas_extras",
    "Valores imputados em nivel_clima",
    "Horarios substituidos por Nao informado"
  ),
  valor = c(
    nrow(bronze),
    nrow(bronze) - nrow(bronze %>% distinct()),
    nrow(dados_sem_duplicatas_exatas),
    nrow(dados_sem_duplicatas_exatas) - nrow(dados_unicos),
    nrow(dados_silver),
    dplyr::n_distinct(dados_silver$id_colaborador),
    n_horas_antes,
    n_clima_antes,
    n_horario_antes,
    n_horas_antes,
    n_clima_antes,
    n_horario_antes
  )
)

readr::write_csv(
  relatorio,
  file.path(pasta_resultados, "relatorio_qualidade_silver.csv")
)
readr::write_csv(
  validacoes,
  file.path(pasta_resultados, "validacoes_faixa_silver.csv")
)

# 9. Exportacao: cria/atualiza somente o arquivo de saida Silver.
readr::write_csv(dados_silver, arquivo_silver, na = "")

cat("\nSilver criada com sucesso!\n")
cat("Bronze:", nrow(bronze), "registros\n")
cat("Silver:", nrow(dados_silver), "registros\n")
cat("IDs distintos:", dplyr::n_distinct(dados_silver$id_colaborador), "\n")
cat("Arquivo:", arquivo_silver, "\n")
cat("Auditorias e relatorios salvos em:", pasta_resultados, "\n")

if (nrow(dados_silver) != dplyr::n_distinct(dados_silver$id_colaborador)) {
  stop("A Silver ainda possui IDs repetidos. Verifique a auditoria.")
}
