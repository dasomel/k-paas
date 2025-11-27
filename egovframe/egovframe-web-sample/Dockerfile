FROM docker.io/library/maven:3.9.5-eclipse-temurin-8-focal as build

# 1000 사용자 생성 (이미 있으면 스킵)
RUN useradd -u 1000 -m appuser || true

# install git, maven
RUN apt-get update && \
    apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

# source download
RUN git clone https://github.com/eGovFramework/egovframe-web-sample.git

# 소스 디렉터리 권한 조정 및 1000 사용자로 컴파일
WORKDIR /egovframe-web-sample
RUN chown -R 1000:1000 /egovframe-web-sample
USER 1000
RUN mvn package -DskipTests


FROM docker.io/library/tomcat:8.5.96-jdk8-temurin-jammy as tomcat
LABEL maintainer="dasomell@gmail.com"
LABEL title="egovframe-web-sample"
LABEL version="4.3.0"
LABEL description="egov sample xml template"

# 1000 사용자 생성 (이미 있으면 스킵)
RUN useradd -u 1000 -m appuser || true

# 톰캣 디렉터리 권한을 1000 사용자에게 부여
RUN chown -R 1000:1000 /usr/local/tomcat

## tomcat deploy
COPY --from=build /egovframe-web-sample/target/web-example-1.0.0.war /usr/local/tomcat/webapps/ROOT.war

# war 파일 권한도 조정
RUN chown 1000:1000 /usr/local/tomcat/webapps/ROOT.war

# 이후부터는 1000 사용자로 실행
USER 1000

## tomcat run
EXPOSE 8080
ENTRYPOINT ["catalina.sh", "run"]
