#!/bin/bash

# FractureGo MediaPipe 模型下载脚本
# 此脚本用于下载姿势识别和手部识别模型文件

set -e

echo "🚀 开始下载 FractureGo MediaPipe 模型文件..."

# 创建模型目录（如果不存在）
echo "📁 检查模型文件夹..."
mkdir -p MLModels/PoseDetection
mkdir -p MLModels/HandDetection

# 检查网络连接
echo "🌐 检查网络连接..."
if ! ping -c 1 google.com &> /dev/null; then
    echo "❌ 网络连接失败，请检查网络设置"
    exit 1
fi

# 下载姿势识别模型
echo "📥 下载姿势识别模型 (pose_landmarker.task)..."
if [ ! -f "MLModels/PoseDetection/pose_landmarker.task" ]; then
    curl -L --progress-bar \
        "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task" \
        -o "MLModels/PoseDetection/pose_landmarker.task"
    
    if [ $? -eq 0 ]; then
        echo "✅ 姿势识别模型下载完成"
        # 检查文件大小
        size=$(stat -f%z "MLModels/PoseDetection/pose_landmarker.task" 2>/dev/null || stat -c%s "MLModels/PoseDetection/pose_landmarker.task" 2>/dev/null)
        echo "   文件大小: $(numfmt --to=iec $size)"
    else
        echo "❌ 姿势识别模型下载失败"
        exit 1
    fi
else
    echo "✅ 姿势识别模型已存在，跳过下载"
fi

# 下载手部识别模型
echo "📥 下载手部识别模型 (hand_landmarker.task)..."
if [ ! -f "MLModels/HandDetection/hand_landmarker.task" ]; then
    curl -L --progress-bar \
        "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task" \
        -o "MLModels/HandDetection/hand_landmarker.task"
    
    if [ $? -eq 0 ]; then
        echo "✅ 手部识别模型下载完成"
        # 检查文件大小
        size=$(stat -f%z "MLModels/HandDetection/hand_landmarker.task" 2>/dev/null || stat -c%s "MLModels/HandDetection/hand_landmarker.task" 2>/dev/null)
        echo "   文件大小: $(numfmt --to=iec $size)"
    else
        echo "❌ 手部识别模型下载失败"
        exit 1
    fi
else
    echo "✅ 手部识别模型已存在，跳过下载"
fi

# 验证模型文件
echo "🔍 验证模型文件完整性..."

# 检查姿势识别模型
pose_size=$(stat -f%z "MLModels/PoseDetection/pose_landmarker.task" 2>/dev/null || stat -c%s "MLModels/PoseDetection/pose_landmarker.task" 2>/dev/null)
if [ $pose_size -lt 10000000 ]; then  # 期望文件大小至少10MB
    echo "⚠️  姿势识别模型文件可能不完整"
else
    echo "✅ 姿势识别模型文件验证通过"
fi

# 检查手部识别模型
hand_size=$(stat -f%z "MLModels/HandDetection/hand_landmarker.task" 2>/dev/null || stat -c%s "MLModels/HandDetection/hand_landmarker.task" 2>/dev/null)
if [ $hand_size -lt 8000000 ]; then  # 期望文件大小至少8MB
    echo "⚠️  手部识别模型文件可能不完整"
else
    echo "✅ 手部识别模型文件验证通过"
fi

# 设置文件权限
echo "🔐 设置文件权限..."
chmod 644 MLModels/PoseDetection/pose_landmarker.task
chmod 644 MLModels/HandDetection/hand_landmarker.task

# 显示摘要信息
echo ""
echo "📊 下载完成摘要:"
echo "┌─────────────────────────────────────────────────────────┐"
echo "│ 模型文件                    │ 状态  │ 大小              │"
echo "├─────────────────────────────────────────────────────────┤"
printf "│ pose_landmarker.task        │ ✅    │ %-16s │\n" "$(numfmt --to=iec $pose_size)"
printf "│ hand_landmarker.task        │ ✅    │ %-16s │\n" "$(numfmt --to=iec $hand_size)"
echo "└─────────────────────────────────────────────────────────┘"
echo ""

echo "🎉 模型文件下载完成！"
echo ""
echo "📋 接下来的步骤:"
echo "1. 运行 'pod install' 安装 MediaPipe 依赖"
echo "2. 在 Xcode 中将模型文件添加到项目"
echo "3. 确保模型文件包含在 Bundle Resources 中"
echo ""
echo "📖 详细说明请参阅:"
echo "   - MLModels/README.md"
echo "   - MLModels/PoseDetection/README.md"
echo "   - MLModels/HandDetection/README.md" 