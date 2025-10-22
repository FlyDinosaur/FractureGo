const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const db = require('../config/database');

// 速率限制中间件
const createRateLimit = (windowMs, max, message) => {
    return rateLimit({
        windowMs: windowMs || parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15分钟
        max: max || parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 500, // 提高限制到500个请求
        message: {
            success: false,
            message: message || '请求过于频繁，请稍后再试'
        },
        standardHeaders: true,
        legacyHeaders: false,
        skip: (req) => {
            // 跳过健康检查端点和认证相关端点
            const skipPaths = [
                '/health', 
                '/api/v1/health',
                '/api/v1/auth/login',
                '/api/v1/auth/register',
                '/api/v1/auth/wechat-login'
            ];
            return skipPaths.includes(req.path);
        }
    });
};

// 登录专用速率限制（测试友好的设置）
const loginRateLimit = createRateLimit(
    2 * 60 * 1000, // 2分钟
    50, // 最多50次登录尝试
    '登录尝试过于频繁，请2分钟后再试'
);

// 注册专用速率限制（更宽松的设置）
const registerRateLimit = createRateLimit(
    30 * 60 * 1000, // 30分钟
    10, // 最多10次注册尝试
    '注册尝试过于频繁，请30分钟后再试'
);

// 请求日志中间件
const requestLogger = async (req, res, next) => {
    const startTime = Date.now();

    // 重写res.end方法来捕获响应
    const originalEnd = res.end;
    res.end = function(chunk, encoding) {
        const responseTime = Date.now() - startTime;
        
        // 异步记录日志，不阻塞响应
        setImmediate(async () => {
            try {
                await db.query(`
                    INSERT INTO request_logs 
                    (ip_address, user_agent, method, endpoint, status_code, response_time, user_id, api_key_id)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                `, [
                    req.ip || req.connection.remoteAddress,
                    req.get('User-Agent') || '',
                    req.method,
                    req.originalUrl,
                    res.statusCode,
                    responseTime,
                    req.user?.id || null,
                    req.apiKey?.id || null
                ]);
            } catch (error) {
                console.error('记录请求日志失败:', error.message);
            }
        });

        originalEnd.call(this, chunk, encoding);
    };

    next();
};

// IP白名单检查中间件
const ipWhitelist = (whitelist = []) => {
    return (req, res, next) => {
        if (whitelist.length === 0) {
            return next();
        }

        const clientIp = req.ip || req.connection.remoteAddress;
        
        if (!whitelist.includes(clientIp)) {
            return res.status(403).json({
                success: false,
                message: 'IP地址不在白名单中'
            });
        }

        next();
    };
};

// 请求体大小限制
const bodySizeLimit = (limit = '10mb') => {
    return (req, res, next) => {
        const contentLength = parseInt(req.get('Content-Length'));
        const maxSize = parseLimit(limit);

        if (contentLength && contentLength > maxSize) {
            return res.status(413).json({
                success: false,
                message: '请求体过大'
            });
        }

        next();
    };
};

// 解析大小限制字符串
function parseLimit(limit) {
    const units = {
        'b': 1,
        'kb': 1024,
        'mb': 1024 * 1024,
        'gb': 1024 * 1024 * 1024
    };

    const match = limit.toString().toLowerCase().match(/^(\d+(?:\.\d+)?)\s*([kmg]?b?)$/);
    if (!match) return 0;

    const value = parseFloat(match[1]);
    const unit = match[2] || 'b';

    return Math.floor(value * (units[unit] || 1));
}

// CORS配置
const corsOptions = {
    origin: function (origin, callback) {
        // 在生产环境中，应该设置具体的域名白名单
        const allowedOrigins = process.env.ALLOWED_ORIGINS 
            ? process.env.ALLOWED_ORIGINS.split(',')
            : ['http://localhost:3000', 'https://your-app-domain.com'];

        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('不被CORS策略允许'));
        }
    },
    credentials: true,
    optionsSuccessStatus: 200
};

// Helmet安全配置
const helmetOptions = {
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
        },
    },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    }
};

// Morgan日志格式
const morganFormat = process.env.NODE_ENV === 'production' 
    ? 'combined' 
    : 'dev';

module.exports = {
    createRateLimit,
    loginRateLimit,
    registerRateLimit,
    requestLogger,
    ipWhitelist,
    bodySizeLimit,
    corsOptions,
    helmetOptions,
    morganFormat,
    helmet: helmet(helmetOptions),
    compression: compression(),
    morgan: morgan(morganFormat)
}; 