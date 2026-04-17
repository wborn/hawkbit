# hawkBit Update Server

[![Docker Image](https://github.com/openremote/hawkbit/actions/workflows/hawkbit.yml/badge.svg)](https://github.com/openremote/hawkbit/actions/workflows/hawkbit.yml)

hawkBit update server Docker image with:

* Java 21 runtime
* Multi-architecture image publishing for `linux/amd64` and `linux/arm64`
* The official `hawkbit-update-server` JAR downloaded from Maven Central during image build
* GPG signature verification of the downloaded JAR using the bundled Eclipse hawkBit public key
* Image publishing to `openremote/hawkbit-update-server`

## Published tags

The GitHub Actions workflow publishes:

* `openremote/hawkbit-update-server:develop` on pushes to `main`
* `openremote/hawkbit-update-server:latest` and `openremote/hawkbit-update-server:<release-tag>` when a GitHub release is published

## Runtime

The container exposes port `8080` and stores hawkBit artifacts in `/opt/hawkbit/artifactrepo`.

The JVM is started with:

```text
-Xms768m
-Xmx768m
-XX:MaxMetaspaceSize=250m
-XX:MetaspaceSize=250m
-Xss300K
-XX:+UseG1GC
-XX:+UseStringDeduplication
-XX:+UseCompressedOops
-XX:+HeapDumpOnOutOfMemoryError
```

## Configuration

These settings are the main runtime properties used by this image in Compose deployments. They can be supplied as Spring properties, command-line arguments, or environment variables, depending on how you run the container. When using Compose, mount `/opt/hawkbit/artifactrepo` for persistent hawkBit artifact storage.

Example Compose service entries:

```yaml
volumes:
  - hawkbit-artifact-data:/opt/hawkbit/artifactrepo
environment:
  - LOGGING_LEVEL_ROOT=INFO
  # DATASOURCE
  - SPRING_DATASOURCE_URL=jdbc:postgresql://hawkbitdb:5432/hawkbit
  - SPRING_DATASOURCE_USERNAME=${HAWKBIT_DB_USER:-postgres}
  - SPRING_DATASOURCE_PASSWORD=${HAWKBIT_DB_PASSWORD:-postgres}
  - SPRING_JPA_DATABASE=POSTGRESQL
  - SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver
  # RABBITMQ INTEGRATION
  - HAWKBIT_DMF_RABBITMQ_ENABLED=false
  # ARTIFACT ACCESS
  - HAWKBIT_ARTIFACT_URL_PROTOCOLS_DOWNLOAD_HTTP_PORT=8080
  - HAWKBIT_ARTIFACT_URL_PROTOCOLS_DOWNLOAD_HTTP_PROTOCOL=http
  - 'HAWKBIT_ARTIFACT_URL_PROTOCOLS_DOWNLOAD_HTTP_REF={protocol}://{hostnameRequest}:{port}$${server.servlet.context-path}/{tenant}/controller/v1/{controllerId}/softwaremodules/{softwareModuleId}/artifacts/{artifactFileName}'
  - HAWKBIT_SERVER_DDI_SECURITY_AUTHENTICATION_TARGETTOKEN_ENABLED=true
  # REVERSE PROXY
  - SERVER_USE_FORWARD_HEADERS=true
  - SERVER_FORWARD_HEADERS_STRATEGY=NATIVE
  - SERVER_SERVLET_CONTEXT_PATH=/hawkbit
  # SPRING SECURITY OAUTH2
  - SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI=http://localhost:8081/auth/realms/master
  - SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI=http://keycloak:8080/auth/realms/master/protocol/openid-connect/certs
  - HAWKBIT_SERVER_SECURITY_OAUTH2_RESOURCESERVER_ENABLED=true
  - HAWKBIT_SERVER_SECURITY_OAUTH2_RESOURCESERVER_JWT_CLAIM_USERNAME=preferred_username
  - HAWKBIT_SERVER_SECURITY_OAUTH2_RESOURCESERVER_JWT_CLAIM_ROLES=resource_access.hawkbit.roles
```

### Logging

`LOGGING_LEVEL_ROOT=INFO`
Sets the default root log level.

### Datasource

hawkBit supports PostgreSQL, and the upstream project documents PostgreSQL as a supported SQL database.

`SPRING_DATASOURCE_URL=jdbc:postgresql://hawkbitdb:5432/hawkbit`
JDBC connection URL for the hawkBit database.

`SPRING_DATASOURCE_USERNAME=${HAWKBIT_DB_USER:-postgres}`
Database username.

`SPRING_DATASOURCE_PASSWORD=${HAWKBIT_DB_PASSWORD:-postgres}`
Database password.

`SPRING_JPA_DATABASE=POSTGRESQL`
Selects PostgreSQL for Spring JPA.

`SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver`
Uses the PostgreSQL JDBC driver.

### Messaging

`HAWKBIT_DMF_RABBITMQ_ENABLED=false`
Disables the optional DMF RabbitMQ integration.

### Artifact URLs

These settings control the download links hawkBit returns to devices for artifacts.

`HAWKBIT_ARTIFACT_URL_PROTOCOLS_DOWNLOAD_HTTP_PORT=8080`
External port used in generated artifact URLs.

`HAWKBIT_ARTIFACT_URL_PROTOCOLS_DOWNLOAD_HTTP_PROTOCOL=http`
Protocol used in generated artifact URLs.

`HAWKBIT_ARTIFACT_URL_PROTOCOLS_DOWNLOAD_HTTP_REF={protocol}://{hostnameRequest}:{port}$${server.servlet.context-path}/{tenant}/controller/v1/{controllerId}/softwaremodules/{softwareModuleId}/artifacts/{artifactFileName}`
Template used to build the artifact download URL.

### DDI Security

`HAWKBIT_SERVER_DDI_SECURITY_AUTHENTICATION_TARGETTOKEN_ENABLED=true`
Enables target token authentication for the Direct Device Integration API.

### Reverse Proxy

hawkBit documentation for reverse-proxy deployments explicitly calls out `SERVER_FORWARD_HEADERS_STRATEGY=NATIVE` so generated URLs match the client-facing scheme and headers.

`SERVER_FORWARD_HEADERS_STRATEGY=NATIVE`
Uses native forwarded-header handling for reverse proxy deployments.

`SERVER_USE_FORWARD_HEADERS=true`
Legacy forwarded-header setting that appears in some deployments; keep only if you specifically rely on it.

`SERVER_SERVLET_CONTEXT_PATH=/hawkbit`
Serves hawkBit under the `/hawkbit` path prefix.

### OAuth2

`SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI=http://localhost:8081/auth/realms/master`
Issuer URI that hawkBit uses to validate the JWT `iss` claim and, depending on configuration, for issuer discovery. This must exactly match the issuer value in the tokens accepted by hawkBit. In containerized deployments, use the externally advertised issuer URL if that is the value included in the tokens' `iss` claim; use an internal container-network URL only if your identity provider actually issues tokens with that internal issuer.

`SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI=http://keycloak:8080/auth/realms/master/protocol/openid-connect/certs`
JWK set endpoint that the hawkBit container uses to fetch signing keys. This can be an internal Compose-network URL such as `http://keycloak:8080/...` even when `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI` is set to the host-reachable issuer URL from the tokens.

`HAWKBIT_SERVER_SECURITY_OAUTH2_RESOURCESERVER_ENABLED=true`
Enables hawkBit's OAuth2 resource-server security integration.

`HAWKBIT_SERVER_SECURITY_OAUTH2_RESOURCESERVER_JWT_CLAIM_USERNAME=preferred_username`
JWT claim used as the hawkBit username.

`HAWKBIT_SERVER_SECURITY_OAUTH2_RESOURCESERVER_JWT_CLAIM_ROLES=resource_access.hawkbit.roles`
JWT claim path used to extract hawkBit roles.
