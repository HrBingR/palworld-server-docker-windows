FROM cm2network/steamcmd:root-trixie

LABEL org.opencontainers.image.source="https://github.com/HrBingR/palworld-server-docker-windows" \
      org.opencontainers.image.description="Palworld Windows dedicated server running under Proton Experimental"

ARG TARGETARCH=amd64

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN if [[ "${TARGETARCH}" != "amd64" ]]; then \
        echo "Milestone 1 supports amd64 only; received TARGETARCH=${TARGETARCH}" >&2; \
        exit 1; \
    fi

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        fontconfig \
        gettext-base \
        gosu \
        jq \
        libasound2t64 \
        libfreetype6 \
        libgl1 \
        libpulse0 \
        libvulkan1 \
        libx11-6 \
        libxcomposite1 \
        libxcursor1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxinerama1 \
        libxrandr2 \
        libxrender1 \
        mesa-vulkan-drivers \
        procps \
        python3 \
        tini \
    && rm -rf /var/lib/apt/lists/*

# Proton Experimental is free-to-download Steam tool 1493710. Installing it at
# image-build time keeps only the game server and its prefix in /palworld.
RUN install -d -o steam -g steam /opt/proton \
    && gosu steam /home/steam/steamcmd/steamcmd.sh \
        +force_install_dir /opt/proton \
        +login anonymous \
        +app_update 1493710 validate \
        +quit \
    && test -x /opt/proton/proton

# The Windows dedicated server still initializes Win32 display APIs before
# becoming headless. Keep its virtual display local to the container.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xauth \
        xvfb \
    && rm -rf /var/lib/apt/lists/*

ENV HOME=/home/steam \
    PUID=1000 \
    PGID=1000 \
    PORT=8211 \
    QUERY_PORT=27015 \
    PLAYERS=16 \
    PUBLIC_PORT=8211 \
    SERVER_NAME="Palworld Windows Server" \
    SERVER_DESCRIPTION="" \
    SERVER_PASSWORD="" \
    ADMIN_PASSWORD="" \
    REST_API_ENABLED=true \
    REST_API_PORT=8212 \
    RCON_ENABLED=false \
    RCON_PORT=25575 \
    UPDATE_ON_BOOT=true \
    MULTITHREADING=true \
    LOG_LEVEL=INFO \
    STEAM_COMPAT_CLIENT_INSTALL_PATH=/home/steam/Steam \
    STEAM_COMPAT_DATA_PATH=/palworld/.proton \
    STEAM_COMPAT_APP_ID=2394010 \
    SteamAppId=2394010 \
    SteamGameId=2394010 \
    WINEDEBUG=-all

WORKDIR /home/steam/server

COPY scripts/helper_functions.sh /home/steam/server/helper_functions.sh
COPY scripts/compile-settings.sh /home/steam/server/compile-settings.sh
COPY scripts/files/PalWorldSettings.ini.template /home/steam/server/files/PalWorldSettings.ini.template
COPY scripts/windows-entrypoint.sh /home/steam/server/windows-entrypoint.sh

RUN chmod 0755 \
        /home/steam/server/compile-settings.sh \
        /home/steam/server/windows-entrypoint.sh \
    && chown -R steam:steam /home/steam/server

VOLUME ["/palworld"]

EXPOSE 8211/udp 27015/udp 8212/tcp

HEALTHCHECK --start-period=5m --interval=30s --timeout=5s --retries=3 \
    CMD pgrep -f "[P]alServer-Win64-Shipping-Cmd.exe" >/dev/null || exit 1

ENTRYPOINT ["tini", "--", "/home/steam/server/windows-entrypoint.sh"]
