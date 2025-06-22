#!/bin/bash

# 服务器备份脚本
# 备份远程服务器代码和数据库，并下载到本地

# 服务器配置
SERVER_IP="117.72.161.6"
SERVER_USER="root"
SERVER_PASS="WYX11037414qq"

# 数据库配置
DB_HOST="117.72.161.6"
DB_USER="fracturego_user"
DB_PASS="WYX11037414qq"
DB_NAME="fracturego_db"

# 本地备份目录
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
LOCAL_BACKUP_DIR="./server_backup_${BACKUP_DATE}"
BACKUP_FILE="fracturego_backup_${BACKUP_DATE}.tar.gz"

echo "开始备份 FractureGo 服务器..."
echo "备份时间: $(date)"
echo "服务器: ${SERVER_IP}"
echo "================================"

# 创建本地备份目录
mkdir -p "${LOCAL_BACKUP_DIR}"

echo "1. 连接服务器并创建远程备份目录..."
sshpass -p "${SERVER_PASS}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << 'EOF'
# 创建备份目录
mkdir -p /tmp/fracturego_backup
cd /tmp/fracturego_backup

echo "远程备份目录创建完成"
EOF

echo "2. 备份服务器代码..."
sshpass -p "${SERVER_PASS}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << 'EOF'
cd /tmp/fracturego_backup

# 查找并备份所有可能的项目代码位置
echo "正在查找项目代码..."

# 常见的项目部署位置
PROJECT_PATHS=(
    "/root/FractureGo-Server"
    "/home/*/FractureGo-Server" 
    "/var/www/FractureGo-Server"
    "/opt/FractureGo-Server"
    "/usr/local/FractureGo-Server"
)

# 查找实际的项目路径
FOUND_PATH=""
for path in "${PROJECT_PATHS[@]}"; do
    if [ -d "$path" ]; then
        FOUND_PATH="$path"
        echo "找到项目路径: $path"
        break
    fi
done

# 如果没找到预定义路径，搜索整个系统
if [ -z "$FOUND_PATH" ]; then
    echo "在预定义路径中未找到项目，正在搜索整个系统..."
    FOUND_PATH=$(find / -name "FractureGo-Server" -type d 2>/dev/null | head -1)
fi

if [ -n "$FOUND_PATH" ]; then
    echo "备份项目代码从: $FOUND_PATH"
    cp -r "$FOUND_PATH" ./project_code/
else
    echo "警告: 未找到 FractureGo-Server 项目目录"
    mkdir -p ./project_code
fi

# 备份 PM2 配置
if command -v pm2 &> /dev/null; then
    echo "备份 PM2 配置..."
    pm2 save
    cp -r ~/.pm2 ./pm2_config/ 2>/dev/null || echo "PM2 配置备份失败"
fi

# 备份 Nginx 配置（如果存在）
if [ -d "/etc/nginx" ]; then
    echo "备份 Nginx 配置..."
    cp -r /etc/nginx ./nginx_config/
fi

# 备份系统服务配置
echo "备份系统信息..."
ps aux > ./system_processes.txt
netstat -tulpn > ./network_ports.txt
crontab -l > ./crontab_backup.txt 2>/dev/null || echo "无 crontab 任务"

echo "服务器代码备份完成"
EOF

echo "3. 备份数据库..."
sshpass -p "${SERVER_PASS}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << EOF
cd /tmp/fracturego_backup

echo "正在备份数据库..."
mysqldump -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} ${DB_NAME} > database_backup.sql

if [ \$? -eq 0 ]; then
    echo "数据库备份成功"
    ls -lh database_backup.sql
else
    echo "数据库备份失败"
fi
EOF

echo "4. 创建远程压缩包..."
sshpass -p "${SERVER_PASS}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << 'EOF'
cd /tmp

echo "正在创建压缩包..."
tar -czf fracturego_complete_backup.tar.gz fracturego_backup/

if [ $? -eq 0 ]; then
    echo "压缩包创建成功"
    ls -lh fracturego_complete_backup.tar.gz
else
    echo "压缩包创建失败"
fi
EOF

echo "5. 下载备份文件到本地..."
sshpass -p "${SERVER_PASS}" scp -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP}:/tmp/fracturego_complete_backup.tar.gz "${LOCAL_BACKUP_DIR}/"

if [ $? -eq 0 ]; then
    echo "备份文件下载成功"
else
    echo "备份文件下载失败"
    exit 1
fi

echo "6. 清理远程临时文件..."
sshpass -p "${SERVER_PASS}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << 'EOF'
rm -rf /tmp/fracturego_backup
rm -f /tmp/fracturego_complete_backup.tar.gz
echo "远程临时文件清理完成"
EOF

echo "7. 创建本地恢复脚本..."
cat > "${LOCAL_BACKUP_DIR}/restore.sh" << 'RESTORE_SCRIPT'
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
RESTORE_SCRIPT

chmod +x "${LOCAL_BACKUP_DIR}/restore.sh"

echo "8. 创建最终压缩包..."
cd "$(dirname "${LOCAL_BACKUP_DIR}")"
tar -czf "${BACKUP_FILE}" "$(basename "${LOCAL_BACKUP_DIR}")"

echo "================================"
echo "备份完成!"
echo "备份时间: $(date)"
echo "本地备份目录: ${LOCAL_BACKUP_DIR}"
echo "压缩包文件: ${BACKUP_FILE}"
echo "压缩包大小: $(ls -lh "${BACKUP_FILE}" | awk '{print $5}')"
echo ""
echo "恢复方法:"
echo "1. 解压备份文件: tar -xzf ${BACKUP_FILE}"
echo "2. 进入备份目录: cd $(basename "${LOCAL_BACKUP_DIR}")"
echo "3. 运行恢复脚本: ./restore.sh"
echo "================================" 