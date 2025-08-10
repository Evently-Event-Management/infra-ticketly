# Use a lightweight, modern Java base image
FROM openjdk:21-slim

# Set an argument for the JAR file name for flexibility
ARG JAR_FILE=target/*.jar

# Copy the built JAR file from your target directory into the container
COPY ${JAR_FILE} app.jar

# Expose the port the gateway runs on (as defined in your application.yml)
EXPOSE 8088

# Set the command to run the application when the container starts
ENTRYPOINT ["java","-jar","/app.jar"]
