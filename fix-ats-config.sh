#!/bin/bash

# FractureGo ATS配置修复脚本
# 用于在编译后自动添加NSAppTransportSecurity配置

echo "🔧 FractureGo ATS配置修复脚本"

# 函数：为指定的Info.plist添加ATS配置
add_ats_config() {
    local plist_file="$1"
    local platform="$2"
    
    echo "📍 处理$platform版本: $plist_file"
    
    # 检查是否已有ATS配置
    if plutil -p "$plist_file" | grep -q "NSAppTransportSecurity"; then
        echo "✅ $platform版本ATS配置已存在"
    else
        echo "🔄 为$platform版本添加ATS配置..."
        # 添加NSAppTransportSecurity配置
        plutil -insert NSAppTransportSecurity -xml '<dict><key>NSAllowsArbitraryLoads</key><true/></dict>' "$plist_file"
        
        if [ $? -eq 0 ]; then
            echo "✅ $platform版本ATS配置添加成功"
        else
            echo "❌ $platform版本ATS配置添加失败"
            return 1
        fi
    fi
    
    # 验证配置
    echo "🔍 验证$platform版本ATS配置:"
    plutil -p "$plist_file" | grep -A 3 -B 1 "NSAppTransportSecurity"
    echo ""
}

# 查找模拟器版本的Info.plist文件
SIMULATOR_PLIST=$(find ~/Library/Developer/Xcode/DerivedData/FractureGo-*/Build/Products/Debug-iphonesimulator/FractureGo.app/Info.plist 2>/dev/null | head -1)

# 查找真机版本的Info.plist文件
DEVICE_PLIST=$(find ~/Library/Developer/Xcode/DerivedData/FractureGo-*/Build/Products/Debug-iphoneos/FractureGo.app/Info.plist 2>/dev/null | head -1)

# 检查是否找到任何版本
if [ -z "$SIMULATOR_PLIST" ] && [ -z "$DEVICE_PLIST" ]; then
    echo "❌ 未找到任何编译输出的Info.plist文件"
    echo "请先编译项目："
    echo "  模拟器版本：xcodebuild -workspace FractureGo.xcworkspace -scheme FractureGo -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build"
    echo "  真机版本：xcodebuild -workspace FractureGo.xcworkspace -scheme FractureGo -destination 'generic/platform=iOS' build"
    exit 1
fi

# 处理模拟器版本
if [ -n "$SIMULATOR_PLIST" ]; then
    add_ats_config "$SIMULATOR_PLIST" "模拟器"
fi

# 处理真机版本
if [ -n "$DEVICE_PLIST" ]; then
    add_ats_config "$DEVICE_PLIST" "真机"
fi

echo "🚀 配置完成！"
echo ""
echo "📱 对于模拟器，运行以下命令启动应用："
if [ -n "$SIMULATOR_PLIST" ]; then
    echo "   xcrun simctl terminate booted net.appcontest.FractureGo"
    echo "   xcrun simctl launch booted net.appcontest.FractureGo"
fi

echo ""
echo "📱 对于真机，请重新安装应用到设备："
if [ -n "$DEVICE_PLIST" ]; then
    echo "   1. 在Xcode中选择你的设备"
    echo "   2. 按 Cmd+R 重新运行应用"
    echo "   3. 或者删除设备上的应用，然后重新安装"
fi

echo ""
echo "🔧 如果问题仍然存在，请尝试："
echo "   1. 清理构建缓存：rm -rf ~/Library/Developer/Xcode/DerivedData/FractureGo*"
echo "   2. 重新编译项目"
echo "   3. 再次运行此脚本" 