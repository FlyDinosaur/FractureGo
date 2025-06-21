#!/bin/bash

# FractureGo数据库配置脚本
# 单独处理数据库创建，避免HERE文档语法问题

set -e

# 参数
DB_NAME=${1:-"fracturego_db"}
DB_USER=${2:-"fracturego_user"}
DB_PASSWORD=${3:-$(openssl rand -base64 32)}

echo "🗄️ 配置FractureGo数据库..."
echo "数据库名: $DB_NAME"
echo "用户名: $DB_USER"
echo "密码长度: ${#DB_PASSWORD} 字符"

# 创建SQL文件
cat > /tmp/setup_fracturego_db.sql << EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "📝 执行数据库配置..."

# 执行SQL文件
if mysql -u root -p < /tmp/setup_fracturego_db.sql; then
    echo "✅ 数据库配置成功!"
    
    # 保存配置信息
    echo "DB_NAME=$DB_NAME" > /tmp/fracturego_db_config
    echo "DB_USER=$DB_USER" >> /tmp/fracturego_db_config
    echo "DB_PASSWORD=$DB_PASSWORD" >> /tmp/fracturego_db_config
    
    echo "📋 配置信息已保存到 /tmp/fracturego_db_config"
else
    echo "❌ 数据库配置失败!"
    exit 1
fi

# 清理临时SQL文件
rm -f /tmp/setup_fracturego_db.sql

echo "🎉 数据库配置完成!" 