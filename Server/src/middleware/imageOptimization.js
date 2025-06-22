const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;

// 图片优化中间件
const imageOptimization = async (req, res, next) => {
    try {
        // 只处理图片请求
        if (!req.path.match(/\.(jpg|jpeg|png|webp|gif)$/i)) {
            return next();
        }

        // 获取查询参数
        const { 
            width, 
            height, 
            quality = 80, 
            format,
            optimize = 'true' // 新增：是否启用优化
        } = req.query;
        
        // 如果明确指定不优化，直接返回原图
        if (optimize === 'false') {
            return next();
        }
        
        // 构建原始文件路径
        const originalPath = path.join(__dirname, '..', '..', 'uploads', req.path.replace('/uploads/', ''));
        
        // 检查原始文件是否存在
        try {
            await fs.access(originalPath);
        } catch (error) {
            console.log(`图片文件不存在: ${originalPath}`);
            return next(); // 文件不存在，继续到下一个中间件
        }

        // 检查文件大小，只优化大于1KB的文件
        const stats = await fs.stat(originalPath);
        const fileSizeKB = stats.size / 1024;
        
        // 如果文件太小且没有指定参数，直接返回原图
        if (fileSizeKB < 1 && !width && !height && !format) {
            return next();
        }

        // 生成缓存键
        const cacheKey = `${req.path}_w${width || 'auto'}_h${height || 'auto'}_q${quality}_f${format || 'original'}_opt${optimize}`;
        const cacheDir = path.join(__dirname, '..', '..', 'uploads', 'cache');
        const cachePath = path.join(cacheDir, cacheKey.replace(/[\/\\:*?"<>|]/g, '_'));

        // 确保缓存目录存在
        try {
            await fs.mkdir(cacheDir, { recursive: true });
        } catch (error) {
            console.error('创建缓存目录失败:', error);
        }

        // 检查缓存文件是否存在且不过期（7天）
        let useCache = false;
        try {
            const cacheStats = await fs.stat(cachePath);
            const cacheAge = Date.now() - cacheStats.mtime.getTime();
            const maxAge = 7 * 24 * 60 * 60 * 1000; // 7天
            
            if (cacheAge < maxAge) {
                useCache = true;
            } else {
                // 缓存过期，删除旧文件
                await fs.unlink(cachePath);
            }
        } catch (error) {
            // 缓存文件不存在，需要创建
        }

        let outputPath = cachePath;

        if (!useCache) {
            try {
                // 处理图片
                let sharpInstance = sharp(originalPath);
                
                // 获取原图信息
                const metadata = await sharpInstance.metadata();
                console.log(`处理图片: ${req.path}, 原始尺寸: ${metadata.width}x${metadata.height}, 格式: ${metadata.format}`);

                // 调整尺寸
                if (width || height) {
                    const targetWidth = width ? parseInt(width) : null;
                    const targetHeight = height ? parseInt(height) : null;
                    
                    sharpInstance = sharpInstance.resize(targetWidth, targetHeight, {
                        fit: 'inside',
                        withoutEnlargement: true,
                        background: { r: 255, g: 255, b: 255, alpha: 0 }
                    });
                }

                // 设置质量和格式
                const targetFormat = format || (metadata.format === 'png' ? 'png' : 'jpeg');
                const targetQuality = Math.max(10, Math.min(100, parseInt(quality)));
                
                switch (targetFormat.toLowerCase()) {
                    case 'jpg':
                    case 'jpeg':
                        sharpInstance = sharpInstance.jpeg({ 
                            quality: targetQuality,
                            progressive: true,
                            mozjpeg: true,
                            optimizeScans: true
                        });
                        break;
                    case 'png':
                        sharpInstance = sharpInstance.png({ 
                            quality: targetQuality,
                            compressionLevel: 9,
                            progressive: true,
                            palette: true
                        });
                        break;
                    case 'webp':
                        sharpInstance = sharpInstance.webp({ 
                            quality: targetQuality,
                            effort: 6,
                            lossless: false
                        });
                        break;
                    case 'avif':
                        sharpInstance = sharpInstance.avif({
                            quality: targetQuality,
                            effort: 4
                        });
                        break;
                    default:
                        // 默认使用JPEG，兼容性最好
                        sharpInstance = sharpInstance.jpeg({ 
                            quality: targetQuality,
                            progressive: true,
                            mozjpeg: true
                        });
                        break;
                }

                // 保存处理后的图片
                await sharpInstance.toFile(cachePath);
                
                const newStats = await fs.stat(cachePath);
                const compressionRatio = ((stats.size - newStats.size) / stats.size * 100).toFixed(1);
                console.log(`图片压缩完成: ${req.path}, 原始大小: ${(stats.size/1024).toFixed(1)}KB, 压缩后: ${(newStats.size/1024).toFixed(1)}KB, 压缩率: ${compressionRatio}%`);
                
            } catch (error) {
                console.error('图片处理失败:', error);
                // 处理失败时返回原图
                return next();
            }
        }

        // 设置正确的Content-Type
        const ext = format || path.extname(originalPath).slice(1).toLowerCase() || 'jpeg';
        const mimeTypes = {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'webp': 'image/webp',
            'avif': 'image/avif',
            'gif': 'image/gif'
        };
        
        const mimeType = mimeTypes[ext] || 'image/jpeg';
        
        // 设置响应头
        res.setHeader('Content-Type', mimeType);
        res.setHeader('Cache-Control', 'public, max-age=86400, immutable'); // 缓存24小时
        res.setHeader('Vary', 'Accept, Accept-Encoding');
        res.setHeader('X-Image-Optimized', useCache ? 'cached' : 'processed');
        res.setHeader('X-Original-Size', stats.size);
        
        // 添加压缩信息头
        if (!useCache) {
            const processedStats = await fs.stat(outputPath);
            res.setHeader('X-Compressed-Size', processedStats.size);
            res.setHeader('X-Compression-Ratio', ((stats.size - processedStats.size) / stats.size * 100).toFixed(1) + '%');
        }
        
        // 返回处理后的图片
        const imageBuffer = await fs.readFile(outputPath);
        res.send(imageBuffer);

    } catch (error) {
        console.error('图片优化中间件错误:', error);
        next(); // 出错时返回原图
    }
};

// 清理过期缓存的工具函数
const cleanExpiredCache = async () => {
    try {
        const cacheDir = path.join(__dirname, '..', '..', 'uploads', 'cache');
        const files = await fs.readdir(cacheDir);
        const maxAge = 7 * 24 * 60 * 60 * 1000; // 7天
        
        for (const file of files) {
            const filePath = path.join(cacheDir, file);
            const stats = await fs.stat(filePath);
            const age = Date.now() - stats.mtime.getTime();
            
            if (age > maxAge) {
                await fs.unlink(filePath);
                console.log(`清理过期缓存: ${file}`);
            }
        }
    } catch (error) {
        console.error('清理缓存失败:', error);
    }
};

// 每小时清理一次过期缓存
setInterval(cleanExpiredCache, 60 * 60 * 1000);

module.exports = { imageOptimization, cleanExpiredCache }; 