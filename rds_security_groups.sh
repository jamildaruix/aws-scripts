#!/bin/bash

# Nome do arquivo de saída
OUTPUT_FILE="rds_security_groups.csv"

# Cabeçalho do arquivo CSV
echo "DBInstanceIdentifier,SecurityGroupId,IPRange" > $OUTPUT_FILE

# Listar todas as instâncias RDS
DB_INSTANCES=$(aws rds describe-db-instances --query "DBInstances[*].DBInstanceIdentifier" --output text)

echo "Obtendo dados de todos os bancos de dados..."

# Para cada instância RDS, obtemos os detalhes dos Security Groups
for DB_INSTANCE in $DB_INSTANCES; do
    echo "Processando Banco de Dados: $DB_INSTANCE"
    
    # Obtendo os grupos de segurança da instância RDS
    SECURITY_GROUPS=$(aws rds describe-db-instances --db-instance-identifier "$DB_INSTANCE" --query "DBInstances[0].VpcSecurityGroups[*].VpcSecurityGroupId" --output text)
    
    # Para cada Security Group, obtemos os IPs associados
    for SG in $SECURITY_GROUPS; do
        echo "  Processando Security Group: $SG"
        
        # Obtendo os detalhes dos IPs vinculados ao Security Group
        SG_DETAILS=$(aws ec2 describe-security-groups --group-ids "$SG" --query "SecurityGroups[*].IpPermissions[*].IpRanges[*].CidrIp" --output text)
        
        # Se houver IPs vinculados, exporta para o arquivo CSV
        if [[ -n "$SG_DETAILS" ]]; then
            IFS=$'\n'
            for IP in $SG_DETAILS; do
                echo "$DB_INSTANCE,$SG,$IP" >> $OUTPUT_FILE
            done
        else
            echo "$DB_INSTANCE,$SG,Nenhum IP encontrado" >> $OUTPUT_FILE
        fi
    done
done

echo "Exportação concluída para o arquivo: $OUTPUT_FILE"
