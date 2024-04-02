FROM docker.io/eclipse-temurin:21-jdk-alpine@sha256:b5d37df8ee5bb964bb340acca83957f9a09291d07768fba1881f6bfc8048e4f5 AS build

USER root

RUN mkdir /var/sim-bankid

COPY . /var/sim-bankid

WORKDIR /var/sim-bankid

RUN chmod +x mvnw

RUN ./mvnw -B --file pom.xml package

FROM eclipse-temurin:21.0.2_13-jre-alpine@sha256:efdec7ae2b3e60bb253cdbe046249ddc07f3f0056837658616a94097f22a7449

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
