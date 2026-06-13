# Script

存放常用的 shell 和 batch 脚本。

## 目录结构

```
script/
├── linux/          # Linux/macOS shell 脚本 (.sh)
│   ├── system/     # 系统运维：部署、备份、监控
│   ├── dev/        # 开发工具：构建、测试、Git 辅助
│   └── network/    # 网络工具
├── windows/        # Windows 批处理脚本 (.bat / .cmd)
│   ├── system/
│   ├── dev/
│   └── network/
└── common/         # 跨平台说明、配置或资源
```

## 使用约定

- Linux 脚本添加可执行权限：`chmod +x script.sh`
- 每个脚本头部建议注明：用途、用法、参数、作者、日期
- 涉及敏感信息（密码、token）请使用环境变量，禁止硬编码

## 脚本模板

### Shell

```bash
#!/usr/bin/env bash
# Description: 脚本用途
# Usage: ./script.sh [args]
set -euo pipefail
```

### Batch

```bat
@echo off
setlocal enabledelayedexpansion
rem Description: 脚本用途
rem Usage: script.bat [args]
```
