# Contributing

欢迎贡献。这个项目的核心价值是**踩坑经验**，不是代码。

## 怎么贡献

### 加一个新 Pitfall

1. 在 `SKILL.md` 的 Pitfalls 区域，按现有格式加一条
2. 格式：`### 症状（一句话）` → **Symptom** → **Root cause** → **Fix**
3. 贴真实的命令和错误信息，不要编

### 加一个新的 Reference

1. 在 `references/` 下新建 `.md` 文件
2. 在 `SKILL.md` 末尾的 Support files 列表里加一条链接
3. Reference 应该是"做某件事的完整指南"，不是泛泛而谈

### 改 Template

1. 在 `templates/` 里改对应的文件
2. 确保占位符用 `{{VARIABLE_NAME}}` 格式
3. 如果是新的启动方式（比如 macOS 的 `.command`），加新文件即可

## 风格约定

- 用中文写 Pitfalls（因为坑都是中文环境下踩的），用英文写 Reference 标题
- 真实 > 优雅。一个贴了真实报错信息的条目比一段漂亮的理论分析有用十倍
- 一个条目只讲一个坑，不要混
