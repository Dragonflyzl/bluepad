# BluePad

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-v3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Android-9.0+-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Driverless-HID-orange?style=for-the-badge" alt="HID">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
</p>

**BluePad** 是一款基于 Flutter 构建的高性能蓝牙 HID (Human Interface Device) 控制套件。它通过 Android 原生蓝牙 HID 协议，将你的手机伪装成标准的蓝牙鼠标、键盘和多媒体控制器，实现对电脑（Windows/macOS/Linux）、平板甚至手机的控制。

> **核心价值**：无需在受控端安装任何接收软件，即连即用，就像插入了一个真实的无线接收器。

---

## ✨ 核心功能

### 🖱️ 智能触控板 (Touchpad)
- **精准映射**：支持单指平滑移动、轻点点击、双指右键及拖拽操作。
- **动态手势**：
  - 双指自然滚动/传统滚动，支持动态灵敏度调节。
  - 捏合缩放 (Pinch to Zoom)。

### ⌨️ 效率键盘 (Keyboard)
- **多布局支持**：标准 QWERTY、数字键盘、Fn 功能键区。
- **修饰键锁定**：支持 Ctrl/Alt/Shift/Win 组合键长按操作。

### 🪄 空中飞鼠 (Air Mouse)
- **传感器融合**：利用陀螺仪与加速度计，结合姿态融合算法，实现空间指向控制。

---

## 📦 快速开始

### 运行环境
- Android 9.0 (API 28) 及以上版本（HID Profile 硬件支持）。
- Flutter SDK v3.11.0+。

### 安装步骤
1. **克隆项目**
   ```bash
   git clone https://github.com/Dragonflyzl/bluepad.git
   ```
2. **安装依赖**
   ```bash
   flutter pub get
   ```
3. **原生配置**
   确保 `android/app/src/main/AndroidManifest.xml` 中已声明蓝牙及前台服务权限。
4. **编译运行**
   ```bash
   flutter run --release
   ```

---

## 📖 项目结构

```text
lib/
├── models/         # 领域模型与不可变数据类
├── providers/      # Riverpod 状态管理逻辑
├── screens/        # 视图层 (UI 页面)
├── services/       # 业务服务 (蓝牙/剪贴板/数据库)
├── theme/          # 全局主题配置
├── utils/          # HID 键码映射与算法工具
└── widgets/        # 可复用自定义组件
```

---

## ⚠️ 使用建议

1. **首次配对**：请先在手机系统的“蓝牙设置”中与目标电脑完成配对，随后在 App 内选择该设备连接。
2. **权限授予**：App 需要“附近设备”、“位置信息”及“前台服务”权限以确保连接稳定。

---

## 📄 开源协议
本项目采用 [MIT License](LICENSE) 开源。

---
<p align="center">Made with ❤️ by AI & Human</p>
