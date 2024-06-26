#!/bin/bash
source validate_functions.sh

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker and try again."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi


echo "Rails Docker Setup Wizard v1.0.2"

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
    rails new /app --database=postgresql --skip-bundle  --skip-git --api  --skip-test --skip-system-test --skip-action-mailbox --skip-action-text --skip-active-storage --skip-action-cable --skip-sprockets --skip-spring --skip-javascript --skip-turbolinks --skip-webpack-install --skip-bootsnap"

sudo chown -R $(id -u):$(id -g) "$PROJECT_DIR"

echo 'creating docker environment...'
bash $(dirname "$0")/create_docker_environment.sh $APP_NAME $RUBY_VERSION

echo 'setting up database...'
bash $(dirname "$0")/setup_database.sh $APP_NAME

echo 'creating and iniliazing  docker container...'
docker-compose -f "$PROJECT_DIR/docker-compose.yml" up -d --build

echo ' installing gems and creating database...'
docker-compose -f "$PROJECT_DIR/docker-compose.yml" exec $APP_NAME bash -c "bundle install && rails db:prepare"

echo "Project $APP_NAME created successfully in $PROJECT_DIR"