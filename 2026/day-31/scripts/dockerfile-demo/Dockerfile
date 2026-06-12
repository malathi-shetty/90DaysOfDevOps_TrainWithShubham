FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl

WORKDIR /app

COPY . .

EXPOSE 8080

CMD ["cat", "message.txt"]
