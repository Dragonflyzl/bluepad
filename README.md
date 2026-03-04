# BluePad

[![Flutter](https://img.shields.io/badge/Flutter-v3.11+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20macOS-blue)](https://github.com/Dragonflyzl/bluepad)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**BluePad** 是一款基于 Flutter 构建的高性能蓝牙 HID 控制器。它可以将你的移动设备转变为电脑（Windows/macOS/Linux）的无线触控板、键盘、空中飞鼠和剪贴板同步器。

该项目是从原生 Kotlin (Android) 项目重写而来，保留并优化了核心 C++ 传感器算法，旨在提供极致的操控体验。

## 🚀 核心功能

-   **智能触控板**
    -   支持单指移动、点击、拖拽。
    -   双指滚动（支持自然滚动/非自然滚动切换）。
    -   双指缩放。
    -   三指手势（轻点唤起搜索、轻扫切换桌面/任务）。
    -   高精度惯性滚动算法。
-   **全功能键盘**
    -   包含 QWERTY、数字、符号、Fn、导航键等多种布局。
    -   **粘性修饰键**：支持锁定 Ctrl、Alt、Shift、Win/Cmd 进行组合键操作。
    -   **智能模式切换**：根据连接设备（Mac/Windows）自动转换修饰键符号与逻辑。
-   **空中飞鼠 (Air Mouse)**
    -   **姿态感应**：基于加速度计动态加权的陀螺仪角速度算法（完美移植自原生 C++ 核心）。
    -   支持竖握、平放等多种姿态下的方向自动校正。
    -   包含低速吸附死区与指数加速逻辑，兼顾微调精准度与大范围移动速度。
-   **全局剪贴板同步**
    -   自动检测手机剪贴板并同步至电脑。
    -   本地历史记录管理，支持快速搜索、复制与重新发送。
    -   敏感内容过滤提示。
-   **个性化设置**
    -   **UI 设计**：现代化的生产力级界面，支持深色/浅色模式切换。
    -   **多语言**：完整支持中英文实时切换。
    -   **性能微调**：可自定义触摸灵敏度、滚动速度、震动反馈等。

## 🛠 技术架构

-   **前端框架**: [Flutter](https://flutter.dev) (Dart)
-   **状态管理**: [Riverpod](https://riverpod.dev)
-   **本地存储**: [Shared Preferences](https://pub.dev/packages/shared_preferences) & [sqflite](https://pub.dev/packages/sqflite)
-   **蓝牙通信**: [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus) & 自定义 MethodChannel (HID Profile)
-   **核心算法**: 传感器数据处理算法由原生 C++ 移植，确保在不同采样率下的平滑表现。

## 📦 快速开始

1.  **克隆仓库**
    ```bash
    git clone https://github.com/Dragonflyzl/bluepad.git
    cd bluepad
    ```
2.  **安装依赖**
    ```bash
    flutter pub get
    ```
3.  **运行项目**
    ```bash
    # 确保已连接 Android 设备并开启了蓝牙权限
    flutter run
    ```

## ⚠️ 注意事项

-   **HID 协议支持**：该应用利用了 Android 系统的 Bluetooth HID Device Profile。请确保你的 Android 系统版本在 9.0 (API 28) 或以上。
-   **配对**：在使用应用连接之前，请先在手机系统的蓝牙设置中与目标电脑完成配对。

---

Developed with ❤️ by Dragonflyzl.
