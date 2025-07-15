# claude-lane

<div align="center">

## 🔐 终于有一个不会泄露你API密钥的Claude切换工具了

**你的API密钥价值连城，为什么要把它们明文保存在配置文件里？**

**claude-lane** 使用军用级系统原生加密技术，让你的API密钥获得与银行账户密码相同级别的保护。

</div>

---

## 💡 为什么选择 claude-lane？

### 🚨 其他工具的致命问题
- ❌ **配置文件明文存储** - 任何人都能看到你的API密钥
- ❌ **简单Base64编码** - 10秒就能破解
- ❌ **文本文件保存** - 误传GitHub直接泄露
- ❌ **无权限控制** - 恶意软件轻松窃取

### ✅ claude-lane的安全革命
- 🔒 **系统级硬件加密**: 
  - Windows DPAPI（企业级数据保护）
  - macOS Keychain（苹果安全架构）  
  - Linux Secret Service（开源安全标准）
- 🛡️ **零明文存储**: 密钥永远不会以可读形式出现
- 🔐 **用户级权限**: 只有你的账户才能解密
- 💎 **防窃取设计**: 即使系统被入侵，密钥依然安全

---

## ⚡ 强大功能，极简使用

- ↔️ **一键切换**: `claude-lane official` 瞬间切换到官方API
- 🌍 **全平台统一**: Windows、macOS、Linux 完全相同的体验  
- 🔄 **智能回退**: 无配置时自动使用 Claude 网页登录
- ⚙️ **灵活配置**: 支持官方、代理、私有部署等任意端点

---

## 🎯 安全性对比演示

### 😱 传统工具的可怕现实
```yaml
# ~/.config/other-tools/config.yaml
api_key: "sk-ant-api03-your-precious-key-here"  # 😱 明文可见！
```
**任何人都能看到你的密钥！** 文件分享、GitHub提交、恶意软件扫描...一不小心就全完了。

### 😎 claude-lane的安全堡垒
```yaml
# ~/.claude/config.yaml  
endpoints:
  official-api:
    base_url: "https://api.anthropic.com"
    # 🔒 密钥安全存储在系统密钥库中，配置文件中看不到任何敏感信息
```

```bash
# 尝试查看存储的密钥
$ cat ~/.claude/config.yaml
# 😎 完全看不到API密钥！

$ claude-lane status
# ✅ [OK] official-api (has key) 
# 😎 工具知道密钥存在，但不暴露内容！
```

**这就是专业级安全的差距！**

---

## 🚀 立即开始安全之旅

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

### ⚡ 三步极简配置

1. **创建安全配置** (`~/.claude/config.yaml`):
```yaml
endpoints:
  official-api:
    base_url: "https://api.anthropic.com"
    # 🔒 不需要key_ref - 直接使用profile名称
  
  proxy:
    base_url: "https://your-proxy.example.com/v1"
    # 🔒 密钥将安全存储在系统密钥库中
```

2. **密钥安全入库**（永远不会明文保存）:
```bash
claude-lane set-key official-api sk-ant-api03-你的官方密钥
claude-lane set-key proxy 你的代理密钥
```

3. **开始安全对话**:
```bash
# 无配置模式（Claude网页登录）
claude-lane "你好，今天天气怎么样？"

# API密钥模式（安全加密）
claude-lane official-api "写一首诗"
claude-lane proxy "翻译这段文字"

# 交互模式
claude-lane                    # 智能选择最佳方式
claude-lane official-api       # 使用加密存储的API密钥

# 环境变量模式
claude-lane --env-only official-api  # 仅设置环境变量
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

## 与 Claude CLI 集成

claude-lane 设置的环境变量会被官方 Claude CLI 识别：

```bash
# 切换配置后
claude-lane official

# 这些环境变量会被设置：
# ANTHROPIC_API_KEY=你的API密钥
# ANTHROPIC_BASE_URL=https://api.anthropic.com

# 配合 Claude CLI 使用
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

## Integration with Claude CLI

claude-lane sets environment variables that the official Claude CLI recognizes:

```bash
# After switching profiles
claude-lane official

# These variables are now set:
# ANTHROPIC_API_KEY=your-api-key
# ANTHROPIC_BASE_URL=https://api.anthropic.com

# Use with Claude CLI
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