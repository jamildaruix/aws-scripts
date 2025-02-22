#!/bin/bash

echo "Listando usuários do IAM..."
echo "==================================="

aws iam list-users --query "Users[*].UserName" --output text | tr '\t' '\n' | while read user; do
    echo "Usuário: $user"
    
    # Detalhes básicos do usuário
    aws iam get-user --user-name "$user" --query "{UserId:User.UserId, ARN:User.Arn, Created:User.CreateDate}" --output table

    # Verificar status da senha
    aws iam get-login-profile --user-name "$user" --query "{PasswordEnabled: LoginProfile.CreateDate}" --output table 2>/dev/null || echo "Senha: Não configurada"

    # Listar grupos do usuário
    aws iam list-groups-for-user --user-name "$user" --query "Groups[*].GroupName" --output table

    echo "-----------------------------------"
done
