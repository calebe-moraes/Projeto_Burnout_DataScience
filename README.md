# Projeto Burnout

## Monitoramento de Clima Organizacional e Prevenção Preditiva de Burnout Operacional

Projeto Integrado desenvolvido pelo **Grupo 6 — UNIFEOB**, para a disciplina de **Análise de Dados**.

---

## Integrantes

| RA | Nome |
|---|---|
| 24000974 | Calebe Matheus Moreira Moraes |
| 24001964 | Leandro Jose de Carvalho Coelho |
| 24000092 | Lucas Vigo Calio |
| 24000308 | Mateus Oliveira Milane |

---

## Sobre o projeto

O **Projeto Burnout** consiste no desenvolvimento de uma plataforma de inteligência de dados voltada ao **Capital Humano**, com o objetivo de utilizar dados operacionais para identificar sinais relacionados à sobrecarga e exaustão dos colaboradores.

A solução trabalha com indicadores como:

- Horas extras;
- Marcações de ponto;
- Tickets e atividades realizados fora do horário de trabalho;
- Dados de pesquisas de clima organizacional.

A partir desses dados, o projeto busca calcular indicadores de exaustão e estimar o risco de **burnout e turnover por departamento**, possibilitando a identificação de situações que possam exigir atenção preventiva.

O projeto também está relacionado ao **ODS 8 — Trabalho Decente e Crescimento Econômico**, da Organização das Nações Unidas.

> **Nota:** por se tratar de uma atividade acadêmica, os dados utilizados neste projeto são fictícios/simulados e destinados exclusivamente a fins de estudo e demonstração.

---

## Objetivos

O projeto tem como principais objetivos:

- Organizar e processar dados relacionados ao clima organizacional;
- Identificar padrões e indicadores de exaustão;
- Estruturar os dados utilizando conceitos de Data Lake e Data Warehouse;
- Aplicar técnicas de análise de dados;
- Preparar uma infraestrutura reproduzível utilizando Docker;
- Disponibilizar um ambiente padronizado para execução do projeto;
- Gerar dados brutos simulados para utilização nas etapas de análise e tratamento.

---

## Etapas do projeto

O desenvolvimento do projeto está organizado nas seguintes etapas:

### 1. Análise Exploratória de Dados (AED)

Análise dos dados para identificação de padrões, tendências, distribuições, correlações e possíveis pontos fora do comportamento esperado.

**Relatório:**

`docs/relatorios/AED_Burnout_Relatorio_Completo.pdf`

### 2. Data Warehouse e Data Lake

Organização dos dados nas camadas **Bronze, Silver e Gold**, além da estruturação do modelo dimensional utilizado no projeto.

**Relatório:**

`docs/relatorios/DW_DL_Burnout_Relatorio.pdf`

### 3. DevOps — Infraestrutura e Ambiente Reproduzível

Preparação e padronização do ambiente de execução utilizando **Docker, Docker Compose, Python e PostgreSQL**, permitindo que a infraestrutura seja criada e reconstruída de maneira padronizada.

**Relatório:**

`docs/relatorios/DevOps_Infraestrutura_Burnout_Relatorio.pdf`

### 4. DevOps — Simulador Gerador de Dados

Desenvolvimento de um simulador responsável pela geração automática dos dados brutos utilizados no projeto.

O simulador produz dados compatíveis com a situação-problema do projeto, incluindo informações relacionadas a:

- Colaboradores;
- Departamentos;
- Horas extras;
- Horas trabalhadas;
- Tickets realizados fora do horário;
- Horários de atendimento;
- Indicadores de clima organizacional.

Também são inseridos problemas de qualidade de forma controlada, como:

- Valores ausentes;
- Registros duplicados;
- Categorias divergentes;
- Formatos inconsistentes.

O simulador está localizado em:

`src/gerador/gerar_dados.py`

Para executar o simulador utilizando o ambiente Docker:

```bash
docker compose run --rm app python src/gerador/gerar_dados.py
```

---

## Checkpoint 01 — Infraestrutura privada com OpenTofu, cloud-init e Ansible

Uma VM Linux (Ubuntu 22.04) é criada **por código** na máquina hospedeira (Linux com KVM/libvirt). O simulador (`simulador/`) é transferido por SCP, executado **dentro da VM** e grava os dados em `/opt/burnout/dados/dados_burnout.csv`.

```
Hospedeira Linux ── OpenTofu ─▶ VM (libvirt/KVM) ◀── cloud-init (usuário + chave SSH)
        │                              ▲
        ├── Ansible (pacotes, venv, diretórios)
        └── SCP/SSH (simulador) ─▶ /opt/burnout ─▶ dados_burnout.csv
```

### Estrutura

```
infraestrutura/
  main.tf, variables.tf        OpenTofu (provider libvirt)
  cloud_init.cfg               cloud-init (usuário, SSH por chave, marcador)
  terraform.tfvars.example     modelo de variáveis locais
  ansible/                     inventory.ini, playbook.yml, ansible.cfg
  scripts/                     deploy.sh, executar.sh, verificar.sh
simulador/                     simulador.py, requirements.txt
dados/exemplo_dados.csv        amostra de saída do simulador
```

### Requisitos na máquina hospedeira (Linux Mint / Ubuntu)

- KVM/libvirt: `sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients` e `sudo usermod -aG libvirt $USER` (relogar)
- [OpenTofu](https://opentofu.org/docs/intro/install/) ≥ 1.6
- Ansible: `sudo apt install ansible`
- Cliente SSH (`openssh-client`) e um par de chaves: `ssh-keygen -t ed25519`

> Se o libvirt negar acesso ao disco da VM (AppArmor), defina `security_driver = "none"` em `/etc/libvirt/qemu.conf` e rode `sudo systemctl restart libvirtd`.

### Configuração local (nada sensível vai ao repositório)

```bash
cd infraestrutura
cp terraform.tfvars.example terraform.tfvars   # ajuste os caminhos das chaves, se necessário
```

Somente o caminho das chaves é configurado; a chave **pública** é injetada na VM e a **privada** nunca sai da máquina. `terraform.tfvars`, `*.tfstate` e chaves estão no `.gitignore`.

### Passo a passo

```bash
# 1. Provisionar a VM (OpenTofu + cloud-init)
cd infraestrutura
tofu init
tofu apply            # gera também ansible/inventory.ini com o IP da VM

# 2. Comprovar o cloud-init
./scripts/verificar.sh

# 3. Preparar o ambiente (Ansible) — pode ser repetido sem efeitos colaterais
cd ansible && ansible-playbook -i inventory.ini playbook.yml && cd ..

# 4. Transferir o simulador por SSH (SCP)
./scripts/deploy.sh

# 5. Executar na VM (cada execução acrescenta novos registros ao CSV)
./scripts/executar.sh 20
```

Para destruir o ambiente: `tofu destroy`.

### Simulador

Campos: `id_registro`, `id_colaborador`, `departamento`, `horas_extras`, `horas_trabalhadas`, `tickets_fora_horario`, `nivel_clima`, `risco_burnout`, `data_hora_geracao`. Gera no mínimo 10 registros por execução (padrão 20) e **acrescenta** ao CSV, preservando execuções anteriores. Teste local (sem VM):

```bash
pip install -r simulador/requirements.txt
python simulador/simulador.py --quantidade 15 --saida dados/exemplo_dados.csv
```

### Configuração do Docker (etapas anteriores)

Copie `.env.example` para `.env` e defina `POSTGRES_PASSWORD` antes de usar `docker compose`.
