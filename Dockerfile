FROM openjdk:8 as build

# install make and maven; maven MUST be installed
RUN apt-get update && apt-get install -y maven make locales locales-all

# set locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# mount creds
COPY docker/settings.xml /root/.m2/settings.xml

# artifactory info (set as --build-arg for local run)
ARG ARTIFACTORY_PRO_USER
ARG ARTIFACTORY_PRO_PASS

# cache java deps
COPY pom.xml /build/pom.xml
COPY ./rate-limit-api/pom.xml /build/rate-limit-api/pom.xml
COPY ./rate-limit-core/pom.xml /build/rate-limit-core/pom.xml
COPY ./redis-distributed-token-bucket/pom.xml /build/redis-distributed-token-bucket/pom.xml

# set workdir
WORKDIR /build

# bring in dependencies
RUN mvn dependency:resolve -P \!build -q

# bring in code
COPY . /build

# cache maven resources
ENV MAVEN_OPTS="-Xmx4096m"

RUN java -version

# compile, test, spotbugs, and checkstyle
RUN mvn -T 2C --errors install -am -DskipITs -Dhttp.keepAlive=false

# for veracode support
RUN find /build -type f -name "*.jar" -print0 | xargs -0 tar -czf java.tar.gz

ARG BUILD_ARTIFACTS_VERACODE=/build/java.tar.gz
ARG BUILD_ARTIFACTS_POM=/build/pom.xml
ARG BUILD_ARTIFACTS_TEST=/build/target/surefire-reports/*.xml
ARG BUILD_ARTIFACTS_JAVA=/build/target/rate-limit-api/*.jar:/build/target/rate-limit-core/*.jar:/build/target/redis-distributed-token-bucket/*.jar

# no-op container build
FROM scratch
