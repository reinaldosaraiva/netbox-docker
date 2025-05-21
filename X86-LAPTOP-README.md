# Migrando NetBox para laptop x86

Este guia explica como migrar a stack NetBox de um laptop ARM (Apple Silicon) para um laptop x86.

## Requisitos no laptop x86:

- Docker 20.10.10 ou superior
- Docker Compose 1.28.0 ou superior
- Git (opcional, mas recomendado)

## Opções de migração

### Opção 1: Clone direto do GitHub (recomendado para iniciar do zero)

Esta é a opção mais simples se você só precisa da estrutura básica do NetBox, sem dados específicos.

```bash
# Clone o repositório
git clone -b release https://github.com/netbox-community/netbox-docker.git
cd netbox-docker

# Crie o docker-compose.override.yml
cat > docker-compose.override.yml << EOF
services:
  netbox:
    ports:
      - "8000:8080"
EOF

# Inicie os contêineres
docker compose up -d
```

O NetBox iniciará com os dados de demonstração. Acesse http://localhost:8000 e faça login com:
- Usuário: admin
- Senha: admin

### Opção 2: Transferindo os arquivos do projeto

Se você transferiu o arquivo `netbox-project.tar.gz` do laptop ARM:

```bash
# Extraia o projeto
tar -xzvf netbox-backup/netbox-project.tar.gz

# Entre na pasta extraída
cd netbox-docker

# Inicie os contêineres
docker compose up -d
```

## Instalando o AWX (opcional)

Como o laptop x86 é compatível com as imagens do AWX, você pode adicionar o AWX à stack. Para isso, use o arquivo `docker-compose.override.yml`:

```yaml
services:
  netbox:
    ports:
      - "8000:8080"
    # Expor a API para que o AWX possa acessá-la
    environment:
      - CORS_ORIGIN_ALLOW_ALL=True

  # Usando uma versão mais simples do AWX para teste
  awx:
    image: ansible/awx:17.1.0
    container_name: awx_server
    hostname: awx
    ports:
      - "8053:8052"
    volumes:
      - awx-data:/var/lib/awx
    environment:
      - SECRET_KEY=awxsecret
      - DATABASE_NAME=awx
      - DATABASE_USER=awx
      - DATABASE_PASSWORD=awxpass
      - DATABASE_PORT=5432
      - DATABASE_HOST=awx-postgres
      - RABBITMQ_HOST=awx-rabbitmq
      - RABBITMQ_USER=admin
      - RABBITMQ_PASSWORD=adminpass
      - RABBITMQ_VHOST=awx
      - AWX_ADMIN_USER=admin
      - AWX_ADMIN_PASSWORD=password
    depends_on:
      - awx-postgres
      - awx-rabbitmq
    networks:
      - netbox-awx

  # PostgreSQL para o AWX
  awx-postgres:
    image: postgres:12
    container_name: awx_postgres
    volumes:
      - awx-postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=awx
      - POSTGRES_PASSWORD=awxpass
      - POSTGRES_DB=awx
    networks:
      - netbox-awx

  # RabbitMQ para o AWX
  awx-rabbitmq:
    image: rabbitmq:3.8-management
    container_name: awx_rabbitmq
    environment:
      - RABBITMQ_DEFAULT_USER=admin
      - RABBITMQ_DEFAULT_PASS=adminpass
      - RABBITMQ_DEFAULT_VHOST=awx
    volumes:
      - awx-rabbitmq-data:/var/lib/rabbitmq
    networks:
      - netbox-awx

volumes:
  awx-data:
    driver: local
  awx-postgres-data:
    driver: local
  awx-rabbitmq-data:
    driver: local

networks:
  netbox-awx:
    driver: bridge
```

## Importação/Exportação de dados (opcional)

Se necessário migrar dados específicos entre as instâncias:

1. No NetBox de origem (ARM), exporte os dados:
   - Acesse Admin > Data Management > Export Data
   - Selecione os modelos que deseja exportar
   - Download do arquivo JSON

2. No NetBox de destino (x86):
   - Acesse Admin > Data Management > Import Data
   - Carregue o arquivo JSON exportado
   - Importe os dados

## Notas importantes

1. **Volumes Docker**: Os volumes do Docker são específicos para cada host e não são transferidos neste processo.
2. **Banco de dados**: Se você precisar transferir o banco de dados completo entre arquiteturas diferentes (ARM para x86), será necessário usar um backup/restore PostgreSQL.
3. **Arquivos de mídia**: Você pode transferir manualmente os arquivos de mídia entre os sistemas, caso necessário.

## Verificação

Após iniciar o NetBox no laptop x86:

1. Acesse http://localhost:8000
2. Faça login com as credenciais (admin/admin para instalação nova)
3. Verifique se o NetBox está funcionando corretamente

Para o AWX (se instalado):
1. Acesse http://localhost:8053
2. Faça login com admin/password
3. Configure a integração com o NetBox seguindo a documentação