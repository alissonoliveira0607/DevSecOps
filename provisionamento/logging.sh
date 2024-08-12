#!/bin/bash
    
# Variaveis
DEPS_PACKAGES="vim java tree wget curl redhat-rpm-config python3-devel gcc httpd-tools"
PACKAGES="vault consul mariadb"

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

# Solução alternativa erro: Errors during downloading metadata for repository 'AppStream'
# sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
# sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
# sudo bash -c "sed -i 's/best=True/best=False/' /etc/dnf/dnf.conf"
# sudo yum update -y
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
sed -i 's/mirrorlist/mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
sudo yum update -y

# Solução temporaria para EOL Centos 8 Não funciona mais
sudo rpm -Uhv --nodeps http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/centos-stream-repos-8-3.el8.noarch.rpm http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/centos-stream-release-8.5-3.el8.noarch.rpm >/dev/null 2>>/var/log/vagrant_provision.log

# Copia git plugin
sudo cp /tmp/git-plugin-1.0.4.jar /root/git-plugin-1.0.4.jar >/dev/null 2>>/var/log/vagrant_provision.log

validateCommand "Copia git plugin"

# Configura infra para Rundeck
sudo useradd rundeck >/dev/null 2>>/var/log/vagrant_provision.log && \
sudo mkdir -p /opt/rundeck/projects/ansible-hardening/ >/dev/null 2>>/var/log/vagrant_provision.log && \
sudo chown -R rundeck: /opt/rundeck/projects/ansible-hardening/ >/dev/null 2>>/var/log/vagrant_provision.log && \
sudo cp /tmp/devsecops.pem /home/rundeck/id_rsa >/dev/null 2>>/var/log/vagrant_provision.log && \
sudo chmod 600 /home/rundeck/id_rsa >/dev/null 2>>/var/log/vagrant_provision.log && \
sudo chown rundeck:rundeck /home/rundeck/id_rsa >/dev/null 2>>/var/log/vagrant_provision.log

validateCommand "Configuracoes gerais Rundeck"

# Corrige profile
sudo sed -i 's/77.30/56.30/g' /etc/profile >/dev/null 2>>/var/log/vagrant_provision.log

validateCommand "Configura profile"

# Instalando Pacotes
sudo dnf install -q -y ${DEPS_PACKAGES} ${PACKAGES} >/dev/null 2>>/var/log/vagrant_provision.log

validateCommand "Instalação de Pacotes"