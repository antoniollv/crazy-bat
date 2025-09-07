# Proyecto murciélago loco

## Descripción

Prueba de concepto de un contenedor que crea mediante ***Netcat*** un servicio HTTP en el puerto 8080.

Muestra un murciélago durmiendo. Al pasar el puntero del ratón sobre el, despierta y persigue al puntero, mostrando el texto pasado mediante la variable de entorno `TEAM`

Para que se muestre el texto se modifica el archivo `index.html` *al vuelo* mediante la utilidad ***envsubst***

## Ejecución

### Prueba local

Ejecutamos en una terminal 

Definimos la variable de entorno `TEAM`

```Bash
export TEAM="What's up, doc?"
```

Ejecución de ***Netcat***

```Bash
while true; do { echo -e 'HTTP/1.1 200 OK\r\n'; envsubst < index.html; } | nc -l -p 8080 -N; done
```

### Prueba mediante contenedor

Mediante  [Docker](https://docs.docker.com/), ejecutar estos dos comandos en el directorio donde se haya clonado el repositorio y se tengan los archivos:

- Dockerfile
- index.html

```BASH
docker build -t crazybat:snapshot .
docker run --name crazybat -p 8081:8080 -e TEAM='What\'s up, doc?' --rm -d crazybat:snapshot
```

Accede mediante el navegador a <http://localhost:8081>

Acuérdate de eliminar el contenedor

```BASH
docker stop crazybat
```
