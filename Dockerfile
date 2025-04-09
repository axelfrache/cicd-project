# Stage 1: Build the application
FROM maven:3.9-eclipse-temurin-21 AS maven_build

WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN mvn package -DskipTests

# Stage 2: Run the application
FROM amazoncorretto:21-alpine

RUN apk add --no-cache curl

WORKDIR /app

EXPOSE 2022

COPY --from=maven_build /app/target/*.jar /app/application.jar

CMD ["java", "-jar", "/app/application.jar"] 