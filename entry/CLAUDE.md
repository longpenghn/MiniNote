[根目录](../../CLAUDE.md) > **entry**

# Entry 模块 - MiniNote2 笔记应用核心模块

## 变更记录 (Changelog)

**2025-11-08**: 初始化模块文档，完成功能分析和接口梳理。

## ✨ 相对路径面包屑

[根目录](../../CLAUDE.md) > **entry**

## 模块职责

Entry 模块是 MiniNote2 应用的核心实现模块，负责提供完整的笔记管理功能，包括：

- 笔记的创建、编辑、删除和查看
- 笔记内容的搜索和过滤
- 本地数据持久化存储
- 用户界面交互和体验优化
- 自动保存功能实现

## 入口与启动

### 应用入口
- **主入口**: `src/main/ets/entryability/EntryAbility.ets`
  - 应用生命周期管理
  - 窗口创建和页面加载
  - 颜色模式配置

### 页面入口
- **首页**: `src/main/ets/pages/Index.ets`
  - 笔记列表展示
  - 搜索功能
  - 笔记操作（创建、编辑、删除）

- **编辑页**: `src/main/ets/pages/NoteEdit.ets`
  - 笔记内容编辑
  - 自动保存机制
  - 删除功能

## 对外接口

### 页面路由接口
```typescript
// 首页 -> 编辑页（新建笔记）
router.pushUrl({
  url: 'pages/NoteEdit',
  params: { isNew: true }
});

// 首页 -> 编辑页（编辑笔记）
router.pushUrl({
  url: 'pages/NoteEdit',
  params: {
    isNew: false,
    noteId: note.id
  }
});
```

### 数据管理接口
- **NoteDataManager**: 笔记数据管理
  - `init(context)`: 初始化存储
  - `saveNote(note)`: 保存单个笔记
  - `getNoteById(id)`: 根据ID获取笔记
  - `deleteNote(id)`: 删除笔记
  - `searchNotes(keyword)`: 搜索笔记
  - `getNotesOrderByUpdateTime()`: 按更新时间排序

- **ThemeManager**: 主题管理（未实际使用）
  - `getCurrentTheme()`: 获取当前主题
  - `setTheme(theme)`: 设置主题
  - `toggleTheme()`: 切换主题

## 关键依赖与配置

### 系统依赖
- `@kit.AbilityKit`: 应用能力相关API
- `@kit.ArkUI`: UI组件和路由
- `@kit.ArkData`: 数据存储(Preferences)
- `@kit.PerformanceAnalysisKit`: 性能分析和日志

### 开发依赖
- `@ohos/hypium`: 单元测试框架
- `@ohos/hamock`: Mock框架

### 配置文件
- `module.json5`: 模块配置，包含页面路由和能力配置
- `build-profile.json5`: 构建配置
- `oh-package.json5`: 依赖管理
- `main_pages.json`: 页面路由配置

## 数据模型

### Note 实体
```typescript
interface NoteJson {
  id: string;         // 唯一标识符
  title: string;      // 笔记标题（从内容首行提取）
  content: string;    // 笔记内容
  createTime: number; // 创建时间戳
  updateTime: number; // 更新时间戳
}
```

### 存储结构
- **笔记存储**: 使用Preferences键值对存储
- **存储键名**: `notes_data`
- **数据格式**: JSON字符串数组

## 测试与质量

### 测试覆盖
- ✅ 基础测试框架搭建完成
- ✅ 单元测试配置就绪
- ✅ UI测试环境配置
- ⚠️ 缺乏业务逻辑具体测试
- ⚠️ 缺乏页面交互测试

### 质量工具
- **代码规范**: TypeScript严格模式
- **构建优化**: 启用严格模式检查
- **签名配置**: 支持debug和release环境

## 常见问题 (FAQ)

### Q: 笔记数据存储在哪里？
A: 使用HarmonyOS的Preferences API存储在应用私有空间中，数据安全性有保障。

### Q: 如何处理数据持久化？
A: NoteDataManager单例模式管理，所有笔记数据以JSON格式序列化后存储。

### Q: 自动保存如何工作？
A: NoteEdit页面使用防抖机制，输入停止1秒后自动保存到本地存储。

### Q: 主题切换功能如何启用？
A: ThemeManager服务已实现但未在UI中集成，需要在页面中添加主题切换控件。

## 相关文件清单

### 核心源码
- `src/main/ets/entryability/EntryAbility.ets` - 应用入口
- `src/main/ets/pages/Index.ets` - 笔记列表页
- `src/main/ets/pages/NoteEdit.ets` - 笔记编辑页
- `src/main/ets/model/Note.ets` - 笔记数据模型
- `src/main/ets/service/NoteDataManager.ets` - 数据管理服务
- `src/main/ets/service/ThemeManager.ets` - 主题管理服务

### 测试文件
- `src/test/LocalUnit.test.ets` - 本地单元测试
- `src/test/List.test.ets` - 列表测试
- `src/ohosTest/ets/test/Ability.test.ets` - 能力测试
- `src/ohosTest/ets/test/List.test.ets` - UI列表测试

### 配置文件
- `src/main/module.json5` - 模块配置
- `src/main/resources/base/profile/main_pages.json` - 页面路由配置
- `src/main/resources/base/backup_config.json` - 备份配置

### 资源文件
- `src/main/resources/base/element/` - 元素资源
- `src/main/resources/base/media/` - 媒体资源
- `src/main/resources/dark/` - 深色主题资源

## 性能特点

- **轻量级**: 单模块架构，应用体积小
- **响应式**: 声明式UI，流畅的用户体验
- **本地优先**: 数据本地存储，快速访问
- **自动保存**: 智能防抖，减少不必要的存储操作

## 扩展建议

1. **完善主题系统**: 集成ThemeManager到UI中
2. **添加分类功能**: 支持笔记标签和文件夹
3. **导入导出**: 支持数据备份和恢复
4. **富文本支持**: 增强编辑功能
5. **搜索优化**: 支持更复杂的搜索条件