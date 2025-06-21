# SwiftSVG 集成指南

## 概述

本项目现在支持使用真实的 `curve.svg` 文件来渲染关卡路径，而不是手动转换的坐标。这提供了更精确和真实的路径显示。

## 安装步骤

### 1. 安装 CocoaPods 依赖

```bash
cd /path/to/FractureGo
pod install
```

### 2. 打开 .xcworkspace 文件

确保使用 `FractureGo.xcworkspace` 而不是 `.xcodeproj` 文件打开项目。

### 3. 启用 SwiftSVG 导入

在 `LevelComponents.swift` 中取消注释以下行：

```swift
import SwiftSVG
```

## 新增功能

### SVGCurvePath 组件

- **真实SVG解析**: 直接从 `curve.svg` 文件解析路径数据
- **自动缩放**: 根据视图大小自动调整路径比例
- **回退机制**: 如果SVG解析失败，自动回退到手动路径

### 使用方式

```swift
// 在关卡视图中使用
SVGCurvePath(color: armColor)
```

### 支持的SVG特性

- ✅ ViewBox 自动检测和缩放
- ✅ 基本路径命令 (M, C, Z)
- ✅ 坐标解析和转换
- ✅ 颜色主题支持

## 技术细节

### SVG 路径解析

1. **ViewBox 提取**: 自动读取SVG的 `viewBox` 属性
2. **路径数据解析**: 使用正则表达式提取 `path` 元素的 `d` 属性
3. **命令处理**: 支持 Move To (M), Curve To (C), Close Path (Z) 命令
4. **坐标转换**: 将SVG坐标系转换为iOS坐标系

### 性能优化

- **缓存机制**: SVG解析结果会被缓存
- **回退策略**: 解析失败时使用预定义路径
- **异步加载**: 避免阻塞主线程

## 文件结构

```
FractureGo/
├── curve.svg                 # 原始SVG文件
├── Views/
│   ├── LevelComponents.swift # SVG组件定义
│   ├── ArmLevelView.swift   # 手臂关卡视图
│   ├── HandLevelView.swift  # 手部关卡视图
│   └── LegLevelView.swift   # 腿部关卡视图
└── Podfile                  # CocoaPods 依赖
```

## 故障排除

### 常见问题

1. **SVG 未显示**
   - 检查 `curve.svg` 文件是否在 Bundle 中
   - 确认文件路径和扩展名正确

2. **路径不准确**
   - 验证 SVG 的 `viewBox` 属性
   - 检查路径数据是否使用了支持的命令

3. **编译错误**
   - 确保运行了 `pod install`
   - 检查 SwiftSVG 导入语句

### 调试技巧

```swift
// 在 SVGCurvePath 中添加调试输出
private func loadSVGPath(for size: CGSize) -> CGPath? {
    print("Loading SVG for size: \(size)")
    // ... 其余代码
}
```

## 优势对比

### 使用 SwiftSVG 的优势

✅ **精确度**: 直接使用设计师提供的SVG文件  
✅ **可维护性**: 设计更改时只需替换SVG文件  
✅ **一致性**: 确保与设计稿完全一致  
✅ **灵活性**: 支持复杂的SVG路径和形状  

### 与手动路径的对比

| 特性 | 手动路径 | SwiftSVG |
|------|----------|----------|
| 精确度 | ⚠️ 近似 | ✅ 完全精确 |
| 维护性 | ❌ 需要手动转换 | ✅ 自动解析 |
| 设计一致性 | ⚠️ 可能有差异 | ✅ 完全一致 |
| 开发效率 | ❌ 耗时 | ✅ 快速 |

## 下一步

1. **完整SVG支持**: 添加更多SVG命令支持 (L, H, V, S, Q, T, A)
2. **动画支持**: 支持SVG路径动画
3. **颜色解析**: 支持SVG中的颜色和样式定义
4. **缓存优化**: 实现更智能的缓存机制

## 参考资源

- [SwiftSVG GitHub](https://github.com/mchoe/SwiftSVG)
- [SVG Path 规范](https://www.w3.org/TR/SVG/paths.html)
- [CocoaPods 官方文档](https://cocoapods.org/) 