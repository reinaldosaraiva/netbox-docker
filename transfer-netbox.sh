#!/bin/bash
# Script para transferir o NetBox para outro laptop

# Cria um backup dos volumes relevantes
echo "Criando backup dos volumes..."
BACKUP_DIR="./netbox-backup"
mkdir -p "$BACKUP_DIR"

# Gera um arquivo tar com o projeto inteiro (exceto dados volumados)
echo "Compactando projeto NetBox..."
cd ..
tar --exclude="netbox-docker/netbox-backup" --exclude="netbox-docker/.git" -zcvf "netbox-docker/netbox-backup/netbox-project.tar.gz" netbox-docker
cd netbox-docker

echo "Backup concluído! Os arquivos estão em $BACKUP_DIR"
echo ""
echo "Para transferir para outro laptop:"
echo "1. Copie a pasta $BACKUP_DIR para o outro laptop (por exemplo, usando scp, USB, etc.)"
echo "2. No outro laptop, extraia o arquivo:"
echo "   $ tar -xzvf netbox-backup/netbox-project.tar.gz"
echo "3. Navegue até a pasta extraída e inicie o NetBox:"
echo "   $ cd netbox-docker"
echo "   $ docker compose up -d"
echo ""
echo "Nota: O banco de dados iniciará com os dados de demonstração incluídos no repositório."
echo "Nenhum dado do seu volume foi exportado por questões de compatibilidade entre arquiteturas."