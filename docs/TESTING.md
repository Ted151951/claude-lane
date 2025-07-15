# 测试指南

本文档提供 claude-lane 的基础测试和验证方法，帮助用户和开发者验证功能正常性。

## 🎯 快速验证

### 安装后验证

安装完成后，运行以下命令验证基本功能：

```bash
# 检查安装
claude-lane --version
claude-lane help

# 检查当前状态  
claude-lane status
```

**预期结果**:
- 显示版本信息
- 显示完整的帮助信息
- 显示配置状态（即使是空配置也应正常显示）

## ⚙️ 功能测试

### 1. 配置管理测试

```bash
# 测试密钥存储
claude-lane set-key test-profile sk-test-12345

# 验证存储成功
claude-lane status
claude-lane list
```

**预期结果**:
- 密钥安全存储在系统密钥库中
- status 命令显示配置状态
- list 命令显示已存储的密钥

### 2. 环境变量测试

```bash
# 设置环境变量（需要有效配置）
claude-lane --env-only your-profile

# 检查环境变量
echo $ANTHROPIC_API_KEY    # Linux/macOS
echo $env:ANTHROPIC_API_KEY # Windows PowerShell
```

**预期结果**:
- 环境变量正确设置
- 可以检索到API密钥（显示为 *** 保护隐私）

### 3. 错误处理测试

```bash
# 测试无效命令
claude-lane invalid-command

# 测试缺少参数
claude-lane set-key

# 测试无效配置
claude-lane nonexistent-profile
```

**预期结果**:
- 显示清晰的错误信息
- 提供有用的使用建议
- 不应崩溃或产生异常

## 🔧 平台特定测试

### Windows PowerShell

```powershell
# 测试PowerShell集成
Get-Command claude-lane
claude-lane status

# 测试DPAPI密钥存储
claude-lane set-key win-test sk-test-key
```

### Linux

```bash
# 测试Secret Service集成
claude-lane set-key linux-test sk-test-key

# 验证PATH设置
which claude-lane
```

### macOS

```bash
# 测试Keychain集成
claude-lane set-key macos-test sk-test-key

# 验证权限
ls -la ~/.local/bin/claude-lane
```

## 🚨 常见问题排查

### 问题1: 命令找不到

**症状**: `claude-lane: command not found`

**解决方案**:
```bash
# 刷新PATH环境变量
export PATH="$HOME/.local/bin:$PATH"

# 或重启终端
```

### 问题2: PowerShell执行策略错误

**症状**: `执行策略更改`

**解决方案**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 问题3: 密钥存储失败

**症状**: `Failed to store API key`

**解决方案**:
- **Windows**: 确保DPAPI服务正常
- **Linux**: 安装并启动密钥环服务
- **macOS**: 检查Keychain Access权限

## 📊 性能基准

### 响应时间预期

- `claude-lane --version`: < 1秒
- `claude-lane status`: < 2秒  
- `claude-lane set-key`: < 3秒
- 环境变量设置: < 1秒

### 资源使用

- 内存占用: < 50MB
- 磁盘空间: < 5MB（安装后）
- 网络使用: 仅安装时需要

## 🔍 高级诊断

### 详细日志

如需调试，可以启用详细输出：

```bash
# Windows
$VerbosePreference = "Continue"
claude-lane status

# Linux/macOS  
set -x
claude-lane status
set +x
```

### 配置文件检查

验证配置文件格式：

```bash
# 检查配置文件位置
ls -la ~/.claude/config.yaml

# 验证YAML语法（如果安装了yq）
yq eval ~/.claude/config.yaml
```

## 📝 问题报告

如果测试中发现问题，请在 [GitHub Issues](https://github.com/Ted151951/claude-lane/issues) 中报告，包含：

1. **系统信息**
   - 操作系统和版本
   - Shell类型和版本
   - claude-lane版本

2. **重现步骤**
   - 具体执行的命令
   - 预期结果 vs 实际结果

3. **错误信息**
   - 完整的错误输出
   - 相关日志信息

4. **环境上下文**
   - 是否为全新安装
   - 是否有其他API工具
   - 网络环境信息

---

通过这些测试步骤，你可以验证 claude-lane 在你的环境中是否正常工作。如有任何问题，欢迎提交issue！🛠️