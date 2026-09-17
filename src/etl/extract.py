from pathlib import Path


def extract():
    print("Iniciando etapa de extração dos dados...")

    pasta_bronze = Path("data/bronze")
    pasta_bronze.mkdir(parents=True, exist_ok=True)

    print(f"Pasta Bronze preparada: {pasta_bronze}")

    print("Extração executada com sucesso!")


if __name__ == "__main__":
    extract()