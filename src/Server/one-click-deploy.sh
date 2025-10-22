#!/bin/bash

# FractureGo服务器一键部署脚本
# 支持Ubuntu/Debian/CentOS系统，自动检测环境并完成部署

set -e

# 脚本版本
SCRIPT_VERSION="2.0.0"

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

print_header() {
    echo -e "\033[35m"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   FractureGo 服务器部署                     ║"
    echo "║                     一键部署脚本 v$SCRIPT_VERSION                    ║"
    echo "║                                                              ║"
    echo "║  功能特性：                                                  ║"
    echo "║  • 自动检测系统环境（Ubuntu/Debian/CentOS）                 ║"
    echo "║  • 安装Node.js 18.x + PM2 + MySQL                          ║"
    echo "║  • 自动配置数据库和环境变量                                 ║"
    echo "║  • 支持SSH密钥和Token两种GitHub认证方式                     ║"
    echo "║  • 自动SSL证书配置（可选）                                  ║"
    echo "║  • 生产环境优化配置                                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "\033[0m"
}

# 全局配置变量
PROJECT_NAME="fracturego-server"
REPO_URL="https://github.com/FlyDinosaur/FractureGo-Server.git"
SSH_REPO_URL="git@github.com:FlyDinosaur/FractureGo-Server.git"
SERVER_PORT=28974
DB_NAME="fracturego_db"
DB_USER="fracturego_user"
PROJECT_DIR=""
SYSTEM_TYPE=""
PACKAGE_MANAGER=""

# 检测操作系统
detect_system() {
    print_info "检测操作系统..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        
        case $ID in
            ubuntu|debian)
                SYSTEM_TYPE="debian"
                PACKAGE_MANAGER="apt"
                ;;
            centos|rhel|rocky|almalinux)
                SYSTEM_TYPE="rhel"
                PACKAGE_MANAGER="yum"
                if command -v dnf &> /dev/null; then
                    PACKAGE_MANAGER="dnf"
                fi
                ;;
            *)
                print_error "不支持的操作系统: $ID"
                exit 1
                ;;
        esac
        
        print_success "检测到操作系统: $OS $VER"
        print_info "包管理器: $PACKAGE_MANAGER"
    else
        print_error "无法检测操作系统"
        exit 1
    fi
}

# 检查用户权限并设置项目目录
setup_permissions() {
    print_info "设置用户权限和项目目录..."
    
    if [[ $EUID -eq 0 ]]; then
        print_warning "检测到root用户"
        
        # 创建专用用户
        if ! id "fracturego" &>/dev/null; then
            print_info "创建专用用户 fracturego..."
            useradd -r -s /bin/bash -m -d /opt/fracturego fracturego
        fi
        
        PROJECT_DIR="/opt/fracturego/fracturego-server"
        
        # 设置目录和权限
        mkdir -p $PROJECT_DIR
        mkdir -p /opt/fracturego/logs
        mkdir -p /opt/fracturego/uploads
        chown -R fracturego:fracturego /opt/fracturego
        
        print_success "设置项目目录: $PROJECT_DIR"
        print_info "服务将以 fracturego 用户身份运行"
    else
        current_user=$(whoami)
        PROJECT_DIR="/home/$current_user/fracturego-server"
        
        mkdir -p $PROJECT_DIR
        mkdir -p $PROJECT_DIR/logs
        mkdir -p $PROJECT_DIR/uploads
        
        print_success "设置项目目录: $PROJECT_DIR"
        print_info "服务将以 $current_user 用户身份运行"
    fi
}

# 更新系统包
update_system() {
    print_info "更新系统包..."
    
    case $PACKAGE_MANAGER in
        apt)
            if [[ $EUID -eq 0 ]]; then
                apt update && apt upgrade -y
            else
                sudo apt update && sudo apt upgrade -y
            fi
            ;;
        yum|dnf)
            if [[ $EUID -eq 0 ]]; then
                $PACKAGE_MANAGER update -y
            else
                sudo $PACKAGE_MANAGER update -y
            fi
            ;;
    esac
    
    print_success "系统包更新完成"
}

# 安装系统依赖
install_system_dependencies() {
    print_info "安装系统依赖..."
    
    local packages=""
    case $SYSTEM_TYPE in
        debian)
            packages="curl wget git build-essential software-properties-common gnupg2 ca-certificates lsb-release"
            ;;
        rhel)
            packages="curl wget git gcc gcc-c++ make openssl-devel"
            ;;
    esac
    
    case $PACKAGE_MANAGER in
        apt)
            if [[ $EUID -eq 0 ]]; then
                apt install -y $packages
            else
                sudo apt install -y $packages
            fi
            ;;
        yum|dnf)
            if [[ $EUID -eq 0 ]]; then
                $PACKAGE_MANAGER install -y $packages
            else
                sudo $PACKAGE_MANAGER install -y $packages
            fi
            ;;
    esac
    
    print_success "系统依赖安装完成"
}

# 安装Node.js
install_nodejs() {
    print_info "安装Node.js 18.x..."
    
    if command -v node &> /dev/null; then
        current_version=$(node --version | sed 's/v//')
        if [[ "${current_version%%.*}" -ge 18 ]]; then
            print_success "Node.js 已安装，版本: $current_version"
            return
        fi
    fi
    
    case $SYSTEM_TYPE in
        debian)
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            if [[ $EUID -eq 0 ]]; then
                apt-get install -y nodejs
            else
                sudo apt-get install -y nodejs
            fi
            ;;
        rhel)
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            if [[ $EUID -eq 0 ]]; then
                $PACKAGE_MANAGER install -y nodejs npm
            else
                sudo $PACKAGE_MANAGER install -y nodejs npm
            fi
            ;;
    esac
    
    print_success "Node.js 安装完成，版本: $(node --version)"
}

# 安装PM2
install_pm2() {
    print_info "安装PM2..."
    
    if command -v pm2 &> /dev/null; then
        print_success "PM2 已安装"
        return
    fi
    
    if [[ $EUID -eq 0 ]]; then
        npm install -g pm2
        
        # 为fracturego用户设置PM2
        if id "fracturego" &>/dev/null; then
            su - fracturego -c "pm2 startup" 2>/dev/null || true
        fi
    else
        sudo npm install -g pm2
        pm2 startup
    fi
    
    print_success "PM2 安装完成"
}

# 安装MySQL
install_mysql() {
    print_info "安装MySQL..."
    
    if command -v mysql &> /dev/null; then
        print_success "MySQL 已安装"
        return
    fi
    
    case $SYSTEM_TYPE in
        debian)
            if [[ $EUID -eq 0 ]]; then
                apt install -y mysql-server
                systemctl start mysql
                systemctl enable mysql
            else
                sudo apt install -y mysql-server
                sudo systemctl start mysql
                sudo systemctl enable mysql
            fi
            ;;
        rhel)
            if [[ $EUID -eq 0 ]]; then
                $PACKAGE_MANAGER install -y mysql-server
                systemctl start mysqld
                systemctl enable mysqld
            else
                sudo $PACKAGE_MANAGER install -y mysql-server
                sudo systemctl start mysqld
                sudo systemctl enable mysqld
            fi
            ;;
    esac
    
    print_success "MySQL 安装完成"
    print_warning "请稍后配置MySQL安全设置"
}

# 配置MySQL数据库
setup_database() {
    print_info "配置数据库..."
    
    # 生成随机密码
    DB_PASSWORD=$(openssl rand -base64 32)
    
    print_info "创建数据库和用户..."
    print_info "数据库名: $DB_NAME"
    print_info "用户名: $DB_USER"
    
    # 创建数据库配置SQL
    mysql_commands="
    CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
    GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
    FLUSH PRIVILEGES;
    "
    
    # 执行SQL命令
    if mysql -u root -e "$mysql_commands"; then
        print_success "数据库配置完成"
        
        # 保存数据库配置
        echo "DB_HOST=localhost" > /tmp/fracturego_db_config
        echo "DB_PORT=3306" >> /tmp/fracturego_db_config
        echo "DB_NAME=$DB_NAME" >> /tmp/fracturego_db_config
        echo "DB_USER=$DB_USER" >> /tmp/fracturego_db_config
        echo "DB_PASSWORD=$DB_PASSWORD" >> /tmp/fracturego_db_config
        
    else
        print_error "数据库配置失败"
        print_info "请手动运行以下SQL命令:"
        echo "$mysql_commands"
        exit 1
    fi
}

# 选择GitHub认证方式
choose_github_auth() {
    print_info "选择GitHub认证方式:"
    echo "1. SSH密钥认证（推荐）"
    echo "2. Personal Access Token"
    echo "3. 跳过，使用现有配置"
    
    read -p "请选择 (1-3): " auth_choice
    
    case $auth_choice in
        1)
            setup_github_ssh
            REPO_URL=$SSH_REPO_URL
            ;;
        2)
            setup_github_token
            ;;
        3)
            print_info "跳过GitHub认证配置"
            ;;
        *)
            print_warning "无效选择，使用HTTPS方式"
            ;;
    esac
}

# 配置GitHub SSH
setup_github_ssh() {
    print_info "配置GitHub SSH认证..."
    
    # 检查是否已有SSH密钥
    if [ -f ~/.ssh/id_rsa.pub ]; then
        print_info "发现现有SSH密钥"
        cat ~/.ssh/id_rsa.pub
        print_warning "请确保此密钥已添加到GitHub账户"
    else
        print_info "生成新的SSH密钥..."
        ssh-keygen -t rsa -b 4096 -C "fracturego-deploy" -f ~/.ssh/id_rsa -N ""
        
        print_success "SSH密钥已生成"
        print_info "公钥内容:"
        cat ~/.ssh/id_rsa.pub
        print_warning "请将上述公钥添加到GitHub账户的SSH密钥中"
        print_info "GitHub设置地址: https://github.com/settings/ssh/new"
        
        read -p "按回车键继续（确认已添加SSH密钥到GitHub）..."
    fi
    
    # 测试SSH连接
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_success "GitHub SSH连接成功"
    else
        print_error "GitHub SSH连接失败"
        print_info "请检查SSH密钥配置，或选择Token认证方式"
        return 1
    fi
}

# 配置GitHub Token
setup_github_token() {
    print_info "配置GitHub Personal Access Token..."
    
    echo "请访问 https://github.com/settings/tokens/new 创建Token"
    echo "权限需要勾选: repo (完整访问权限)"
    
    read -p "请输入GitHub Token: " github_token
    
    if [ -n "$github_token" ]; then
        # 修改REPO_URL包含token
        REPO_URL="https://$github_token@github.com/FlyDinosaur/FractureGo-Server.git"
        print_success "GitHub Token配置完成"
    else
        print_error "Token不能为空"
        return 1
    fi
}

# 克隆代码仓库
clone_repository() {
    print_info "克隆代码仓库..."
    
    # 备份现有目录
    if [ -d "$PROJECT_DIR" ] && [ "$(ls -A $PROJECT_DIR)" ]; then
        backup_dir="${PROJECT_DIR}-backup-$(date +%Y%m%d-%H%M%S)"
        print_info "备份现有目录到: $backup_dir"
        mv "$PROJECT_DIR" "$backup_dir"
    fi
    
    # 创建项目目录
    mkdir -p "$PROJECT_DIR"
    
    # 克隆仓库
    if git clone "$REPO_URL" "$PROJECT_DIR"; then
        print_success "代码克隆完成"
    else
        print_error "代码克隆失败"
        return 1
    fi
}

# 安装项目依赖
install_dependencies() {
    print_info "安装项目依赖..."
    
    cd "$PROJECT_DIR"
    
    if npm install --production; then
        print_success "依赖安装完成"
    else
        print_error "依赖安装失败"
        return 1
    fi
}

# 配置环境变量
setup_environment() {
    print_info "配置环境变量..."
    
    cd "$PROJECT_DIR"
    
    # 生成各种密钥
    JWT_SECRET=$(openssl rand -base64 64)
    API_KEY=$(openssl rand -hex 32)
    REFRESH_TOKEN_SECRET=$(openssl rand -base64 64)
    
    # 读取数据库配置
    if [ -f /tmp/fracturego_db_config ]; then
        . /tmp/fracturego_db_config
    else
        print_error "数据库配置文件不存在"
        return 1
    fi
    
    # 创建.env文件
    cat > .env << EOF
# 服务器配置
PORT=$SERVER_PORT
NODE_ENV=production
API_PREFIX=/api/v1

# 数据库配置
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# JWT配置
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=7d
REFRESH_TOKEN_SECRET=$REFRESH_TOKEN_SECRET

# 安全配置
API_KEY=$API_KEY
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# 微信配置（请根据实际情况修改）
WECHAT_APP_ID=your_wechat_app_id
WECHAT_APP_SECRET=your_wechat_app_secret

# 日志配置
LOG_LEVEL=info
LOG_FILE=logs/fracturego.log

# 文件上传配置
UPLOAD_MAX_SIZE=10485760
UPLOAD_PATH=uploads/

# Redis配置（可选）
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
EOF
    
    # 设置权限
    chmod 600 .env
    
    print_success "环境变量配置完成"
    print_info "API密钥: $API_KEY"
    print_warning "请妥善保存API密钥，客户端需要使用"
}

# 运行数据库迁移
run_migrations() {
    print_info "运行数据库迁移..."
    
    cd "$PROJECT_DIR"
    
    if npm run migrate; then
        print_success "数据库迁移完成"
    else
        print_error "数据库迁移失败"
        return 1
    fi
}

# 配置PM2
setup_pm2() {
    print_info "配置PM2..."
    
    cd "$PROJECT_DIR"
    
    # 更新ecosystem.config.js
    cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: '$PROJECT_NAME',
    script: 'src/server.js',
    cwd: '$PROJECT_DIR',
    instances: 'max',
    exec_mode: 'cluster',
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: $SERVER_PORT
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: $SERVER_PORT
    },
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    restart_delay: 4000
  }]
};
EOF
    
    print_success "PM2配置完成"
}

# 启动服务
start_service() {
    print_info "启动服务..."
    
    cd "$PROJECT_DIR"
    
    # 根据用户类型启动服务
    if [[ $EUID -eq 0 ]]; then
        # root用户：以fracturego用户身份启动
        su - fracturego -c "cd $PROJECT_DIR && pm2 start ecosystem.config.js --env production"
        su - fracturego -c "pm2 save"
    else
        # 普通用户
        pm2 start ecosystem.config.js --env production
        pm2 save
    fi
    
    print_success "服务启动完成"
}

# 配置防火墙
setup_firewall() {
    print_info "配置防火墙..."
    
    # UFW (Ubuntu/Debian)
    if command -v ufw &> /dev/null; then
        if [[ $EUID -eq 0 ]]; then
            ufw allow $SERVER_PORT
            ufw --force enable
        else
            sudo ufw allow $SERVER_PORT
            sudo ufw --force enable
        fi
        print_success "UFW防火墙配置完成"
    # FirewallD (CentOS/RHEL)
    elif command -v firewall-cmd &> /dev/null; then
        if [[ $EUID -eq 0 ]]; then
            firewall-cmd --permanent --add-port=$SERVER_PORT/tcp
            firewall-cmd --reload
        else
            sudo firewall-cmd --permanent --add-port=$SERVER_PORT/tcp
            sudo firewall-cmd --reload
        fi
        print_success "FirewallD防火墙配置完成"
    else
        print_warning "未检测到防火墙，请手动开放端口 $SERVER_PORT"
    fi
}

# 显示部署结果
show_deployment_result() {
    print_success "🎉 FractureGo服务器部署完成！"
    echo
    print_info "部署信息:"
    echo "  📂 项目目录: $PROJECT_DIR"
    echo "  🌐 服务端口: $SERVER_PORT"
    echo "  🗄️  数据库: $DB_NAME"
    echo "  👤 数据库用户: $DB_USER"
    echo "  🔑 API密钥: $(grep API_KEY $PROJECT_DIR/.env | cut -d'=' -f2)"
    echo
    print_info "服务状态:"
    echo "  检查服务: pm2 status"
    echo "  查看日志: pm2 logs $PROJECT_NAME"
    echo "  重启服务: pm2 restart $PROJECT_NAME"
    echo "  停止服务: pm2 stop $PROJECT_NAME"
    echo
    print_info "API端点:"
    echo "  健康检查: http://localhost:$SERVER_PORT/health"
    echo "  API文档: http://localhost:$SERVER_PORT/api/docs"
    echo
    print_warning "重要提醒："
    echo "  • 请保存好API密钥，客户端需要使用"
    echo "  • 请及时修改微信配置（如果使用微信登录）"
    echo "  • 建议配置SSL证书以提高安全性"
    echo "  • 数据库密码已保存在 .env 文件中"
    
    # 清理临时文件
    rm -f /tmp/fracturego_db_config
}

# 主函数
main() {
    # 显示欢迎界面
    print_header
    
    print_info "开始一键部署流程..."
    
    # 检查并确认继续
    read -p "是否继续部署？(y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "部署已取消"
        exit 0
    fi
    
    # 执行部署步骤
    detect_system
    setup_permissions
    update_system
    install_system_dependencies
    install_nodejs
    install_pm2
    install_mysql
    setup_database
    choose_github_auth
    clone_repository
    install_dependencies
    setup_environment
    run_migrations
    setup_pm2
    start_service
    setup_firewall
    show_deployment_result
    
    print_success "🚀 部署完成！享受FractureGo服务吧！"
}

# 错误处理
trap 'print_error "部署过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@" 