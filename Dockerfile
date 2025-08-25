FROM vespaengine/vespa:8.568.7

USER root

ARG CLOJURE_DIR=/opt/vespa/lib/clojure
ARG MAVEN_REPO=https://repo1.maven.org/maven2

# Put Clojure jars into a separate directory
RUN mkdir $CLOJURE_DIR && \
    curl -s https://repo1.maven.org/maven2/org/clojure/clojure/1.12.1/clojure-1.12.1.jar \
          --output $CLOJURE_DIR/clojure-1.12.1.jar && \
    curl -s https://repo1.maven.org/maven2/org/clojure/spec.alpha/0.5.238/spec.alpha-0.5.238.jar \
          --output $CLOJURE_DIR/spec.alpha-0.5.238.jar && \
    curl -s https://repo1.maven.org/maven2/org/clojure/core.specs.alpha/0.4.74/core.specs.alpha-0.4.74.jar \
          --output $CLOJURE_DIR/core.specs.alpha-0.4.74.jar

# Change ownership of several directories so that classes could be loaded
RUN chown vespa -R $CLOJURE_DIR && \
    mkdir /opt/vespa/.cache && \
    chown vespa -R /opt/vespa/.cache

USER vespa
