# MiniNote 极简笔记

MiniNote 是基于 OpenHarmony/ArkTS 打造的轻量级多端笔记应用，支持分类、标签、智能搜索与夜间模式，旨在为日常记录、灵感捕捉与待办管理提供简洁高效的体验。

## 功能亮点

- **笔记管理**：支持快速创建、编辑、长按删除（回收站软删除）与自动保存。
- **分类与标签**：可创建自定义分类、批量选择标签，便于按主题组织内容。
- **智能检索**：首页支持关键字、分类组合过滤，并展示最近更新时间。
- **主题切换**：内置明暗主题与自动模式，跨页面实时生效。
- **回收站/备份**：提供回收站页面以及独立的 Backup Ability，方便恢复与拓展备份策略。

## 项目结构

```
MiniNote2/
├── entry/                     # 应用主模块
│   ├── src/main/ets/          # ArkTS 业务代码
│   │   ├── pages/             # Index / NoteEdit / CategoryPage / TrashPage
│   │   ├── components/        # CategorySelector、TagSelector 等复用组件
│   │   ├── service/           # NoteDataManager、ThemeManager、CategoryManager
│   │   ├── hooks/             # useDebounce、useTheme
│   │   └── model/             # Note 等数据模型
│   ├── src/main/resources/    # UI 资源（多主题、多语言）
│   ├── src/mock/              # Mock 配置
│   ├── src/test/              # 单元测试
│   └── src/ohosTest/          # 集成测试
├── hvigor/、hvigorfile.ts     # Hvigor 构建配置
├── build.sh                   # 简化构建命令
├── AppScope/                  # 卡片/服务描述
└── certificates/              # 测试证书占位
```

## 开发环境要求

- DevEco Studio 4.1+（推荐）或 hvigorw CLI
- OpenHarmony SDK API 11 (5.0.5) 及以上
- Node.js 16+（供 hvigor/ohpm 依赖）
- 已配置好调试设备（真机或仿真器）与调试证书

## 快速开始

1. **克隆仓库**
   ```bash
   git clone git@longpenghn:longpenghn/MiniNote.git
   cd MiniNote
   ```
2. **导入 DevEco Studio**
   - 选择 `File > Open`，指向项目根目录。
   - 确认 SDK/签名/设备配置无误。
3. **运行调试**
   - 在 `entry` 模块上点击 `Run` 即可推送到已连接设备。

## 命令行构建

项目内置 `build.sh` 快捷脚本（依赖 hvigorw）：

```bash
./build.sh debug     # 生成调试版 HAP，输出在 build/outputs/default
./build.sh release   # 生成发布版 HAP（需正确签名）
./build.sh clean     # 清理构建产物
```

也可直接调用 hvigor 命令：

```bash
hvigorw assembleHap           # 默认 Debug
hvigorw assembleHap --mode release
hvigorw clean
```

## 测试

- `entry/src/test`：本地单元测试，可在 DevEco Studio 的 Test Runner 中运行。
- `entry/src/ohosTest`：UI/集成测试，用于设备端验证主题、列表等功能。

## 规划与路线图

- 引入云同步/多设备共享能力。
- 增加富文本与多媒体附件支持。
- 提供更完善的备份/恢复与数据加密方案。

欢迎提交 Issue 或 PR 共同完善 MiniNote，如需定制化方案请直接联系维护者。

