import Foundation
import SwiftUI

@MainActor
class ShareViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var categories: [PostCategory] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var currentUser: PostAuthor?
    
    private let postService = PostService.shared
    private let userManager = UserManager.shared
    
    private var currentPage = 1
    private var hasMorePages = true
    private var currentCategoryId: Int?
    private var currentSearchQuery: String?
    private var isLoadingMore = false
    
    init() {
        // 将 UserManager.UserData 转换为 PostAuthor
        if let userData = userManager.currentUser {
            currentUser = PostAuthor(
                id: 0, // 临时ID，实际应从用户系统获取
                nickname: userData.nickname,
                avatar: userData.wechatAvatarUrl
            )
        }
    }
    
    // 加载初始数据
    func loadInitialData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        // 减少重试机制，避免对服务器造成过大压力
        var retryCount = 0
        let maxRetries = 1  // 减少从3次到1次
        
        while retryCount <= maxRetries {
            do {
                print("🔄 开始加载ShareView数据，第\(retryCount + 1)次尝试")
                
                // 并行加载分类和帖子，增加超时时间
                async let categoriesTask = postService.fetchCategories()
                async let postsTask = postService.fetchPosts(page: 1, limit: 20)
                
                let (categories, postsData) = try await (categoriesTask, postsTask)
                
                self.categories = categories
                self.posts = postsData.posts
                self.currentPage = postsData.pagination.page
                self.hasMorePages = postsData.pagination.page < postsData.pagination.totalPages
                
                print("✅ ShareView数据加载成功")
                break // 成功加载，退出重试循环
                
            } catch {
                retryCount += 1
                print("🔄 ShareView数据加载失败，第\(retryCount)次尝试: \(error.localizedDescription)")
                
                if retryCount <= maxRetries {
                    // 更长的延迟时间，减少服务器压力
                    let delay = min(10.0 * Double(retryCount), 30.0)
                    print("⏱️ 将在\(delay)秒后重试加载数据...")
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    print("❌ 所有重试都失败，停止加载")
                    self.errorMessage = "加载失败，请检查网络连接后下拉刷新重试"
                }
            }
        }
        
        isLoading = false
    }
    
    // 刷新帖子列表
    func refreshPosts() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        currentPage = 1
        hasMorePages = true
        errorMessage = nil
        
        // 刷新时清空当前帖子列表，确保完全重新加载
        self.posts = []
        
        // 刷新时也减少重试机制，避免对服务器造成压力
        var retryCount = 0
        let maxRetries = 1  // 减少从2次到1次
        
        while retryCount <= maxRetries {
            do {
                print("🔄 开始刷新帖子数据，第\(retryCount + 1)次尝试")
                
                let postsData = try await postService.fetchPosts(
                    page: 1,
                    limit: 20,
                    categoryId: currentCategoryId,
                    search: currentSearchQuery
                )
                
                // 使用动画更新数据
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.posts = postsData.posts
                }
                
                self.currentPage = postsData.pagination.page
                self.hasMorePages = postsData.pagination.page < postsData.pagination.totalPages
                
                print("✅ 帖子数据刷新成功")
                break // 成功刷新，退出重试循环
                
            } catch {
                retryCount += 1
                print("🔄 帖子数据刷新失败，第\(retryCount)次尝试: \(error.localizedDescription)")
                
                if retryCount <= maxRetries {
                    // 刷新重试延迟更长
                    let delay = 15.0 * Double(retryCount)
                    print("⏱️ 将在\(delay)秒后重试刷新...")
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    print("❌ 刷新重试失败")
                    self.errorMessage = handleError(error)
                }
            }
        }
        
        isRefreshing = false
    }
    
    // 加载更多帖子
    func loadMorePosts() async {
        guard hasMorePages && !isLoadingMore && !isLoading && !isRefreshing else { return }
        
        isLoadingMore = true
        
        do {
            let postsData = try await postService.fetchPosts(
                page: currentPage + 1,
                limit: 20,
                categoryId: currentCategoryId,
                search: currentSearchQuery
            )
            
            // 去重并添加新帖子
            let existingIds = Set(self.posts.map { $0.id })
            let newPosts = postsData.posts.filter { !existingIds.contains($0.id) }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                self.posts.append(contentsOf: newPosts)
            }
            
            self.currentPage = postsData.pagination.page
            self.hasMorePages = postsData.pagination.page < postsData.pagination.totalPages
            
        } catch {
            // 加载更多失败时不显示错误弹窗，只在控制台输出
            print("加载更多帖子失败: \(error)")
        }
        
        isLoadingMore = false
    }
    
    // 按分类筛选
    func filterByCategory(_ category: PostCategory?) {
        currentCategoryId = category?.id
        Task {
            await refreshPosts()
        }
    }
    
    // 搜索帖子
    func searchPosts(query: String) {
        currentSearchQuery = query.isEmpty ? nil : query
        Task {
            await refreshPosts()
        }
    }
    
    // 错误处理
    private func handleError(_ error: Error) -> String {
        switch error {
        case NetworkError.noConnection:
            return "网络连接失败，请检查网络设置"
        case NetworkError.serverError:
            return "服务器错误，请稍后重试"
        case NetworkError.decodingError(let message):
            return "数据解析失败: \(message)"
        case NetworkError.unauthorized:
            return "用户认证失败，请重新登录"
        case NetworkError.forbidden:
            return "访问权限不足"
        case NetworkError.rateLimited:
            return "请求过于频繁，请稍后再试"
        case NetworkError.requestFailed(let message):
            return "请求失败: \(message)"
        case NetworkError.invalidResponse:
            return "服务器响应无效"
        case NetworkError.invalidData:
            return "数据格式错误"
        default:
            return "发生未知错误，请稍后重试"
        }
    }
    
    // 新增：计算图片显示尺寸的辅助函数
    func calculateImageAspectRatio(for post: Post) -> CGFloat {
        // 根据内容长度和类型动态计算高宽比
        let titleLength = post.title.count
        let summaryLength = post.summary?.count ?? 0
        
        // 基础高宽比
        var baseRatio: CGFloat = 1.0
        
        // 根据标题长度调整
        if titleLength > 50 {
            baseRatio += 0.1
        }
        
        // 根据内容长度调整  
        if summaryLength > 100 {
            baseRatio += 0.2
        }
        
        // 视频类型稍微高一些
        if post.postType == "video" {
            baseRatio += 0.1
        }
        
        // 使用帖子ID作为种子创建稳定的"随机"因子，避免抖动
        srand48(post.id) // 设置随机种子为帖子ID
        let stableRandomFactor = CGFloat(drand48() * 0.5 + 0.8) // 生成0.8-1.3之间的稳定值
        
        return min(max(baseRatio * stableRandomFactor, 0.7), 1.5) // 限制在合理范围内
    }
    
    // 计算帖子卡片的预计高度
    func calculateCardHeight(for post: Post, width: CGFloat) -> CGFloat {
        let imageRatio = calculateImageAspectRatio(for: post)
        let imageHeight = width * imageRatio
        
        // 估算文字部分高度
        let titleHeight: CGFloat = 60 // 标题约3行
        let authorHeight: CGFloat = 30 // 作者信息
        let padding: CGFloat = 20 // 内边距
        
        return imageHeight + titleHeight + authorHeight + padding
    }
}

// 图片缓存管理器
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100 // 限制缓存数量
        cache.totalCostLimit = 100 * 1024 * 1024 // 限制缓存大小为100MB
    }
    
    func getImage(for url: String) -> UIImage? {
        return cache.object(forKey: NSString(string: url))
    }
    
    func setImage(_ image: UIImage, for url: String) {
        cache.setObject(image, forKey: NSString(string: url))
    }
    
    func clearCache() {
        cache.removeAllObjects()
        
        // 清理AsyncImage的内置缓存
        URLCache.shared.removeAllCachedResponses()
        
        print("🧹 图片缓存已清理：NSCache + URLCache")
    }
}

@MainActor
class PostCardViewModel: ObservableObject {
    @Published var isLiked = false
    @Published var likeCount = 0
    
    private let postService = PostService.shared
    private var postId: Int?
    
    func setup(post: Post) {
        self.postId = post.id
        self.likeCount = post.likeCount
        // TODO: 从缓存或API获取当前用户的点赞状态
    }
    
    func toggleLike(for postId: Int) async {
        guard let _ = UserManager.shared.currentUser else {
            // 未登录用户需要先登录
            return
        }
        
        do {
            let likeData = try await postService.toggleLike(postId: postId)
            self.isLiked = likeData.isLiked
            self.likeCount = likeData.likeCount
        } catch {
            print("点赞操作失败: \(error)")
        }
    }
}

