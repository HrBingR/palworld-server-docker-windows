# Milestone 1: Windows server under Proton

This branch installs the Palworld Windows dedicated-server depot into `/palworld` and runs
`PalServer.exe` with Valve Proton Experimental.

Milestone 1 intentionally targets `linux/amd64` only and covers:

1. Booting the Windows dedicated server under Proton.
2. Local client connectivity over UDP 8211.
3. The Palworld REST API on TCP 8212.
4. Persistence of the game, Proton prefix, configuration, and saves through `/palworld`.

UE4SS and mod loading are explicitly deferred to milestone 2.

## Persistent layout

```text
/palworld/
├── PalServer.exe
├── Pal/
│   ├── Binaries/Win64/
│   └── Saved/
│       ├── Config/WindowsServer/PalWorldSettings.ini
│       └── SaveGames/
├── steamapps/appmanifest_2394010.acf
└── .proton/
```

## Build and run

```bash
docker compose build
docker compose up
```

The first image build downloads Proton Experimental. The first container start downloads the
Windows Palworld server, so both operations can take several minutes.

The REST API is intentionally bound to host loopback:

```bash
curl --user admin:change-me http://127.0.0.1:8212/v1/api/info
```

Do not reuse a `/palworld` directory containing the native Linux depot. Use a dedicated empty
directory for this image.
