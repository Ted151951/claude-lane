# 贡献指南

感谢你对 claude-lane 项目的兴趣！这个文档将帮助你了解如何为项目做出贡献。

## 🚀 快速开始

### 环境要求

**Windows**:
- PowerShell 5.0 或更高版本
- Git for Windows

**Linux/macOS**:
- Bash 4.0 或更高版本
- Git

### 开发环境设置

1. **克隆仓库**
```bash
git clone https://github.com/Ted151951/claude-lane.git
cd claude-lane
```

2. **本地测试**
```bash
# Windows
.\scripts\windows\claude-lane.ps1 --version

# Linux/macOS
./bin/claude-lane --version
```

## 📝 贡献流程

### 1. 报告问题
- 使用 [GitHub Issues](https://github.com/Ted151951/claude-lane/issues)
- 描述问题现象和重现步骤
- 包含系统信息（操作系统、Shell版本等）

### 2. 提交代码

1. **Fork 项目**
2. **创建功能分支**
```bash
git checkout -b feature/your-feature-name
```

3. **进行更改**
4. **运行测试**（见下方测试指南）
5. **提交更改**
```bash
git commit -m "feat: add your feature description"
```

6. **推送分支**
```bash
git push origin feature/your-feature-name
```

7. **创建 Pull Request**

### 3. 代码规范

- **PowerShell**: 使用 PascalCase 函数名
- **Bash**: 使用 snake_case 函数名
- **提交信息**: 使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式
- **文档**: 中英文混合，以中文为主

## 🧪 测试指南

### 基础功能验证

运行以下命令验证基本功能：

```bash
# 检查版本和帮助
claude-lane --version
claude-lane help

# 检查状态
claude-lane status

# 测试配置管理
claude-lane set-key test-profile test-key-123
claude-lane list
claude-lane status
```

### 跨平台测试

确保功能在不同平台上一致工作：

- **Windows 10/11 + PowerShell 5.1/7+**
- **Ubuntu 20.04+ + Bash**
- **macOS 12+ + Bash/Zsh**

### 安装测试

测试完整的安装流程：

```bash
# 从本地测试安装脚本
# Windows
Get-Content install.ps1 | PowerShell

# Linux/macOS
bash install.sh
```

## 🐛 问题调试

### 常见问题

1. **PowerShell 执行策略错误**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

2. **PATH 环境变量问题**
```bash
# 刷新环境变量或重启终端
export PATH="$HOME/.local/bin:$PATH"
```

3. **密钥存储问题**
- Windows: 检查 DPAPI 服务
- Linux: 确保 Secret Service 可用
- macOS: 验证 Keychain Access

### 日志和调试

如果遇到问题，请提供：
- 操作系统和版本
- Shell 类型和版本
- 完整的错误信息
- 重现步骤

## 📁 项目结构

```
claude-lane/
├── bin/                    # Linux/macOS 可执行文件
├── scripts/
│   ├── windows/           # Windows PowerShell 脚本
│   ├── linux/            # Linux 平台脚本
│   └── macos/            # macOS 平台脚本
├── templates/             # 配置文件模板
├── docs/                 # 文档
├── install.ps1           # Windows 安装脚本
├── install.sh           # Linux/macOS 安装脚本
└── README.md            # 项目说明
```

## 🎯 开发重点

### 当前优先级

1. **跨平台兼容性** - 确保所有功能在三大平台上正常工作
2. **用户体验** - 简化配置和使用流程
3. **错误处理** - 提供清晰的错误信息和解决建议
4. **文档完善** - 保持文档与代码同步

### 功能路线图

- [ ] 支持配置文件热重载
- [ ] 添加配置验证命令
- [ ] 支持环境变量配置
- [ ] 增强错误诊断功能

## 💬 社区

- **问题讨论**: [GitHub Issues](https://github.com/Ted151951/claude-lane/issues)
- **功能请求**: [GitHub Discussions](https://github.com/Ted151951/claude-lane/discussions)

## 📄 许可证

本项目采用 [CC BY-NC-SA 4.0](../LICENSE) 许可证，确保：
- ✅ 可以使用、修改、分发
- ✅ 必须保持开源
- ❌ 不可用于商业用途
- ✅ 衍生作品必须使用相同许可证

---

再次感谢你的贡献！每一个 issue、PR 或建议都帮助 claude-lane 变得更好。🎉