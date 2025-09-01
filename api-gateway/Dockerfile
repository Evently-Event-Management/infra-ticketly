# Build stage
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Run stage
FROM openjdk:21-slim

# Copy the built JAR file from the build stage
COPY --from=build /app/target/*.jar app.jar

# Expose the port the gateway runs on (as defined in your application.yml)
EXPOSE 8088

# Set the command to run the application when the container starts
ENTRYPOINT ["java","-jar","/app.jar"]
