# publish-to-github-skill

一个用于把本地 Git 仓库发布到 GitHub 的技能。它可以自动创建仓库、推送分支、创建 tag、生成 GitHub Release，并支持上传发布资源文件。

## 功能特点

- 检查 Git 和 GitHub CLI 是否已安装
- 若未登录 GitHub，则自动打开登录页面
- 若仓库不存在，则创建新的 GitHub 仓库
- 推送当前分支到远程仓库
- 自动创建并推送 tag（如果不存在）
- 自动创建 GitHub Release（如果不存在）
- 支持上传自定义资产文件
- 支持 public 和 private 两种可见性

## 快速使用

```powershell
powershell -ExecutionPolicy Bypass -File .\publish-to-github\scripts\publish_to_github.ps1 `
  -RepoName laolao-dada/publish-to-github-skill `
  -Visibility public `
  -Branch main `
  -TagName v0.2.1 `
  -ReleaseTitle "v0.2.1" `
  -ReleaseNotes "Update README and release metadata"
```

## 源代码目录说明

脚本默认会把当前工作目录当作源代码目录来发布：

```powershell
gh repo create $resolvedRepo $visibilityFlag --source . --remote origin --push
```

如果你想发布别的目录，而不是当前文件夹，可以把 `.` 换成你想发布的目录路径。

## 说明

- 脚本会自动检查远程仓库和 Release 是否已存在
- 如果 tag 已存在，则跳过创建
- 如果 release 已存在，则跳过创建
- 上传资源文件是可选的，由 `AssetPaths` 控制