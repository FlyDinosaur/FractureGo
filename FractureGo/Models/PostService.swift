import Foundation

class PostService: ObservableObject {
    static let shared = PostService()
    private let databaseConfig = DatabaseConfig.shared
    
    private init() {}
    
    // 获取帖子列表
    func fetchPosts(
        page: Int = 1,
        limit: Int = 20,
        categoryId: Int? = nil,
        search: String? = nil,
        postType: String? = nil
    ) async throws -> PostsData {
        var endpoint = "/posts?page=\(page)&limit=\(limit)"
        
        if let categoryId = categoryId {
            endpoint += "&category_id=\(categoryId)"
        }
        
        if let search = search, !search.isEmpty {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        if let postType = postType {
            endpoint += "&post_type=\(postType)"
        }
        
        guard var request = databaseConfig.createURLRequest(for: endpoint, method: .GET) else {
            throw NetworkError.invalidResponse
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            databaseConfig.executeRequest(request: request, responseType: PostsResponse.self) { result in
                switch result {
                case .success(let response):
                    if response.success {
                        continuation.resume(returning: response.data)
                    } else {
                        continuation.resume(throwing: NetworkError.requestFailed(response.message ?? "获取帖子失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 获取分类列表
    func fetchCategories() async throws -> [PostCategory] {
        guard var request = databaseConfig.createURLRequest(for: "/posts/categories", method: .GET) else {
            throw NetworkError.invalidResponse
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            databaseConfig.executeRequest(request: request, responseType: CategoriesResponse.self) { result in
                switch result {
                case .success(let response):
                    if response.success {
                        continuation.resume(returning: response.data)
                    } else {
                        continuation.resume(throwing: NetworkError.requestFailed(response.message ?? "获取分类失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 点赞/取消点赞帖子
    func toggleLike(postId: Int) async throws -> LikeData {
        guard var request = databaseConfig.createURLRequest(for: "/posts/\(postId)/like", method: .POST) else {
            throw NetworkError.invalidResponse
        }
        
        // 添加用户认证信息
        databaseConfig.addAuthToken(to: &request)
        
        return try await withCheckedThrowingContinuation { continuation in
            databaseConfig.executeRequest(request: request, responseType: LikeResponse.self) { result in
                switch result {
                case .success(let response):
                    if response.success {
                        continuation.resume(returning: response.data)
                    } else {
                        continuation.resume(throwing: NetworkError.requestFailed(response.message ?? "点赞操作失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 获取帖子详情
    func fetchPostDetail(id: Int) async throws -> Post {
        guard var request = databaseConfig.createURLRequest(for: "/posts/\(id)", method: .GET) else {
            throw NetworkError.invalidResponse
        }
        
        // 添加用户认证信息（用于获取点赞状态）
        databaseConfig.addAuthToken(to: &request)
        
        return try await withCheckedThrowingContinuation { continuation in
            databaseConfig.executeRequest(request: request, responseType: PostDetailResponse.self) { result in
                switch result {
                case .success(let response):
                    if response.success {
                        continuation.resume(returning: response.data)
                    } else {
                        continuation.resume(throwing: NetworkError.requestFailed(response.message ?? "获取帖子详情失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 上传媒体文件
    func uploadMedia(_ data: Data, fileName: String, mimeType: String) async throws -> String {
        // 这里可以实现文件上传逻辑
        // 暂时返回一个占位符URL
        return "https://example.com/\(fileName)"
    }
    
    // MARK: - 兼容性方法（保持与ShareViewModel的兼容）
    
    // 简化的获取帖子方法
    func getPosts(page: Int, limit: Int, categoryId: String? = nil) async throws -> (posts: [Post], hasMore: Bool) {
        let categoryIdInt = categoryId.flatMap { Int($0) }
        let postsData = try await fetchPosts(page: page, limit: limit, categoryId: categoryIdInt)
        let hasMore = postsData.pagination.page < postsData.pagination.totalPages
        return (posts: postsData.posts, hasMore: hasMore)
    }
    
    // 简化的获取分类方法
    func getCategories() async throws -> [PostCategory] {
        return try await fetchCategories()
    }
}

// MARK: - 响应结构体

struct PostDetailResponse: Codable {
    let success: Bool
    let message: String?
    let data: Post
} 