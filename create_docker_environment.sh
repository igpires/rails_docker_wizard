#!/bin/bash

APP_NAME=$1
RUBY_VERSION=$2
PROJECT_DIR=$(pwd)/../$APP_NAME

# Create dockerfile
cat > ${PROJECT_DIR}/Dockerfile <<EOF
FROM ruby:$RUBY_VERSION
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
WORKDIR /app
COPY . /app
RUN bundle install
CMD ["rails", "server", "-b", "0.0.0.0"]
EXPOSE 3000
EOF

# Create docker-compose.yml
cat > ${PROJECT_DIR}/docker-compose.yml <<EOF
services:
  $APP_NAME:
    container_name: $APP_NAME
    build: .
    ports:
      - '3000:3000'
    volumes:
      - .:/app
    depends_on:
      - ${APP_NAME}_db
    environment:
      DB_HOST: ${APP_NAME}_db
      RAILS_ENV: development
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password

  ${APP_NAME}_db:
    image: postgres:14
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: ${APP_NAME}_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"

volumes:
  postgres_data:

EOF