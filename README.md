# publish-to-github-skill

WorkBuddy Skill：将本地 Git 项目按 GitHub 规范整理并一键发布。

## 做了什么

| 阶段 | 内容 |
|------|------|
| **格式准备** | 自动检测并补全 README.md、LICENSE、.gitignore |
| **一键发布** | 通过 gh CLI 创建仓库、推送代码、打 tag、创建 Release |

## 版本

**v0.3.0** — 重大更新
- 新增 GitHub 格式准备阶段（README / LICENSE / .gitignore）
- 修复 PowerShell 脚本中 `Start-Process` 和 `Read-Host` 的 bug
- 添加 SKILL.md YAML frontmatter
- 改善错误处理和日志输出

## 安装

```powershell
Copy-Item -Recurse publish-to-github "$env:USERPROFILE\.workbuddy\skills\"
```

## 使用

在 WorkBuddy 中说：

> 帮我把这个项目发布到 GitHub

Skill 会自动：
1. 检查/生成 README.md、LICENSE、.gitignore
2. git commit 整理后的文件
3. 询问仓库名、可见性、版本号
4. 推送到 GitHub + 创建 Release

## 文件结构

```
publish-to-github/
├── SKILL.md              # Skill 定义和工作流程
├── agents/
│   └── openai.yaml       # Agent 配置
└── scripts/
    └── publish_to_github.ps1  # PowerShell 发布脚本
```
