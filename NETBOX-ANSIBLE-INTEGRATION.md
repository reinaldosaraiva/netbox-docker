# Integração NetBox com Ansible

Este documento apresenta uma alternativa para integrar o NetBox com o Ansible, usando o plugin de inventário do NetBox diretamente, sem a necessidade do AWX.

## Por que não usar AWX?

O AWX (a versão open-source do Ansible Tower) é uma excelente ferramenta para gerenciar o Ansible em escala empresarial, mas:

1. As imagens oficiais do AWX são compiladas para arquitetura x86_64 (amd64) e podem apresentar problemas em sistemas ARM64 (Apple Silicon).
2. O AWX tem requisitos de recursos significativos (CPU, memória).
3. Para muitos casos de uso, a integração direta com o Ansible é mais simples e eficiente.

## Alternativa: Usando o Plugin de Inventário do NetBox diretamente

### Pré-requisitos

1. NetBox em execução (já configurado com docker-compose)
2. Ansible instalado no sistema host
3. Coleção Ansible do NetBox instalada

### Passo a passo

1. **Instale o Ansible e a coleção NetBox**:

```bash
# Instale o Ansible e dependências
pip install ansible netaddr

# Instale a coleção NetBox
ansible-galaxy collection install netbox.netbox
```

2. **Gere um token de API no NetBox**:
   - Acesse o NetBox em http://localhost:8000
   - Faça login com o usuário admin (senha admin)
   - Vá para o menu do usuário > API Tokens > Add a token
   - Anote o token gerado

3. **Crie um arquivo de inventário NetBox**:

```bash
mkdir -p ~/ansible-netbox
cd ~/ansible-netbox
```

Crie um arquivo `netbox_inventory.yml`:

```yaml
plugin: netbox.netbox.nb_inventory
api_endpoint: http://localhost:8000
token: SEU_TOKEN_AQUI
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

4. **Crie um arquivo ansible.cfg**:

```ini
[defaults]
inventory = netbox_inventory.yml
host_key_checking = False
retry_files_enabled = False
collections_path = ~/.ansible/collections

[inventory]
enable_plugins = netbox.netbox.nb_inventory
```

5. **Teste o inventário**:

```bash
ansible-inventory --list
```

Isto deve mostrar os hosts obtidos do NetBox.

6. **Crie um playbook de teste** em `ping.yml`:

```yaml
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
```

7. **Execute o playbook**:

```bash
ansible-playbook ping.yml
```

## Fluxo de trabalho para integração

1. **Cadastre seus sistemas no NetBox**:
   - Crie sites, racks, dispositivos, VMs, etc.
   - Atribua endereços IP e defina o endereço IP primário
   - Organize em tenant groups, device roles, etc.

2. **Use o Ansible com o inventário dinâmico do NetBox**:
   - Crie playbooks que usem o inventário dinâmico
   - Use os grupos automáticos baseados nas propriedades do NetBox
   - Aproveite os dados contextuais e metadados

3. **Automação com Git e CI/CD** (opcional):
   - Armazene seus playbooks em um repositório Git
   - Configure pipelines de CI/CD para executar playbooks com base em eventos
   - Integre com ferramentas como GitLab CI, GitHub Actions, etc.

## Vantagens desta abordagem

1. **Simplicidade**: não requer componentes adicionais além do NetBox e Ansible
2. **Compatibilidade**: funciona em qualquer arquitetura suportada pelo Ansible
3. **Recursos**: requer menos recursos de sistema que o AWX
4. **Flexibilidade**: fácil de integrar com outras ferramentas e workflows
5. **Adequado para automação baseada em CI/CD**

## Recursos adicionais

- [Documentação do plugin de inventário NetBox](https://docs.ansible.com/ansible/latest/collections/netbox/netbox/nb_inventory_inventory.html)
- [Repositório da coleção Ansible para NetBox](https://github.com/netbox-community/ansible_modules)
- [Exemplos de playbooks para NetBox](https://github.com/netbox-community/ansible_modules/tree/master/examples)

## Futuras considerações

Se no futuro você quiser usar o AWX, considere:

1. Usar o AWX Operator no Kubernetes, que tem suporte para ARM64
2. Usar uma VM x86_64 (via UTM, Parallels ou Colima) para hospedar o AWX
3. Usar Ansible Tower gerenciado pela Red Hat (serviço na nuvem)