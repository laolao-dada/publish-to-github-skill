# publish-to-github

This skill publishes the current local Git repository to GitHub, optionally creates a tag, creates a GitHub release, and can upload release assets.

## Features

- verifies that Git and the GitHub CLI are installed
- prompts the user to log in to GitHub if needed
- creates a new GitHub repository when it does not exist
- pushes the selected branch to the remote repository
- creates and pushes a tag if one is not already present
- creates a GitHub release if it does not already exist
- uploads release assets when `AssetPaths` are provided
- supports both public and private repo visibility

## Usage

```powershell
powershell -ExecutionPolicy Bypass -File .\publish-to-github\scripts\publish_to_github.ps1 `
  -RepoName your-name/your-repo `
  -Visibility public `
  -Branch main `
  -TagName v0.2.1 `
  -ReleaseTitle "v0.2.1" `
  -ReleaseNotes "Add release upload support"
```

## Source directory

The script publishes the current working directory as the source repository by using:

```powershell
gh repo create $resolvedRepo $visibilityFlag --source . --remote origin --push
```

If you want to publish a different source folder instead of the current folder, replace `.` with the folder path you want to use.

## Notes

- the script automatically checks whether the target repository and release already exist
- if `TagName` already exists locally, it skips tag creation
- if the release already exists, it skips release creation
- asset uploads are optional and controlled by `AssetPaths`
