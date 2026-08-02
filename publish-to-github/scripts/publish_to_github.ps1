param(
    [Parameter(Mandatory = $true)]
    [string]$RepoName,

    [ValidateSet('public', 'private')]
    [string]$Visibility = 'public',

    [string]$Branch = 'main',

    [string]$TagName = 'v0.1.0',

    [string]$ReleaseTitle = '',

    [string]$ReleaseNotes = 'Initial release',

    [string[]]$AssetPaths = @(),

    [switch]$SkipTag
)

$ErrorActionPreference = 'Stop'

# If ReleaseTitle is not provided, use TagName
if (-not $ReleaseTitle) {
    $ReleaseTitle = $TagName
}

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

function Write-Step {
    param([string]$Title)
    Write-Host ""
    Write-Host ">>> $Title" -ForegroundColor Cyan
}

# --- Step 1: Check workspace ---
Write-Step "Checking workspace"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Git is not installed or not in PATH." -ForegroundColor Red
    exit 1
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Host "[ERROR] Current folder is not a Git repository. Run 'git init' first." -ForegroundColor Red
    exit 1
}
Write-Host "  Repository root: $repoRoot"

# --- Step 2: Check GitHub CLI ---
Write-Step "Checking GitHub CLI"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] GitHub CLI ('gh') is not installed." -ForegroundColor Red
    Write-Host "  Install it from: https://cli.github.com/"
    exit 1
}

$ghVersion = gh --version 2>$null | Select-Object -First 1
Write-Host "  $ghVersion"

# --- Step 3: Authenticate ---
Write-Step "Checking GitHub authentication"

$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Not logged in. Opening browser for GitHub login..."
    gh auth login --hostname github.com --web
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] GitHub login failed. Please run 'gh auth login' manually." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Login successful."
} else {
    Write-Host "  Already authenticated."
}

# Configure git to use gh as credential helper
gh auth setup-git 2>$null

# --- Step 4: Check / switch branch ---
Write-Step "Setting up branch"

$currentBranch = git branch --show-current
if (-not $currentBranch) {
    Write-Host "[ERROR] No current branch detected." -ForegroundColor Red
    exit 1
}

$branchExists = git show-ref --verify --quiet "refs/heads/$Branch" 2>$null
if ($LASTEXITCODE -eq 0) {
    git checkout $Branch 2>$null
    Write-Host "  Switched to existing branch: $Branch"
} else {
    git checkout -b $Branch 2>$null
    Write-Host "  Created and switched to new branch: $Branch"
}

# --- Step 5: Create or update remote repository ---
Write-Step "Publishing to GitHub"

$resolvedRepo = Resolve-GitHubRepoIdentifier -InputName $RepoName
Write-Host "  Target: $resolvedRepo"

$prevErrorAction = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$repoExists = $false
gh repo view $resolvedRepo --json name --jq '.name' 2>$null
if ($LASTEXITCODE -eq 0) {
    $repoExists = $true
}
$ErrorActionPreference = $prevErrorAction

if (-not $repoExists) {
    Write-Host "  Creating new repository..."
    $visibilityFlag = if ($Visibility -eq 'public') { '--public' } else { '--private' }
    gh repo create $resolvedRepo $visibilityFlag --source . --remote origin --push
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to create repository or push branch." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Repository created and code pushed."
} else {
    Write-Host "  Repository already exists. Updating remote..."
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$resolvedRepo.git"
    git push --set-upstream origin $Branch
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to push to existing repository." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Code pushed to existing repository."
}

# --- Step 6: Create and push tag ---
if (-not $SkipTag) {
    Write-Step "Creating tag: $TagName"

    $tagExists = git show-ref --verify --quiet "refs/tags/$TagName" 2>$null
    if ($LASTEXITCODE -ne 0) {
        git tag -a $TagName -m $ReleaseTitle
        git push origin $TagName
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to push tag '$TagName'." -ForegroundColor Red
            exit 1
        }
        Write-Host "  Tag created and pushed."
    } else {
        Write-Host "  Tag already exists locally, pushing..."
        git push origin $TagName 2>$null
        Write-Host "  Tag pushed."
    }
}

# --- Step 7: Create GitHub Release ---
Write-Step "Creating GitHub Release: $ReleaseTitle"

$prevErrorAction = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$releaseExists = $false
gh release view $TagName 2>$null
if ($LASTEXITCODE -eq 0) {
    $releaseExists = $true
}
$ErrorActionPreference = $prevErrorAction

if (-not $releaseExists) {
    gh release create $TagName --title $ReleaseTitle --notes $ReleaseNotes
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to create release for '$TagName'." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Release created."
} else {
    Write-Host "  Release already exists. Skipping."
}

# --- Step 8: Upload assets (optional) ---
if ($AssetPaths.Count -gt 0) {
    Write-Step "Uploading release assets"

    foreach ($assetPath in $AssetPaths) {
        if (-not (Test-Path -LiteralPath $assetPath)) {
            Write-Host "[ERROR] Asset not found: $assetPath" -ForegroundColor Red
            exit 1
        }
    }

    gh release upload $TagName $AssetPaths --clobber
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to upload assets for '$TagName'." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Uploaded: $($AssetPaths -join ', ')"
}

# --- Done ---
Write-Step "Publish complete"
Write-Host ""
Write-Host "  Repository : https://github.com/$resolvedRepo"
Write-Host "  Branch     : $Branch"
Write-Host "  Tag        : $TagName"
Write-Host "  Release    : $ReleaseTitle"
Write-Host ""
Write-Host "Done."
