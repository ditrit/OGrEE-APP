## Build backend
FROM golang:1.19.3-buster AS build

WORKDIR /app

COPY ogree_app_backend/go.mod ./
COPY ogree_app_backend/go.sum ./
RUN go mod download

COPY ogree_app_backend/*.go ./
COPY ogree_app_backend/.env ./

RUN go build -o ogree_app_backend

# Install OS and dependencies to run frontend and backend
FROM ubuntu:20.04
ENV GIN_MODE=release
ENV TZ=Europe/Paris \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update 
RUN apt-get install -y curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback lib32stdc++6 python3
RUN apt-get clean

# Get backend from its build
COPY --from=build /app/ogree_app_backend /app/ogree_app_backend
COPY ogree_app_backend/.env /app/

# Copy frontend
RUN mkdir -p /app/build/web/
COPY ogree_app/build/web/ /app/build/web
WORKDIR /app/

# Record the exposed ports: 5000 frontend, 8080 backend
EXPOSE 5000
EXPOSE 8080

# Make server startup script executable and start the web server
COPY server.sh /app/
RUN ["chmod", "+x", "/app/server.sh"]

ENTRYPOINT [ "/app/server.sh"]