# Proyecto murciélago loco

## Pasos

Para probar el contenedor en local docker instalado ejecuta estos dos comandos en el directorio donde tengas los archivos

- Dockerfile
- index.html

```BASH
docker build -t antoniollv/murcielego:loco .
docker run --name murcielagoloco -p 8081:8080 -e TEAM="MI EQUIPO ES EL MEJOR" --rm -d antoniollv/murcielego:loco
```

Accede mediante el navegador a <http://localhost:8081>

Acuérdate de eliminar el contenedor

```BASH
docker stop murcielagoloco
```
