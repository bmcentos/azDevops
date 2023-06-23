#Esse projeto visa realizar levantamento de metricas de build e de release diretamente da API do Azure Devops

Scripts
 #Coleta informações de releases do Azure Devops
- release/releaseMetrics.sh  
#Coleta informaçoes de build do Azure Devops  
- build/buildMetris.sh     
#Carrega os arquivos CSV para o banco de dados postgres     
- loadToPg.sh                   
#Build da imagem
docker build az_metrics . --no-cache

#Definição de variaveis necessarias
```
export IMAGE=az_metrics
export POC=false        #Se estiver como true, possibilita a criação do banco de dados postgres Docker
export DB_HOST=172.17.0.2
export DB_NAME=db_az_metrics
export DB_USER=poc
export DB_PASSWORD=senha
export PAT=<PAT>
export DB_PORT=5432
export ORG=<ORG>
```
#Execução do levantamento de metricas de build
```
export CMD="release"
export TABLE_NAME="tb_az_releases"
```
```
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
```

#Execução do levantamento de metricas de build
```
export CMD="build"
export TABLE_NAME="tb_az_build"
```
```
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
```
