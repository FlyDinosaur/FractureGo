#!/bin/bash

# 设置ML模型文件脚本
# 确保MediaPipe模型文件能在iOS应用中正确加载

set -e

echo "🚀 设置FractureGo ML模型文件..."

# 检查是否在正确的目录
if [ ! -d "FractureGo" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 创建目标目录
TARGET_DIR="FractureGo/MLModels"
mkdir -p "$TARGET_DIR"

# 复制姿势检测模型
if [ -f "MLModels/PoseDetection/pose_landmarker.task" ]; then
    echo "📁 复制姿势检测模型..."
    cp "MLModels/PoseDetection/pose_landmarker.task" "$TARGET_DIR/"
    echo "✅ 姿势检测模型复制完成"
else
    echo "❌ 姿势检测模型文件不存在，请先运行 ./download_models.sh"
    exit 1
fi

# 复制手部检测模型  
if [ -f "MLModels/HandDetection/hand_landmarker.task" ]; then
    echo "📁 复制手部检测模型..."
    cp "MLModels/HandDetection/hand_landmarker.task" "$TARGET_DIR/"
    echo "✅ 手部检测模型复制完成"
else
    echo "❌ 手部检测模型文件不存在，请先运行 ./download_models.sh"
    exit 1
fi

# 显示文件信息
echo ""
echo "📊 模型文件信息:"
if [ -f "$TARGET_DIR/pose_landmarker.task" ]; then
    pose_size=$(ls -lh "$TARGET_DIR/pose_landmarker.task" | awk '{print $5}')
    echo "   姿势检测模型: $pose_size"
fi

if [ -f "$TARGET_DIR/hand_landmarker.task" ]; then
    hand_size=$(ls -lh "$TARGET_DIR/hand_landmarker.task" | awk '{print $5}')
    echo "   手部检测模型: $hand_size"
fi

echo ""
echo "🎉 模型文件复制完成！"
echo ""
echo "📋 手动操作步骤："
echo "1. 在Xcode中打开 FractureGo.xcodeproj"
echo "2. 右键点击 FractureGo 组，选择 'Add Files to FractureGo'"
echo "3. 导航到 FractureGo/MLModels/ 目录"
echo "4. 选择以下文件："
echo "   - pose_landmarker.task"
echo "   - hand_landmarker.task"
echo "5. 确保 'Add to target' 勾选了 FractureGo"
echo "6. 点击 'Add' 按钮"
echo ""
echo "💡 验证步骤："
echo "1. 在Xcode项目导航器中查看FractureGo组"
echo "2. 确认可以看到两个.task文件"
echo "3. 选中项目名称，进入Build Phases"
echo "4. 展开 'Copy Bundle Resources'"
echo "5. 确认两个模型文件都在列表中"
echo ""
echo "⚠️  重要提示："
echo "   - 模型文件必须添加到Bundle Resources中才能在运行时访问"
echo "   - 如果遇到找不到模型文件的错误，请检查上述步骤" 