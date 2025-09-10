FROM alpine:3.19.0
ENV TEAM="What's up, doc?"
RUN apk add envsubst
WORKDIR /app
COPY index.html ./
EXPOSE 8080
CMD [ "/bin/sh", "-c", "while true; do { echo -e 'HTTP/1.1 200 OK\r\n'; envsubst < /app/index.html; } | nc -lk -p 8080; done" ]
