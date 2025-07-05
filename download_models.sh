#!/bin/bash

# MediaPipe模型下载脚本
# 用于下载FractureGo应用所需的机器学习模型文件

echo "🚀 开始下载MediaPipe模型文件..."

# 创建模型目录（如果不存在）
mkdir -p MLModels/PoseDetection
mkdir -p MLModels/HandDetection

# 下载姿势检测模型
echo "📥 下载姿势检测模型..."
if [ ! -f "MLModels/PoseDetection/pose_landmarker.task" ]; then
    curl -L -o "MLModels/PoseDetection/pose_landmarker.task" \
        "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task"
    
    if [ $? -eq 0 ]; then
        echo "✅ 姿势检测模型下载成功"
    else
        echo "❌ 姿势检测模型下载失败"
        exit 1
    fi
else
    echo "ℹ️  姿势检测模型已存在，跳过下载"
fi

# 下载手部检测模型
echo "📥 下载手部检测模型..."
if [ ! -f "MLModels/HandDetection/hand_landmarker.task" ]; then
    curl -L -o "MLModels/HandDetection/hand_landmarker.task" \
        "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task"
    
    if [ $? -eq 0 ]; then
        echo "✅ 手部检测模型下载成功"
    else
        echo "❌ 手部检测模型下载失败"
        exit 1
    fi
else
    echo "ℹ️  手部检测模型已存在，跳过下载"
fi

echo "🎉 所有模型文件下载完成！"
echo ""
echo "📋 下一步操作："
echo "1. 在Xcode中将模型文件添加到项目"
echo "2. 确保模型文件的Target Membership包含FractureGo"
echo "3. 在Bundle Resources中确认模型文件被正确包含"
echo ""
echo "📁 模型文件位置："
echo "   - MLModels/PoseDetection/pose_landmarker.task"
echo "   - MLModels/HandDetection/hand_landmarker.task"

# 显示文件大小
echo ""
echo "📊 文件信息："
if [ -f "MLModels/PoseDetection/pose_landmarker.task" ]; then
    pose_size=$(ls -lh "MLModels/PoseDetection/pose_landmarker.task" | awk '{print $5}')
    echo "   姿势检测模型: $pose_size"
fi

if [ -f "MLModels/HandDetection/hand_landmarker.task" ]; then
    hand_size=$(ls -lh "MLModels/HandDetection/hand_landmarker.task" | awk '{print $5}')
    echo "   手部检测模型: $hand_size"
fi

echo ""
echo "⚠️  注意：模型文件较大，请确保网络连接稳定"