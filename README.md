# Projeto de Infraestrutura com Terraform e Docker

Este projeto configura uma infraestrutura na AWS utilizando Terraform e Docker. Ele inclui a criação de um repositório ECR, um cluster ECS, e a implantação de um contêiner Nginx customizado.

## Estrutura do Projeto

- `.github/workflows/terraform-pipeline.yml`: Configuração do GitHub Actions para automatizar o pipeline de Terraform.
- `docker/nginx.conf`: Arquivo de configuração do Nginx.
- `docker/Dockerfile`: Dockerfile para construir a imagem do Nginx.
- `main.tf`: Arquivo principal do Terraform para configurar a infraestrutura na AWS.

## Pré-requisitos

- Conta na AWS com permissões adequadas.
- Terraform instalado.
- Docker instalado.
- Configuração das credenciais AWS no GitHub Secrets (`AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY`).

## Configuração do Pipeline

O arquivo `.github/workflows/terraform-pipeline.yml` define um pipeline de CI/CD que executa as seguintes etapas:

1. Checkout do repositório.
2. Configuração do Terraform.
3. Configuração das credenciais AWS.
4. Inicialização do Terraform.
5. Planejamento da infraestrutura.
6. Aplicação das mudanças na infraestrutura.

## Configuração do Docker

O arquivo `docker/nginx.conf` define a configuração do Nginx, e o `Dockerfile` constrói a imagem Docker com base no Nginx e copia a configuração customizada.

## Configuração do Terraform

O arquivo `main.tf` configura os seguintes recursos na AWS:

- **Provider AWS**: Define a região AWS.
- **Backend S3**: Configura o backend S3 para armazenar o estado do Terraform.
- **Repositório ECR**: Cria um repositório ECR para armazenar a imagem Docker.
- **Cluster ECS**: Cria um cluster ECS.
- **IAM Roles**: Define as roles necessárias para execução das tasks ECS.
- **Task Definition**: Define a task ECS com a imagem Docker.
- **Service ECS**: Cria um serviço ECS com balanceamento de carga.
- **Load Balancer**: Configura um Application Load Balancer.
- **Security Group**: Define regras de segurança para o Load Balancer.
- **Auto Scaling**: Configura políticas de auto scaling para o serviço ECS.

## Como Executar

1. Clone o repositório:
    ```sh
    git clone <URL_DO_REPOSITORIO>
    cd <NOME_DO_REPOSITORIO>
    ```

2. Configure suas credenciais AWS:
    ```sh
    export AWS_ACCESS_KEY_ID=<SEU_ACCESS_KEY_ID>
    export AWS_SECRET_ACCESS_KEY=<SEU_SECRET_ACCESS_KEY>
    ```

3. Inicialize e aplique o Terraform:
    ```sh
    terraform init
    terraform apply -auto-approve
    ```

4. Construa e envie a imagem Docker:
    ```sh
    docker build -t custom_nginx_image:latest ./docker
    docker tag custom_nginx_image:latest <URL_DO_REPOSITORIO_ECR>:latest
    docker push <URL_DO_REPOSITORIO_ECR>:latest
    ```

## Licença

Este projeto está licenciado sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
