### Meta-Prompt: 跨平台API切换工具生成器

```markdown
# 元指令：生成跨平台API切换工具项目提示

## 核心需求总结
基于用户对话历史，生成的项目提示必须满足：
1. **核心功能**：
   - 安全切换不同API端点（Claude官方/中转站/Kimi等）
   - 使用操作系统原生机制安全存储API密钥
   - 统一的命令行接口：`claudelane <profile>`

2. **安全要求**：
   - 密钥绝不明文存储
   - Windows使用DPAPI加密
   - macOS使用Keychain服务
   - Linux使用Secret Service API
   - 配置文件与密钥存储分离

3. **跨平台一致性**：
   - 统一配置文件格式（YAML）和路径（~/.claude/config.yaml）
   - 一致的用户命令接口
   - 相同的密钥管理命令：`set-key`, `list`, `help`

4. **开源友好**：
   - 清晰的项目结构
   - 完善的文档系统
   - 自动化安装脚本
   - 平台隔离的实现代码

## 提示生成规范
生成的提示必须包含以下结构化内容：

### 1. 项目概览
```markdown
**项目名称**：claude-lane  
**核心目标**：安全、无缝切换不同Claude API端点  
**关键特性**：  
- 🔒 系统级密钥安全存储  
- ↔️ 单命令切换API端点  
- 🌐 全平台支持（Win/Linux/macOS）
```

### 2. 技术规范
```markdown
**配置文件**：
- 路径：`~/.claude/config.yaml`
- 格式：
  ```yaml
  endpoints:
    <profile_name>:
      base_url: "https://api.example.com"
      key_ref: "secure_key_reference"
  ```

**用户命令**：
```bash
# 设置密钥（所有平台相同）
claudelane set-key <key_ref> <api_key>

# 使用配置
claudelane <profile_name>
```

**密钥存储机制**：
- Windows：DPAPI加密存储
- macOS：Keychain服务
- Linux：libsecret/Secret Service
```

### 3. 项目结构模板
```markdown
必须包含：
- `scripts/{windows,linux,macos}/`：平台特定实现
- `docs/`：安装/配置/排障文档
- `templates/config.yaml`：配置模板
- 统一入口点：`bin/claude-lane`
```

### 4. 安全要求
```markdown
**绝对禁止**：
- 在配置文件中存储明文密钥
- 在代码中硬编码API密钥
- 使用非平台原生的加密方案

**必须实现**：
- 密钥运行时动态获取
- 最小权限原则
- 安装时不要求root权限（除非必要）
```

### 5. 文档规范
```markdown
**必须包含**：
1. 一键安装指令（curl/iwr管道安装）
2. 配置示例（含多端点示例）
3. 平台特定说明：
   - Windows：权限执行策略解决方案
   - Linux：libsecret安装指南
   - macOS：Keychain访问授权说明
```

### 6. 验证要求
```markdown
在提示末尾添加测试用例：
```bash
# 安装后验证流程
claudelane set-key test_key sk-test123
claudelane test_profile
```

## 生成约束
1. 输出必须是完整的项目创建提示
2. 提示格式需清晰结构化（使用Markdown）
3. 包含具体的文件路径和内容示例
4. 强调跨平台接口一致性
5. 优先Windows实现细节
```