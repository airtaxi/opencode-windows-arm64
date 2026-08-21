# OpenCode Windows ARM64

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

🌐 [English](README.md) | 한국어

OpenCode Windows ARM64는 AI 코딩 에이전트인 [OpenCode](https://github.com/anomalyco/opencode)의 Windows ARM64 바이너리를 자동으로 생성하는 비공식 빌드 파이프라인입니다. GitHub Actions에서 실행되며, 업스트림 저장소의 새 릴리즈를 6시간마다 폴링하고, 리눅스 러너에서 ARM64 바이너리를 크로스 컴파일한 뒤 GitHub Release를 게시하고 Scoop bucket 매니페스트를 갱신하여 자동 업데이트를 지원합니다.

## Disclaimer

이 프로젝트는 OpenCode 팀과 제휴 관계가 없으며, 보증하거나 후원하거나 공식 지원하는 프로젝트가 아닙니다. Windows on ARM 호환성을 위한 독립 커뮤니티 도구입니다.

OpenCode는 각 소유자의 상표입니다. 그 외 모든 상표는 각 소유자의 자산입니다.

## Release에서 빠르게 설치

Scoop 사용:

```powershell
scoop bucket add opencode-arm64 https://github.com/airtaxi/opencode-windows-arm64
scoop install opencode-arm64
```

일반적인 업데이트:

```powershell
scoop update
scoop update opencode-arm64
```

또는 [GitHub Releases](https://github.com/airtaxi/opencode-windows-arm64/releases) 페이지에서 바이너리를 직접 다운로드하여 실행할 수 있습니다.

## 작동 방식

1. **정기 확인** — 6시간마다 워크플로우가 업스트림 OpenCode 저장소의 최신 태그를 가져와 이 저장소의 최신 릴리즈와 비교합니다.
2. **빌드** — 새 태그가 발견되거나 수동 빌드가 트리거되면, 해당 태그의 소스를 클론하고 Bun을 1.4.0으로 고정한 뒤 의존성을 설치하고, 업스트림 릴리즈 파이프라인과 동일한 방식으로 리눅스 러너에서 `bun run build`로 ARM64 바이너리를 크로스 컴파일합니다.
3. **릴리즈** — 바이너리를 zip으로 아카이브하고 해시값이 포함된 Scoop 매니페스트를 생성한 뒤 GitHub Release를 만듭니다.
4. **Scoop 업데이트** — Scoop bucket 매니페스트를 저장소에 커밋하여 `scoop update`가 새 버전을 자동으로 인식합니다.

## 적용되는 패치

빌드는 클론된 소스에 다음 패치를 적용합니다:

- **package.json** — `packageManager`를 `bun@1.4.0`으로 고정합니다 (업스트림이 이미 1.4.0 이상을 요구하면 그대로 유지). Bun 1.4.0은 Windows ARM64에서 `bun:ffi`를 지원하는 첫 번째 안정 릴리즈이며([oven-sh/bun#28055](https://github.com/oven-sh/bun/issues/28055)), OpenCode 빌드에 필요합니다.
- **bunfig.toml** — `minimumReleaseAgeExcludes`에 `@types/bun`과 `bun-types`를 추가하여 갓 게시된 타입 패키지가 3일 릴리즈 연령 정책에 막히지 않도록 합니다.

패치 앵커를 찾지 못하면(예: 업스트림 리팩터링) 빌드를 즉시 중단하여, 패치가 누락된 바이너리가 조용히 배포되지 않도록 합니다.

## 수동 빌드

Actions 탭에서 워크플로우를 수동으로 실행할 수 있으며, 다음 옵션을 지원합니다:

- **force_build** — 업스트림 태그가 최신 릴리즈보다 새롭지 않아도 빌드합니다.
- **tag_override** — 특정 업스트림 태그를 빌드합니다 (예: `v1.18.20`).
- **release_tag_override** — 특정 릴리즈 태그로 게시합니다 (예: `v1.18.20.1`).
- **version_override** — 바이너리에 특정 버전을 넣습니다 (예: `1.18.20`). 기본값은 릴리즈 태그에서 앞의 `v`를 뺀 값입니다.

## 요구사항 (로컬 빌드 시)

- Windows on ARM 장치 (로컬 Windows 빌드 시).
- PowerShell 7 (`pwsh`).
- [Bun](https://bun.sh) 1.4.0 이상.
- "Desktop development with C++" 워크로드가 설치된 Visual Studio 2022 (ARM64 toolset 포함).
- `PATH`의 Node.js 및 Git.

## 출력물

빌드가 성공하면 다음 파일이 생성됩니다:

- `dist/opencode-windows-arm64.zip` — ARM64 바이너리 아카이브.
- `bucket/opencode-arm64.json` — 해시가 포함된 Scoop 매니페스트.

이 저장소의 초기 매니페스트는 자리 표시자이며, 첫 빌드에서 실제 해시로 교체됩니다.

## 라이선스

OpenCode Windows ARM64는 [MIT 라이선스](LICENSE)로 배포됩니다.

## 제작자

[이호원 (airtaxi)](https://github.com/airtaxi)이 만들었습니다.
