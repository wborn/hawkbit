# ------------------------------------------------------------
# Build our own hawkbit image with Java 21, and adding arm64 support.
# ------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/openjdk-21-runtime

ARG GIT_COMMIT=unknown

LABEL git-commit=$GIT_COMMIT

ENV HAWKBIT_VERSION=1.0.0 \
    HAWKBIT_HOME=/opt/hawkbit

EXPOSE 8080

COPY KEY .

# Needed for install
USER root
RUN set -x \
    && microdnf -y install --nodocs wget \
    && gpg --import KEY \
    && useradd --uid 1001 --home-dir $HAWKBIT_HOME --create-home --shell /sbin/nologin hawkbit \
    && mkdir -p $HAWKBIT_HOME/artifactrepo \
    && cd $HAWKBIT_HOME \
    && wget -O hawkbit-update-server.jar --no-verbose https://repo1.maven.org/maven2/org/eclipse/hawkbit/hawkbit-update-server/$HAWKBIT_VERSION/hawkbit-update-server-$HAWKBIT_VERSION.jar \
    && wget -O hawkbit-update-server.jar.asc --no-verbose https://repo1.maven.org/maven2/org/eclipse/hawkbit/hawkbit-update-server/$HAWKBIT_VERSION/hawkbit-update-server-$HAWKBIT_VERSION.jar.asc \
    && gpg --batch --verify hawkbit-update-server.jar.asc hawkbit-update-server.jar \
    && chown -R hawkbit:root $HAWKBIT_HOME \
    && chmod -R g=u $HAWKBIT_HOME \
    && microdnf clean all

VOLUME "$HAWKBIT_HOME/artifactrepo"

WORKDIR $HAWKBIT_HOME
USER hawkbit
ENTRYPOINT ["java", "-Xms768m", "-Xmx768m", "-XX:MaxMetaspaceSize=250m", "-XX:MetaspaceSize=250m", "-Xss300K", "-XX:+UseG1GC", "-XX:+UseStringDeduplication", "-XX:+UseCompressedOops", "-XX:+HeapDumpOnOutOfMemoryError", "-jar", "hawkbit-update-server.jar"]
