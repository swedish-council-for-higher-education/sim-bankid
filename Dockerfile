FROM docker.io/eclipse-temurin:25-jdk-alpine@sha256:f4c0b771cfed29902e1dd2e5c183b9feca633c7686fb85e278a0486b03d27369 AS build

USER root

RUN mkdir /var/sim-bankid

COPY . /var/sim-bankid

WORKDIR /var/sim-bankid

RUN chmod +x mvnw

RUN ./mvnw -B --file pom.xml package

FROM eclipse-temurin:24.0.2_12-jre-alpine@sha256:4044b6c87cb088885bcd0220f7dc7a8a4aab76577605fa471945d2e98270741f

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
