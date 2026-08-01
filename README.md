# publish-to-github-skill

一个独立的 GitHub 发布 Skill，专门负责把本地项目发布到 GitHub。它支持：登录 GitHub、创建远程仓库、推送分支、创建 Tag，以及额外上传 GitHub Release。

## 版本

- 0.2.0
- 新增功能：支持“附加上传 release”流程

## 目标

这个 Skill 只负责 GitHub 发布流程，不夹杂任何其他功能。

## 目录结构

```text
publish-to-github-skill/
├── LICENSE
├── README.md
├── publish-to-github/
│   ├── SKILL.md
│   ├── agents/
│   │   └── openai.yaml
│   └── scripts/
│       └── publish_to_github.ps1
```

## 快速开始

```powershell
powershell -ExecutionPolicy Bypass -File .\publish-to-github\scripts\publish_to_github.ps1 -RepoName your-name/your-repo -Visibility public -TagName v0.2.0 -ReleaseTitle "v0.2.0" -ReleaseNotes "Add release upload support"
```

## 新增功能说明

### 附加上传 release

0.2 版本新增：

- 支持创建并推送 tag
- 支持额外上传 GitHub Release
- 若 release 已存在，则跳过重复创建
- 若 tag 已存在，则跳过重复创建

## 说明

这个仓库是独立发布 skill，单独上传到 GitHub，避免和原始知识卡片 skill 混在一起。