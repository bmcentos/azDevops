#!/bin/bash
############# COLORS #############
     GREEN="\e[1;32m"
     DEFAULT="\e[0m"
     RED="\e[1;31m"
     YELLOW="\e[1;33m"
     BLUE="\e[1;36m"


#Coleta o valor de parametro passado para o script (build ou release)
export opc=${1,,}
# Verificar se a variável POC está definida
if [ -z "$POC" ]; then
    echo -e "${RED}[-] A variável POC não está definida."
    echo -e "  - Essa variavel é booleana, se estiver true, subirá um container postgreSql local"
fi

# Verificar se a variável DB_HOST está definida
if [ -z "$DB_HOST" ]; then
    echo -e "${RED}[-] A variável DB_HOST não está definida."
    echo -e "  - Host PostgreSQL que será conectado"
fi

# Verificar se a variável DB_NAME está definida
if [ -z "$DB_NAME" ]; then
    echo -e "${RED}A variável DB_NAME não está definida."
    echo -e "  - Nome do banco de dados que será criado"
fi

# Verificar se a variável DB_USER está definida
if [ -z "$DB_USER" ]; then
    echo -e "${RED}[-] A variável DB_USER não está definida."
    echo -e "  - Nome do usuario com acesso ao banco (Ou se a env POC estiver como true, vai criar o usuario)"
fi

# Verificar se a variável DB_PASSWORD está definida
if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}[-] A variável DB_PASSWORD não está definida."
    echo "  - Variavel de senha do usuario com acesso ao banco (Ou se a env POC estiver como true, irá definir a senha do banco)"
fi

# Verificar se a variável PAT está definida
if [ -z "$PAT" ]; then
    echo -e "${RED}[-] A variável PAT não está definida."
    echo -e "  - Essa variavel irá definir o Personal Access Token com acesso a organização do Azure devops, para consulta a API"
fi

# Verificar se a variável DB_PORT está definida
if [ -z "$DB_PORT" ]; then
    echo -e "${RED}[-] A variável DB_PORT não está definida."
    echo -e "  - Porta padrão: 5432"
fi

# Verificar se a variável ORG está definida
if [ -z "$ORG" ]; then
    echo -e "${RED}[-] A variável ORG não está definida."
    echo -e "  - Organização Azure Devops"
fi
if [ -z "$POC" ] || [ -z "$DB_HOST" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$PAT" ] || [ -z "$DB_PORT" ] || [ -z "$ORG" ]; then
    echo -e "${YELLOW}[!!] Verificar a variavel não definida e declarar."
    exit 1
else
    echo -e "${GREEN}[+] Variaveis definidas com sucesso!!!"
fi
#Fluxo de execução do script 
if [ "$opc" == "release" ] ; then
	echo -e "${GREEN}[+] Coletando metricas de release da org $ORG..."
	bash release/releaseMetrics.sh
elif [ "$opc" == "build" ] ; then
	echo -e "${GREEN}[+] Coletando metricas de Build da org $ORG..."
	bash build/buildMetrics.sh
else
	echo -e "${RED}[-] Opção não reconhecida."
	echo "   Opções disponiveis: build, release"
	echo "USO:"
	echo -e ''${YELLOW}'CMD=release #(OU CMD=build)
		docker run \
		-e POC=$POC \
		-e DB_HOST="$DB_HOST" \
		-e DB_PORT="$DB_PORT" \
		-e DB_NAME="$DB_NAME" \
		-e DB_USER="$DB_USER" \
		-e DB_PASSWORD="$DB_PASSWORD" \
		-e TABLE_NAME="$TABLE_NAME" \
		-e PAT="$PAT" \
		-e ORG="$ORG" \
		$IMAGE \
		$CMD
'
	exit 1
fi
echo -e ${DEFAULT}
