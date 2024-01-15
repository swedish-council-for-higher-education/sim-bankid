FROM registry.access.redhat.com/ubi9/openjdk-21-runtime@sha256:84175e911f3bac8bb51f113cc9704e95d1d7ce6348a49ee217501cc1d2df2699

USER root

ENV TZ=Europe/Stockholm HOME=/opt/sim-bankid LANG=C.utf8

RUN groupadd --system --gid=1000 sim-bankid && \
    useradd --system --no-log-init --gid sim-bankid --uid=1000 sim-bankid && \
    mkdir /var/sim-bankid && chown sim-bankid:sim-bankid /var/sim-bankid && \
    mkdir /opt/sim-bankid && chown sim-bankid:sim-bankid /opt/sim-bankid

# We make four distinct layers so if there are application changes the library layers can be re-used
COPY --chown=sim-bankid:sim-bankid target/quarkus-app/lib/ /opt/sim-bankid/lib/
COPY --chown=sim-bankid:sim-bankid target/quarkus-app/*.jar /opt/sim-bankid/
COPY --chown=sim-bankid:sim-bankid target/quarkus-app/app/ /opt/sim-bankid/app/
COPY --chown=sim-bankid:sim-bankid target/quarkus-app/quarkus/ /opt/sim-bankid/quarkus/

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
