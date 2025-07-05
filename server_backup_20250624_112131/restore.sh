#!/bin/bash

# FractureGo 服务器恢复脚本
# 用于一键恢复备份的服务器环境

SERVER_IP="117.72.161.6"
SERVER_USER="root"
SERVER_PASS="WYX11037414qq"
DB_HOST="117.72.161.6"
DB_USER="fracturego_user"
DB_PASS="WYX11037414qq"
DB_NAME="fracturego_db"

echo "开始恢复 FractureGo 服务器..."
echo "恢复时间: $(date)"
echo "目标服务器: ${SERVER_IP}"
echo "================================"

# 检查备份文件
if [ ! -f "fracturego_complete_backup.tar.gz" ]; then
    echo "错误: 找不到备份文件 fracturego_complete_backup.tar.gz"
    exit 1
fi

echo "1. 上传备份文件到服务器..."
sshpass -p "${SERVER_PASS}" scp -o StrictHostKeyChecking=no fracturego_complete_backup.tar.gz ${SERVER_USER}@${SERVER_IP}:/tmp/

echo "2. 在服务器上解压备份文件..."
sshpass -p "${SERVER_PASS}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << 'EOF'
cd /tmp
tar -xzf fracturego_complete_backup.tar.gz
echo "备份文件解压完成"
EOF

echo "3. 恢复项目代码..."
sshpass -p "${SERVER_PASS}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << 'EOF'
# 停止现有服务
if command -v pm2 &> /dev/null; then
    pm2 stop all
fi

# 备份现有代码（如果存在）
if [ -d "/root/FractureGo-Server" ]; then
    mv /root/FractureGo-Server /root/FractureGo-Server.backup.$(date +%Y%m%d_%H%M%S)
fi

# 恢复项目代码
if [ -d "/tmp/fracturego_backup/project_code/FractureGo-Server" ]; then
    cp -r /tmp/fracturego_backup/project_code/FractureGo-Server /root/
    echo "项目代码恢复完成"
else
    echo "警告: 备份中未找到项目代码"
fi

# 恢复 PM2 配置
if [ -d "/tmp/fracturego_backup/pm2_config" ]; then
    cp -r /tmp/fracturego_backup/pm2_config/.pm2 ~/
    echo "PM2 配置恢复完成"
fi

# 恢复 Nginx 配置
if [ -d "/tmp/fracturego_backup/nginx_config" ]; then
    cp -r /tmp/fracturego_backup/nginx_config/* /etc/nginx/
    nginx -t && systemctl reload nginx
    echo "Nginx 配置恢复完成"
fi
EOF

echo "4. 恢复数据库..."
sshpass -p "${SERVER_PASS}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << EOF
if [ -f "/tmp/fracturego_backup/database_backup.sql" ]; then
    echo "正在恢复数据库..."
    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < /tmp/fracturego_backup/database_backup.sql
    
    if [ \$? -eq 0 ]; then
        echo "数据库恢复成功"
    else
        echo "数据库恢复失败"
    fi
else
    echo "警告: 未找到数据库备份文件"
fi
EOF

echo "5. 重新启动服务..."
sshpass -p "${SERVER_PASS}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << 'EOF'
cd /root/FractureGo-Server

# 安装依赖
if [ -f "package.json" ]; then
    npm install
fi

# 启动服务
if command -v pm2 &> /dev/null && [ -f "ecosystem.config.js" ]; then
    pm2 start ecosystem.config.js
    pm2 save
    echo "PM2 服务启动完成"
else
    echo "警告: 未找到 PM2 或配置文件"
fi
EOF

echo "6. 清理临时文件..."
sshpass -p "${SERVER_PASS}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << 'EOF'
rm -rf /tmp/fracturego_backup
rm -f /tmp/fracturego_complete_backup.tar.gz
echo "临时文件清理完成"
EOF

echo "================================"
echo "FractureGo 服务器恢复完成!"
echo "恢复时间: $(date)"
echo "请检查服务是否正常运行"
