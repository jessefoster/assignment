# For Local Development
UI - \assignment-ui> npm start
Local Database - docker-compose -f .\local-stack.yaml up
Server - \assignment> ./mvnw compile quarkus:dev

# Real Deployment
UI - \assignment-ui> npm run build
Production Assets in \assignment-ui\build
Server - \assignment> ./mvnw compile quarkus:dev