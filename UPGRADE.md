# claude-lane 升级指南

## 🚀 从旧版本升级到最新版本

### 快速升级（推荐）

重新运行安装脚本即可自动更新到最新版本：

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/Ted151951/claude-lane/main/install.ps1 | iex
```

**macOS/Linux (Bash):**
```bash
curl -fsSL https://raw.githubusercontent.com/Ted151951/claude-lane/main/install.sh | bash
```

### 手动升级

如果您通过 Git clone 安装：

```bash
cd /path/to/claude-lane
git pull origin main
# 重新运行安装
./install.sh  # Linux/macOS
# 或
.\install.ps1  # Windows
```

## ⚠️ v1.2.0 重大变更

### 配置文件迁移

v1.2.0 将 `official` 配置重命名为 `official-api` 以避免与默认行为混淆。

#### 自动迁移（推荐）

升级后运行以下命令自动迁移配置：

```bash
# 检查当前配置
claude-lane status

# 如果看到 "Profile 'official' not found" 错误，进行迁移：
```

**Windows:**
```powershell
# 备份现有配置
Copy-Item "$env:USERPROFILE\.claude\config.yaml" "$env:USERPROFILE\.claude\config.yaml.backup"

# 替换配置中的 official 为 official-api
(Get-Content "$env:USERPROFILE\.claude\config.yaml") -replace 'official:', 'official-api:' | Set-Content "$env:USERPROFILE\.claude\config.yaml"

# 更新 last_profile 文件（如果存在）
if (Test-Path "$env:USERPROFILE\.claude\last_profile") {
    (Get-Content "$env:USERPROFILE\.claude\last_profile") -replace '^official$', 'official-api' | Set-Content "$env:USERPROFILE\.claude\last_profile"
}
```

**Linux/macOS:**
```bash
# 备份现有配置
cp ~/.claude/config.yaml ~/.claude/config.yaml.backup

# 替换配置中的 official 为 official-api
sed -i 's/official:/official-api:/' ~/.claude/config.yaml

# 更新 last_profile 文件（如果存在）
if [ -f ~/.claude/last_profile ]; then
    sed -i 's/^official$/official-api/' ~/.claude/last_profile
fi
```

#### 手动迁移

编辑 `~/.claude/config.yaml` 文件：

```yaml
# 将这个：
endpoints:
  official:
    base_url: "https://api.anthropic.com"
    key_ref: "official"

# 改为：
endpoints:
  official-api:
    base_url: "https://api.anthropic.com"
    key_ref: "official"
```

### 行为变更

#### v1.1.0 及之前：
```bash
claude-lane              # 错误：需要配置文件
claude-lane official     # 使用 API 密钥模式
```

#### v1.2.0 及之后：
```bash
claude-lane                  # ✅ 自动使用 Claude CLI 网页登录
claude-lane official-api     # 使用 API 密钥模式
```

## 🔧 升级后验证

升级完成后，验证安装：

```bash
# 检查版本（应显示 v1.2.0 或更高）
claude-lane --version

# 检查状态
claude-lane status

# 测试默认行为（应该使用网页登录）
claude-lane "Hello, test upgrade"

# 如果有 API 配置，测试 API 模式
claude-lane official-api "Hello, test API mode"
```

## 🆘 升级问题排除

### 问题：找不到 'official' 配置
**解决方案：** 运行上面的配置迁移命令，或手动重命名为 `official-api`

### 问题：仍然提示配置文件错误
**解决方案：** 
1. 备份现有配置：`cp ~/.claude/config.yaml ~/.claude/config.yaml.backup`
2. 复制新模板：`cp ~/.claude/scripts/*/../../templates/config.yaml ~/.claude/config.yaml`
3. 重新配置 API 密钥

### 问题：命令未找到
**解决方案：** 
1. 重启终端/PowerShell
2. 检查 PATH：`echo $PATH` (Linux/macOS) 或 `$env:PATH` (Windows)
3. 手动添加到 PATH：`~/.local/bin` (Linux/macOS) 或 `%USERPROFILE%\.local\bin` (Windows)

### 问题：权限错误 (Linux/macOS)
**解决方案：**
```bash
chmod +x ~/.local/bin/claude-lane
chmod +x ~/.claude/scripts/*/keystore.sh
```

## 📋 版本对比

| 版本 | 默认行为 | 配置名称 | 主要特性 |
|------|----------|----------|----------|
| v1.0.0 | 需要手动配置 | `official` | 基础 API 切换 |
| v1.1.0 | 记住上次配置 | `official` | 智能默认 + 自动运行 |
| v1.2.0 | 网页登录优先 | `official-api` | 零配置启动 |

## 🔄 降级（如需要）

如果遇到问题需要回到旧版本：

```bash
# 下载特定版本
git clone https://github.com/Ted151951/claude-lane.git
cd claude-lane
git checkout v1.1.0  # 或其他版本标签
# 重新安装
```

## 📞 获取帮助

如果升级过程中遇到问题：

1. 查看 [GitHub Issues](https://github.com/Ted151951/claude-lane/issues)
2. 运行 `claude-lane status` 获取诊断信息
3. 创建新 Issue 并提供错误信息