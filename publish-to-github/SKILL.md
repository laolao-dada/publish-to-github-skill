# publish-to-github

一个用于 GitHub 一键发布的 WorkBuddy Skill。它会在 Windows 环境中按标准流程：校验 Git/gh、登录 GitHub、创建远程仓库、推送分支、创建 tag，并可额外上传 GitHub Release。

## 版本

- 0.2.0
- 新增功能：附加上传 release

## 1. 解决什么问题

本地项目已经完成，但发布到 GitHub 时需要反复执行：

- 登录 GitHub
- 创建远程仓库
- 推送当前分支
- 创建并推送 tag
- 创建 GitHub Release

这个 Skill 把这些动作标准化成一个可重复执行的发布流程。

## 2. 适用场景

- 用户想把本地项目上传到 GitHub
- 用户准备公开发布或打版本标签
- 用户已经有 Git 仓库，但还没建远程仓库

不适用场景：

- 当前目录不是 Git 仓库
- 用户不希望创建远程仓库
- 用户尚未授权 GitHub 登录

## 3. 安装方式

把 `publish-to-github` 目录放到 `skills` 目录即可：

```powershell
Copy-Item -Recurse skills/publish-to-github "$env:USERPROFILE\.workbuddy\skills\"
```

## 4. 快速开始

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\publish-to-github\scripts\publish_to_github.ps1 -RepoName article-to-knowledge-cards -Visibility public -TagName v0.1.0 -ReleaseTitle "v0.1.0"
```

参数：

- `-RepoName`：GitHub 仓库名
- `-Visibility`：`public` 或 `private`
- `-TagName`：tag 名称，例如 `v0.1.0`
- `-ReleaseTitle`：GitHub Release 标题
- `-ReleaseNotes`：发布说明
- `-Branch`：目标分支，默认 `main`

## 5. 发布流程

1. 检查当前目录是否为 Git 仓库
2. 检查 GitHub CLI (`gh`) 是否已安装
3. 若未登录，启动浏览器授权流程
4. 创建远程仓库并推送当前分支
5. 若 tag 不存在，则创建并推送
6. 创建 GitHub Release
7. 返回仓库地址、tag、release 结果

## 6. 安全规则

- 仅在用户明确授权后执行 GitHub 登录和仓库创建
- 不覆盖已有远程仓库
- 不输出 Token、密码或密钥
- 若当前目录不是 Git 仓库，先要求初始化

## 7. 示例

公开发布：

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\publish-to-github\scripts\publish_to_github.ps1 -RepoName article-to-knowledge-cards -Visibility public -TagName v0.1.0 -ReleaseTitle "v0.1.0"
```

私有发布：

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\publish-to-github\scripts\publish_to_github.ps1 -RepoName internal-docs -Visibility private -TagName v1.0.0 -ReleaseTitle "v1.0.0" -ReleaseNotes "初始发布"
```

## 8. 说明

这个 Skill 适合本地开发环境中的标准化发布工作流。真正的 GitHub 账号、仓库名和可见性，仍由用户最终确认。

## 9. 0.2.0 更新说明

新增附加上传 release 功能：

- 自动检查 tag 是否已存在
- 自动检查 release 是否已存在
- 若已存在则跳过重复创建
- 适合需要发布新版本时附带 release 说明的场景
