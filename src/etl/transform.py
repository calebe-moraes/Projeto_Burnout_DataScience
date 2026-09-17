from pathlib import Path


def transform():
    print("Iniciando etapa de transformação dos dados...")

    pasta_silver = Path("data/silver")
    pasta_silver.mkdir(parents=True, exist_ok=True)

    print(f"Pasta Silver preparada: {pasta_silver}")

    print("Transformação executada com sucesso!")


if __name__ == "__main__":
    transform()