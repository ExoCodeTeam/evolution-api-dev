#!/bin/bash

source ./Docker/scripts/env_functions.sh

if [ "$DOCKER_ENV" != "true" ]; then
    export_env_vars
fi

if [[ "$DATABASE_PROVIDER" == "postgresql" || "$DATABASE_PROVIDER" == "mysql" || "$DATABASE_PROVIDER" == "psql_bouncer" ]]; then
    export DATABASE_URL
    echo "Deploying migrations for $DATABASE_PROVIDER"
    echo "Database URL: $DATABASE_URL"
    # Ensure DATABASE_URL and DATABASE_CONNECTION_URI are in .env so
    # dotenv (in runWithProvider.js and prisma.config.ts) can read them.
    # The container ships with .env.example as .env which lacks the real
    # connection string; writing it here guarantees Prisma finds it.
    if [ -n "$DATABASE_URL" ]; then
      grep -q '^DATABASE_URL=' .env 2>/dev/null && sed -i "s|^DATABASE_URL=.*|DATABASE_URL=${DATABASE_URL}|" .env || echo "DATABASE_URL=${DATABASE_URL}" >> .env
    fi
    if [ -n "$DATABASE_CONNECTION_URI" ]; then
      grep -q '^DATABASE_CONNECTION_URI=' .env 2>/dev/null && sed -i "s|^DATABASE_CONNECTION_URI=.*|DATABASE_CONNECTION_URI=${DATABASE_CONNECTION_URI}|" .env || echo "DATABASE_CONNECTION_URI=${DATABASE_CONNECTION_URI}" >> .env
    fi
    npm run db:deploy
    if [ $? -ne 0 ]; then
        echo "Migration failed"
        exit 1
    else
        echo "Migration succeeded"
    fi
    npm run db:generate
    if [ $? -ne 0 ]; then
        echo "Prisma generate failed"
        exit 1
    else
        echo "Prisma generate succeeded"
    fi
else
    echo "Error: Database provider $DATABASE_PROVIDER invalid."
    exit 1
fi
