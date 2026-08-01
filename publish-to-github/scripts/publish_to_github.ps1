param(
    [Parameter(Mandatory = $true)]
    [string]$RepoName,

    [ValidateSet('public', 'private')]
    [string]$Visibility = 'public',

    [string]$Branch = 'main',

    [string]$TagName = 'v0.2.1',

    [string]$ReleaseTitle = 'v0.2.1',

    [string]$ReleaseNotes = 'Add release upload support',

    [string[]]$AssetPaths = @(),

    [switch]$SkipTag
)

$ErrorActionPreference = 'Stop'

function Resolve-GitHubRepoIdentifier {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputName
    )

    if ($InputName -match '/') {
        return $InputName
    }

    $remoteUrl = git remote get-url origin 2>$null
    if ($remoteUrl -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+?)(?:\.git)?$') {
        return "$($Matches.owner)/$($Matches.repo)"
    }

    return $InputName
}

function Write-Section($title) {
    Write-Host ""
    Write-Host "==== $title ====" -ForegroundColor Cyan
}

Write-Section 'Check workspace'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed or not in PATH.'
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    throw 'Current folder is not a Git repository. Run `git init` first.'
}

Write-Host "Repository root: $repoRoot"

Write-Section 'Check GitHub CLI'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (`gh`) is not installed. Please install it before publishing.'
}

$authStatus = gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'GitHub is not logged in. Opening browser login...'
    Start-Process 'gh.exe' 'auth login -h github.com -p https --web'
    Write-Host 'Complete the browser login, then press Enter to continue...'
    Read-Host | Out-Null
}

gh auth setup-git

Write-Section 'Check branch'
$currentBranch = git branch --show-current
if (-not $currentBranch) {
    throw 'No current branch detected.'
}

$branchExists = git show-ref --verify --quiet "refs/heads/$Branch"
if ($LASTEXITCODE -eq 0) {
    git checkout $Branch
} else {
    git checkout -b $Branch
}

Write-Section 'Create repository'
$resolvedRepo = Resolve-GitHubRepoIdentifier -InputName $RepoName
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$repoExists = $false
gh repo view $resolvedRepo --json name --jq '.name' 2>$null
if ($LASTEXITCODE -eq 0) {
    $repoExists = $true
}
$ErrorActionPreference = $previousErrorActionPreference
if (-not $repoExists) {
    $visibilityFlag = if ($Visibility -eq 'public') { '--public' } else { '--private' }
    gh repo create $resolvedRepo $visibilityFlag --source . --remote origin --push
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to create the GitHub repository or push the current branch.'
    }
} else {
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$resolvedRepo.git"
    git push --set-upstream origin $Branch
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to push the branch to the existing GitHub repository.'
    }
}

if (-not $SkipTag) {
    Write-Section 'Create and push tag'
    git show-ref --verify --quiet "refs/tags/$TagName" 2>$null
    if ($LASTEXITCODE -ne 0) {
        git tag -a $TagName -m $ReleaseTitle
        git push origin $TagName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to push tag $TagName."
        }
    } else {
        Write-Host "Tag $TagName already exists locally. Skipping tag creation."
    }
}

Write-Section 'Create GitHub Release'
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$releaseExists = $false
gh release view $TagName 2>$null
if ($LASTEXITCODE -eq 0) {
    $releaseExists = $true
}
$ErrorActionPreference = $previousErrorActionPreference
if (-not $releaseExists) {
    $releaseArgs = @('release', 'create', $TagName, '--title', $ReleaseTitle, '--notes', $ReleaseNotes)
    gh @releaseArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create GitHub Release for $TagName."
    }
} else {
    Write-Host "Release $TagName already exists. Skipping creation."
}

if ($AssetPaths.Count -gt 0) {
    Write-Section 'Upload release assets'
    foreach ($assetPath in $AssetPaths) {
        if (-not (Test-Path -LiteralPath $assetPath)) {
            throw "Asset file not found: $assetPath"
        }
    }

    gh release upload $TagName $AssetPaths --clobber
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to upload release assets for $TagName."
    }

    Write-Host "Uploaded assets: $($AssetPaths -join ', ')"
}

Write-Section 'Result'
Write-Host "Repository: https://github.com/$resolvedRepo"
Write-Host "Branch: $Branch"
Write-Host "Tag: $TagName"
Write-Host "Release: $ReleaseTitle"
Write-Host "Done."
