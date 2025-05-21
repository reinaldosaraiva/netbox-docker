# NetBox Docker com Dados de Demonstração

Este é um fork do projeto [netbox-docker](https://github.com/netbox-community/netbox-docker) que inclui suporte para inicialização automática com dados de demonstração.

## Recursos Adicionais

- Carregamento automático de dados de demonstração durante a inicialização do PostgreSQL
- Dados completos para explorar todas as funcionalidades do NetBox
- Login padrão com username: `admin` e senha: `admin`

## Como Usar

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/netbox-docker.git
cd netbox-docker
```

2. Certifique-se de que o repositório de dados de demonstração está disponível:
```bash
git clone https://github.com/netbox-community/netbox-demo-data.git
```

3. Inicie o NetBox com docker compose:
```bash
docker compose up -d
```

4. Acesse o NetBox em http://localhost:8000 e faça login com:
   - Usuário: `admin`
   - Senha: `admin`

## Configurações Personalizadas

O arquivo SQL para popular o banco de dados é configurado através da variável de ambiente `NETBOX_DEMO_DATA` e por padrão usa `./netbox-demo-data/sql/netbox-demo-v4.2.sql`.

Se você deseja usar uma versão diferente dos dados de demonstração, você pode:

1. Especificar um caminho diferente para o arquivo SQL:
```bash
NETBOX_DEMO_DATA=/caminho/para/seu/arquivo.sql docker compose up -d
```

2. Para desativar os dados de demonstração e iniciar com um banco de dados limpo:
```bash
NETBOX_DEMO_DATA=/dev/null docker compose up -d
```

## Observações Importantes

- Os dados de demonstração são carregados apenas na primeira inicialização (quando o volume do PostgreSQL é criado)
- Se você já tem dados no NetBox e deseja reiniciar com os dados de demonstração, remova o volume primeiro:
```bash
docker compose down -v
docker compose up -d
```

## Datasets Disponíveis

Os dados de demonstração são fornecidos pelo projeto [netbox-demo-data](https://github.com/netbox-community/netbox-demo-data) e incluem:

- Sites, regiões e grupos de sites
- Fabricantes e modelos de equipamentos
- Dispositivos e interfaces
- Racks e localizações
- Endereços IP, VLANs e configurações de rede
- Circuitos e provedores
- Configurações de virtualização
- E muito mais...

Este conjunto de dados completo é perfeito para demonstrações, treinamentos e testes do NetBox.