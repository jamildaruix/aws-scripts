#!/bin/bash

# Nome do arquivo de saída
OUTPUT_FILE="iam_users.csv"

# Escreve o cabeçalho do CSV
echo "UserName,UserId,ARN,CreatedAt,PasswordEnabled,Groups,AccessKeyID,AccessKeyStatus,AccessKeyAgeDays,LastAccessed" > "$OUTPUT_FILE"

# Lista todos os usuários e remove caracteres inválidos
aws iam list-users --query "Users[*].UserName" --output text | tr '\t' '\n' | grep -E '^[a-zA-Z0-9+=,.@_-]+$' | while read -r user; do
    echo "Processando usuário: $user"

    # Obtém detalhes básicos do usuário
    details=$(aws iam get-user --user-name "$user" --query "[User.UserId, User.Arn, User.CreateDate]" --output text 2>/dev/null || echo ",,")

    # Verifica se a senha está habilitada
    password_enabled=$(aws iam get-login-profile --user-name "$user" --query "LoginProfile.CreateDate" --output text 2>/dev/null || echo "No")

    # Lista os grupos do usuário
    groups=$(aws iam list-groups-for-user --user-name "$user" --query "Groups[*].GroupName" --output text 2>/dev/null | tr '\t' ';')

    # Obtém a última vez que o usuário acessou a AWS
    last_accessed=$(aws iam generate-service-last-accessed-details --arn "arn:aws:iam::$AWS_ACCOUNT_ID:user/$user" --query "JobId" --output text 2>/dev/null)
    
    # Aguarda a conclusão da análise do último acesso
    sleep 5
    
    # Obtém os detalhes do último acesso
    last_accessed_details=$(aws iam get-service-last-accessed-details --job-id "$last_accessed" --query "ServicesLastAccessed[0].LastAuthenticated" --output text 2>/dev/null || echo "Never")

    # Inicializa variáveis para as chaves de acesso
    access_keys=""
    
    # Obtém informações sobre as chaves de acesso
    aws iam list-access-keys --user-name "$user" --query "AccessKeyMetadata[*].[AccessKeyId,Status,CreateDate]" --output text 2>/dev/null | while read -r key_id status created_at; do
        # Calcula a idade da chave em dias
        if [[ -n "$created_at" ]]; then
            created_at_epoch=$(date -d "$created_at" +%s)
            now_epoch=$(date +%s)
            key_age_days=$(( (now_epoch - created_at_epoch) / 86400 ))
        else
            key_age_days=""
        fi

        # Adiciona os dados da chave ao usuário
        access_keys="$key_id,$status,$key_age_days"
    done

    # Se o usuário não tiver chaves, coloca valores vazios
    if [[ -z "$access_keys" ]]; then
        access_keys=",,"
    fi

    # Adiciona os dados ao arquivo CSV
    echo "$user,$details,$password_enabled,\"$groups\",$access_keys,$last_accessed_details" >> "$OUTPUT_FILE"
done

echo "✅ Exportação concluída! Arquivo salvo como $OUTPUT_FILE"
