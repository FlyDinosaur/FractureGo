const express = require('express');
const { body, query } = require('express-validator');
const router = express.Router();

// 导入控制器
const userController = require('../controllers/userController');
const trainingController = require('../controllers/trainingController');
const signInController = require('../controllers/signInController');

// 导入中间件
const { authenticateApiKey, authenticateToken, requirePermission } = require('../middleware/auth');
const { loginRateLimit, registerRateLimit } = require('../middleware/security');

// 输入验证规则
const userValidation = {
    register: [
        body('phoneNumber')
            .matches(/^1[3-9]\d{9}$/)
            .withMessage('请输入有效的手机号码'),
        body('password')
            .isLength({ min: 6, max: 20 })
            .withMessage('密码长度应为6-20位'),
        body('nickname')
            .isLength({ min: 1, max: 50 })
            .withMessage('昵称长度应为1-50位')
            .trim()
            .escape(),
        body('userType')
            .isIn(['patient', 'doctor', 'therapist', '家长', '儿童', '患者', '医生', '治疗师'])
            .withMessage('用户类型无效'),
        body('birthDate')
            .isISO8601()
            .withMessage('请输入有效的出生日期')
    ],
    login: [
        body('phoneNumber')
            .matches(/^1[3-9]\d{9}$/)
            .withMessage('请输入有效的手机号码'),
        body('password')
            .notEmpty()
            .withMessage('密码不能为空')
    ],
    updateProfile: [
        body('nickname')
            .optional()
            .isLength({ min: 1, max: 50 })
            .withMessage('昵称长度应为1-50位')
            .trim()
            .escape(),
        body('birthDate')
            .optional()
            .isISO8601()
            .withMessage('请输入有效的出生日期'),
        body('avatarData')
            .optional()
            .isString()
            .withMessage('头像数据格式不正确')
    ],
    updateAvatar: [
        body('avatarData')
            .notEmpty()
            .withMessage('头像数据不能为空')
            .isString()
            .withMessage('头像数据必须为字符串')
    ],
    changePassword: [
        body('oldPassword')
            .notEmpty()
            .withMessage('原密码不能为空'),
        body('newPassword')
            .isLength({ min: 6, max: 20 })
            .withMessage('新密码长度应为6-20位')
    ]
};

const trainingValidation = {
    recordTraining: [
        body('trainingType')
            .isIn(['hand', 'arm', 'leg'])
            .withMessage('训练类型无效'),
        body('level')
            .isInt({ min: 1, max: 100 })
            .withMessage('关卡必须为1-100之间的整数'),
        body('score')
            .isInt({ min: 0 })
            .withMessage('分数必须为非负整数'),
        body('duration')
            .isInt({ min: 1 })
            .withMessage('训练时长必须为正整数')
    ],
    updateCurrentLevel: [
        body('trainingType')
            .isIn(['hand', 'arm', 'leg'])
            .withMessage('训练类型无效'),
        body('level')
            .isInt({ min: 1, max: 100 })
            .withMessage('关卡必须为1-100之间的整数')
    ]
};

const signInValidation = {
    signIn: [
        body('signType')
            .optional()
            .isIn(['normal', 'gift', 'target'])
            .withMessage('签到类型无效'),
        body('note')
            .optional()
            .isLength({ max: 200 })
            .withMessage('备注长度不能超过200字符')
    ],
    getSignInData: [
        query('year')
            .isInt({ min: 2020, max: 2030 })
            .withMessage('年份必须为2020-2030之间的整数'),
        query('month')
            .isInt({ min: 1, max: 12 })
            .withMessage('月份必须为1-12之间的整数')
    ]
};

const trainingQueryValidation = {
    getProgress: [
        query('trainingType')
            .optional()
            .isIn(['hand', 'arm', 'leg'])
            .withMessage('训练类型无效')
    ],
    getTrainingHistory: [
        query('trainingType')
            .optional()
            .isIn(['hand', 'arm', 'leg'])
            .withMessage('训练类型无效'),
        query('page')
            .optional()
            .isInt({ min: 1 })
            .withMessage('页码必须为正整数'),
        query('limit')
            .optional()
            .isInt({ min: 1, max: 100 })
            .withMessage('每页数量必须为1-100之间的整数')
    ],
    getTrainingStats: [
        query('trainingType')
            .optional()
            .isIn(['hand', 'arm', 'leg'])
            .withMessage('训练类型无效'),
        query('period')
            .optional()
            .isIn(['1d', '7d', '30d', '90d'])
            .withMessage('时间范围无效')
    ],
    getLeaderboard: [
        query('trainingType')
            .isIn(['hand', 'arm', 'leg'])
            .withMessage('训练类型无效'),
        query('period')
            .optional()
            .isIn(['7d', '30d', '90d'])
            .withMessage('时间范围无效'),
        query('limit')
            .optional()
            .isInt({ min: 1, max: 100 })
            .withMessage('数量限制必须为1-100之间的整数')
    ]
};

// 健康检查端点（无需认证）
router.get('/health', (req, res) => {
    res.json({
        success: true,
        message: 'FractureGo服务器运行正常',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// 应用所有API路由的API密钥验证
router.use('/api/v1', authenticateApiKey);

// ==================== 用户相关路由 ====================

// 用户注册
router.post('/api/v1/auth/register', 
    registerRateLimit,
    requirePermission('user:write'),
    userValidation.register,
    userController.register
);

// 用户登录
router.post('/api/v1/auth/login',
    loginRateLimit,
    requirePermission('user:read'),
    userValidation.login,
    userController.login
);

// 微信登录
router.post('/api/v1/auth/wechat-login',
    loginRateLimit,
    requirePermission('user:read'),
    userController.wechatLogin
);

// 获取用户信息（需要Token验证）
router.get('/api/v1/user/profile',
    authenticateToken,
    requirePermission('user:read'),
    userController.getProfile
);

// 更新用户信息
router.put('/api/v1/user/profile',
    authenticateToken,
    requirePermission('user:write'),
    userValidation.updateProfile,
    userController.updateProfile
);

// 修改密码
router.put('/api/v1/user/change-password',
    authenticateToken,
    requirePermission('user:write'),
    userValidation.changePassword,
    userController.changePassword
);

// 更新用户头像
router.put('/api/v1/user/avatar',
    authenticateToken,
    requirePermission('user:write'),
    userValidation.updateAvatar,
    userController.updateAvatar
);

// ==================== 训练相关路由 ====================

// 获取用户训练进度
router.get('/api/v1/training/progress',
    authenticateToken,
    requirePermission('training:read'),
    trainingQueryValidation.getProgress,
    trainingController.getProgress
);

// 记录训练成绩
router.post('/api/v1/training/record',
    authenticateToken,
    requirePermission('training:write'),
    trainingValidation.recordTraining,
    trainingController.recordTraining
);

// 获取训练历史记录
router.get('/api/v1/training/history',
    authenticateToken,
    requirePermission('training:read'),
    trainingQueryValidation.getTrainingHistory,
    trainingController.getTrainingHistory
);

// 获取训练统计数据
router.get('/api/v1/training/stats',
    authenticateToken,
    requirePermission('training:read'),
    trainingQueryValidation.getTrainingStats,
    trainingController.getTrainingStats
);

// 更新当前训练关卡
router.put('/api/v1/training/current-level',
    authenticateToken,
    requirePermission('training:write'),
    trainingValidation.updateCurrentLevel,
    trainingController.updateCurrentLevel
);

// 获取排行榜
router.get('/api/v1/training/leaderboard',
    authenticateToken,
    requirePermission('training:read'),
    trainingQueryValidation.getLeaderboard,
    trainingController.getLeaderboard
);

// ==================== 签到相关路由 ====================

// 用户签到
router.post('/api/v1/signin',
    authenticateToken,
    requirePermission('signin:write'),
    signInValidation.signIn,
    signInController.signIn
);

// 获取签到数据
router.get('/api/v1/signin/data',
    authenticateToken,
    requirePermission('signin:read'),
    signInValidation.getSignInData,
    signInController.getSignInData
);

// 获取签到统计
router.get('/api/v1/signin/stats',
    authenticateToken,
    requirePermission('signin:read'),
    signInController.getSignInStats
);

// 检查今日签到状态
router.get('/api/v1/signin/today',
    authenticateToken,
    requirePermission('signin:read'),
    signInController.checkTodaySignIn
);

// ==================== 错误处理 ====================

// 404处理
router.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        message: '接口不存在',
        path: req.originalUrl
    });
});

// 全局错误处理
router.use((error, req, res, next) => {
    console.error('API错误:', error);
    
    if (error.type === 'entity.parse.failed') {
        return res.status(400).json({
            success: false,
            message: 'JSON格式错误'
        });
    }

    res.status(500).json({
        success: false,
        message: '服务器内部错误'
    });
});

module.exports = router; 