FROM alpine:3.19.0
ENV TEAM="Mi equipo"
RUN apk add envsubst
WORKDIR /app
COPY index.html ./
EXPOSE 8080
CMD [ "/bin/sh", "-c", "apk add envsubst && while true; do { echo -e 'HTTP/1.1 200 OK\r\n'; envsubst < /app/index.html; } | nc -l -p 8080; done" ]
