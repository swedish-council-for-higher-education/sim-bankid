FROM docker.io/eclipse-temurin:21-jdk-alpine@sha256:c4e39b956750b52fdf49c93d51a63546a5e91b22224fc462e58b00be91b17b62 AS build

USER root

RUN mkdir /var/sim-bankid

COPY . /var/sim-bankid

WORKDIR /var/sim-bankid

RUN chmod +x mvnw

RUN ./mvnw -B --file pom.xml package

FROM eclipse-temurin:23.0.1_11-jre-alpine@sha256:5aa334404315c590f8262d1bdb1fa855c127aa219df30bad4ea35d553de58d2f

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
