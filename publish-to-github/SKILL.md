---
name: publish-to-github
description: >
  将本地项目按 GitHub 规范整理并一键发布：自动检测或生成 README.md、LICENSE、.gitignore，
  然后通过 gh CLI 创建仓库、推送代码、打 tag、创建 Release。适用于任何想快速把本地项目
  变成 GitHub 规范仓库的场景。
version: 0.3.0
agent_created: true
---

# publish-to-github

将本地 Git 项目一键整理 + 发布到 GitHub。先确保项目符合 GitHub 规范（README、LICENSE、.gitignore），再执行推送和 Release 创建。

## 适用场景

- 本地项目已经完成，想发布到 GitHub
- 项目缺少 README / LICENSE / .gitignore，需要补齐
- 需要创建 tag 和 Release

## 工作流程（两阶段）

### 阶段一：GitHub 格式准备（由你执行）

在做任何推送之前，先检查项目根目录是否有以下文件：

| 文件 | 检查内容 | 不存在时的动作 |
|------|---------|---------------|
| `README.md` | 是否存在 | 根据项目内容自动生成。读取项目结构、关键文件（package.json / Cargo.toml / pyproject.toml 等），生成有项目名、简介、安装说明、用法的 README.md |
| `LICENSE` | 是否存在 | 使用 `AskUserQuestion` 询问用户要哪种许可证（MIT / Apache-2.0 / GPL-3.0 / 跳过）。选 MIT 直接写入标准 MIT 文本；选其他则写入对应标准文本；选跳过则不创建 |
| `.gitignore` | 是否存在 | 根据项目语言自动生成。检测项目中的语言标识文件（Node.js → node_modules, Python → __pycache__ 等），写入对应的 .gitignore 模板 |

生成完所有缺失文件后，执行 `git add -A && git commit -m "chore: prepare GitHub-compliant repo structure"`。

**重要**：只有在这个阶段完成后才能进入阶段二。生成的 README.md 要有实际内容，不能是空模板。

### 阶段二：推送到 GitHub（由 PowerShell 脚本执行）

运行以下命令推送到 GitHub：

```powershell
powershell -ExecutionPolicy Bypass -File .\publish-to-github\scripts\publish_to_github.ps1 `
  -RepoName "owner/repo-name" `
  -Visibility public `
  -Branch main `
  -TagName "v0.1.0" `
  -ReleaseTitle "v0.1.0" `
  -ReleaseNotes "发布的说明内容"
```

参数说明：

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `-RepoName` | 是 | - | GitHub 仓库名，格式 `owner/repo` |
| `-Visibility` | 否 | `public` | `public` 或 `private` |
| `-Branch` | 否 | `main` | 目标分支名 |
| `-TagName` | 否 | `v0.1.0` | Git tag 名称 |
| `-ReleaseTitle` | 否 | 同 TagName | Release 标题 |
| `-ReleaseNotes` | 否 | `Initial release` | Release 说明 |
| `-AssetPaths` | 否 | `@()` | 要上传的附件路径数组 |
| `-SkipTag` | 否 | `$false` | 跳过创建 tag |

## 前置条件

- 当前目录必须是 Git 仓库（如果不是，先 `git init`）
- 已安装 GitHub CLI（`gh`），如未安装脚本会报错提示
- 已登录 GitHub（未登录时脚本会打开浏览器登录）

## 完整使用示例

用户说："帮我把这个项目发布到 GitHub"，你应该：

1. 检查/生成 README.md、LICENSE、.gitignore
2. git add + git commit
3. 询问用户：仓库名、可见性、tag、release 说明
4. 运行 PowerShell 脚本发布
5. 返回仓库 URL
