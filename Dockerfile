FROM docker.io/eclipse-temurin:21-jdk-alpine@sha256:56ffb38891c7ea074c1dd42cc9a978206b7c2752589f8f613e383050a8af0e50 AS build

USER root

RUN mkdir /var/sim-bankid

COPY . /var/sim-bankid

WORKDIR /var/sim-bankid

RUN chmod +x mvnw

RUN ./mvnw -B --file pom.xml package

FROM eclipse-temurin:23.0.1_11-jre-alpine@sha256:bd8e2c8c19bcadbaa8c6a128051a22384c6f7cfe5fa520cb663fe21fff96f084

ENV TZ=Europe/Stockholm HOME=/opt/sim-bankid LANG=C.utf8

RUN addgroup -S -g 1000 sim-bankid && \
    adduser -D -H -G sim-bankid -u 1000 sim-bankid && \
    mkdir /var/sim-bankid && chown sim-bankid:sim-bankid /var/sim-bankid && \
    mkdir /opt/sim-bankid && chown sim-bankid:sim-bankid /opt/sim-bankid

# We make four distinct layers so if there are application changes the library layers can be re-used
COPY --chown=sim-bankid:sim-bankid --from=build var/sim-bankid/target/quarkus-app/lib/ /opt/sim-bankid/lib/
COPY --chown=sim-bankid:sim-bankid --from=build var/sim-bankid/target/quarkus-app/*.jar /opt/sim-bankid/
COPY --chown=sim-bankid:sim-bankid --from=build var/sim-bankid/target/quarkus-app/app/ /opt/sim-bankid/app/
COPY --chown=sim-bankid:sim-bankid --from=build var/sim-bankid/target/quarkus-app/quarkus/ /opt/sim-bankid/quarkus/

USER sim-bankid

# Required to build with Docker on Windows
RUN chmod u+x \
    /opt/sim-bankid \
    /opt/sim-bankid/lib \
    /opt/sim-bankid/lib/main \
    /opt/sim-bankid/lib/boot \
    /opt/sim-bankid/app \
    /opt/sim-bankid/quarkus

WORKDIR /var/sim-bankid

EXPOSE 8080
EXPOSE 8787

CMD java \
    -Djdk.tracePinnedThreads=full \
    ${JAVA_OPTS} \
    -agentlib:jdwp=transport=dt_socket,address=*:8787,server=y,suspend=n \
    -Djava.net.preferIPv4Stack=true \
    -jar /opt/sim-bankid/quarkus-run.jar
