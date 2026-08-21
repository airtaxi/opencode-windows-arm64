#Requires -Version 7.0
<#
.SYNOPSIS
Resolve the latest OpenCode tag and decide whether a build is needed.

.DESCRIPTION
Fetches the latest tag from the upstream OpenCode repository and compares it
against the latest GitHub release in this repository. Sets GitHub Actions outputs
for use by subsequent workflow steps.

.PARAMETER Repo
The GitHub repository in owner/repo format (e.g. "airtaxi/opencode-windows-arm64").
Defaults to $env:GITHUB_REPOSITORY.

.PARAMETER UpstreamUrl
Git remote URL for the OpenCode source. Defaults to the public HTTPS URL.

.PARAMETER TagOverride
Force a specific upstream tag to clone (e.g. "v1.18.20"). Skips upstream lookup.

.PARAMETER ReleaseTagOverride
Force a specific release tag to publish (e.g. "v1.18.20.1"). Defaults to the upstream tag.

.PARAMETER VersionOverride
Force the version embedded in the binary (e.g. "1.18.20"). Defaults to the release tag without the leading "v".
#>

[CmdletBinding()]
param(
    [string]$Repo = $env:GITHUB_REPOSITORY,
    [string]$UpstreamUrl = "https://github.com/anomalyco/opencode.git",
    [string]$TagOverride = "",
    [string]$ReleaseTagOverride = "",
    [string]$VersionOverride = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-LatestTag {
    param([string]$Remote)
    $tags = & git ls-remote --tags $Remote 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $tags) {
        throw "Failed to fetch tags from $Remote"
    }
    $tagLines = $tags | Where-Object { $_ -match 'refs/tags/v\d+\.\d+\.\d+$' }
    $validTags = @($tagLines | ForEach-Object { ($_ -split '\s+')[1] -replace 'refs/tags/','' } |
        Where-Object { $_ -match '^v\d+\.\d+\.\d+$' })
    if ($validTags.Count -eq 0) { throw "No version tags found in $Remote" }
    $latest = ($validTags |
        Sort-Object { try { [version]($_ -replace '^v','') } catch { [version]'0.0.0' } } -Descending)[0]
    return $latest
}

function Get-LatestReleaseTag {
    param([string]$RepoName)
    try {
        $tag = gh release view --repo $RepoName --json tagName --jq ".tagName" 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($tag)) {
            $tag = $tag.Trim()
            if ($tag -match '^v\d+\.\d+\.\d+$') { return $tag }
        }
    } catch {
        Write-Host "[DEBUG] gh release view failed: $_"
    }
    return $null
}

# -- Resolve upstream tag ----------------------------------------------
if ([string]::IsNullOrWhiteSpace($TagOverride)) {
    Write-Host "Fetching latest tag from upstream: $UpstreamUrl"
    $upstreamTag = Get-LatestTag -Remote $UpstreamUrl
} else {
    Write-Host "Using tag override: $TagOverride"
    $upstreamTag = $TagOverride.Trim()
}

Write-Host "Upstream tag:      $upstreamTag"

# -- Resolve release tag -----------------------------------------------
if ([string]::IsNullOrWhiteSpace($ReleaseTagOverride)) {
    $releaseTag = $upstreamTag
} else {
    Write-Host "Using release tag override: $ReleaseTagOverride"
    $releaseTag = $ReleaseTagOverride.Trim()
}

Write-Host "Release tag:       $releaseTag"

# -- Resolve version ----------------------------------------------------
if ([string]::IsNullOrWhiteSpace($VersionOverride)) {
    $version = $releaseTag -replace '^v',''
} else {
    Write-Host "Using version override: $VersionOverride"
    $version = $VersionOverride.Trim()
}

Write-Host "Version:           $version"

# -- Resolve latest release in this repo -------------------------------
$latestReleaseTag = Get-LatestReleaseTag -RepoName $Repo
Write-Host "Latest release:    $(if ($latestReleaseTag) { $latestReleaseTag } else { '(none)' })"

# -- Decide whether to build ------------------------------------------
$shouldBuild = $false
if ([string]::IsNullOrWhiteSpace($latestReleaseTag)) {
    $shouldBuild = $true
    Write-Host "No existing release found. Build needed."
} elseif (([version]($releaseTag -replace '^v','')) -gt ([version]($latestReleaseTag -replace '^v',''))) {
    $shouldBuild = $true
    Write-Host "Release tag is newer than latest release. Build needed."
} else {
    Write-Host "Latest release is up to date. No build needed."
}

# -- Emit outputs ------------------------------------------------------
Write-Host ""
Write-Host "Summary:"
Write-Host "  upstream_tag:      $upstreamTag"
Write-Host "  release_tag:       $releaseTag"
Write-Host "  version:           $version"
Write-Host "  latest_release:    $latestReleaseTag"
Write-Host "  should_build:      $shouldBuild"

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_OUTPUT)) {
    "upstream_tag=$upstreamTag"        >> $env:GITHUB_OUTPUT
    "release_tag=$releaseTag"          >> $env:GITHUB_OUTPUT
    "version=$version"                 >> $env:GITHUB_OUTPUT
    "latest_release=$latestReleaseTag" >> $env:GITHUB_OUTPUT
    "should_build=$shouldBuild".ToLower() >> $env:GITHUB_OUTPUT
}

exit 0
