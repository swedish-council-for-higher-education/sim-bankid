FROM docker.io/eclipse-temurin:21-jdk-alpine@sha256:cafcfad1d9d3b6e7dd983fa367f085ca1c846ce792da59bcb420ac4424296d56 AS build

USER root

RUN mkdir /var/sim-bankid

COPY . /var/sim-bankid

WORKDIR /var/sim-bankid

RUN chmod +x mvnw

RUN ./mvnw -B --file pom.xml package

FROM eclipse-temurin:23.0.2_7-jre-alpine@sha256:88593498863c64b43be16e8357a3c70ea475fc20a93bf1e07f4609213a357c87

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
