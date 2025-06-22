#!/bin/bash

SERVER_IP="117.72.161.6"
SERVER_USER="root"
SERVER_PASSWORD="WYX11037414qq"
SERVER_PATH="/root/FractureGo"

echo "🚀 开始部署到服务器..."

# 检查服务器连接
echo "📡 检查服务器连接..."
./ssh_connect.exp << 'EOF'
spawn ssh root@117.72.161.6

expect {
    "password:" {
        send "WYX11037414qq\r"
    }
    "Are you sure you want to continue connecting" {
        send "yes\r"
        expect "password:"
        send "WYX11037414qq\r"
    }
}

expect "# "
send "echo '连接成功，当前目录：'; pwd\r"
send "ls -la\r"
send "exit\r"
expect eof
EOF

echo "📁 创建项目目录..."
./ssh_connect.exp << 'EOF'
spawn ssh root@117.72.161.6

expect {
    "password:" {
        send "WYX11037414qq\r"
    }
    "Are you sure you want to continue connecting" {
        send "yes\r"
        expect "password:"
        send "WYX11037414qq\r"
    }
}

expect "# "
send "mkdir -p /root/FractureGo/Server/src\r"
send "mkdir -p /root/FractureGo/Server/src/controllers\r"
send "mkdir -p /root/FractureGo/Server/src/middleware\r"
send "mkdir -p /root/FractureGo/Server/src/routes\r"
send "mkdir -p /root/FractureGo/Server/uploads/posts\r"
send "echo '目录创建完成'\r"
send "exit\r"
expect eof
EOF

echo "📤 上传SQL文件..."
expect << 'EOF'
spawn scp server_setup.sql root@117.72.161.6:/root/FractureGo/

expect {
    "password:" {
        send "WYX11037414qq\r"
    }
    "Are you sure you want to continue connecting" {
        send "yes\r"
        expect "password:"
        send "WYX11037414qq\r"
    }
}

expect eof
EOF

echo "📤 上传服务器文件..."
expect << 'EOF'
spawn scp Server/src/controllers/postController.js root@117.72.161.6:/root/FractureGo/Server/src/controllers/

expect {
    "password:" {
        send "WYX11037414qq\r"
    }
    "Are you sure you want to continue connecting" {
        send "yes\r"
        expect "password:"
        send "WYX11037414qq\r"
    }
}

expect eof
EOF

expect << 'EOF'
spawn scp Server/src/middleware/upload.js root@117.72.161.6:/root/FractureGo/Server/src/middleware/

expect {
    "password:" {
        send "WYX11037414qq\r"
    }
    "Are you sure you want to continue connecting" {
        send "yes\r"
        expect "password:"
        send "WYX11037414qq\r"
    }
}

expect eof
EOF

echo "🗄️ 执行数据库迁移..."
./ssh_connect.exp << 'EOF'
spawn ssh root@117.72.161.6

expect {
    "password:" {
        send "WYX11037414qq\r"
    }
    "Are you sure you want to continue connecting" {
        send "yes\r"
        expect "password:"
        send "WYX11037414qq\r"
    }
}

expect "# "
send "cd /root/FractureGo\r"
send "mysql -u root -p fracture_go < server_setup.sql\r"
expect "password:"
send "123456\r"
expect "# "
send "echo 'SQL执行完成'\r"
send "exit\r"
expect eof
EOF

echo "📦 安装依赖..."
./ssh_connect.exp << 'EOF'
spawn ssh root@117.72.161.6

expect {
    "password:" {
        send "WYX11037414qq\r"
    }
    "Are you sure you want to continue connecting" {
        send "yes\r"
        expect "password:"
        send "WYX11037414qq\r"
    }
}

expect "# "
send "cd /root/FractureGo/Server\r"
send "npm install multer\r"
expect "# "
send "echo '依赖安装完成'\r"
send "exit\r"
expect eof
EOF

echo "✅ 部署完成！" 