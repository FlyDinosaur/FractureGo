const { validationResult } = require('express-validator');
const db = require('../config/database');
const { uploadSingle } = require('../middleware/upload');
const path = require('path');
const fs = require('fs').promises;

class PostController {
    // 获取帖子列表（支持分页、分类筛选、搜索）
    async getPosts(req, res) {
        try {
            const {
                page = 1,
                limit = 10,
                category_id,
                search,
                post_type,
                sort = 'created_at',
                order = 'DESC'
            } = req.query;

            const offset = (Number(page) - 1) * Number(limit);
            let whereConditions = ["p.status = 'published'"];
            let queryParams = [];

            // 分类筛选
            if (category_id) {
                whereConditions.push('p.category_id = ?');
                queryParams.push(Number(category_id));
            }

            // 类型筛选
            if (post_type) {
                whereConditions.push('p.post_type = ?');
                queryParams.push(post_type);
            }

            // 搜索功能
            if (search) {
                whereConditions.push('(p.title LIKE ? OR p.content LIKE ?)');
                queryParams.push(`%${search}%`, `%${search}%`);
            }

            // 验证排序参数
            const allowedSortFields = ['created_at', 'like_count', 'view_count', 'comment_count'];
            const sortField = allowedSortFields.includes(sort) ? sort : 'created_at';
            const sortOrder = ['ASC', 'DESC'].includes(order.toUpperCase()) ? order.toUpperCase() : 'DESC';

            // 构建查询
            const whereClause = whereConditions.join(' AND ');
            
            const query = `
                SELECT 
                    p.id,
                    p.title,
                    p.summary,
                    p.cover_image,
                    p.post_type,
                    p.video_url,
                    p.video_duration,
                    p.view_count,
                    p.like_count,
                    p.comment_count,
                    p.published_at,
                    p.created_at,
                    u.id as user_id,
                    u.nickname as user_nickname,
                    u.avatar as user_avatar,
                    c.name as category_name,
                    c.color as category_color,
                    c.icon as category_icon
                FROM posts p
                LEFT JOIN users u ON p.user_id = u.id
                LEFT JOIN post_categories c ON p.category_id = c.id
                WHERE ${whereClause}
                ORDER BY p.${sortField} ${sortOrder}
                LIMIT ${Number(limit)} OFFSET ${Number(offset)}
            `;

            const posts = await db.query(query, queryParams);

            // 获取总数
            const countQuery = `SELECT COUNT(*) as total FROM posts p WHERE ${whereClause}`;
            const [countResult] = await db.query(countQuery, queryParams);
            const total = countResult.total;

            res.json({
                success: true,
                data: {
                    posts: posts.map(post => ({
                        id: post.id,
                        title: post.title,
                        summary: post.summary,
                        coverImage: post.cover_image,
                        postType: post.post_type,
                        videoUrl: post.video_url,
                        videoDuration: post.video_duration,
                        viewCount: post.view_count,
                        likeCount: post.like_count,
                        commentCount: post.comment_count,
                        publishedAt: post.published_at,
                        createdAt: post.created_at,
                        author: {
                            id: post.user_id,
                            nickname: post.user_nickname,
                            avatar: post.user_avatar
                        },
                        category: post.category_name ? {
                            name: post.category_name,
                            color: post.category_color,
                            icon: post.category_icon
                        } : null
                    })),
                    pagination: {
                        page: Number(page),
                        limit: Number(limit),
                        total,
                        totalPages: Math.ceil(total / Number(limit))
                    }
                }
            });

        } catch (error) {
            console.error('获取帖子列表错误:', error);
            console.error('Error stack:', error.stack);
            console.error('Error details:', {
                message: error.message,
                sqlState: error.sqlState,
                sqlMessage: error.sqlMessage,
                code: error.code
            });
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 获取帖子详情
    async getPostDetail(req, res) {
        try {
            const { id } = req.params;
            const userId = req.user?.userId;

            // 获取帖子详情
            const [post] = await db.query(`
                SELECT 
                    p.*,
                    u.nickname as user_nickname,
                    u.avatar as user_avatar,
                    c.name as category_name,
                    c.color as category_color,
                    c.icon as category_icon
                FROM posts p
                LEFT JOIN users u ON p.user_id = u.id
                LEFT JOIN post_categories c ON p.category_id = c.id
                WHERE p.id = ? AND p.status = "published"
            `, [id]);

            if (!post) {
                return res.status(404).json({
                    success: false,
                    message: '帖子不存在'
                });
            }

            // 增加浏览次数
            await db.query('UPDATE posts SET view_count = view_count + 1 WHERE id = ?', [id]);

            // 检查当前用户是否已点赞
            let isLiked = false;
            if (userId) {
                const [likeResult] = await db.query(
                    'SELECT id FROM post_likes WHERE user_id = ? AND post_id = ?',
                    [userId, id]
                );
                isLiked = !!likeResult;
            }

            // 获取媒体文件
            const media = await db.query(`
                SELECT file_path, file_name, file_type, mime_type
                FROM post_media
                WHERE post_id = ?
                ORDER BY sort_order
            `, [id]);

            res.json({
                success: true,
                data: {
                    id: post.id,
                    title: post.title,
                    content: post.content,
                    summary: post.summary,
                    coverImage: post.cover_image,
                    postType: post.post_type,
                    videoUrl: post.video_url,
                    videoDuration: post.video_duration,
                    tags: post.tags ? JSON.parse(post.tags) : [],
                    viewCount: post.view_count + 1, // 包含本次浏览
                    likeCount: post.like_count,
                    commentCount: post.comment_count,
                    shareCount: post.share_count,
                    isLiked,
                    publishedAt: post.published_at,
                    createdAt: post.created_at,
                    updatedAt: post.updated_at,
                    author: {
                        id: post.user_id,
                        nickname: post.user_nickname,
                        avatar: post.user_avatar
                    },
                    category: post.category_name ? {
                        id: post.category_id,
                        name: post.category_name,
                        color: post.category_color,
                        icon: post.category_icon
                    } : null,
                    media
                }
            });

        } catch (error) {
            console.error('获取帖子详情错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 创建帖子
    async createPost(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: '输入验证失败',
                    errors: errors.array()
                });
            }

            const userId = req.user.userId;
            const {
                title,
                content,
                summary,
                coverImage,
                postType = 'text',
                videoUrl,
                videoDuration,
                categoryId,
                tags,
                status = 'published'
            } = req.body;

            const publishedAt = status === 'published' ? new Date() : null;

            const result = await db.query(`
                INSERT INTO posts (
                    user_id, title, content, summary, cover_image,
                    post_type, video_url, video_duration, category_id,
                    tags, status, published_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `, [
                userId, title, content, summary, coverImage,
                postType, videoUrl, videoDuration, categoryId,
                tags ? JSON.stringify(tags) : null, status, publishedAt
            ]);

            const postId = result.insertId;

            res.status(201).json({
                success: true,
                message: '帖子创建成功',
                data: {
                    postId,
                    status
                }
            });

        } catch (error) {
            console.error('创建帖子错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 点赞/取消点赞帖子
    async toggleLike(req, res) {
        try {
            const { id } = req.params;
            const userId = req.user.userId;

            // 检查帖子是否存在
            const [post] = await db.query(
                'SELECT id FROM posts WHERE id = ? AND status = "published"',
                [id]
            );

            if (!post) {
                return res.status(404).json({
                    success: false,
                    message: '帖子不存在'
                });
            }

            // 检查是否已点赞
            const [existingLike] = await db.query(
                'SELECT id FROM post_likes WHERE user_id = ? AND post_id = ?',
                [userId, id]
            );

            let isLiked;
            let likeCount;

            if (existingLike) {
                // 取消点赞
                await db.query(
                    'DELETE FROM post_likes WHERE user_id = ? AND post_id = ?',
                    [userId, id]
                );
                isLiked = false;
            } else {
                // 添加点赞
                await db.query(
                    'INSERT INTO post_likes (user_id, post_id) VALUES (?, ?)',
                    [userId, id]
                );
                isLiked = true;
            }

            // 获取最新点赞数
            const [postData] = await db.query(
                'SELECT like_count FROM posts WHERE id = ?',
                [id]
            );
            likeCount = postData.like_count;

            res.json({
                success: true,
                data: {
                    isLiked,
                    likeCount
                }
            });

        } catch (error) {
            console.error('点赞操作错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 获取分类列表
    async getCategories(req, res) {
        try {
            const categories = await db.query(`
                SELECT id, name, description, color, icon, sort_order
                FROM post_categories
                WHERE is_active = TRUE
                ORDER BY sort_order, id
            `);

            res.json({
                success: true,
                data: categories
            });

        } catch (error) {
            console.error('获取分类列表错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 上传媒体文件
    async uploadMedia(req, res) {
        try {
            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    message: '未上传文件'
                });
            }

            const { file } = req;
            const fileUrl = `/uploads/posts/${file.filename}`;

            res.json({
                success: true,
                data: {
                    url: fileUrl,
                    filename: file.filename,
                    originalName: file.originalname,
                    size: file.size,
                    mimeType: file.mimetype
                }
            });

        } catch (error) {
            console.error('上传媒体文件错误:', error);
            res.status(500).json({
                success: false,
                message: '上传失败'
            });
        }
    }
}

module.exports = new PostController(); 