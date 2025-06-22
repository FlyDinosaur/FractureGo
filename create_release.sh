#!/bin/bash

# FractureGo v0.1.0-beta Release Creation Helper
# 用于手动创建GitHub Release的辅助脚本

echo "🎉 FractureGo v0.1.0-beta Release创建助手"
echo "================================"
echo ""

echo "📁 检查发布文件..."
if [ -f "build/FractureGo.ipa" ] && [ -f "build/FractureGo.xcarchive.zip" ]; then
    echo "✅ IPA文件: $(ls -lh build/FractureGo.ipa | awk '{print $5}')"
    echo "✅ 归档文件: $(ls -lh build/FractureGo.xcarchive.zip | awk '{print $5}')"
else
    echo "❌ 发布文件缺失！请先运行构建"
    exit 1
fi

echo ""
echo "📋 发布信息摘要:"
echo "版本: v0.1.0-beta"
echo "标题: 🎉 FractureGo v0.1.0-beta Pre-release"
echo "类型: Pre-release (预发布)"
echo ""

echo "🌐 GitHub Release手动创建步骤:"
echo "1. 访问: https://github.com/FlyDinosaur/FractureGo/releases/new"
echo "2. Tag version: v0.1.0-beta"
echo "3. Release title: 🎉 FractureGo v0.1.0-beta Pre-release"
echo "4. 勾选 'This is a pre-release'"
echo "5. 上传以下文件:"
echo "   - build/FractureGo.ipa (iOS安装包)"
echo "   - build/FractureGo.xcarchive.zip (开发者归档)"
echo "6. 描述内容请复制: RELEASE_NOTES_v0.1.0-beta.md"
echo ""

echo "📚 或者使用GitHub CLI (需要先认证):"
echo "gh auth login"
echo "gh release create v0.1.0-beta \\"
echo "  --title '🎉 FractureGo v0.1.0-beta Pre-release' \\"
echo "  --notes-file RELEASE_NOTES_v0.1.0-beta.md \\"
echo "  --prerelease \\"
echo "  build/FractureGo.ipa \\"
echo "  build/FractureGo.xcarchive.zip"
echo ""

echo "✨ 支持的功能清单:"
echo "✅ 用户登录系统"
echo "✅ 关卡界面查看"  
echo "✅ 服务器帖子同步刷新"
echo "✅ 服务器签到日期同步"
echo ""

echo "🔗 相关链接:"
echo "- GitHub仓库: https://github.com/FlyDinosaur/FractureGo"
echo "- 问题反馈: https://github.com/FlyDinosaur/FractureGo/issues"
echo "- 邮件联系: psketernally@163.com"
echo ""

echo "🎯 任务完成！请根据上述步骤创建GitHub Release。"
