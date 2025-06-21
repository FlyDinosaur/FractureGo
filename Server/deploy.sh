#!/bin/bash

# FractureGo服务端自动部署脚本
# 适用于Linux服务器

set -e

echo "🚀 开始部署FractureGo服务端..."

# 配置变量
SERVER_DIR="/home/ubuntu/fracturego-server"
SERVICE_NAME="fracturego-server"
PORT=28974
DB_NAME="fracturego_db"
DB_USER="fracturego_user"

# 颜色输出函数
print_success() {
    echo -e "\033[32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[31m❌ $1\033[0m"
}

print_info() {
    echo -e "\033[34m📋 $1\033[0m"
}

print_warning() {
    echo -e "\033[33m⚠️ $1\033[0m"
}

# 检查用户权限并设置相应配置
check_user_and_setup() {
    if [[ $EUID -eq 0 ]]; then
        print_info "检测到root用户，配置相应权限..."
        
        # 为root用户设置项目目录
        SERVER_DIR="/opt/fracturego-server"
        
        # 创建专用用户（如果不存在）
        if ! id "fracturego" &>/dev/null; then
            print_info "创建专用用户 fracturego..."
            useradd -r -s /bin/bash -d /opt/fracturego-server fracturego
        fi
        
        print_info "root用户部署模式："
        print_info "- 项目目录: $SERVER_DIR"
        print_info "- 服务用户: fracturego"
        print_info "- 将以适当权限运行服务"
        
    else
        print_info "检测到普通用户: $(whoami)"
        SERVER_DIR="/home/$(whoami)/fracturego-server"
        print_info "普通用户部署模式："
        print_info "- 项目目录: $SERVER_DIR"
        print_info "- 当前用户: $(whoami)"
    fi
}

# 安装系统依赖
install_dependencies() {
    print_info "安装系统依赖..."
    
    # 更新包列表
    if [[ $EUID -eq 0 ]]; then
        apt update
    else
        sudo apt update
    fi
    
    # 安装Node.js (如果未安装)
    if ! command -v node &> /dev/null; then
        print_info "安装Node.js..."
        if [[ $EUID -eq 0 ]]; then
            curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
            apt-get install -y nodejs
        else
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    fi
    
    # 安装PM2 (如果未安装)
    if ! command -v pm2 &> /dev/null; then
        print_info "安装PM2..."
        if [[ $EUID -eq 0 ]]; then
            npm install -g pm2
            # root用户：为fracturego用户设置PM2
            su - fracturego -c "pm2 startup" 2>/dev/null || true
        else
            sudo npm install -g pm2
            pm2 startup
        fi
    fi
    
    # 安装MySQL (如果未安装)
    if ! command -v mysql &> /dev/null; then
        print_info "安装MySQL..."
        if [[ $EUID -eq 0 ]]; then
            apt install -y mysql-server
            systemctl start mysql
            systemctl enable mysql
            print_info "配置MySQL..."
            mysql_secure_installation
        else
            sudo apt install -y mysql-server
            sudo systemctl start mysql
            sudo systemctl enable mysql
            print_info "配置MySQL..."
            sudo mysql_secure_installation
        fi
    fi
    
    print_success "系统依赖安装完成"
}

# 配置数据库
setup_database() {
    print_info "配置数据库..."
    
    # 检查数据库配置脚本是否存在
    if [ -f "scripts/setup-database.sh" ]; then
        print_info "使用独立的数据库配置脚本..."
        chmod +x scripts/setup-database.sh
        
        # 运行数据库配置脚本
        if bash scripts/setup-database.sh "$DB_NAME" "$DB_USER"; then
            print_success "数据库配置完成"
        else
            print_error "数据库配置失败"
            exit 1
        fi
    else
        print_info "使用内置数据库配置..."
        
        # 生成数据库密码
        DB_PASSWORD=$(openssl rand -base64 32)
        
        print_info "创建数据库和用户..."
        print_info "数据库名: $DB_NAME"
        print_info "用户名: $DB_USER"
        
        # 创建临时SQL文件
        cat > /tmp/setup_db.sql << 'EOF'
CREATE DATABASE IF NOT EXISTS `fracturego_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'fracturego_user'@'localhost' IDENTIFIED BY 'TEMP_PASSWORD';
GRANT ALL PRIVILEGES ON `fracturego_db`.* TO 'fracturego_user'@'localhost';
FLUSH PRIVILEGES;
EOF
        
        # 替换密码
        sed -i "s/TEMP_PASSWORD/$DB_PASSWORD/g" /tmp/setup_db.sql
        
        # 执行SQL文件
        if mysql -u root -p < /tmp/setup_db.sql; then
            print_success "数据库配置完成"
            
            # 保存配置信息
            echo "DB_NAME=$DB_NAME" > /tmp/fracturego_db_config
            echo "DB_USER=$DB_USER" >> /tmp/fracturego_db_config
            echo "DB_PASSWORD=$DB_PASSWORD" >> /tmp/fracturego_db_config
            
        else
            print_error "数据库配置失败"
            rm -f /tmp/setup_db.sql
            exit 1
        fi
        
        # 清理临时文件
        rm -f /tmp/setup_db.sql
    fi
}

# 创建项目目录
setup_project() {
    print_info "设置项目目录..."
    
    # 创建项目目录
    mkdir -p $SERVER_DIR
    mkdir -p $SERVER_DIR/logs
    mkdir -p $SERVER_DIR/uploads
    
    # 根据用户类型设置权限
    if [[ $EUID -eq 0 ]]; then
        # root用户：设置目录所有者为fracturego用户
        chown -R fracturego:fracturego $SERVER_DIR
        chmod 755 $SERVER_DIR
        chmod 755 $SERVER_DIR/logs
        chmod 755 $SERVER_DIR/uploads
        print_info "已设置目录所有者为 fracturego 用户"
    else
        # 普通用户：标准权限设置
        chmod 755 $SERVER_DIR
        chmod 755 $SERVER_DIR/logs
        chmod 755 $SERVER_DIR/uploads
    fi
    
    print_success "项目目录创建完成"
}

# 部署应用
deploy_app() {
    print_info "部署应用..."
    
    cd $SERVER_DIR
    
    # 检查是否需要获取代码
    if [ ! -d ".git" ]; then
        print_info "首次部署，获取代码..."
        
        # 检查目录是否为空
        if [ "$(ls -A .)" ]; then
            print_warning "目标目录不为空，清理现有内容..."
            rm -rf *
            rm -rf .[^.]*
            print_info "目录已清理"
        fi
        
        # 询问仓库URL
        read -p "请输入GitHub仓库URL (格式: https://github.com/username/repo.git): " repo_url
        
        if [ -z "$repo_url" ]; then
            print_error "仓库URL不能为空"
            exit 1
        fi
        
        # 检查是否为私有仓库
        if [[ "$repo_url" == *"github.com"* ]]; then
            print_warning "如果是私有仓库，请确保已配置访问权限"
            echo "配置方法："
            echo "1. SSH密钥: bash scripts/setup-github-ssh.sh"
            echo "2. Personal Access Token: bash scripts/setup-github-token.sh"
            echo ""
            
            read -p "是否已配置GitHub访问权限? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "请先配置GitHub访问权限后再运行部署脚本"
                exit 1
            fi
        fi
        
        # 克隆仓库
        print_info "正在克隆仓库..."
        if git clone "$repo_url" .; then
            print_success "代码克隆完成"
        else
            print_error "代码克隆失败，尝试其他方法..."
            
            # 尝试使用临时目录克隆，然后移动文件
            temp_dir="/tmp/fracturego_clone_$$"
            if git clone "$repo_url" "$temp_dir"; then
                print_info "使用临时目录克隆成功，正在移动文件..."
                mv "$temp_dir"/* .
                mv "$temp_dir"/.[^.]* . 2>/dev/null || true
                rm -rf "$temp_dir"
                print_success "代码获取完成"
            else
                print_error "代码克隆失败，请检查："
                echo "1. 仓库URL是否正确"
                echo "2. 网络连接是否正常"
                echo "3. 是否有仓库访问权限"
                echo "4. SSH密钥或Token是否配置正确"
                exit 1
            fi
        fi
    else
        print_info "更新代码..."
        git pull origin main
    fi
    
    # 安装依赖
    print_info "安装Node.js依赖..."
    npm install --production
    
    # 创建环境配置文件
    if [ ! -f ".env" ]; then
        print_info "创建环境配置文件..."
        cp env.example .env
        
        # 生成随机密钥
        JWT_SECRET=$(openssl rand -base64 64)
        API_KEY=$(openssl rand -hex 32)
        
        # 从临时文件读取数据库配置
        if [ -f "/tmp/fracturego_db_config" ]; then
            source /tmp/fracturego_db_config
            print_info "使用之前生成的数据库配置"
        else
            print_warning "未找到数据库配置信息，使用默认值"
            DB_PASSWORD=$(openssl rand -base64 32)
        fi
        
        # 更新配置文件
        sed -i "s/your_secure_password_here/$DB_PASSWORD/g" .env
        sed -i "s/your_jwt_secret_key_at_least_32_characters_long/$JWT_SECRET/g" .env
        sed -i "s/your_api_key_for_client_authentication/$API_KEY/g" .env
        
        # 更新数据库配置
        sed -i "s/fracturego_db/$DB_NAME/g" .env
        sed -i "s/fracturego_user/$DB_USER/g" .env
        
        print_success "环境配置文件创建完成"
        print_info "API密钥: $API_KEY"
        print_info "数据库: $DB_NAME"
        print_info "数据库用户: $DB_USER"
        print_info "请保存此API密钥，客户端需要使用"
        
        # 清理临时文件
        rm -f /tmp/fracturego_db_config
    fi
    
    # 运行数据库迁移
    print_info "运行数据库迁移..."
    npm run migrate
    
    print_success "应用部署完成"
}

# 配置防火墙
setup_firewall() {
    print_info "配置防火墙..."
    
    # 配置防火墙规则
    if [[ $EUID -eq 0 ]]; then
        ufw --force enable
        ufw allow ssh
        ufw allow 80
        ufw allow 443
        ufw allow $PORT
    else
        sudo ufw --force enable
        sudo ufw allow ssh
        sudo ufw allow 80
        sudo ufw allow 443
        sudo ufw allow $PORT
    fi
    
    print_success "防火墙配置完成"
}

# 启动服务
start_service() {
    print_info "启动服务..."
    
    cd $SERVER_DIR
    
    if [[ $EUID -eq 0 ]]; then
        # root用户：以fracturego用户身份运行PM2
        print_info "以 fracturego 用户身份启动服务..."
        
        # 确保文件权限正确
        chown -R fracturego:fracturego $SERVER_DIR
        
        # 停止现有进程
        su - fracturego -c "cd $SERVER_DIR && pm2 delete $SERVICE_NAME" 2>/dev/null || true
        
        # 启动新进程
        su - fracturego -c "cd $SERVER_DIR && pm2 start ecosystem.config.js --env production"
        
        # 保存PM2配置
        su - fracturego -c "pm2 save"
        
        print_info "为fracturego用户设置PM2开机自启..."
        su - fracturego -c "pm2 startup" 2>/dev/null || true
        
    else
        # 普通用户：直接运行PM2
        # 停止现有进程（如果存在）
        pm2 delete $SERVICE_NAME 2>/dev/null || true
        
        # 启动新进程
        pm2 start ecosystem.config.js --env production
        
        # 保存PM2配置
        pm2 save
        
        # 设置开机自启
        pm2 startup
    fi
    
    print_success "服务启动完成"
}

# 配置Nginx反向代理（可选）
setup_nginx() {
    read -p "是否配置Nginx反向代理? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "配置Nginx..."
        
        # 安装和配置Nginx
        if [[ $EUID -eq 0 ]]; then
            apt install -y nginx
            # 创建配置文件
            tee /etc/nginx/sites-available/fracturego << EOF
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
        
            # 启用站点
            ln -sf /etc/nginx/sites-available/fracturego /etc/nginx/sites-enabled/
            rm -f /etc/nginx/sites-enabled/default
            
            # 测试配置
            nginx -t
            
            # 重启Nginx
            systemctl restart nginx
            systemctl enable nginx
        else
            sudo apt install -y nginx
            # 创建配置文件
            sudo tee /etc/nginx/sites-available/fracturego << EOF
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
            
            # 启用站点
            sudo ln -sf /etc/nginx/sites-available/fracturego /etc/nginx/sites-enabled/
            sudo rm -f /etc/nginx/sites-enabled/default
            
            # 测试配置
            sudo nginx -t
            
            # 重启Nginx
            sudo systemctl restart nginx
            sudo systemctl enable nginx
        fi
        
        print_success "Nginx配置完成"
    fi
}

# 验证部署
verify_deployment() {
    print_info "验证部署..."
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if [[ $EUID -eq 0 ]]; then
        # root用户：检查fracturego用户的PM2进程
        if su - fracturego -c "pm2 describe $SERVICE_NAME" > /dev/null 2>&1; then
            print_success "服务运行正常"
        else
            print_error "服务启动失败"
            su - fracturego -c "pm2 logs $SERVICE_NAME"
            exit 1
        fi
    else
        # 普通用户：直接检查PM2进程
        if pm2 describe $SERVICE_NAME > /dev/null; then
            print_success "服务运行正常"
        else
            print_error "服务启动失败"
            pm2 logs $SERVICE_NAME
            exit 1
        fi
    fi
    
    # 测试API
    if curl -f http://localhost:$PORT/health > /dev/null 2>&1; then
        print_success "API健康检查通过"
    else
        print_error "API健康检查失败，这可能是正常的（API可能需要一些时间启动）"
        print_info "您可以稍后手动检查: curl http://localhost:$PORT/health"
    fi
    
    print_success "部署验证完成"
}

# 显示部署信息
show_deployment_info() {
    print_info "部署完成！"
    echo "=================================="
    echo "🌍 服务地址: http://localhost:$PORT"
    echo "📋 健康检查: http://localhost:$PORT/health"
    echo "📚 API文档: http://localhost:$PORT/api/docs"
    echo "📁 项目目录: $SERVER_DIR"
    echo "📝 日志目录: $SERVER_DIR/logs"
    echo "🔧 PM2管理: pm2 list, pm2 logs, pm2 restart $SERVICE_NAME"
    echo "=================================="
    
    # 显示API密钥（如果是首次部署）
    if [ -f "$SERVER_DIR/.env" ]; then
        API_KEY=$(grep "^API_KEY=" "$SERVER_DIR/.env" | cut -d '=' -f2)
        echo "🔑 API密钥: $API_KEY"
        echo "   客户端需要在请求头中添加: X-API-Key: $API_KEY"
    fi
}

# 主函数
main() {
    check_user_and_setup
    install_dependencies
    setup_database
    setup_project
    deploy_app
    setup_firewall
    start_service
    setup_nginx
    verify_deployment
    show_deployment_info
}

# 运行主函数
main "$@" 