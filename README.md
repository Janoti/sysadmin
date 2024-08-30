# Scrips Sysadmin

![Badge em Desenvolvimento](http://img.shields.io/static/v1?label=STATUS&message=EM%20DESENVOLVIMENTO&color=GREEN&style=for-the-badge)

##  Description title


## Descrição do Projeto
<p align="justify">monitoring_centos.sh --> Instala e configura o Zabbix, Prometheus, Grafana, Cadvisor, Portainer, Wazuh e Nessus (Tenable). Será um para cada OS e arquitetura</p>
<p align="justify">jenkins-home-bkp.sh  --> Script para fazer bkp da pasta de plugins e conf do Jenkins. Salva em um S3</p>
<p align="justify">TERRAFORM            --> Terraform para criação dos alertas de system status e gerar auto healing para EC2 que estejam paradas por falha</p>

```
aws ec2 describe-instances --region sa-east-1 --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value, InstanceId]' --output text | sed 'N;s/\n/,/' > instances.csv
```

Esse comando busca o nome e id da cadas EC2 na região e salva em um csv

## Requirements:
```
AWS CLI
Acesso SSM ou SSH a EC2 como root
Acesso ao Managed Grafana da região
Porteiner precisa liberar a porta 9000 com Cyber para acesso via browser

```

## TODOs
```
Automatizar a execução do comando de listar IDs e nome das EC2 gerando um cvs e o Terraform ler automaticamente aplicando os novos alertas as novas instancias.
```

## xxxx
```
ipssdlsdasd

```

## ACCOUNTS
```
Matera-prd --> São Paulo (sa-east-1)
```
