# publish-to-github-skill

一个独立的 GitHub 发布 Skill，专门负责把本地项目发布到 GitHub：登录 GitHub、创建远程仓库、推送分支、生成 tag 和 GitHub Release。

## 目标

该 Skill 只负责发布流程，不夹杂任何其他功能。

## 目录结构

```text
publish-to-github-skill/
├── LICENSE
├── README.md
├── skills/
│   └── publish-to-github/
│       ├── SKILL.md
│       ├── agents/
│       │   └── openai.yaml
│       └── scripts/
│           └── publish_to_github.ps1
```

## 快速开始

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\publish-to-github\scripts\publish_to_github.ps1 -RepoName your-name/your-repo -Visibility public -TagName v0.1.0 -ReleaseTitle "v0.1.0"
```

## 说明

这个仓库是独立发布 skill，单独上传到 GitHub，避免和原来的知识卡片 skill 混在一起。
