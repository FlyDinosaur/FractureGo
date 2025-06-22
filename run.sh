#!/bin/bash

# FractureGo 一键恢复脚本
# 快速恢复服务器到备份状态

BACKUP_FILE="fracturego_backup_20250623_023547.tar.gz"
BACKUP_DIR="server_backup_20250623_023547"

echo "================================"
echo "FractureGo 服务器一键恢复工具"
echo "================================"
echo "备份时间: 2025年6月23日 02:35:47"
echo "服务器IP: 117.72.161.6"
echo "备份大小: 21MB"
echo ""

# 检查备份文件是否存在
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ 错误: 找不到备份文件 $BACKUP_FILE"
    echo "请确保备份文件在当前目录中"
    exit 1
fi

echo "✅ 发现备份文件: $BACKUP_FILE"

# 检查是否已解压
if [ ! -d "$BACKUP_DIR" ]; then
    echo "📦 正在解压备份文件..."
    tar -xzf "$BACKUP_FILE"
    if [ $? -eq 0 ]; then
        echo "✅ 备份文件解压成功"
    else
        echo "❌ 备份文件解压失败"
        exit 1
    fi
else
    echo "✅ 备份目录已存在: $BACKUP_DIR"
fi

# 进入备份目录
cd "$BACKUP_DIR"

if [ ! -f "restore.sh" ]; then
    echo "❌ 错误: 找不到恢复脚本 restore.sh"
    exit 1
fi

echo ""
echo "🚀 开始执行服务器恢复..."
echo "此过程可能需要几分钟时间，请耐心等待..."
echo ""

# 执行恢复脚本
chmod +x restore.sh
./restore.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 服务器恢复完成!"
    echo ""
    echo "📋 请进行以下验证:"
    echo "1. 检查服务状态: ssh root@117.72.161.6 'pm2 status'"
    echo "2. 测试API接口: curl http://117.72.161.6:3000/api/health"
    echo "3. 检查数据库: mysql -h 117.72.161.6 -u fracturego_user -pWYX11037414qq fracturego_db"
    echo ""
    echo "如有问题，请查看 README_备份恢复说明.md 文件"
else
    echo "❌ 服务器恢复过程中出现错误"
    echo "请查看上面的错误信息，或手动执行恢复步骤"
    exit 1
fi 