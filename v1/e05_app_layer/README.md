# E05 Stockage et réplication des données en mode multi-cloud

L'architecture cible est la suivante :

![Multi-cloud-step05](../architecture/Multi-cloud-step05.png)

Les variables dans le fichier `variables.tf` peuvent être ajustées. Ensuite il suffit de lancer terraform pour construire l'infrastructure :
```shell
$ terraform init
$ terraform apply
```

Pour le déploiement des jobs Nomad depuis un des serveurs de l'infra :
```shell
export NOMAD_ADDR=http://nomad.service.consul:4646
nomad run app-aws.nomad
nomad run app-gcp.nomad
```

Pour la création de la query Consul :
```shell
curl --request POST --data @storage-query.json http://consul.service.consul:8500/v1/query
```

Pour la création de l'image Docker de l'application :
```shell
cd files/app/
docker build -t username/minio-js-store-app:1.2 .
```

Pour la création du stockage objet et l'import des objets dedans :
```shell
# Récupération du client et connexion au cluster
wget https://dl.minio.io/client/mc/release/linux-amd64/mc
chmod +x mc
mc config host add myminio http://storage-object-minio.query.consul:9000 AKIAIOSFODNN7EXAMPLE wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Création du bucket et changement de la policy par défaut
mc mb myminio/minio-store
mc policy public myminio/minio-store

# Copie des fichiers
mc cp files/bucket/*.png myminio/minio-store/
```
