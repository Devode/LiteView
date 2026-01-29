

# 轻阅屏 (LiteView)

轻量级 PDF 阅读器，专为多平台优化的现代文档查看体验。

## 📱 支持平台

- **Windows** - 完整支持 ✓
- **Android** - 完整支持 ✓

## ✨ 主要功能

### 📚 PDF 文件管理
- **PDF 列表界面** (`pdf_list_screen.dart`) - 浏览和管理已导入的 PDF 文档
- **PDF 文件扫描** (`pdf_file_scanner.dart`) - 扫描设备存储中的 PDF 文档
- **PDF 导入功能** (`import_pdf.dart`) - 导入外部 PDF 文件

### 📖 PDF 阅读体验
- **PDF 查看页面** (`pdf_view_page.dart`) - 核心阅读界面
- **绘制标注** (`pdf_aware_drawing_painter.dart`, `current_path_painter.dart`) - 支持手绘标注和批注
- **路径绘制** - 记录和显示用户绘制的标注路径

### 💾 数据持久化
- **JSON 文件处理** (`json_file_handler.dart`) - 保存导入的 PDF 文档列表
- **数据类型定义** (`data_types.dart`) - 统一的数据结构

## 🏗️ 项目架构

```
lib/
├── main.dart                    # 应用入口
├── icons/
│   └── my_icons.dart            # 自定义图标
├── screens/
│   ├── pdf_list_screen.dart     # PDF 文件列表
│   └── pdf_view_page.dart       # PDF 阅读界面
├── utils/
│   ├── import_pdf.dart          # PDF 导入工具
│   ├── json_file_handler.dart   # JSON 数据处理
│   ├── pdf_aware_drawing_painter.dart  # 标注绘制
│   └── pdf_file_scanner.dart    # PDF 文件扫描
└── widgets/
    └── current_path_painter.dart # 路径绘制组件
```

## 🚀 快速开始

### 环境要求

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio / VS Code
- 各平台对应的开发环境

### 安装依赖

```bash
flutter pub get
```

### 运行项目

```bash
# 运行到 Windows
flutter run -d windows

# 运行到 Android
flutter run -d android
```

### 构建发布

```bash
# Windows
flutter build windows

# Android
flutter build apk --release
```

## 📦 依赖配置

主要依赖项 (查看 `pubspec.yaml` 完整列表):

- **Flutter SDK** - 跨平台 UI 框架
- **file_selector** - 文件选择
- **path_provider** - 路径获取
- **shared_preferences** - 轻量数据存储

## 🎨 界面特性

- **现代 UI 设计** - 采用 HarmonyOS Sans SC 字体
- **自定义图标** - 内置矢量图标集
- **启动动画** - 平台原生启动体验

## 🛠️ 开发说明

### 代码规范

遵循 `analysis_options.yaml` 中的 Flutter 代码规范。

### 平台配置

- **Android** - Kotlin 开发，位于 `android/` 目录
- **Windows/Linux** - C++ 原生渲染，位于 `windows/` 和 `linux/` 目录

## 📄 许可证

本项目采用 **MIT 许可证**，详见 LICENSE 文件。

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request 来改进项目。

## 📧 联系方式

- 项目地址: https://gitee.com/devode/lite_view
- 问题反馈: https://gitee.com/devode/lite_view/issues

---

*轻阅屏 - 让阅读更轻松*