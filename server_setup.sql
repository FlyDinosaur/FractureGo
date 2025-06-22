-- 给users表添加avatar列
ALTER TABLE users ADD COLUMN avatar VARCHAR(500) NULL COMMENT '用户头像URL' AFTER wechat_avatar_url;

-- 创建帖子相关表（如果不存在）
CREATE TABLE IF NOT EXISTS post_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL COMMENT '分类名称',
    description TEXT COMMENT '分类描述',
    color VARCHAR(7) DEFAULT '#9ecd57' COMMENT '分类颜色',
    icon VARCHAR(50) COMMENT '分类图标',
    sort_order INT DEFAULT 0 COMMENT '排序',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS posts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT '作者ID',
    title VARCHAR(255) NOT NULL COMMENT '帖子标题',
    content LONGTEXT NOT NULL COMMENT 'Markdown内容',
    summary TEXT COMMENT '帖子摘要',
    cover_image VARCHAR(500) COMMENT '封面图片URL',
    post_type ENUM('text', 'video') DEFAULT 'text' COMMENT '帖子类型',
    video_url VARCHAR(500) COMMENT '视频URL（如果是视频帖）',
    video_duration INT COMMENT '视频时长（秒）',
    category_id INT COMMENT '分类ID',
    tags JSON COMMENT '标签数组',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    like_count INT DEFAULT 0 COMMENT '点赞数',
    comment_count INT DEFAULT 0 COMMENT '评论数',
    share_count INT DEFAULT 0 COMMENT '分享数',
    status ENUM('draft', 'published', 'hidden', 'deleted') DEFAULT 'draft' COMMENT '状态',
    is_featured BOOLEAN DEFAULT FALSE COMMENT '是否精选',
    published_at TIMESTAMP NULL COMMENT '发布时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES post_categories(id) ON DELETE SET NULL,
    
    INDEX idx_user_id (user_id),
    INDEX idx_category_id (category_id),
    INDEX idx_status (status),
    INDEX idx_published_at (published_at),
    INDEX idx_view_count (view_count),
    INDEX idx_like_count (like_count),
    FULLTEXT INDEX idx_title_content (title, content)
);

CREATE TABLE IF NOT EXISTS post_likes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT '用户ID',
    post_id INT NOT NULL COMMENT '帖子ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_like (user_id, post_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_post_id (post_id)
);

CREATE TABLE IF NOT EXISTS post_comments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    post_id INT NOT NULL COMMENT '帖子ID',
    user_id INT NOT NULL COMMENT '评论者ID',
    parent_id INT NULL COMMENT '父评论ID（回复）',
    content TEXT NOT NULL COMMENT '评论内容',
    like_count INT DEFAULT 0 COMMENT '点赞数',
    reply_count INT DEFAULT 0 COMMENT '回复数',
    status ENUM('active', 'hidden', 'deleted') DEFAULT 'active' COMMENT '状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES post_comments(id) ON DELETE CASCADE,
    
    INDEX idx_post_id (post_id),
    INDEX idx_user_id (user_id),
    INDEX idx_parent_id (parent_id),
    INDEX idx_created_at (created_at)
);

CREATE TABLE IF NOT EXISTS post_media (
    id INT PRIMARY KEY AUTO_INCREMENT,
    post_id INT NOT NULL COMMENT '帖子ID',
    file_path VARCHAR(500) NOT NULL COMMENT '文件路径',
    file_name VARCHAR(255) NOT NULL COMMENT '文件名',
    file_type VARCHAR(50) NOT NULL COMMENT '文件类型',
    file_size INT NOT NULL COMMENT '文件大小(字节)',
    mime_type VARCHAR(100) NOT NULL COMMENT 'MIME类型',
    sort_order INT DEFAULT 0 COMMENT '排序',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    
    INDEX idx_post_id (post_id)
);

-- 插入默认分类
INSERT IGNORE INTO post_categories (name, description, color, icon, sort_order) VALUES
('经验分享', '用户分享康复训练经验和心得', '#9ecd57', 'lightbulb', 1),
('医生分享', '医生专业知识和指导分享', '#FF6B6B', 'stethoscope', 2),
('求助', '寻求帮助和建议的帖子', '#4ECDC4', 'hand.raised', 3),
('日常', '日常生活和康复过程记录', '#45B7D1', 'calendar', 4),
('问答', '问题解答和知识交流', '#96CEB4', 'questionmark.circle', 5),
('成果展示', '康复成果和进展展示', '#FFEAA7', 'trophy', 6);

-- 创建触发器：更新帖子统计数据
DELIMITER //

DROP TRIGGER IF EXISTS update_post_like_count_insert//
CREATE TRIGGER update_post_like_count_insert 
AFTER INSERT ON post_likes
FOR EACH ROW
BEGIN
    UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
END//

DROP TRIGGER IF EXISTS update_post_like_count_delete//
CREATE TRIGGER update_post_like_count_delete
AFTER DELETE ON post_likes
FOR EACH ROW
BEGIN
    UPDATE posts SET like_count = like_count - 1 WHERE id = OLD.post_id;
END//

DROP TRIGGER IF EXISTS update_post_comment_count_insert//
CREATE TRIGGER update_post_comment_count_insert
AFTER INSERT ON post_comments
FOR EACH ROW
BEGIN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
END//

DROP TRIGGER IF EXISTS update_post_comment_count_delete//
CREATE TRIGGER update_post_comment_count_delete
AFTER DELETE ON post_comments
FOR EACH ROW
BEGIN
    UPDATE posts SET comment_count = comment_count - 1 WHERE id = OLD.post_id;
END//

DELIMITER ;

-- 插入一些测试数据
INSERT IGNORE INTO posts (user_id, title, content, summary, cover_image, post_type, category_id, status, published_at) VALUES
(1, '我的康复训练心得分享', '在康复训练过程中，我发现了一些很有用的小技巧...', '分享我在康复训练中的一些心得体会', 'https://example.com/cover1.jpg', 'text', 1, 'published', NOW()),
(1, '手部训练的重要性', '手部训练对于康复的重要性不容忽视...', '专业医生分享手部训练知识', 'https://example.com/cover2.jpg', 'text', 2, 'published', NOW()),
(1, '求助：康复过程中遇到的问题', '我在康复过程中遇到了一些问题，希望大家能帮忙解答...', '寻求康复过程中问题的解答', 'https://example.com/cover3.jpg', 'text', 3, 'published', NOW()),
(1, '今天的训练记录', '今天完成了30分钟的手部训练，感觉有所进步...', '记录今天的康复训练情况', 'https://example.com/cover4.jpg', 'text', 4, 'published', NOW()),
(1, '康复训练视频教程', '这是一个详细的康复训练视频教程...', '视频教程：正确的康复训练方法', 'https://example.com/video_cover.jpg', 'video', 1, 'published', NOW()); 