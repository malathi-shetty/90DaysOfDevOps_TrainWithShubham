FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl

WORKDIR /app

COPY . .

CMD ["cat", "app.txt"]
