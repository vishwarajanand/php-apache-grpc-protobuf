# php-apache-grpc-protobuf
This repository helps developers create a docker container whereby a PHP code can be run to serve requests over apache server

## Steps to Run

1. `docker build -t vishwaraj00/php-8.0-apache-grpc-protobuf .`
2. `docker push vishwaraj00/php-8.0-apache-grpc-protobuf`

## Instructions

The built image is available in [dockerhub.io](https://hub.docker.com/repository/docker/vishwaraj00/php-8.0-apache-grpc-protobuf).
And can be consumed in other `Dockerfile` as follows:

```
FROM vishwaraj00/php-8.0-apache-grpc-protobuf as build
```

