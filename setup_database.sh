#!/bin/bash

APP_NAME=$1
PROJECT_DIR=$(pwd)/../$APP_NAME

cat > ${PROJECT_DIR}/config/database.yml <<EOF
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