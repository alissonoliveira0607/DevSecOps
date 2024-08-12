#!/bin/bash
    
# Variaveis
VAULT_SSH_HELPER="0.1.6"
SSH_HELPER_URL="https://releases.hashicorp.com/vault-ssh-helper/${VAULT_SSH_HELPER}/vault-ssh-helper_${VAULT_SSH_HELPER}_linux_amd64.zip"
DEPS_PACKAGES="vim python3 python3-pip python-setuptools tree wget curl unzip mlocate gem ruby rubygems ruby-dev zlib1g-dev zlib1g"
PACKAGES="git nmap dirb postgresql postgresql-client mariadb-server"

validateCommand() {
  if [ $? -eq 0 ]; then
    echo "[OK] $1"
  else
    echo "[ERROR] $1"
    exit 1
  fi
}

# Registrando dia do Provision
sudo date >> /var/log/vagrant_provision.log

# Inserindo chave SSH
sudo test -f /root/.ssh/id_rsa
if [ $? -eq 1 ]; then
  sudo mkdir -p /root/.ssh/ && \
	  sudo cp /tmp/devsecops.pem /root/.ssh/id_rsa && \
	  sudo cp /tmp/devsecops.pub /root/.ssh/authorized_keys && \
    sudo cat /tmp/windows.pub >> /root/.ssh/authorized_keys && \
	  sudo chmod 600 /root/.ssh/id_rsa
  
  validateCommand "Preparando SSH KEY"
else
  echo "[OK] SSH KEY"
fi

# Verifica se o usuário devops já existe
if ! getent passwd devops > /dev/null; then
  echo "Criando usuário devops"
  useradd -m -d /home/devops -s /bin/bash devops
  
  # Verifica se o diretório .ssh já existe
  if [ ! -d /home/devops/.ssh ]; then
    echo "Criando diretório .ssh para o usuário devops"
    mkdir -p /home/devops/.ssh/
    
    # Copia as chaves autorizadas do root
    echo "Copiando authorized_keys do root"
    cp -Rp /root/.ssh/authorized_keys /home/devops/.ssh/
    
    # Ajusta as permissões
    echo "Ajustando permissões"
    chown -R devops: /home/devops/.ssh/
    chmod 700 /home/devops/.ssh
    chmod 600 /home/devops/.ssh/authorized_keys
  else
    echo "[OK] SSH KEY já existente"
  fi
  
  # Verifica e adiciona o usuário devops ao sudoers
  if [ ! -f /etc/sudoers.d/devops ]; then
    echo "Adicionando o usuário devops ao sudoers"
    echo "devops ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/devops
  else
    echo "[OK] Regra de sudo já existente"
  fi
else
  echo "Usuário devops já existe"
fi


# Correção repositório do buster
#echo "Comenta a linha do repo problemático"
#sudo sed -i '/https:\/\/apt.releases.hashicorp.com/s/^/#/' /etc/apt/sources.list.d/hashicorp.list
sudo sed -i '/https:\/\/apt.releases.hashicorp.com/s/^/#/' /etc/apt/sources.list.d/*hashicorp_com.list
sudo apt update -y
sudo apt install -y curl jq unzip

echo "Instalando o Terraform"
wget  https://releases.hashicorp.com/terraform/1.9.4/terraform_1.9.4_linux_amd64.zip
unzip terraform_1.9.4_linux_amd64.zip
sudo mv terraform /usr/local/bin



# Instalando Pacotes
export DEBIAN_FRONTEND=noninteractive
sudo apt-get --allow-releaseinfo-change update -qq >/dev/null 2>>/var/log/vagrant_provision.log && \
sudo apt-get install -qq -y ${DEPS_PACKAGES} ${PACKAGES} >/dev/null 2>>/var/log/vagrant_provision.log

validateCommand "Instalação de Pacotes"

# Desabilitando Serviço do Postgresql
sudo systemctl disable postgresql &>/dev/null && \
	sudo systemctl stop postgresql &>/dev/null

validateCommand "Desabilitando Serviço"

# Baixando Vault SSH Helper
if [ ! -e /usr/bin/vault-ssh-helper ]; then
  sudo wget -q -c ${SSH_HELPER_URL} -O /tmp/vault-ssh-helper.zip && \
	  sudo unzip /tmp/vault-ssh-helper.zip -d /usr/bin/ >/dev/null && \
	  sudo chmod +x /usr/bin/vault-ssh-helper

  validateCommand "Preparando Vault SSH Helper"
else
  echo "[OK] Vault SSH Helper"
fi

# Preparando Gauntlt
if [ ! -d /opt/gauntlt ]; then
  sudo git clone https://github.com/gauntlt/gauntlt.git /opt/gauntlt/ >/dev/null 2>>/var/log/vagrant_provision.log

  validateCommand "Preparando Gauntlt"
else
  echo "[OK] Gauntlt"
fi
