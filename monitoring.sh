#!/bin/bash
##############################################################################
# 
# Script de instalação Prometheus, Grafana, Node Exporter (LINUX)
# Data: 19/07/2024
# Author: Paulo Janoti 
#
# Sistema: Debian, Ubuntu, RHEL, CentOS, Amazon Linux
# Arquitetura: x86_64, aarch64
#
##############################################################################

# Função para destacar mensagens
print_info() {
    echo ""
    echo "#############################################"
    echo -e "# \033[1;32m$1\033[0m"
    echo "#############################################"
    echo ""
}

# Função para solicitar seleção
select_option() {
    PS3='Por favor, selecione uma opção: '
    options=("$@")
    select opt in "${options[@]}"; do
        if [[ -n "$opt" ]]; then
            echo "$opt"
            break
        else
            echo "Opção inválida."
        fi
    done
}

# Solicitar seleção da conta
print_info "Selecione a conta:"
CONTA=$(select_option "Matera-Prod" "Matera-BR" "TIC-STISUP-DATA" "RIM-RIMGRL-RISCOS")

# Definir o endpoint com base na conta selecionada
if [[ "$CONTA" == "Matera-Prod" ]]; then
    print_info "Selecione a região:"
    REGION_GRAFANA=$(select_option "us-east-1" "sa-east-1")

    case $REGION_GRAFANA in
        "us-east-1")
            ENDPOINT="CHANGE FOR AN PROMETHEUS ENDPOINT"
            SIGV4_REGION="us-east-1"
            ;;
        "sa-east-1")
            ENDPOINT="CHANGE FOR AN PROMETHEUS ENDPOINT"
            SIGV4_REGION="us-east-2"
            ;;
        *)
            echo "Região desconhecida. Saindo."
            exit 1
            ;;
    esac
else
    REGION_GRAFANA="us-east-1"  # Definir uma região padrão
    case $CONTA in
        "Matera-BR")
            ENDPOINT="CHANGE FOR AN PROMETHEUS ENDPOINT"
            SIGV4_REGION="us-east-1"
            ;;
        "TIC-STISUP-DATA")
            ENDPOINT="CHANGE FOR AN PROMETHEUS ENDPOINT"
            SIGV4_REGION="us-east-1"
            ;;
        "RIM-RIMGRL-RISCOS")
            ENDPOINT="CHANGE FOR AN PROMETHEUS ENDPOINT"
            SIGV4_REGION="us-east-1"
            ;;
        *)
            echo "Conta desconhecida. Saindo."
            exit 1
            ;;
    esac
fi

print_info "Conta selecionada: $CONTA"
print_info "Região selecionada: $REGION_GRAFANA"
print_info "Endpoint configurado: $ENDPOINT"

# Detectar arquitetura e sistema operacional
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    Prometheus_arch="amd64"
    NodeExporter_arch="amd64"
elif [ "$ARCH" == "aarch64" ]; then
    Prometheus_arch="arm64"
    NodeExporter_arch="arm64"
else
    print_info "Arquitetura não suportada: $ARCH"
    exit 1
fi

OS=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release)
if [[ "$OS" == "debian" || "$OS" == "ubuntu" ]]; then
    INSTALLER="apt-get"
    INSTALLER_OPTS="-y install"
elif [[ "$OS" == "rhel" || "$OS" == "centos" || "$OS" == "amzn" ]]; then
    INSTALLER="yum"
    INSTALLER_OPTS="-y install"
else
    print_info "Sistema operacional não suportado: $OS"
    exit 1
fi

# Variáveis
PROMETHEUS_VERSION="2.53.1"
PROMETHEUS_FILE="prometheus-${PROMETHEUS_VERSION}.linux-${Prometheus_arch}.tar.gz"
PROMETHEUS_URL="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/${PROMETHEUS_FILE}"
INSTALL_DIR="/usr/local/bin/"
CONFIG_FILE="/etc/prometheus.yaml"
SERVICE_FILE="/etc/systemd/system/prometheus.service"
SERVICE_FILE_NODE_EXPORTER="/etc/systemd/system/node_exporter.service"
HOSTNAME=$(hostname)

NODE_EXPORTER_VERSION="1.8.2"
NODE_EXPORTER_FILE="node_exporter-${NODE_EXPORTER_VERSION}.linux-${NodeExporter_arch}.tar.gz"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${NODE_EXPORTER_FILE}"

# Instalar dependências
print_info "Instalando dependências..."
sudo $INSTALLER $INSTALLER_OPTS wget tar

# Baixar e instalar o Prometheus
if [ -e "${PROMETHEUS_FILE}" ]; then
    print_info "O arquivo do Prometheus já existe. Pulando o download."
else
    print_info "Baixando Prometheus..."
    wget "${PROMETHEUS_URL}"
fi

print_info "Descompactando e instalando Prometheus..."
tar -xvf "${PROMETHEUS_FILE}"
cp "prometheus-${PROMETHEUS_VERSION}.linux-${Prometheus_arch}/prometheus" "${INSTALL_DIR}"

# Criar o arquivo de configuração prometheus.yaml
print_info "Configurando Prometheus..."
sudo tee "${CONFIG_FILE}" > /dev/null <<EOF
global:
  scrape_interval: 15s
  external_labels:
    monitor: 'prometheus'

scrape_configs:
  - job_name: '${HOSTNAME}-Prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: '${HOSTNAME}'
    static_configs:
      - targets: ['localhost:9100']

remote_write:
  -
    url: '${ENDPOINT}'
    queue_config:
        max_samples_per_send: 1000
        max_shards: 200
        capacity: 2500
    sigv4:
        region: '${SIGV4_REGION}'
EOF

# Criar o serviço systemd para o Prometheus
print_info "Criando serviço systemd para Prometheus..."
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Prometheus Server
After=network.target

[Service]
ExecStart=/usr/local/bin/prometheus --config.file="$CONFIG_FILE"
Restart=always

[Install]
WantedBy=default.target
EOF

# Iniciar e habilitar o serviço Prometheus
print_info "Iniciando e habilitando serviço Prometheus..."
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Baixar e instalar o Node Exporter
if [ -e "${NODE_EXPORTER_FILE}" ]; then
    print_info "O arquivo do Node Exporter já existe. Pulando o download."
else
    print_info "Baixando Node Exporter..."
    wget "${NODE_EXPORTER_URL}"
fi

print_info "Descompactando e instalando Node Exporter..."
tar xf "${NODE_EXPORTER_FILE}"
sudo mv "node_exporter-${NODE_EXPORTER_VERSION}.linux-${NodeExporter_arch}" node_exporter
sudo cp node_exporter/node_exporter /usr/local/bin/

# Criar arquivo de configuração node_exporter.yaml
print_info "Criando serviço systemd para Node Exporter..."
sudo tee "$SERVICE_FILE_NODE_EXPORTER" > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=default.target
EOF

# Iniciar e habilitar o serviço node_exporter
print_info "Iniciando e habilitando serviço Node Exporter..."
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Exibir o status dos serviços Prometheus e Node Exporter
print_info "Status dos serviços Prometheus e Node Exporter:"
systemctl --no-pager status prometheus node_exporter

print_info "AVISO: "
echo "Verifique se no Prometheus em remote_write msg aparece Done replaying WAL"
echo "O Prometheus pode estar rodando e mesmo assim com erro no yaml"
echo ""
print_info "Script Finished"

