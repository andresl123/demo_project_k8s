# ---- 1) Build stage ----
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /app

# Leverage Docker layer caching:
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw -q -B -DskipTests dependency:go-offline

# Copy sources and build
COPY src ./src
RUN chmod +x mvnw
RUN ./mvnw -q -B -DskipTests package

# ---- 2) Runtime stage ----
FROM eclipse-temurin:17-jre-jammy AS runtime
WORKDIR /app

# Non-root user (safer)
RUN useradd -m spring
USER spring

# Copy the fat jar from the build stage
# Adjust the jar name if your artifact is different
COPY --from=build /app/target/*-SNAPSHOT.jar app.jar
RUN java -Djarmode=layertools -jar app.jar extract

# 2. Add layers in correct order (cached!)
COPY --from=build /app/dependencies/ ./
COPY --from=build /app/spring-boot-loader/ ./
COPY --from=build /app/snapshot-dependencies/ ./
COPY --from=build /app/application/ ./

# Optional: set heap ergonomics for containers
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport"

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || curl -f http://localhost:8080/hello || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
