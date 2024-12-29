FROM linuxserver/ffmpeg:version-7.1-cli

ENV WRURL=http://example.com \
    PGAPPDATA=/data/ \
    PGREGENERATERSSURL=http://example.com \
    FFMPEGOPTIONS="" \
    PATH=$PATH:/scripts/

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Record Web Radio to Podcast" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/vonProteus/record-web-radio-to-podcast" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

RUN apt-get update && apt-get install -y \
    bc \
    xmlstarlet \
    && rm -rf /var/lib/apt/lists/* \

WORKDIR /tmp/

COPY ./scripts/ /scripts/

ENTRYPOINT [ "record-web-radio.sh" ]
