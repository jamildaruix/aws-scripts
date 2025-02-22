#!/bin/bash

# Nome do arquivo de saída
OUTPUT_FILE="iam_user_rds_security_groups.csv"

# Cabeçalho do arquivo CSV
echo "IAMUser,SecurityGroupId,DBInstanceIdentifier" > $OUTPUT_FILE

# Listar todos os usuários IAM
IAM_USERS=$(aws iam list-users --query "Users[*].UserName" --output text)

echo "Obtendo dados de usuários IAM..."

# Para cada usuário IAM, obtemos as políticas
for IAM_USER in $IAM_USERS; do
    echo "Processando Usuário IAM: $IAM_USER"
    
    # Listar as políticas anexadas ao usuário
    POLICIES=$(aws iam list-attached-user-policies --user-name "$IAM_USER" --query "AttachedPolicies[*].PolicyArn" --output text)
    
    # Para cada política, verificamos se há permissões de acesso ao RDS
    for POLICY in $POLICIES; do
        echo "  Processando Política: $POLICY"
        
        # Obtemos os detalhes da política
        POLICY_DOCUMENT=$(aws iam get-policy-version --policy-arn "$POLICY" --version-id "$(aws iam list-policy-versions --policy-arn "$POLICY" --query "Versions[0].VersionId" --output text)" --query "PolicyVersion.Document" --output text)
        
        # Verifica se a política permite acesso ao RDS
        if [[ "$POLICY_DOCUMENT" == *"rds:"* ]]; then
            echo "    Política permite acesso ao RDS, buscando instâncias..."
            
            # Listar todas as instâncias RDS
            DB_INSTANCES=$(aws rds describe-db-instances --query "DBInstances[*].DBInstanceIdentifier" --output text)
            
            # Para cada instância RDS, obtemos os Security Groups
            for DB_INSTANCE in $DB_INSTANCES; do
                echo "      Processando Banco de Dados: $DB_INSTANCE"
                
                # Obter os Security Groups associados à instância RDS
                SECURITY_GROUPS=$(aws rds describe-db-instances --db-instance-identifier "$DB_INSTANCE" --query "DBInstances[0].VpcSecurityGroups[*].VpcSecurityGroupId" --output text)
                
                # Para cada Security Group, escrever no arquivo CSV
                for SG in $SECURITY_GROUPS; do
                    echo "$IAM_USER,$SG,$DB_INSTANCE" >> $OUTPUT_FILE
                done
            done
        fi
    done
done

echo "Exportação concluída para o arquivo: $OUTPUT_FILE"
