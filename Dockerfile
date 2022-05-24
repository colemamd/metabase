###################
# STAGE 1: builder
###################

FROM adoptopenjdk/openjdk11:debianslim-jre

ENV FC_LANG en-US LC_CTYPE en_US.UTF-8

# dependencies
RUN apt-get update -yq && apt-get install -yq bash ttf-dejavu fontconfig curl wget unzip openjdk-11-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/ && \
    mkdir -p /app/certs && \
    curl https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem -o /app/certs/rds-combined-ca-bundle.pem  && \
    /opt/java/openjdk/bin/keytool -noprompt -import -trustcacerts -alias aws-rds -file /app/certs/rds-combined-ca-bundle.pem -keystore /etc/ssl/certs/java/cacerts -keypass changeit -storepass changeit && \
    curl https://cacerts.digicert.com/DigiCertGlobalRootG2.crt.pem -o /app/certs/DigiCertGlobalRootG2.crt.pem  && \
    /opt/java/openjdk/bin/keytool -noprompt -import -trustcacerts -alias azure-cert -file /app/certs/DigiCertGlobalRootG2.crt.pem -keystore /etc/ssl/certs/java/cacerts -keypass changeit -storepass changeit && \
    mkdir -p /plugins && chmod a+rwx /plugins && \
    useradd --shell /bin/bash metabase

WORKDIR /app

# copy app from the official image
COPY --from=metabase/metabase:latest /app /app

RUN mkdir /data/  && \
    wget https://crowdsec-statics-assets.s3-eu-west-1.amazonaws.com/metabase_sqlite.zip && \
    unzip metabase_sqlite.zip -d /data/ && chown -R metabase /app && chown -R metabase /data 

USER metabase
# expose our default runtime port
EXPOSE 3000

# run it
ENTRYPOINT ["/app/run_metabase.sh"]