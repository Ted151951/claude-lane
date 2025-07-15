# claude-lane

<div align="center">

## ⚡ 多个Claude API一键切换，密钥密文存储防泄漏

**🔒 密钥系统级硬件加密存储，永不明文泄露**

`官方API` → `代理服务` → `私有部署` 随意切换，配置一次终身使用

🔒 **Windows DPAPI** • **macOS Keychain** • **Linux Secret Service**

</div>

---

## 🆚 为什么选择claude-lane？

| 痛点场景 | 传统做法 | claude-lane解决方案 |
|---------|---------|------------------|
| **多API切换** | ❌ 手动修改配置文件 | ✅ `claude-lane official-api` 一键切换 |
| **密钥管理** | ❌ 明文写在配置里 | ✅ 系统级硬件加密存储 |
| **误传泄露** | ❌ 一不小心传GitHub完蛋 | ✅ 配置文件无任何敏感信息 |
| **环境隔离** | ❌ 不同项目混用密钥 | ✅ 一键设置项目专用环境 |

## 🚀 强大功能

- **⚡ 瞬间切换**: `claude-lane proxy` → `claude-lane official-api` 秒级切换API
- **🔒 军用加密**: Windows DPAPI、macOS Keychain、Linux Secret Service硬件级保护
- **🎯 智能模式**: 无配置自动web登录，有配置自动加密调用
- **🌍 全平台**: Windows、macOS、Linux完全相同命令和体验

---

## 📋 使用前提

使用 claude-lane 之前，请确保已安装以下工具：

### 🔧 必需组件
- **[Claude Code](https://github.com/anthropics/claude-code)** - Anthropic官方命令行工具
  ```bash
  npm install -g @anthropic-ai/claude-code
  ```

### 🛠️ 系统要求
- **Windows**: PowerShell 5.0+ / Windows 10+
- **macOS**: macOS 10.13+ / Bash或Zsh
- **Linux**: Ubuntu 18.04+ / Bash 4.0+

### 🌐 网络要求
- 安装时需要访问GitHub（下载脚本和文件）
- 使用时需要访问相应的API端点

---

## 🚀 快速安装

### 📦 一键安装

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/Ted151951/claude-lane/main/install.ps1 | iex
```

**macOS/Linux (Bash):**
```bash
curl -fsSL https://raw.githubusercontent.com/Ted151951/claude-lane/main/install.sh | bash
```

### 升级

**从旧版本升级：重新运行安装脚本即可**
```bash
# 自动覆盖旧版本并保留配置
# Windows: 运行上面的 PowerShell 命令
# Linux/macOS: 运行上面的 Bash 命令
```

**⚠️ v1.2.0+ 重要变更：** `official` 配置已重命名为 `official-api`  
详细升级指南请参考：[UPGRADE.md](./UPGRADE.md)

### ⚡ 两步极简配置

1. **创建配置文件** - 从模板复制或手动创建

   **方法一：复制模板（推荐）**
   ```bash
   # 安装后会在这里找到模板
   # Windows: C:\Users\你的用户名\.claude\scripts\windows\..\..\templates\config.yaml
   # Linux/macOS: ~/.claude/scripts/*/templates/config.yaml
   
   # 复制到配置目录
   cp ~/.claude/scripts/*/templates/config.yaml ~/.claude/config.yaml
   ```

   **方法二：手动创建 `~/.claude/config.yaml`**
   ```yaml
   endpoints:
     official-api:
       base_url: "https://api.anthropic.com"
     
     proxy:
       base_url: "https://your-proxy.example.com/v1"
     
     kimi:
       base_url: "https://api.moonshot.cn/anthropic"
   ```
   > 💡 配置文件位置：
   > - **Windows**: `C:\Users\你的用户名\.claude\config.yaml`
   > - **Linux/macOS**: `~/.claude/config.yaml`

2. **密钥安全入库**（永远不会明文保存）:
```bash
claude-lane set-key official-api sk-ant-api03-你的官方密钥
claude-lane set-key proxy 你的代理密钥
```

3. **体验极速切换**:
```bash
# 🚀 一键切换API，享受安全对话
claude-lane official-api "用官方API写首诗"
claude-lane proxy "用代理API翻译文字"  
claude-lane kimi "用Kimi API回答问题"

# 💨 更快的切换方式
claude-lane proxy              # 切换到代理并进入交互模式
claude-lane official-api       # 切换回官方API

# 🔧 高级用法  
claude-lane --env-only proxy   # 只设置环境变量，不启动对话
claude-lane status             # 查看所有API状态和密钥状况
```

## 命令说明

| 命令 | 说明 |
|---------|-------------|
| `claude-lane [消息]` | 使用上次/默认配置运行 Claude |
| `claude-lane <配置名> [消息]` | 切换配置并运行 Claude |
| `claude-lane set-key <引用名> <密钥>` | 安全存储 API 密钥 |
| `claude-lane list` | 列出可用配置和已存储的密钥 |
| `claude-lane status` | 显示当前配置状态 |
| `claude-lane --reset` | 重置为 official 配置 |
| `claude-lane --env-only [配置]` | 仅设置环境变量 |
| `claude-lane help` | 显示帮助信息 |

## 平台特定设置

### Windows
- **要求**: PowerShell 5.0+（Windows 10+ 内置）
- **密钥存储**: Windows 数据保护 API (DPAPI)
- **执行策略**: 如果遇到执行策略错误，运行：
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### macOS
- **要求**: macOS 10.12+（使用内置 `security` 命令）
- **密钥存储**: Keychain 服务
- **权限**: 可能会提示允许钥匙串访问

### Linux
- **要求**: `libsecret-tools` 包
- **安装**:
  - Ubuntu/Debian: `sudo apt install libsecret-tools`
  - Fedora/RHEL: `sudo dnf install libsecret`
  - Arch: `sudo pacman -S libsecret`
- **密钥存储**: Secret Service API (gnome-keyring、KDE Wallet 等)

## 配置示例

### 多代理服务
```yaml
endpoints:
  official:
    base_url: "https://api.anthropic.com"
    key_ref: "official"
  
  cloudflare:
    base_url: "https://gateway.ai.cloudflare.com/v1/your-account/claude/anthropic"
    key_ref: "cloudflare"
  
  openrouter:
    base_url: "https://openrouter.ai/api/v1"
    key_ref: "openrouter"
  
  local:
    base_url: "http://localhost:8080/v1"
    key_ref: "local"
```

### 开发环境 vs 生产环境
```yaml
endpoints:
  prod:
    base_url: "https://api.anthropic.com"
    key_ref: "production"
  
  staging:
    base_url: "https://staging-api.yourcompany.com/v1"
    key_ref: "staging"
  
  dev:
    base_url: "http://localhost:8080/v1"
    key_ref: "development"
```

## 安全性

- **API 密钥从不以明文存储** - 所有密钥都使用操作系统原生安全存储
- **配置文件不包含机密信息** - 只包含对安全存储密钥的引用
- **最小权限** - 安装无需 root/管理员权限
- **平台原生加密**:
  - Windows: 使用 CurrentUser 范围的 DPAPI
  - macOS: 使用用户钥匙串的 Keychain 服务
  - Linux: 使用会话钥匙环的 Secret Service API

## 故障排除

### 密钥未找到错误
```bash
# 列出已存储的密钥
claude-lane list

# 如果缺失，重新存储密钥
claude-lane set-key <密钥引用> <API密钥>
```

### Windows 执行策略问题
```powershell
# 允许本地脚本
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 或一次性绕过运行
powershell -ExecutionPolicy Bypass -File claude-lane
```

### Linux Secret Service 问题
```bash
# 安装 libsecret-tools
sudo apt install libsecret-tools  # Ubuntu/Debian
sudo dnf install libsecret        # Fedora/RHEL

# 检查 secret service 是否运行
systemctl --user status gnome-keyring-daemon
```

### macOS Keychain 访问
- 可能会看到请求钥匙串访问的提示
- 点击"始终允许"以避免重复提示
- 如需要可使用钥匙串访问应用管理存储的密钥

## 与 Claude Code 集成

claude-lane 设置的环境变量会被官方 Claude Code 识别：

```bash
# 切换配置后
claude-lane official

# 这些环境变量会被设置：
# ANTHROPIC_API_KEY=你的API密钥
# ANTHROPIC_BASE_URL=https://api.anthropic.com

# 配合 Claude Code 使用
claude "你好，最近怎么样？"
```

## 验证安装

测试安装：

```bash
# 存储测试密钥
claude-lane set-key test_key sk-test123

# 切换到测试配置（需要在配置中定义）
claude-lane test_profile

# 列出所有信息
claude-lane list
```

## 贡献

1. Fork 仓库
2. 创建功能分支
3. 在所有平台上测试
4. 提交 Pull Request

## 许可证

本项目采用 CC BY-NC-SA 4.0（知识共享署名-非商业性使用-相同方式共享 4.0 国际许可协议）进行许可 - 详见 LICENSE 文件。

---

🔒 **Secure, cross-platform Claude API endpoint switcher**

Switch between different Claude API endpoints (official, proxies, alternatives) with secure key storage and a unified interface.

## Features

- 🔒 **Secure Key Storage**: Uses OS-native encryption (Windows DPAPI, macOS Keychain, Linux Secret Service)
- ↔️ **Single Command Switching**: `claudelane <profile>` to switch endpoints instantly
- 🌐 **Cross-Platform**: Works on Windows, macOS, and Linux with consistent interface
- 🛡️ **Zero Plaintext**: API keys never stored in plaintext configuration files
- ⚡ **Simple Setup**: One-command installation and configuration

## Quick Start

### Installation

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/Ted151951/claude-lane/main/install.ps1 | iex
```

**macOS/Linux (Bash):**
```bash
curl -fsSL https://raw.githubusercontent.com/Ted151951/claude-lane/main/install.sh | bash
```

### Upgrade

**Upgrade from older versions: Simply re-run the installation script**
```bash
# Automatically overwrites old version while preserving config
# Windows: Run the PowerShell command above
# Linux/macOS: Run the Bash command above
```

**⚠️ v1.2.0+ Breaking Change:** `official` profile renamed to `official-api`  
For detailed upgrade instructions, see: [UPGRADE.md](./UPGRADE.md)

### Configuration

1. **Set up your configuration file** (`~/.claude/config.yaml`):
```yaml
endpoints:
  official:
    base_url: "https://api.anthropic.com"
    key_ref: "official"
  
  proxy:
    base_url: "https://your-proxy.example.com/v1"
    key_ref: "proxy"
```

2. **Store your API keys securely**:
```bash
claude-lane set-key official sk-ant-api03-your-official-key
claude-lane set-key proxy your-proxy-api-key
```

3. **Smart usage**:
```bash
# Quick chat (auto-uses last/default profile)
claude-lane "Hello, how are you today?"

# Specify profile and chat
claude-lane official-api "Write a poem"

# Interactive mode
claude-lane                    # Use last profile
claude-lane proxy              # Use specified profile

# Environment-only mode
claude-lane --env-only official
```

## Commands

| Command | Description |
|---------|-------------|
| `claude-lane [message]` | Use last/default profile and run Claude |
| `claude-lane <profile> [message]` | Switch to profile and run Claude |
| `claude-lane set-key <ref> <key>` | Store an API key securely |
| `claude-lane list` | List available profiles and stored keys |
| `claude-lane status` | Show current configuration status |
| `claude-lane --reset` | Reset to official profile |
| `claude-lane --env-only [profile]` | Only set environment variables |
| `claude-lane help` | Show help information |

## Platform-Specific Setup

### Windows
- **Requirements**: PowerShell 5.0+ (built into Windows 10+)
- **Key Storage**: Windows Data Protection API (DPAPI)
- **Execution Policy**: If you get execution policy errors, run:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### macOS
- **Requirements**: macOS 10.12+ (uses built-in `security` command)
- **Key Storage**: Keychain Services
- **Permissions**: You may be prompted to allow keychain access

### Linux
- **Requirements**: `libsecret-tools` package
- **Installation**:
  - Ubuntu/Debian: `sudo apt install libsecret-tools`
  - Fedora/RHEL: `sudo dnf install libsecret`
  - Arch: `sudo pacman -S libsecret`
- **Key Storage**: Secret Service API (gnome-keyring, KDE Wallet, etc.)

## Configuration Examples

### Multiple Proxy Services
```yaml
endpoints:
  official:
    base_url: "https://api.anthropic.com"
    key_ref: "official"
  
  cloudflare:
    base_url: "https://gateway.ai.cloudflare.com/v1/your-account/claude/anthropic"
    key_ref: "cloudflare"
  
  openrouter:
    base_url: "https://openrouter.ai/api/v1"
    key_ref: "openrouter"
  
  local:
    base_url: "http://localhost:8080/v1"
    key_ref: "local"
```

### Development vs Production
```yaml
endpoints:
  prod:
    base_url: "https://api.anthropic.com"
    key_ref: "production"
  
  staging:
    base_url: "https://staging-api.yourcompany.com/v1"
    key_ref: "staging"
  
  dev:
    base_url: "http://localhost:8080/v1"
    key_ref: "development"
```

## Security

- **API keys are never stored in plaintext** - all keys use OS-native secure storage
- **Configuration files contain no secrets** - only references to securely stored keys
- **Minimal permissions** - no root/admin access required for installation
- **Platform-native encryption**:
  - Windows: DPAPI with CurrentUser scope
  - macOS: Keychain Services with user keychain
  - Linux: Secret Service API with session keyring

## Troubleshooting

### Key Not Found Errors
```bash
# List stored keys
claude-lane list

# Re-store a key if missing
claude-lane set-key <key_ref> <api_key>
```

### Windows Execution Policy Issues
```powershell
# Allow local scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass (one-time)
powershell -ExecutionPolicy Bypass -File claude-lane
```

### Linux Secret Service Issues
```bash
# Install libsecret-tools
sudo apt install libsecret-tools  # Ubuntu/Debian
sudo dnf install libsecret        # Fedora/RHEL

# Check if secret service is running
systemctl --user status gnome-keyring-daemon
```

### macOS Keychain Access
- You may see prompts asking for keychain access
- Click "Always Allow" to avoid repeated prompts
- Use Keychain Access.app to manage stored keys if needed

## Integration with Claude Code

claude-lane sets environment variables that the official Claude Code recognizes:

```bash
# After switching profiles
claude-lane official

# These variables are now set:
# ANTHROPIC_API_KEY=your-api-key
# ANTHROPIC_BASE_URL=https://api.anthropic.com

# Use with Claude Code
claude "Hello, how are you?"
```

## Verification

Test your installation:

```bash
# Store a test key
claude-lane set-key test_key sk-test123

# Switch to a test profile (you'll need this in your config)
claude-lane test_profile

# List everything
claude-lane list
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test on all platforms
4. Submit a pull request

## License

This project is licensed under CC BY-NC-SA 4.0 (Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License) - see LICENSE file for details.