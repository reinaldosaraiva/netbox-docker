#!/bin/bash
# Script para configurar o AWX no laptop x86

# Verificar se estamos em um sistema x86_64
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]]; then
  echo "AVISO: Este script foi projetado para sistemas x86_64!"
  echo "Seu sistema é: $ARCH"
  echo "Continuar? (y/n)"
  read answer
  if [[ "$answer" != "y" ]]; then
    exit 1
  fi
fi

# Criar estrutura de diretórios
mkdir -p awx-config

# Criar docker-compose.override.yml com suporte a AWX
cat > docker-compose.override.yml << 'EOF'
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
EOF

# Criar arquivos de configuração do AWX
echo "awxsecret12345" > awx-config/SECRET_KEY

cat > awx-config/environment.sh << 'EOF'
DATABASE_USER=awx
DATABASE_PASSWORD=awxpass
DATABASE_NAME=awx
DATABASE_PORT=5432
DATABASE_HOST=awx-postgres
RABBITMQ_HOST=awx-rabbitmq
RABBITMQ_USER=admin
RABBITMQ_PASSWORD=adminpass
RABBITMQ_VHOST=awx
EOF

cat > awx-config/credentials.py << 'EOF'
DATABASES = {
    'default': {
        'ATOMIC_REQUESTS': True,
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': "awx",
        'USER': "awx",
        'PASSWORD': "awxpass",
        'HOST': "awx-postgres",
        'PORT': "5432",
    }
}

BROKER_URL = 'redis://:awxredis@awx-redis:6379/0'
CHANNEL_LAYER = {
    'hosts': ['redis://:awxredis@awx-redis:6379/0'],
}
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': 'memcached:11211',
    }
}
EOF

cat > awx-config/netbox_inventory.yml << 'EOF'
---
plugin: netbox.netbox.nb_inventory
api_endpoint: http://netbox:8080
token: 0123456789abcdef0123456789abcdef01234567
validate_certs: false
config_context: true
group_by:
  - device_roles
  - sites
  - tenants
query_filters:
  - has_primary_ip: true
  - status: "active"
device_query_filters:
  - has_primary_ip: true
vm_query_filters:
  - has_primary_ip: true
flatten_custom_fields: true
compose:
  ansible_host: primary_ip4
  ansible_network_os: platform.slug
EOF

cat > awx-config/test-playbook.yml << 'EOF'
---
- name: Test NetBox Inventory
  hosts: all
  gather_facts: no
  
  tasks:
    - name: Ping test
      ping:
      
    - name: Display Inventory Information
      debug:
        msg: "Host: {{ inventory_hostname }} - IP: {{ ansible_host }}"
EOF

cat > awx-config/ansible.cfg << 'EOF'
[defaults]
inventory = netbox_inventory.yml
host_key_checking = False
retry_files_enabled = False
collections_path = /usr/share/ansible/collections

[inventory]
enable_plugins = netbox.netbox.nb_inventory
EOF

# Instruções para o usuário
cat > awx-config/INSTRUCOES.md << 'EOF'
# Instruções para integração do NetBox com AWX

## Inicialização e acesso

1. Inicie o ambiente com Docker Compose:

```bash
docker compose up -d
```

2. Acesse o NetBox em http://localhost:8000
   - Usuário: admin
   - Senha: admin

3. Acesse o AWX em http://localhost:8053
   - Usuário: admin
   - Senha: password

## Configuração do Token de API no NetBox

1. Acesse o NetBox e faça login com as credenciais do administrador
2. Acesse o menu do usuário no canto superior direito -> Minha Conta
3. Acesse a aba "API Tokens"
4. Clique em "Adicionar um token de API"
5. Forneça uma descrição como "AWX Integration"
6. Anote o token gerado, você precisará dele para a configuração do AWX

## Configuração do inventário dinâmico no AWX

1. Acesse o AWX e faça login como administrador
2. Vá para **Credenciais** -> **Adicionar**
   - Nome: NetBox API
   - Tipo de Credencial: Source Control
   - Campos adicionais:
     - Username: admin
     - Password: (Token gerado no NetBox)

3. Vá para **Projetos** -> **Adicionar**
   - Nome: NetBox Integration
   - Organização: Default
   - Tipo de SCM: Git
   - URL SCM: Vazio (será um projeto manual)
   - Marque "Atualizar revisão no launch"

4. Vá para **Inventários** -> **Adicionar**
   - Nome: NetBox Inventory
   - Organização: Default
   - Descrição: Inventário obtido do NetBox

5. No novo inventário criado, vá para **Fontes** -> **Adicionar** -> **Fonte de inventário**
   - Nome: NetBox Source
   - Fonte: NetBox (netbox.netbox.nb_inventory)
   - Credencial: NetBox API (criada anteriormente)
   - Substitua o conteúdo do campo de variáveis com o seguinte YAML:

```yaml
---
plugin: netbox.netbox.nb_inventory
api_endpoint: http://netbox:8080
validate_certs: false
config_context: true
group_by:
  - device_roles
  - sites
  - tenants
query_filters:
  - has_primary_ip: true
  - status: "active"
device_query_filters:
  - has_primary_ip: true
vm_query_filters:
  - has_primary_ip: true
flatten_custom_fields: true
compose:
  ansible_host: primary_ip4
  ansible_network_os: platform.slug
```

6. Clique em "Salvar" e depois em "Sincronizar"

## Teste da integração

1. Crie algumas máquinas virtuais no NetBox:
   - Acesse **Virtualização** -> **Máquinas Virtuais** -> **Adicionar**
   - Preencha os detalhes necessários, incluindo o endereço IP primário
   
2. Após criar algumas máquinas virtuais, volte ao AWX e sincronize o inventário
   - Acesse **Inventários** -> **NetBox Inventory**
   - Clique em **Fontes** -> **NetBox Source**
   - Clique no botão "Sincronizar"

3. Verifique se as máquinas virtuais do NetBox apareceram no inventário do AWX

4. Crie um Job Template para testar a conectividade:
   - Vá para **Modelos** -> **Adicionar** -> **Modelo de Job**
   - Nome: Test Connectivity
   - Inventário: NetBox Inventory
   - Projeto: NetBox Integration
   - Playbook: (use um playbook simples como ping.yml ou crie um)
   - Credenciais: Selecione as credenciais apropriadas para acessar os hosts

5. Execute o Job Template e verifique se a conectividade funciona corretamente

## Notas importantes

- O NetBox e o AWX estão na mesma rede Docker, portanto, use `http://netbox:8080` para a API do NetBox quando estiver configurando no AWX
- Certifique-se de que as máquinas virtuais no NetBox tenham endereços IP que o AWX possa alcançar
- Para ambientes de produção, ajuste as senhas e tokens para valores seguros e complexos
- Considere usar HTTPS e validação de certificados em ambientes de produção
EOF

echo "Configuração do AWX (para laptop x86) concluída!"
echo "Para iniciar a stack completa (NetBox + AWX), execute:"
echo "docker compose up -d"
echo ""
echo "NetBox será acessível em: http://localhost:8000"
echo "AWX será acessível em: http://localhost:8053"