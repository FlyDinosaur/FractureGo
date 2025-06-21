#!/bin/bash

# GitHub Personal Access Token配置脚本
# 用于在Linux服务器上使用Token访问私有仓库

set -e

echo "🔐 开始配置GitHub Personal Access Token..."

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

# 创建GitHub PAT指南
show_token_creation_guide() {
    print_info "GitHub Personal Access Token创建步骤:"
    echo "1. 登录GitHub → Settings → Developer settings"
    echo "2. Personal access tokens → Tokens (classic)"
    echo "3. Generate new token → Generate new token (classic)"
    echo "4. 设置Token名称，如: 'FractureGo-Server'"
    echo "5. 选择权限（至少需要）:"
    echo "   ✓ repo (完整仓库访问权限)"
    echo "   ✓ read:org (如果是组织仓库)"
    echo "6. 点击 'Generate token'"
    echo "7. 复制生成的Token（只会显示一次）"
    echo ""
}

# 配置Git凭据
setup_git_credentials() {
    print_info "配置Git凭据..."
    
    # 获取GitHub用户名
    read -p "请输入GitHub用户名: " github_username
    
    # 获取Personal Access Token
    echo ""
    print_warning "请粘贴您的GitHub Personal Access Token:"
    read -s github_token
    echo ""
    
    # 验证输入
    if [ -z "$github_username" ] || [ -z "$github_token" ]; then
        print_error "用户名或Token不能为空"
        exit 1
    fi
    
    # 配置Git全局用户信息
    git config --global user.name "$github_username"
    
    # 获取邮箱
    read -p "请输入GitHub邮箱: " github_email
    git config --global user.email "$github_email"
    
    # 存储凭据（安全方式）
    git config --global credential.helper store
    
    # 创建凭据文件
    echo "https://$github_username:$github_token@github.com" > ~/.git-credentials
    chmod 600 ~/.git-credentials
    
    print_success "Git凭据配置完成"
    
    # 返回凭据信息供后续使用
    export GITHUB_USERNAME="$github_username"
    export GITHUB_TOKEN="$github_token"
}

# 测试仓库访问
test_repository_access() {
    print_info "测试仓库访问..."
    
    read -p "请输入要测试的私有仓库 (格式: username/repo): " test_repo
    
    if [ -n "$test_repo" ]; then
        # 创建临时目录测试
        temp_dir="/tmp/github-test-$(date +%s)"
        
        if git clone "https://github.com/$test_repo.git" "$temp_dir" 2>/dev/null; then
            print_success "仓库访问测试成功!"
            rm -rf "$temp_dir"
        else
            print_error "仓库访问测试失败，请检查:"
            echo "1. Token权限是否正确"
            echo "2. 仓库名称是否正确"
            echo "3. 网络连接是否正常"
        fi
    fi
}

# 创建部署脚本
create_deploy_script() {
    print_info "创建部署脚本..."
    
    read -p "请输入服务器代码仓库 (格式: username/repo): " server_repo
    
    if [ -n "$server_repo" ]; then
        cat << EOF > ~/deploy-fracturepo-server.sh
#!/bin/bash

# FractureGo服务器自动部署脚本
# 使用GitHub Personal Access Token

set -e

REPO_URL="https://github.com/$server_repo.git"
DEPLOY_DIR="/opt/fracturepo-server"
BACKUP_DIR="/opt/fracturepo-server-backup-\$(date +%Y%m%d-%H%M%S)"

echo "🚀 开始部署FractureGo服务器..."

# 备份现有版本
if [ -d "\$DEPLOY_DIR" ]; then
    echo "📦 备份现有版本..."
    sudo mv "\$DEPLOY_DIR" "\$BACKUP_DIR"
fi

# 克隆最新代码
echo "📥 下载最新代码..."
sudo git clone "\$REPO_URL" "\$DEPLOY_DIR"

# 切换到部署目录
cd "\$DEPLOY_DIR"

# 安装依赖
echo "📦 安装依赖..."
sudo npm install --production

# 复制环境配置
if [ -f "\$BACKUP_DIR/.env" ]; then
    echo "🔧 恢复环境配置..."
    sudo cp "\$BACKUP_DIR/.env" "\$DEPLOY_DIR/.env"
else
    echo "⚠️ 请手动配置 .env 文件"
    sudo cp env.example .env
fi

# 运行数据库迁移
echo "🗄️ 运行数据库迁移..."
sudo npm run migrate

# 重启服务
echo "🔄 重启服务..."
sudo pm2 reload ecosystem.config.js

echo "✅ 部署完成!"
echo "查看服务状态: sudo pm2 status"
echo "查看日志: sudo pm2 logs"

EOF

        chmod +x ~/deploy-fracturepo-server.sh
        print_success "部署脚本创建完成: ~/deploy-fracturepo-server.sh"
    fi
}

# 安全建议
show_security_recommendations() {
    print_warning "安全建议:"
    echo "1. 定期轮换Personal Access Token"
    echo "2. 只授予必要的最小权限"
    echo "3. 不要在日志或脚本中暴露Token"
    echo "4. 考虑使用环境变量存储敏感信息"
    echo "5. 监控Token的使用情况"
    echo ""
    
    print_info "环境变量配置:"
    echo "可以将Token设置为环境变量:"
    echo "export GITHUB_TOKEN='your_token_here'"
    echo "然后在脚本中使用: git clone https://\$GITHUB_USERNAME:\$GITHUB_TOKEN@github.com/repo.git"
}

# 主函数
main() {
    show_token_creation_guide
    
    read -p "已创建Personal Access Token? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "请先创建Personal Access Token后再运行此脚本"
        exit 0
    fi
    
    setup_git_credentials
    test_repository_access
    create_deploy_script
    show_security_recommendations
    
    print_success "GitHub Token配置完成!"
}

# 运行主函数
main "$@" 