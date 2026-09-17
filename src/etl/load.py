from sqlalchemy import create_engine, text


def load():
    print("Iniciando etapa de carregamento dos dados...")

    conexao = (
        "postgresql+psycopg2://"
        "grupo6:burnout123@db:5432/dw_burnout"
    )

    engine = create_engine(conexao)

    with engine.connect() as connection:
        print("Conexão com PostgreSQL realizada com sucesso!")

        connection.execute(text("""
            CREATE TABLE IF NOT EXISTS controle_etl (
                id SERIAL PRIMARY KEY,
                etapa VARCHAR(50) NOT NULL,
                status VARCHAR(50) NOT NULL
            )
        """))

        connection.commit()

        print("Tabela controle_etl criada com sucesso!")

    print("Carregamento executado com sucesso!")


if __name__ == "__main__":
    load()