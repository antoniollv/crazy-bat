# Crazy Bat Project

## Description

Proof of concept of a container that creates an HTTP service on port 8080 using ***Netcat***.

It shows a sleeping bat. When you hover the mouse pointer over it, the bat wakes up and chases the pointer, displaying the text passed via the `BAT_SAY` environment variable, by example `export BAT_SAY="What's up, doc?"`or other text.

The text is injected into `index.html` *on the fly* using the ***envsubst*** utility.

## Requirements

- [Docker](https://docs.docker.com/) (for container usage)
- [Netcat](https://nc110.sourceforge.io/) (`nc` command, for local tests)
- [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html) (usually included in GNU gettext, for variable substitution)
- Bash or compatible shell (for running local commands)
- Modern web browser (for best animation experience)

### Local test

Open a local shell, and clone de repository

```bash
git clone https://github.com/antoniollv/crazy-bat.git
```

Change to repository directory

```bash
cd crazy-bat
```

Set the environment variable `BAT_SAY`:

```bash
export BAT_SAY="What's up, doc?"
```

Run ***Netcat***:

```bash
while true; do { echo -e 'HTTP/1.1 200 OK\r\n'; envsubst < index.html; } | nc -lNp 8080; done
```

Then access the application in your browser, <http://localhost:8080>

## Test with container

Using [Docker](https://docs.docker.com/), run these two commands in the directory where you cloned the repository and have the files:

- Dockerfile
- index.html

```bash
docker build -t crazybat:snapshot .
docker run --name crazybat -p 8081:8080 -e BAT_SAY="What's up, doc?" --rm -d crazybat:snapshot
```

Access via browser at <http://localhost:8081>

To remove the container:

```bash
docker stop crazybat
```

## Known Issues

### Port Occupied

If you get an error or nothing happens, port 8080 may already be in use by another application.

**How to change the port for this project:**

- For local tests with Netcat, use another port (for example, 8081):

  ```bash
  while true; do { echo -e 'HTTP/1.1 200 OK\r\n'; envsubst < index.html; } | nc -l -p 8081; done
  ```

- For Docker, map a different external port (for example, 8082):

  ```bash
  docker run --name crazybat -p 8082:8080 -e BAT_SAY="What's up, doc?" --rm -d crazybat:snapshot
  ```

Then access the application in your browser at the new port, e.g. <http://localhost:8082>

## Contributing

Contributions are welcome!  
If you want to improve this project, fix bugs, or suggest new features, feel free to open an issue or submit a pull request.

Please follow these steps:
1. Fork the repository.
2. Create a new branch for your changes.
3. Make your changes and commit them.
4. Open a pull request describing your contribution.

---

# Proyecto murciélago loco

## Descripción

Prueba de concepto de un contenedor que crea mediante ***Netcat*** un servicio HTTP en el puerto 8080.

Muestra un murciélago durmiendo. Al pasar el puntero del ratón sobre él, despierta y persigue al puntero, mostrando el texto pasado mediante la variable de entorno `BAT_SAY`, por ejemplo, export `BAT_SAY="What's up, doc?"` o cualquier otro text .

Para que se muestre el texto se modifica el archivo `index.html` *al vuelo* mediante la utilidad ***envsubst***.

## Requisitos

- [Docker](https://docs.docker.com/) (para usar el contenedor)
- [Netcat](https://nc110.sourceforge.io/) (comando `nc`, para pruebas locales)
- [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html) (normalmente incluido en GNU gettext, para sustitución de variables)
- Bash o shell compatible (para ejecutar los comandos locales)
- Navegador web moderno (para mejor experiencia de animación)

## Prueba local

Definimos la variable de entorno `BAT_SAY`:

```bash
export BAT_SAY="What's up, doc?"
```

Ejecución de ***Netcat***:

```bash
while true; do { echo -e 'HTTP/1.1 200 OK\r\n'; envsubst < index.html; } | nc -lNp 8080; done
```

## Prueba mediante contenedor

Mediante [Docker](https://docs.docker.com/), ejecutar estos dos comandos en el directorio donde se haya clonado el repositorio y se tengan los archivos:

- Dockerfile
- index.html

```bash
docker build -t crazybat:snapshot .
docker run --name crazybat -p 8081:8080 -e BAT_SAY="What's up, doc?" --rm -d crazybat:snapshot
```

Accede mediante el navegador a <http://localhost:8081>

Acuérdate de eliminar el contenedor:

```bash
docker stop crazybat
```

## Problemas conocidos

### Puerto ocupado

Si obtienes un error o no ocurre nada, puede que el puerto 8080 ya esté en uso por otra aplicación.

**Cómo cambiar el puerto para este proyecto:**

- Para pruebas locales con *Netcat*, usa otro puerto (por ejemplo, 8081):

  ```bash
  while true; do { echo -e 'HTTP/1.1 200 OK\r\n'; envsubst < index.html; } | nc -lNp 8081; done
  ```

- Para Docker, mapea un puerto externo diferente (por ejemplo, 8082):

  ```bash
  docker run --name crazybat -p 8082:8080 -e BAT_SAY="What's up, doc?" --rm -d crazybat:snapshot
  ```

Después accede a la aplicación en tu navegador usando el nuevo puerto, por ejemplo <http://localhost:8082>

## Contribuciones

¡Se aceptan contribuciones!  
Si quieres mejorar este proyecto, corregir errores o proponer nuevas funcionalidades, puedes abrir un issue o enviar un pull request.

Por favor, sigue estos pasos:
1. Haz un fork del repositorio.
2. Crea una rama nueva para tus cambios.
3. Realiza tus cambios y haz commit.
4. Abre un pull request describiendo tu contribución.
