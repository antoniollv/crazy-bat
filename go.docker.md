# Construye tu imagen de Go con Docker

## Descripción general

Referencia: [Build your Go image](https://docs.docker.com/language/golang/build-images/)

Crea una *imagen de contenedor* que incluya todo lo que necesitas para ejecutar una aplicación **Go**: el archivo binario compilado, la *runtime de Go*, las bibliotecas y el resto de recursos que requiera la aplicación.

## Software requerido
Necesita lo siguiente:

- [*Go* versión 1.19 o posterior](https://golang.org/dl/)
- *Docker* ejecutándose localmente.
- Un IDE o un editor de texto para editar archivos.
- Un cliente Git.
- Una aplicación de terminal de línea de comandos. Los ejemplos que se muestran provienen del shell de Linux.

## Sobre la aplicación de ejemplo

La aplicación de ejemplo es una *caricatura* de un microservicio. Es intencionalmente trivial para permanecer enfocados en los conceptos básicos de creación de aplicaciones mediante *contenedores*.

La aplicación ofrece dos *endpoints HTTP*:

- Responde con una cadena que contiene un símbolo de corazón `<3` a las solicitudes de `/`'.
- Responde con `{"Status" : "OK"}` JSON a una solicitud a `/health`.

Responde con el error **HTTP 404** a cualquier otra solicitud.

La aplicación escucha en un puerto TCP definido por el valor de la variable de entorno `PORT`. El valor predeterminado es `8080``.

La aplicación no tiene estado.

El código fuente completo de la aplicación está en **GitHub**: [github.com/docker/docker-gs-ping](https://github.com/docker/docker-gs-ping).

Para continuar, clona el repositorio de aplicaciones en tu máquina local:

```BASH
git clone https://github.com/docker/docker-gs-ping
```

El archivo `main.go`` de la aplicación es sencillo si estás familiarizado con *Go*:

```GO
package main

import (
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {

	e := echo.New()

	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	e.GET("/", func(c echo.Context) error {
		return c.HTML(http.StatusOK, "Hello, Docker! <3")
	})

	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, struct{ Status string }{Status: "OK"})
	})

	httpPort := os.Getenv("PORT")
	if httpPort == "" {
		httpPort = "8080"
	}

	e.Logger.Fatal(e.Start(":" + httpPort))
}

// Simple implementation of an integer minimum
// Adapted from: https://gobyexample.com/testing-and-benchmarking
func IntMin(a, b int) int {
	if a < b {
		return a
	}
	return b
}
```

## Prueba de humo de la aplicación.

Inicia tu aplicación y asegúrate de que se esté ejecutando. Abre un terminal de intérprete de comandos y navega hasta el directorio en el que se clonó el repositorio del proyecto. De ahora en adelante el directorio del proyecto.

```BASH
go run main.go
```

Esto debería compilar e iniciar el servidor como una aplicación de primer plano, generando el banner, como se ilustra en la siguiente figura.

```
   ____    __
  / __/___/ /  ___
 / _// __/ _ \/ _ \
/___/\__/_//_/\___/ v4.10.2
High performance, minimalist Go web framework
https://echo.labstack.com
____________________________________O/_______
                                    O\
⇨ http server started on [::]:8080
```

Ejecute una prueba de humo rápida accediendo a la aplicación en <http://localhost:8080>. Puedes usar un navegador web, o un comando *CURL* en la terminal:

```BASH
curl http://localhost:8080/
```

```
Hello, Docker! <3
```

Esto verifica que la aplicación se compila localmente e inicia sin errores. 

Ya estamos listos para colocar la aplicación en un *contenedor*.

## Crea un *Dockerfile* para la aplicación.

Para crear una *imagen de contenedor* con **Docker** se necesita un archivo *Dockerfile* con instrucciones de construcción.

El archivo *Dockerfile* empieza con la línea *parser* (opcional) que le indica al *BuildKit* que interprete su archivo de acuerdo con las reglas gramaticales de la versión especificada.

```DOCKERFILE
# syntax=docker/dockerfile:1
```

Luego le dice a *Docker* qué imagen base le gustaría usar para su aplicación:

```DOCKERFILE
FROM golang:1.19

```

Las *imágenes de Docker* se pueden heredar de otras *imágenes*. Por lo tanto, en lugar de crear tu propia *imagen* base desde cero, puedes utilizar la *imagen* oficial de **Go** que ya cuenta con todas las herramientas y bibliotecas necesarias para compilar y ejecutar una aplicación **Go**.

Ahora que has definido la *imagen* base para tu próxima *imagen de contenedor*, puedes comenzar a construir sobre ella.

Para facilitar las cosas al ejecutar el resto de los comandos, crea un directorio dentro de la *imagen* que estás creando. Esto también le indica a **Docker** que use este directorio como destino predeterminado para todos los comandos posteriores. De esta manera, no es necesario escribir las rutas completas de los archivos en el archivo *Dockerfile*, las rutas relativas se basarán en este directorio.

```DOCKERFILE
WORKDIR /app
```

Normalmente lo primero que haces una vez que has descargado un proyecto escrito en *Go* es instalar los módulos necesarios para compilarlo. Ten en cuenta que la *imagen* base ya tiene la cadena de herramientas, pero su código fuente aún no está en ella.

Entonces, antes de poder ejecutar `go mod download` dentro de tu *imagen*, debes copiar tus archivos `go.mod` y `go.sum` en ella. Utiliza el comando `COPY` para hacer esto.

En su forma más simple, el comando `COPY` toma dos parámetros. El primer parámetro le dice a **Docker** qué archivos desea copiar en la *imagen*. El último parámetro le dice a **Docker** dónde desea que se copie ese archivo.

Copia los archivos `go.mody` y `go.sum` en el directorio del proyecto `/app` que debido al uso de `WORKDIR`, es el directorio actual `./` dentro de la *imagen*. A diferencia de algunos *shells* modernos que parecen ser indiferentes al uso de la barra diagonal final `/` y pueden descifrar lo que quiso decir el usuario la mayor parte del tiempo, el comando `COPY` de **Docker** es bastante sensible en su interpretación de la barra diagonal final.

```DOCKERFILE
COPY go.mod go.sum ./
```

Ahora que tienes los archivos necesarios dentro de la *imagen de Docker* que estás creando puede usar el comando `RUN` para ejecutar `go mod download`. Esto funciona exactamente igual que si estuvieras ejecutando `go` localmente en tu máquina, pero esta vez estos módulos **Go** se instalarán en un directorio dentro de la *imagen*.

```DOCKERFILE
RUN go mod download
```

En este punto tienes la versión 1.19.x de **Go** y todas sus dependencias instaladas dentro de la *imagen*.

Lo siguiente que debes hacer es copiar tu código fuente en la *imagen*. Utilizará el comando `COPY` tal como se hizo antes con los archivos del módulo.

```DOCKERFILE
COPY *.go ./
```

Este comando `COPY` utiliza un comodín para copiar todos los archivos con extensión `.go` ubicados en el directorio actual del host, el directorio donde se encuentra el archivo `Dockerfile` al directorio actual dentro de la imagen.

Ahora para compilar la aplicación usa el comando `RUN`

```DOCKERFILE
RUN CGO_ENABLED=0 GOOS=linux go build -o /docker-gs-ping
```

El resultado de ese comando será el binario de aplicación estática llamado `docker-gs-pingy` ubicado en la raíz del sistema de archivos de la *imagen* que está creando. Se podría haber puesto el binario en cualquier otro lugar dentro de la *imagen*. Es conveniente mantener las rutas de los archivos cortas para mejorar la legibilidad.

Ahora, todo lo que queda por hacer es decirle a Docker qué comando ejecutar cuando su imagen se use para iniciar un contenedor.

Esto lo haces con el comando `CMD`

```DOCKERFILE
CMD ["/docker-gs-ping"]
```

El archivo Dockerfile completo

```DOCKERFILE
# syntax=docker/dockerfile:1

FROM golang:1.19

# Set destination for COPY
WORKDIR /app

# Download Go modules
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code. Note the slash at the end, as explained in
# https://docs.docker.com/engine/reference/builder/#copy
COPY *.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -o /docker-gs-ping

# Optional:
# To bind to a TCP port, runtime parameters must be supplied to the docker command.
# But we can document in the Dockerfile what ports
# the application is going to listen on by default.
# https://docs.docker.com/engine/reference/builder/#expose
EXPOSE 8080

# Run
CMD ["/docker-gs-ping"]
```

*Dockerfile* También pueden contener comentarios. Siempre comienzan con un símbolo `#`  y deben estar al principio de una línea.

Las directivas siempre deben estar en la parte superior de los archivo *Dockerfile*, por lo que al agregar comentarios irán después de cualquier directiva que se haya utilizado:

```DOCKERFILE
# syntax=docker/dockerfile:1
# A sample microservice in Go packaged into a container image.

FROM golang:1.19

# ...
```

## Construir la *imagen*

Ahora que ya has creado tu archivo *Dockerfile*, crea una imagen a partir de él. El comando `docker build` crea imágenes de **Docker** a partir del archivo `Dockerfile` y un contexto. Un contexto de compilación es el conjunto de archivos ubicados en la ruta o URL especificada. El proceso de compilación de **Docker** puede acceder a cualquiera de los archivos ubicados en el contexto.

El comando de compilación opcionalmente toma el modificador `--tag`. Este modificador se utiliza para etiquetar la *imagen* con una  cadena de texto que es fácil de leer y reconocer. Si no se pasa el modificador `--tag`, **Docker** utilizará `latest` como valor predeterminado.

Crea la *imagen de Docker*.

```BASH
docker build --tag docker-gs-ping .
```

El proceso de compilación mostrará algunos mensajes de diagnóstico a medida que avanza por los pasos de compilación. El texto siguiente es sólo un ejemplo de cómo pueden verse estos mensajes.

```TEXT
[+] Building 2.2s (15/15) FINISHED
 => [internal] load build definition from Dockerfile                                                                                       0.0s
 => => transferring dockerfile: 701B                                                                                                       0.0s
 => [internal] load .dockerignore                                                                                                          0.0s
 => => transferring context: 2B                                                                                                            0.0s
 => resolve image config for docker.io/docker/dockerfile:1                                                                                 1.1s
 => CACHED docker-image://docker.io/docker/dockerfile:1@sha256:39b85bbfa7536a5feceb7372a0817649ecb2724562a38360f4d6a7782a409b14            0.0s
 => [internal] load build definition from Dockerfile                                                                                       0.0s
 => [internal] load .dockerignore                                                                                                          0.0s
 => [internal] load metadata for docker.io/library/golang:1.19                                                                             0.7s
 => [1/6] FROM docker.io/library/golang:1.19@sha256:5d947843dde82ba1df5ac1b2ebb70b203d106f0423bf5183df3dc96f6bc5a705                       0.0s
 => [internal] load build context                                                                                                          0.0s
 => => transferring context: 6.08kB                                                                                                        0.0s
 => CACHED [2/6] WORKDIR /app                                                                                                              0.0s
 => CACHED [3/6] COPY go.mod go.sum ./                                                                                                     0.0s
 => CACHED [4/6] RUN go mod download                                                                                                       0.0s
 => CACHED [5/6] COPY *.go ./                                                                                                              0.0s
 => CACHED [6/6] RUN CGO_ENABLED=0 GOOS=linux go build -o /docker-gs-ping                                                                  0.0s
 => exporting to image                                                                                                                     0.0s
 => => exporting layers                                                                                                                    0.0s
 => => writing image sha256:ede8ff889a0d9bc33f7a8da0673763c887a258eb53837dd52445cdca7b7df7e3                                               0.0s
 => => naming to docker.io/library/docker-gs-ping                                                                                          0.0s
```

Su resultado exacto variará, pero siempre que no haya ningún error, debería ver la palabra `FINISHED` en la salida del comando. Esto significa que **Docker** ha creado con éxito tu *imagen*, llamada `docker-gs-ping`.

## Ver *imágenes* locales

Para ver la lista de *imágenes* que tienes en tu máquina local, tienes dos opciones. Una es usar la *CLI* y el otro es usar *Docker Desktop*. Dado que actualmente estás trabajando en la terminal, echa un vistazo a la lista de *imágenes* con la *CLI*.

Para enumerar imágenes, ejecute el comando `docker image ls` o `docker images` abreviado.

```BASH
docker image ls
```

```
REPOSITORY                       TAG       IMAGE ID       CREATED         SIZE
docker-gs-ping                   latest    7f153fbcc0a8   2 minutes ago   1.11GB
...
```

El resultado exacto puede variar, pero deberías ver la *imagen* `docker-gs-ping` con la *etiqueta* `latest`. Debido a que no se especificó una *etiqueta* personalizada cuando se creó la *imagen*, **Docker** asumió que la *etiqueta* sería *latest*, que es un valor especial.

## Etiquetar *imágenes*

El nombre de una *imagen* se compone de componentes de nombre separados por barras. Los componentes del nombre pueden contener letras minúsculas, dígitos y separadores. Un separador se define como un punto, uno o dos guiones bajos o uno o más guiones. Un componente de nombre no puede comenzar ni terminar con un separador.

Una *imagen* se compone de un manifiesto y una lista de capas. En términos simples, una *etiqueta* apunta a una combinación de estos artefactos. Puede tener varias etiquetas para la *imagen* y, de hecho, la mayoría de las imágenes tienen varias *etiquetas*.

Utiliza el comando `docker image tag` o `docker tag` abreviado, para crear una nueva *etiqueta* para tu *imagen*. Este comando toma dos argumentos; el primer argumento es la *imagen* de origen y el segundo es la nueva *etiqueta* a crear. El siguiente comando crea una nueva *etiqueta* `docker-gs-ping:v1.0`

```BASH
docker image tag docker-gs-ping:latest docker-gs-ping:v1.0
```

El comando `docker tag` crea una nueva *etiqueta* para la *imagen*, no crea una nueva *imagen*. La *etiqueta* apunta a la misma *imagen* y es simplemente otra forma de hacer referencia a la *imagen*.

Ahora ejecutando nuevamente el comando `docker image ls` veremos la lista actualizada de *imágenes* locales:

```BASH
docker image ls
```

```
REPOSITORY                       TAG       IMAGE ID       CREATED         SIZE
docker-gs-ping                   latest    7f153fbcc0a8   6 minutes ago   1.11GB
docker-gs-ping                   v1.0      7f153fbcc0a8   6 minutes ago   1.11GB
...
```

Puedes ver que tienes dos imágenes que comienzan con `docker-gs-ping`. Sabes que son la misma imagen porque si miras la columna `IMAGE ID`, puedes ver que los valores son los mismos para las dos *imágenes*. Este valor es un identificador único que **Docker** utiliza internamente para identificar la *imagen*.

Elimina la *etiqueta* que acabas de crear. Para hacer esto, usará el comando `docker image rm` o la abreviatura `docker rmi`

```BASH
docker image rm docker-gs-ping:v1.0
```

```
Untagged: docker-gs-ping:v1.0
```

Observa que la respuesta de **Docker** indica que la *imagen* no se ha eliminado, solo se ha desetiquetado.

Verifique esto ejecutando el siguiente comando:

```BASH
docker image ls
```

Verás que la *etiqueta* `v1.0` ya no está en la lista de *imágenes* mantenida por la *instancia de Docker*.

```
REPOSITORY                       TAG       IMAGE ID       CREATED         SIZE
docker-gs-ping                   latest    7f153fbcc0a8   7 minutes ago   1.11GB
...
```

La *etiqueta* `v1.0` se eliminó pero aún tiene la etiqueta `docker-gs-ping:latest` disponible en tu máquina, por lo que la *imagen* está ahí.

## Construcciones en varias etapas

Es posible que hayas notado que tu *imagen* `docker-gs-ping` pesa más de un gigabyte, lo cual es mucho para una pequeña aplicación **Go** compilada. Quizás también te preguntes qué pasó con el conjunto completo de herramientas **Go**, incluido el compilador, después de haber creado la `imagen`.

La respuesta es que la cadena de herramientas completa todavía está ahí, en la *imagen del contenedor*. Esto no sólo es un inconveniente debido al gran tamaño del archivo, sino que también puede presentar un riesgo de seguridad cuando se implementa el *contenedor*.

Estos dos problemas se pueden resolver mediante construcciones en varias etapas.

En pocas palabras, una construcción en varias etapas puede transferir los *artefactos* de una etapa de compilación a otra, y se puede crear una *instancia* de cada etapa de compilación a partir de una *imagen* base diferente.

Por lo tanto, en el siguiente ejemplo, utilizaremos una *imagen* oficial de **Go** para crear la aplicación. Luego, copiaremos el binario de la aplicación en otra *imagen* cuya base sea más sencilla y no incluya las *herramientas Go* ni otros componentes opcionales.

El archivo *`Dockerfile.multistage` de la aplicación de ejemplo tiene el siguiente contenido:

```DOCKERFILE
# syntax=docker/dockerfile:1

# Build the application from source
FROM golang:1.19 AS build-stage

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -o /docker-gs-ping

# Run the tests in the container
FROM build-stage AS run-test-stage
RUN go test -v ./...

# Deploy the application binary into a lean image
FROM gcr.io/distroless/base-debian11 AS build-release-stage

WORKDIR /

COPY --from=build-stage /docker-gs-ping /docker-gs-ping

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/docker-gs-ping"]
```

Como ahora tenemos dos *Dockerfiles*, debemos decirle a **Docker** qué *Dockerfile* le gustaría usar para crear la *imagen*. Etiqueta la nueva *imagen* con multistage. Esta *etiqueta*, como cualquier otra, aparte de latest, no tiene un significado especial para **Docker**, es simplemente algo que uno elige.

```BASH
docker build -t docker-gs-ping:multistage -f Dockerfile.multistage .
```

Al comparar los tamaños de `docker-gs-ping:multistage` y `docker-gs-ping:latest` se ven las diferencias.

```BASH
docker image ls
```

```
REPOSITORY       TAG          IMAGE ID       CREATED              SIZE
docker-gs-ping   multistage   e3fdde09f172   About a minute ago   28.1MB
docker-gs-ping   latest       336a3f164d0f   About an hour ago    1.11GB
```

Esto es así porque los **`gcr.io/distroless`**, la *imagen* base que ha utilizado en la segunda etapa de la construcción es muy básica y está diseñada para implementaciones sencillas de binarios estáticos.

Hay mucho más sobre las construcciones en múltiples etapas, incluida la posibilidad de compilar para múltiples arquitecturas.

---

# Lanzar *imágenes de contenedor*, *ejecutar contenedores*

## Descripción general

En el tema anterior, creamos un archivo *Dockerfile* para la aplicación **Go** de ejemplo, se creó una *imagen de Docker* usando el comando `docker build`. Ahora que tenemos la *imagen*, podemos ejecutarla y ver si la aplicación se ejecuta correctamente.

Un *contenedor* es un proceso normal del sistema operativo excepto que este proceso está aislado y tiene su propio sistema de archivos, su propia red y su propio árbol de procesos aislado separado del host.

Para ejecutar una *imagen* dentro de un *contenedor*, usa el comando `docker run`. Requiere un parámetro y ese es el nombre de la *imagen*. Lanza tu *imagen* y asegúrate de que se esté ejecutando correctamente. Ejecuta el siguiente comando en la terminal.

```BASH
docker run docker-gs-ping
```

```
   ____    __
  / __/___/ /  ___
 / _// __/ _ \/ _ \
/___/\__/_//_/\___/ v4.10.2
High performance, minimalist Go web framework
https://echo.labstack.com
____________________________________O/_______
                                    O\
⇨ http server started on [::]:8080
```

Cuando se ejecute este comando, notarás que el *prompt* no regresó al símbolo del sistema. Esto se debe a que la aplicación es un servidor REST y se ejecutará en un bucle esperando solicitudes entrantes sin devolver el control al sistema operativo hasta que se detenga el contenedor.

Realiza una solicitud GET al servidor utilizando el comando `curl`.

```BASH
curl http://localhost:8080/
```

```
curl: (7) Failed to connect to localhost port 8080: Connection refused
```

El comando `curl` falló porque se rechazó la conexión al servidor. Lo que significa que no pudo conectarse a *localhost* en el *puerto* 8080. Esto es de esperarse porque el *contenedor* se ejecuta de forma aislada, lo que incluye la red. Deten el contenedor y reinícialo con el *puerto* 8080 publicado en tu red local.

Para detener el contenedor, pulsa `Ctrl-c`. Con esto regresará al *prompt* del terminal.

Para publicar un *puerto* para el *contenedor*, hay que usar el modificador `--publish`,  `-p` para abreviar con el comando `docker run`. El formato de `--publish` es `[host_port]:[container_port]`. Entonces, si quisiera exponer el *puerto* 8080 dentro del *contenedor* al *puerto* 3000 fuera del contenedor, pasaría `3000:8080` al modificador `--publish`.

Inicia el *contenedor* y expón el *puerto* 8080 en el puerto 8080 del host.

```BASH
docker run --publish 8080:8080 docker-gs-ping
```

Ahora, vuelve a ejecutar el comando curl.

```BASH
curl http://localhost:8080/
```

```
Hello, Docker! <3
```

¡Éxito! Te has conectado a la aplicación que se ejecuta dentro de tu *contenedor* en el *puerto* 8080. Si vuelves a la terminal donde se ejecuta tu contenedor debería ver la solicitud *GET* registrada en la consola.

Pulsa `ctrl-c` para detener el *contenedor*.

## Ejecutar en modo independiente

Esto está bien, pero la aplicación de ejemplo es un servidor web y el contenedor no debería depender de una terminal abierta. **Docker** puede ejecutar el contenedor de modo independiente, en segundo plano. Para hacer esto, puedes usar `--detach` o `-d` abreviado. **Docker** iniciará el *contenedor* de la misma manera que antes, pero esta vez se separará el contenedor de la terminal y regresará el *prompt* a la terminal.

```BASH
docker run -d -p 8080:8080 docker-gs-ping
```

```
d75e61fcad1e0c0eca69a3f767be6ba28a66625ce4dc42201a8a323e8313c14e
```

*Docker* inicia el *contenedor* en segundo plano y muestra la identificación del *contenedor* en la terminal.

Nos aseguramos que el contenedor se esté ejecutando. Ejecuta el mismo comando `curl` anterior:

```BASH
curl http://localhost:8080/
```

```
Hello, Docker! <3
```

## Listar contenedores

Dado que se ejecutó el *contenedor* en segundo plano, ¿cómo saber si el *contenedor* se está ejecutando o qué otros *contenedores* se están ejecutando en tu máquina? Bueno, para ver una lista de *contenedores* que se ejecutan en tu máquina, ejecuta `docker ps`. Esto es similar a cómo se usa el comando `ps` para ver una lista de procesos en una máquina Linux.

```BASH
docker ps
```

```
CONTAINER ID   IMAGE            COMMAND             CREATED          STATUS          PORTS                    NAMES
d75e61fcad1e   docker-gs-ping   "/docker-gs-ping"   41 seconds ago   Up 40 seconds   0.0.0.0:8080->8080/tcp   inspiring_ishizaka
```

El comando `ps` dice un montón de cosas sobre tus contenedores en ejecución. Puedes ver el ***ID del contenedor***, la ***imagen*** que se ejecuta dentro del *contenedor*, el ***comando*** que se usó para iniciar el *contenedor*, ***cuándo se creó***, ***el estado***, l***os puertos expuestos*** y ***los nombres del contenedor***.

Probablemente te estés preguntando de dónde viene el nombre de tu *contenedor*. Como no se proporcionó un nombre para el *contenedor* cuando inició, **Docker** generó un nombre aleatorio. Arreglaremos esto en un minuto, pero primero debes detener el *contenedor*. Para detener el *contenedor*, ejecuta el comando `docker stop`, pasando ***el nombre*** o ***ID del contenedor***.

```BASH
docker stop inspiring_ishizaka
```

```
inspiring_ishizaka
```

Ahora vuelva a ejecutar el comando `docker ps` para ver de nuevo la lista de *contenedores* en ejecución.

```BASH
docker ps
```

```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

## Detener, iniciar y nombrar *contenedores*

Los *contenedores Docker* se pueden iniciar, detener y reiniciar. Cuando detiene un *contenedor*, no se elimina, pero el estado cambia a detenido y se detiene el proceso dentro del *contenedor*. Cuando ejecutó el comando `docker ps`, el resultado predeterminado es mostrar solo los *contenedores* en ejecución. Si pasas el modificador `--all` o `-a` abreviado, verás todos los *contenedores* en el sistema, incluidos los *contenedores* detenidos y los *contenedores* en ejecución.

```BASH
docker ps --all
```

```
CONTAINER ID   IMAGE            COMMAND                  CREATED              STATUS                      PORTS     NAMES
d75e61fcad1e   docker-gs-ping   "/docker-gs-ping"        About a minute ago   Exited (2) 23 seconds ago             inspiring_ishizaka
f65dbbb9a548   docker-gs-ping   "/docker-gs-ping"        3 minutes ago        Exited (2) 2 minutes ago              wizardly_joliot
aade1bf3d330   docker-gs-ping   "/docker-gs-ping"        3 minutes ago        Exited (2) 3 minutes ago              magical_carson
52d5ce3c15f0   docker-gs-ping   "/docker-gs-ping"        9 minutes ago        Exited (2) 3 minutes ago              gifted_mestorf
```

Si has estado siguiendo las instrucciones, deberías ver varios *contenedores* en la lista. Estos son *contenedores* que se iniciaron y se detuvieron pero que aún no se han eliminado.

Reinicia el *contenedor* que acabas de detener. Localiza el nombre del *contenedor* y reemplázalo en el siguiente comando `restart`:

```BASH
docker restart inspiring_ishizaka
```
Ahora, enumera todos los contenedores nuevamente usando el comando `ps`:

```BASH
docker ps -a
```

```
CONTAINER ID   IMAGE            COMMAND                  CREATED          STATUS                     PORTS                    NAMES
d75e61fcad1e   docker-gs-ping   "/docker-gs-ping"        2 minutes ago    Up 5 seconds               0.0.0.0:8080->8080/tcp   inspiring_ishizaka
f65dbbb9a548   docker-gs-ping   "/docker-gs-ping"        4 minutes ago    Exited (2) 2 minutes ago                            wizardly_joliot
aade1bf3d330   docker-gs-ping   "/docker-gs-ping"        4 minutes ago    Exited (2) 4 minutes ago                            magical_carson
52d5ce3c15f0   docker-gs-ping   "/docker-gs-ping"        10 minutes ago   Exited (2) 4 minutes ago                            gifted_mestorf
```

Observa que el *contenedor* que acabas de reiniciar se inició en modo desconectado y tiene el *puerto* 8080 expuesto. Además, ten en cuenta que el ***estado*** del *contenedor* es ***Up X seconds***. Cuando reinicias un *contenedor*, se iniciará con los mismos indicadores o comandos con los que se inició originalmente.

Detén y elimina todos tus *contenedores* y echa un vistazo a cómo solucionar el problema de nombres aleatorios.

Detén el *contenedor* que acaba de iniciar. Busca el nombre del *contenedor* en ejecución y reemplaza el nombre en el siguiente comando con el nombre del *contenedor* en tu sistema:

```BASH
docker stop inspiring_ishizaka
```

```
inspiring_ishizaka
```

Ahora que todos los contenedores están detenidos, *¡elimínalos!*. Cuando se elimina un *contenedor*, ya no se ejecuta ni se encuentra en estado detenido. El proceso dentro del contenedor finaliza y se eliminan los metadatos del *contenedor*.

Para eliminar un *contenedor*, ejecuta el comando `docker rm` pasando el ***nombre*** o el ***ID del contenedor***. Puedes pasar varios *nombres de contenedores* al comando en una sola ejecución.

Asegúrese de reemplazar los ***nombres de los contenedores*** en el siguiente comando con los ***nombres de los contenedores*** de tu sistema:

```BASH
docker rm inspiring_ishizaka wizardly_joliot magical_carson gifted_mestorf
```

```
inspiring_ishizaka
wizardly_joliot
magical_carson
gifted_mestorf
```

Ejecuta el comando `docker ps --all` nuevamente para verificar que todos los *contenedores* han desaparecido.

Ahora, abordaremos el molesto problema de los nombres aleatorios. La práctica estándar es nombrar tus *contenedores* por la sencilla razón de que es más fácil identificar qué se está ejecutando en el *contenedor* y con qué aplicación o servicio está asociado.

Para nombrar un contenedor, debes pasar el modificador  `--name` al comando `run`:

```
docker run -d -p 8080:8080 --name rest-server docker-gs-ping
```

```
3bbc6a3102ea368c8b966e1878a5ea9b1fc61187afaac1276c41db22e4b7f48f
```

```BASH
docker ps
```

```
CONTAINER ID   IMAGE            COMMAND             CREATED          STATUS          PORTS                    NAMES
3bbc6a3102ea   docker-gs-ping   "/docker-gs-ping"   25 seconds ago   Up 24 seconds   0.0.0.0:8080->8080/tcp   rest-server
```

Ahora puedes identificar fácilmente tu *contenedor* según el nombre.
