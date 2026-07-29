#!/bin/bash
set -Eeo pipefail

# shellcheck source=scripts/helper_functions.sh
source "/home/steam/server/helper_functions.sh"

install_server() {
    LogAction "Installing/updating the Palworld Windows dedicated server"
    /home/steam/steamcmd/steamcmd.sh \
        +@sSteamCmdForcePlatformType windows \
        +@sSteamCmdForcePlatformBitness 64 \
        +force_install_dir /palworld \
        +login anonymous \
        +app_update 2394010 validate \
        +quit
}

run_as_steam() {
    local -a start_command

    if [[ ! -f /palworld/PalServer.exe ]] || [[ ! -f /palworld/steamapps/appmanifest_2394010.acf ]]; then
        install_server
    elif isTrue "${UPDATE_ON_BOOT}"; then
        install_server
    fi

    if [[ ! -f /palworld/PalServer.exe ]]; then
        LogError "Windows server installation is incomplete: /palworld/PalServer.exe is missing."
        exit 1
    fi

    /home/steam/server/compile-settings.sh

    install -d \
        "${STEAM_COMPAT_DATA_PATH}" \
        /palworld/Pal/Saved/Config/WindowsServer

    start_command=(
        xvfb-run
        -a
        /opt/proton/proton
        run
        /palworld/PalServer.exe
        "-port=${PORT}"
        "-queryport=${QUERY_PORT}"
        "-players=${PLAYERS}"
    )

    if isTrue "${MULTITHREADING}"; then
        start_command+=(
            -useperfthreads
            -NoAsyncLoadingThread
            -UseMultithreadForDS
            "-NumberOfWorkerThreadsServer=$(nproc --all)"
        )
    fi

    LogAction "Starting the Palworld Windows dedicated server under Proton Experimental"
    exec "${start_command[@]}"
}

if [[ "$(id -u)" -eq 0 ]]; then
    if ! [[ "${PUID}" =~ ^[0-9]+$ && "${PGID}" =~ ^[0-9]+$ ]]; then
        LogError "PUID and PGID must be numeric."
        exit 1
    fi

    if [[ "$(id -g steam)" -ne "${PGID}" ]]; then
        groupmod -o -g "${PGID}" steam
    fi
    if [[ "$(id -u steam)" -ne "${PUID}" ]]; then
        usermod -o -u "${PUID}" steam
    fi

    install -d -o steam -g steam /palworld "${STEAM_COMPAT_DATA_PATH}"
    if ! gosu steam test -w /palworld; then
        LogAction "Correcting ownership of the persistent Palworld directory"
        chown -R steam:steam /palworld
    fi

    exec gosu steam "$0" "$@"
fi

run_as_steam
