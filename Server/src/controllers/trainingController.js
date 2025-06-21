const { validationResult } = require('express-validator');
const db = require('../config/database');

class TrainingController {
    // 获取用户训练进度
    async getProgress(req, res) {
        try {
            const userId = req.user.id;
            const { trainingType } = req.query;

            let query = 'SELECT * FROM user_progress WHERE user_id = ?';
            let params = [userId];

            if (trainingType) {
                query += ' AND training_type = ?';
                params.push(trainingType);
            }

            const progress = await db.query(query, params);

            res.json({
                success: true,
                data: { progress }
            });

        } catch (error) {
            console.error('获取训练进度错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 记录训练成绩
    async recordTraining(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: '输入验证失败',
                    errors: errors.array()
                });
            }

            const userId = req.user.id;
            const { trainingType, level, score, duration, data } = req.body;

            // 开始事务
            await db.transaction(async (connection) => {
                // 记录训练记录
                await connection.execute(`
                    INSERT INTO training_records 
                    (user_id, training_type, level, score, duration, data)
                    VALUES (?, ?, ?, ?, ?, ?)
                `, [userId, trainingType, level, score, duration, JSON.stringify(data || {})]);

                // 获取当前进度
                const [currentProgress] = await connection.execute(
                    'SELECT * FROM user_progress WHERE user_id = ? AND training_type = ?',
                    [userId, trainingType]
                );

                if (currentProgress) {
                    // 更新进度
                    const newMaxLevel = Math.max(currentProgress.max_level_reached, level);
                    const newBestScore = Math.max(currentProgress.best_score, score);
                    const newTotalTime = currentProgress.total_training_time + duration;
                    const newTotalSessions = currentProgress.total_sessions + 1;

                    await connection.execute(`
                        UPDATE user_progress SET 
                            max_level_reached = ?,
                            best_score = ?,
                            total_training_time = ?,
                            total_sessions = ?,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE user_id = ? AND training_type = ?
                    `, [newMaxLevel, newBestScore, newTotalTime, newTotalSessions, userId, trainingType]);
                } else {
                    // 创建新进度记录
                    await connection.execute(`
                        INSERT INTO user_progress 
                        (user_id, training_type, current_level, max_level_reached, 
                         total_training_time, total_sessions, best_score)
                        VALUES (?, ?, ?, ?, ?, ?, ?)
                    `, [userId, trainingType, level, level, duration, 1, score]);
                }
            });

            res.status(201).json({
                success: true,
                message: '训练成绩记录成功'
            });

        } catch (error) {
            console.error('记录训练成绩错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 获取训练历史记录
    async getTrainingHistory(req, res) {
        try {
            const userId = req.user.id;
            const { trainingType, page = 1, limit = 20 } = req.query;

            const offset = (page - 1) * limit;
            let query = `
                SELECT id, training_type, level, score, duration, completed_at, data
                FROM training_records 
                WHERE user_id = ?
            `;
            let params = [userId];

            if (trainingType) {
                query += ' AND training_type = ?';
                params.push(trainingType);
            }

            query += ' ORDER BY completed_at DESC LIMIT ? OFFSET ?';
            params.push(parseInt(limit), parseInt(offset));

            const records = await db.query(query, params);

            // 获取总数
            let countQuery = 'SELECT COUNT(*) as total FROM training_records WHERE user_id = ?';
            let countParams = [userId];

            if (trainingType) {
                countQuery += ' AND training_type = ?';
                countParams.push(trainingType);
            }

            const [countResult] = await db.query(countQuery, countParams);
            const total = countResult.total;

            res.json({
                success: true,
                data: {
                    records,
                    pagination: {
                        page: parseInt(page),
                        limit: parseInt(limit),
                        total,
                        totalPages: Math.ceil(total / limit)
                    }
                }
            });

        } catch (error) {
            console.error('获取训练历史错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 获取训练统计数据
    async getTrainingStats(req, res) {
        try {
            const userId = req.user.id;
            const { trainingType, period = '7d' } = req.query;

            // 计算时间范围
            let dateFilter = '';
            switch (period) {
                case '1d':
                    dateFilter = 'AND completed_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)';
                    break;
                case '7d':
                    dateFilter = 'AND completed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)';
                    break;
                case '30d':
                    dateFilter = 'AND completed_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)';
                    break;
                case '90d':
                    dateFilter = 'AND completed_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)';
                    break;
                default:
                    dateFilter = '';
            }

            let query = `
                SELECT 
                    training_type,
                    COUNT(*) as session_count,
                    SUM(duration) as total_duration,
                    AVG(score) as avg_score,
                    MAX(score) as best_score,
                    MAX(level) as max_level
                FROM training_records 
                WHERE user_id = ? ${dateFilter}
            `;
            let params = [userId];

            if (trainingType) {
                query += ' AND training_type = ?';
                params.push(trainingType);
            }

            query += ' GROUP BY training_type';

            const stats = await db.query(query, params);

            // 获取每日训练数据（用于图表）
            const dailyQuery = `
                SELECT 
                    DATE(completed_at) as date,
                    training_type,
                    COUNT(*) as session_count,
                    SUM(duration) as total_duration,
                    AVG(score) as avg_score
                FROM training_records 
                WHERE user_id = ? ${dateFilter}
                ${trainingType ? 'AND training_type = ?' : ''}
                GROUP BY DATE(completed_at), training_type
                ORDER BY date DESC
            `;

            const dailyParams = trainingType ? [userId, trainingType] : [userId];
            const dailyStats = await db.query(dailyQuery, dailyParams);

            res.json({
                success: true,
                data: {
                    stats,
                    dailyStats,
                    period
                }
            });

        } catch (error) {
            console.error('获取训练统计错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 更新当前训练关卡
    async updateCurrentLevel(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: '输入验证失败',
                    errors: errors.array()
                });
            }

            const userId = req.user.id;
            const { trainingType, level } = req.body;

            // 检查是否已解锁该关卡
            const [progress] = await db.query(
                'SELECT max_level_reached FROM user_progress WHERE user_id = ? AND training_type = ?',
                [userId, trainingType]
            );

            if (!progress) {
                return res.status(404).json({
                    success: false,
                    message: '训练进度不存在'
                });
            }

            if (level > progress.max_level_reached) {
                return res.status(400).json({
                    success: false,
                    message: '该关卡尚未解锁'
                });
            }

            // 更新当前关卡
            await db.query(
                'UPDATE user_progress SET current_level = ? WHERE user_id = ? AND training_type = ?',
                [level, userId, trainingType]
            );

            res.json({
                success: true,
                message: '关卡更新成功'
            });

        } catch (error) {
            console.error('更新训练关卡错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 获取排行榜
    async getLeaderboard(req, res) {
        try {
            const { trainingType, period = '30d', limit = 50 } = req.query;

            if (!trainingType) {
                return res.status(400).json({
                    success: false,
                    message: '请指定训练类型'
                });
            }

            // 计算时间范围
            let dateFilter = '';
            switch (period) {
                case '7d':
                    dateFilter = 'AND tr.completed_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)';
                    break;
                case '30d':
                    dateFilter = 'AND tr.completed_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)';
                    break;
                case '90d':
                    dateFilter = 'AND tr.completed_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)';
                    break;
                default:
                    dateFilter = '';
            }

            const query = `
                SELECT 
                    u.id,
                    u.nickname,
                    u.wechat_avatar_url,
                    MAX(tr.score) as best_score,
                    MAX(tr.level) as max_level,
                    COUNT(tr.id) as session_count,
                    SUM(tr.duration) as total_duration
                FROM users u
                JOIN training_records tr ON u.id = tr.user_id
                WHERE tr.training_type = ? ${dateFilter}
                AND u.status = 'active'
                GROUP BY u.id, u.nickname, u.wechat_avatar_url
                ORDER BY best_score DESC, max_level DESC
                LIMIT ?
            `;

            const leaderboard = await db.query(query, [trainingType, parseInt(limit)]);

            // 添加排名
            const rankedLeaderboard = leaderboard.map((user, index) => ({
                ...user,
                rank: index + 1
            }));

            res.json({
                success: true,
                data: {
                    leaderboard: rankedLeaderboard,
                    trainingType,
                    period
                }
            });

        } catch (error) {
            console.error('获取排行榜错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }
}

module.exports = new TrainingController(); 