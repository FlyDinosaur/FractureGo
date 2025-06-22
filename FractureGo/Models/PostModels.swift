import Foundation

// 帖子数据模型
struct Post: Identifiable, Codable {
    let id: Int
    let title: String
    let summary: String?
    let coverImage: String?
    let postType: String
    let videoUrl: String?
    let videoDuration: Int?
    let viewCount: Int
    let likeCount: Int
    let commentCount: Int
    let publishedAt: String
    let createdAt: String
    let author: PostAuthor
    let category: PostCategory?
}

// 帖子作者信息
struct PostAuthor: Identifiable, Codable {
    let id: Int
    let nickname: String
    let avatar: String?
}

// 帖子分类
struct PostCategory: Identifiable, Codable, Equatable {
    let id: Int?
    let name: String
    let color: String
    let icon: String?
    
    static func == (lhs: PostCategory, rhs: PostCategory) -> Bool {
        return lhs.id == rhs.id
    }
}

// API响应结构
struct PostsResponse: Codable {
    let success: Bool
    let message: String?
    let data: PostsData
}

struct PostsData: Codable {
    let posts: [Post]
    let pagination: Pagination
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

struct CategoriesResponse: Codable {
    let success: Bool
    let message: String?
    let data: [PostCategory]
}

struct LikeResponse: Codable {
    let success: Bool
    let message: String?
    let data: LikeData
}

struct LikeData: Codable {
    let isLiked: Bool
    let likeCount: Int
} 