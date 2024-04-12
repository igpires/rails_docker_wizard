#!/bin/bash

echo "Rails Docker Setup Wizard v1.0.0"

validate_version() {
    local version="$1"
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Format of version number is invalid. Please use the format x.y.z"
        exit 1
    fi
}

validate_app_name() {
    local app_name="$1"
    clean_name=$(echo "$app_name" | tr -cd '[:alnum:]_')
    if [[ "$clean_name" != "$app_name" ]]; then
        echo "Error: The application name can only contain letters, numbers, and underscores."
        exit 1
    fi
    if ! [[ "$app_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Error: The application name must start with a letter and can only contain letters, numbers, and underscores."
        exit 1
    fi
}

read -p "Enter your Ruby version or press enter to use the default (3.3.0): " RUBY_VERSION
RUBY_VERSION=${RUBY_VERSION:-"3.3.0"}
validate_version "$RUBY_VERSION"

clear

read -p "Enter your Rails version or press enter to use the default (7.1.0): " RAILS_VERSION
RAILS_VERSION=${RAILS_VERSION:-"7.1.0"}
validate_version "$RAILS_VERSION"

clear

read -p "Enter your application name: " APP_NAME
validate_app_name "$APP_NAME"

clear

echo "Ruby Version: $RUBY_VERSION"
echo "Rails Version: $RAILS_VERSION"
echo "Application Name: $APP_NAME"
echo "This script will create a new Rails API project with the following configurations. Do you want to continue? (y/n)"
read confirmation
if [[ "$confirmation" != "y" ]]; then
    echo "Script aborted."
    exit 1
fi

PROJECT_DIR=$(pwd)/../$APP_NAME

docker run --rm -v "$PROJECT_DIR:/app" ruby:$RUBY_VERSION bash -c "
    gem install rails -v '$RAILS_VERSION' &&
    rails new /app --database=postgresql --skip-bundle  --skip-git --api  --skip-test --skip-system-test --skip-action-mailbox --skip-action-text --skip-active-storage --skip-action-cable --skip-sprockets --skip-spring --skip-javascript --skip-turbolinks --skip-webpack-install --skip-bootsnap &&

    cat > /app/Dockerfile <<EOF
FROM ruby:$RUBY_VERSION
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
WORKDIR /app
COPY . /app
RUN bundle install
CMD [\"rails\", \"server\", \"-b\", \"0.0.0.0\"]
EXPOSE 3000
EOF

    cat > /app/docker-compose.yml <<EOF
services:
  $APP_NAME:
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


    cat > /app/config/database.yml <<EOF
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV['RAILS_MAX_THREADS'] ||  5 %>
  username: <%= ENV['POSTGRES_USER'] || 'postgres' %>
  password: <%= ENV['POSTGRES_PASSWORD'] || 'password' %>
  host: <%= ENV['DB_HOST'] || 'db' %>
  port: <%= ENV['DB_PORT'] || 5432 %>

development:
  <<: *default
  database: ${APP_NAME}_development

test:
  <<: *default
  database: ${APP_NAME}_test

production:
  <<: *default
  database: ${APP_NAME}_production

EOF
"

sudo chown -R $(id -u):$(id -g) "$PROJECT_DIR"

echo 'creating and iniliazing  docker container...'
docker-compose -f "$PROJECT_DIR/docker-compose.yml" up -d --build

echo ' installing gems and creating database...'
docker-compose -f "$PROJECT_DIR/docker-compose.yml" exec $APP_NAME bash -c "bundle install && rails db:prepare"

echo "Project $APP_NAME created successfully in $PROJECT_DIR"