# OpenCode Windows ARM64

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

🌐 English | [한국어](README.ko.md)

OpenCode Windows ARM64 is an unofficial automated build pipeline that produces Windows ARM64 binaries for [OpenCode](https://github.com/anomalyco/opencode), an AI-powered coding agent. It runs on GitHub Actions, polls the upstream repository for new releases every 6 hours, builds the ARM64 binary on a native Windows ARM runner, publishes a GitHub Release, and updates a Scoop bucket manifest for automatic updates.

## Disclaimer

This project is not affiliated with, endorsed by, sponsored by, or officially supported by the OpenCode team. It is an independent community tool for Windows on ARM compatibility.

OpenCode is a trademark of its respective owners. All other trademarks are the property of their respective owners.

## Quick Install From Release

With Scoop:

```powershell
scoop bucket add opencode-arm64 https://github.com/airtaxi/opencode-windows-arm64
scoop install opencode-arm64
```

Update normally:

```powershell
scoop update
scoop update opencode-arm64
```

Alternatively, download the binary from the [GitHub Releases](https://github.com/airtaxi/opencode-windows-arm64/releases) page and run it directly.

## How It Works

1. **Scheduled check** — Every 6 hours, the workflow fetches the latest tag from the upstream OpenCode repository and compares it against the latest release in this repository.
2. **Build** — If a newer tag is found (or a manual build is triggered), the workflow clones the tagged source, pins Bun to 1.4.0, installs dependencies, and builds the native ARM64 binary with `bun run build -- --single` on a native Windows ARM runner.
3. **Release** — The binary is archived as a zip, a Scoop manifest is generated with the correct hash, and a GitHub Release is created.
4. **Scoop update** — The Scoop bucket manifest is committed to the repository so `scoop update` picks up the new version automatically.

## Applied Patches

The build applies the following patches to the cloned source after cloning:

- **package.json** — Pins `packageManager` to `bun@1.4.0` (kept as-is if the upstream already requires 1.4.0 or newer). Bun 1.4.0 is the first stable release with `bun:ffi` support on Windows ARM64 ([oven-sh/bun#28055](https://github.com/oven-sh/bun/issues/28055)), which the OpenCode build requires.
- **bunfig.toml** — Adds `@types/bun` and `bun-types` to `minimumReleaseAgeExcludes` so freshly published type packages are not blocked by the 3-day release-age policy.

If a patch anchor is not found (e.g. after an upstream refactor), the build fails fast so a silently unpatched binary is never published.

## Manual Builds

The workflow can be triggered manually from the Actions tab with the following options:

- **force_build** — Build even when the upstream tag is not newer than the latest release.
- **tag_override** — Build a specific upstream tag (e.g. `v1.18.20`).
- **release_tag_override** — Publish under a specific release tag (e.g. `v1.18.20.1`).
- **version_override** — Embed a specific version in the binary (e.g. `1.18.20`). Defaults to the release tag without the leading `v`.

## Requirements (for local builds)

- Windows on ARM device (or a Windows ARM CI runner).
- PowerShell 7 (`pwsh`).
- [Bun](https://bun.sh) 1.4.0 or newer on `PATH`.
- Visual Studio 2022 with the "Desktop development with C++" workload (ARM64 toolset).
- Node.js and Git on `PATH`.

## Outputs

A successful build produces:

- `dist/opencode-windows-arm64.zip` — ARM64 binary archive.
- `bucket/opencode-arm64.json` — Scoop manifest with hash.

The initial manifest in this repository is a placeholder; the first build replaces it with the real hash.

## License

OpenCode Windows ARM64 is licensed under the [MIT License](LICENSE).

## Author

Created by [Howon Lee (airtaxi)](https://github.com/airtaxi).
