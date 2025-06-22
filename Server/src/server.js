const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

// 导入中间件
const {
    helmet,
    compression,
    morgan,
    requestLogger,
    createRateLimit,
    corsOptions
} = require('./middleware/security');

// 导入路由
const routes = require('./routes');

// 导入数据库
const db = require('./config/database');

class FractureGoServer {
    constructor() {
        this.app = express();
        this.port = process.env.PORT || 28974;
        this.setupMiddleware();
        this.setupRoutes();
        this.setupErrorHandling();
    }

    setupMiddleware() {
        // 信任代理（用于获取真实IP）
        this.app.set('trust proxy', 1);

        // 安全中间件
        this.app.use(helmet);
        this.app.use(compression);
        
        // CORS设置
        this.app.use(cors(corsOptions));

        // 请求日志
        this.app.use(morgan);
        this.app.use(requestLogger);

        // 全局速率限制
        this.app.use(createRateLimit());

        // 解析JSON和URL编码数据
        this.app.use(express.json({ 
            limit: process.env.UPLOAD_MAX_SIZE || '10mb',
            strict: true
        }));
        this.app.use(express.urlencoded({ 
            extended: true, 
            limit: process.env.UPLOAD_MAX_SIZE || '10mb'
        }));

        // 图片优化中间件
        const { imageOptimization } = require('./middleware/imageOptimization');
        this.app.use('/uploads', imageOptimization);
        
        // 静态文件服务（如果需要）
        const uploadPath = process.env.UPLOAD_PATH || 'uploads';
        this.app.use('/uploads', express.static(path.join(__dirname, '..', uploadPath)));

        // 添加请求时间戳
        this.app.use((req, res, next) => {
            req.timestamp = new Date().toISOString();
            next();
        });
    }

    setupRoutes() {
        // 应用路由
        this.app.use('/', routes);

        // API文档端点
        this.app.get('/api/docs', (req, res) => {
            res.json({
                success: true,
                message: 'FractureGo API 文档',
                version: '1.0.0',
                endpoints: {
                    health: 'GET /health',
                    auth: {
                        register: 'POST /api/v1/auth/register',
                        login: 'POST /api/v1/auth/login',
                        wechatLogin: 'POST /api/v1/auth/wechat-login'
                    },
                    user: {
                        profile: 'GET /api/v1/user/profile',
                        updateProfile: 'PUT /api/v1/user/profile',
                        changePassword: 'PUT /api/v1/user/change-password'
                    },
                    training: {
                        progress: 'GET /api/v1/training/progress',
                        record: 'POST /api/v1/training/record',
                        history: 'GET /api/v1/training/history',
                        stats: 'GET /api/v1/training/stats',
                        updateLevel: 'PUT /api/v1/training/current-level',
                        leaderboard: 'GET /api/v1/training/leaderboard'
                    }
                },
                authentication: {
                    apiKey: '在请求头中添加 X-API-Key',
                    jwt: '在请求头中添加 Authorization: Bearer <token>'
                }
            });
        });
    }

    setupErrorHandling() {
        // 未捕获的Promise拒绝
        process.on('unhandledRejection', (reason, promise) => {
            console.error('未处理的Promise拒绝:', reason);
            // 在生产环境中，可能需要重启服务器
            if (process.env.NODE_ENV === 'production') {
                console.log('服务器将在5秒后重启...');
                setTimeout(() => {
                    process.exit(1);
                }, 5000);
            }
        });

        // 未捕获的异常
        process.on('uncaughtException', (error) => {
            console.error('未捕获的异常:', error);
            console.log('服务器将立即关闭...');
            process.exit(1);
        });

        // 优雅关闭
        process.on('SIGTERM', this.gracefulShutdown.bind(this));
        process.on('SIGINT', this.gracefulShutdown.bind(this));
    }

    async gracefulShutdown(signal) {
        console.log(`收到${signal}信号，开始优雅关闭...`);
        
        this.server.close(async () => {
            console.log('HTTP服务器已关闭');
            
            try {
                await db.close();
                console.log('数据库连接已关闭');
                process.exit(0);
            } catch (error) {
                console.error('关闭数据库连接时出错:', error);
                process.exit(1);
            }
        });

        // 如果30秒内没有正常关闭，强制退出
        setTimeout(() => {
            console.error('强制关闭服务器');
            process.exit(1);
        }, 30000);
    }

    async start() {
        try {
            // 检查必需的环境变量
            this.checkRequiredEnvVars();

            // 等待数据库连接
            console.log('等待数据库连接...');
            // db在require时已经初始化连接

            // 启动服务器
            this.server = this.app.listen(this.port, () => {
                console.log('🚀 FractureGo服务器启动成功!');
                console.log(`📍 端口: ${this.port}`);
                console.log(`🌍 环境: ${process.env.NODE_ENV || 'development'}`);
                console.log(`⏰ 启动时间: ${new Date().toISOString()}`);
                console.log(`🔗 健康检查: http://localhost:${this.port}/health`);
                console.log(`📚 API文档: http://localhost:${this.port}/api/docs`);
            });

            // 设置服务器超时
            this.server.timeout = 30000; // 30秒超时

        } catch (error) {
            console.error('❌ 服务器启动失败:', error);
            process.exit(1);
        }
    }

    checkRequiredEnvVars() {
        const required = [
            'DB_HOST',
            'DB_USER', 
            'DB_PASSWORD',
            'DB_NAME',
            'JWT_SECRET',
            'API_KEY'
        ];

        const missing = required.filter(key => !process.env[key]);
        
        if (missing.length > 0) {
            throw new Error(`缺少必需的环境变量: ${missing.join(', ')}`);
        }

        // 检查JWT密钥长度
        if (process.env.JWT_SECRET.length < 32) {
            throw new Error('JWT_SECRET长度至少需要32个字符');
        }
    }
}

// 启动服务器
if (require.main === module) {
    const server = new FractureGoServer();
    server.start();
}

module.exports = FractureGoServer; 