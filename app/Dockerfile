# Etapa 1: Usando GraalVM para compilar o binário nativo
FROM ghcr.io/graalvm/graalvm-community:21 AS builder

# Definir o diretório de trabalho para o código-fonte
WORKDIR /workspace/app

# Copiar o código fonte e os arquivos de configuração para o container
COPY . .

# Garantir permissões para o Maven Wrapper (mvnw)
RUN chmod +x mvnw

# Rodar o Maven para compilar o binário nativo
RUN ./mvnw -Pnative clean install -DskipTests

# Verificar o conteúdo da pasta após o build
RUN ls -l /workspace/app/

# Etapa 2: Usando Amazon Linux 2 para rodar o binário nativo
FROM amazonlinux:latest

# Instalar as dependências necessárias para rodar o binário nativo
RUN yum update -y && yum install -y libstdc++ file && yum clean all

# Definir o diretório de trabalho no container final
WORKDIR /app

# Copiar o binário nativo gerado da etapa anterior
COPY --from=builder /workspace/app/spring-native /app/application

# Verificar se o arquivo foi copiado corretamente
RUN ls -l /app

# Verificar o formato do binário
RUN file /app/application

# Dar permissões de execução ao binário
RUN chmod +x /app/application

# Definir o entrypoint para rodar o binário nativo
ENTRYPOINT ["/app/application"]

# Expor a porta 8080 (ou qualquer porta configurada na aplicação)
EXPOSE 8080