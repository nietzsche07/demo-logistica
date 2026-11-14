# Guía paso a paso — Demostración técnica (Terraform + Docker)

Sustituto local de AWS: PostgreSQL en Docker representa el RDS del dominio de entregas.
Escenario de cambio: memoria de 512 MB a 1024 MB (equivale a RDS de 4 a 8 GB en el año 3).
Toma una captura en cada paso marcado con [CAPTURA] y pégala en la Parte B de tu plantilla.

## 0. Preparar
Instala Docker Desktop (déjalo abierto), Terraform, Git y VS Code. Verifica:
    docker --version
    terraform -version
    git --version

## 1. Versionar (desde la carpeta demo-logistica-iac)
    git init
    git add .
    git commit -m "feat: módulo de base de datos y ambientes dev/qa"
    git tag v1.0.0
[CAPTURA] git log --oneline --decorate

## 2. Implementar en Dev
    cd envs/dev
    terraform init
    terraform validate
    terraform plan        # debe decir 4 to add
    terraform apply       # escribe yes
Luego sube el archivo de bloqueo de versiones:
    git add .terraform.lock.hcl
    git commit -m "chore: fija versiones del proveedor (dev)"
[CAPTURA] salida de plan y de apply

## 3. Validar
    docker ps
    docker inspect -f "{{.HostConfig.Memory}}" logistica-dev-postgres
        (536870912 = 512 MB)
    docker exec logistica-dev-postgres psql -U postgres -d entregas -c "CREATE TABLE entregas (id serial, vehiculo text); INSERT INTO entregas (vehiculo) VALUES ('V001');"
    terraform plan        # debe decir No changes (sin drift)
[CAPTURA] cada comando

## 4. Modificar (escenario de cambio)
    git checkout -b cambio/aumento-memoria
Edita envs/dev/terraform.tfvars: memoria_mb = 1024
    terraform plan
Observa si dice "update in-place" (~) o "must be replaced" (-/+). Anótalo: es tu análisis de impacto.
    terraform apply
    docker inspect -f "{{.HostConfig.Memory}}" logistica-dev-postgres    (1073741824 = 1024 MB)
    docker exec logistica-dev-postgres psql -U postgres -d entregas -c "SELECT * FROM entregas;"
        (V001 debe seguir ahí gracias al volumen)
    git add .
    git commit -m "change: aumento de memoria de BD a 1024 MB por crecimiento de flota"
    git checkout main
    git merge cambio/aumento-memoria
    git tag v1.1.0
[CAPTURA] plan, inspect, select y git log

## 5. Promover a QA
    cd ../qa
    terraform init
    terraform apply       # se crea con 512
Edita envs/qa/terraform.tfvars: memoria_mb = 1024
    terraform plan
    terraform apply
    docker inspect -f "{{.HostConfig.Memory}}" logistica-qa-postgres
    git add .
    git commit -m "change: promueve aumento de memoria a QA"
[CAPTURA] ambos ambientes con el mismo valor

## 6. Revertir (en Dev)
    cd ../dev
    git log --oneline     # copia el código del commit del cambio de dev
    git revert <codigo>
    terraform plan        # 1024 -> 512
    terraform apply
    git tag v1.1.1
    docker inspect -f "{{.HostConfig.Memory}}" logistica-dev-postgres
[CAPTURA] git log mostrando cambio y reversión (qué, quién, cuándo, por qué)

## 7. Reproducir
    terraform destroy
    terraform apply       # se recrea idéntico desde el código
[CAPTURA] destroy y apply

## 8. Limpiar
    terraform destroy     (en envs/dev y en envs/qa)

## Si algo falla
- Error de conexión con Docker en Windows: quita el # de la línea host en envs/<ambiente>/main.tf.
- Puerto ocupado: cambia el valor de puerto en terraform.tfvars.
- Cualquier otro error: copia el mensaje completo y consúltalo.
