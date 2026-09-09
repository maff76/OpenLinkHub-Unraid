FROM golang:1.25.0-bookworm AS build
ARG GIT_TAG
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y libudev-dev i2c-tools libpipewire-0.3-dev pkg-config git sed
RUN mkdir -p /opt/OpenLinkHub

WORKDIR /app
RUN git clone https://github.com/jurkovic-nikola/OpenLinkHub.git OpenLinkHub

WORKDIR /app/OpenLinkHub
RUN if [ -n "$GIT_TAG" ]; then git checkout "$GIT_TAG"; fi

RUN go build .

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y libpipewire-0.3-0 libudev-dev pciutils usbutils udev i2c-tools pulseaudio-utils nano dmidecode && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/modules-load.d
RUN echo 'KERNEL=="i2c-0", MODE="0600", OWNER="root"' | tee /etc/udev/rules.d/98-corsair-memory.rules
RUN echo "i2c-dev" | tee /etc/modules-load.d/i2c-dev.conf

COPY --from=build /app/OpenLinkHub/OpenLinkHub /usr/local/bin/OpenLinkHub
COPY --from=build /app/OpenLinkHub/database /usr/share/openlinkhub/database
COPY --from=build /app/OpenLinkHub/static /usr/share/openlinkhub/static
COPY --from=build /app/OpenLinkHub/web /usr/share/openlinkhub/web
COPY --from=build /app/OpenLinkHub/99-openlinkhub.rules /etc/udev/rules.d/99-openlinkhub.rules
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh && mkdir -p /opt/OpenLinkHub && chmod 777 /opt/OpenLinkHub

WORKDIR /opt/OpenLinkHub

EXPOSE 27003

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
