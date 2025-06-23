//
//  ShareView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

struct ShareView: View {
    @StateObject private var viewModel = ShareViewModel()
    @State private var selectedCategory: PostCategory?
    @State private var showRefreshSuccess = false
    @State private var pullToRefreshOffset: CGFloat = 0
    @State private var isRefreshTriggered = false
    @State private var isDragging = false
    @State private var scrollOffset: CGFloat = 0
    
    private let refreshThreshold: CGFloat = 80 // 触发刷新的阈值
    private let themeColor = Color.black // 松手刷新颜色改为黑色
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color(hex: "f5f5f0").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 自定义下拉刷新指示器
                    CustomPullToRefreshHeader(
                        offset: pullToRefreshOffset,
                        isRefreshing: viewModel.isRefreshing,
                        threshold: refreshThreshold,
                        isDragging: isDragging,
                        themeColor: themeColor
                    )
                    .frame(height: max(0, pullToRefreshOffset))
                    .clipped()
                    
                    // 内容区域
                    ZStack {
                        ScrollView {
                            LazyVStack(spacing: 0, pinnedViews: []) {
                                // 两列瀑布流内容 - 使用自定义布局
                                WaterfallLayout(posts: viewModel.posts, geometry: geometry)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
                                // 加载更多指示器
                                if viewModel.isLoading {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: themeColor))
                                        Text("加载中...")
                                            .font(.caption)
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                }
                            }
                            .background(
                                GeometryReader { scrollGeometry in
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeometry.frame(in: .named("scroll")).minY)
                                }
                            )
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            scrollOffset = value
                            handleScrollOffset(value)
                        }
                        .refreshable {
                            // 空实现，禁用默认的下拉刷新
                        }
                        
                        // 透明的拖拽检测层
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(coordinateSpace: .global)
                                    .onChanged { value in
                                        handleDragChanged(value)
                                    }
                                    .onEnded { value in
                                        handleDragEnded(value)
                                    }
                            )
                    }
                }
                
                // 灵动岛风格的刷新成功提示
                VStack {
                    RefreshSuccessIndicator(isVisible: $showRefreshSuccess, themeColor: themeColor)
                        .padding(.top, geometry.safeAreaInsets.top + 8)
                        .zIndex(1000) // 确保在最顶层
                    Spacer()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadInitialData()
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private func handleScrollOffset(_ offset: CGFloat) {
        // 更新滚动偏移量，但不直接影响下拉刷新
        scrollOffset = offset
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        // 只有在滚动视图顶部且向下拖拽时才处理下拉刷新
        let translation = value.translation.height
        
        if scrollOffset >= -5 && translation > 0 && !viewModel.isRefreshing {
            isDragging = true
            
            // 使用阻尼效果，让拖拽感觉更自然
            let dampingFactor: CGFloat = 0.5
            let adjustedTranslation = translation * dampingFactor
            
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                pullToRefreshOffset = min(adjustedTranslation, refreshThreshold + 30)
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        isDragging = false
        
        if pullToRefreshOffset >= refreshThreshold && !viewModel.isRefreshing {
            // 触发刷新
            isRefreshTriggered = true
            triggerRefresh()
        } else {
            // 没有达到阈值，回弹
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                pullToRefreshOffset = 0
            }
        }
    }
    
    private func triggerRefresh() {
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            await viewModel.refreshPosts()
            
            DispatchQueue.main.async {
                // 刷新完成后的动画
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    pullToRefreshOffset = 0
                }
                
                // 刷新成功后显示提示（只有在没有错误且有数据时）
                if viewModel.errorMessage == nil && !viewModel.posts.isEmpty {
                    // 触觉反馈
                    let successFeedback = UIImpactFeedbackGenerator(style: .light)
                    successFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showRefreshSuccess = true
                    }
                    // 2.5秒后自动隐藏
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showRefreshSuccess = false
                        }
                    }
                }
                
                isRefreshTriggered = false
            }
        }
    }
}

// 自定义下拉刷新头部组件
struct CustomPullToRefreshHeader: View {
    let offset: CGFloat
    let isRefreshing: Bool
    let threshold: CGFloat
    let isDragging: Bool
    let themeColor: Color
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack {
            if offset > 5 { // 增加一个小的阈值避免闪烁
                HStack(spacing: 12) {
                    // 刷新图标
                    ZStack {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: themeColor))
                        } else {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(themeColor)
                                .rotationEffect(.degrees(rotationAngle))
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: rotationAngle)
                        }
                    }
                    .frame(width: 24, height: 24)
                    
                    // 提示文字
                    VStack(alignment: .leading, spacing: 4) {
                        Text(refreshText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        // 进度指示器
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(themeColor.opacity(0.2))
                                .frame(width: 120, height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(themeColor)
                                .frame(width: 120 * min(offset / threshold, 1.0), height: 4)
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: offset)
                        }
                    }
                }
                .padding(.vertical, 12)
                .opacity(min(offset / 20.0, 1.0)) // 渐入效果
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: offset) { oldValue, newValue in
            updateRotation(for: newValue)
        }
    }
    
    private var refreshText: String {
        if isRefreshing {
            return "正在刷新..."
        } else if offset >= threshold {
            return "松手即可刷新"
        } else {
            return "下拉刷新"
        }
    }
    
    private func updateRotation(for offset: CGFloat) {
        if !isRefreshing {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if offset >= threshold {
                    rotationAngle = 180 // 箭头向上
                } else {
                    rotationAngle = 0 // 箭头向下
                }
            }
        }
    }
}

// 滚动偏移量监听
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 灵动岛风格的刷新成功指示器
struct RefreshSuccessIndicator: View {
    @Binding var isVisible: Bool
    let themeColor: Color
    @State private var animationPhase = 0
    @State private var breathingScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        if isVisible {
            HStack(spacing: 10) {
                // 刷新图标
                ZStack {
                    // 背景光圈
                    Circle()
                        .fill(themeColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .scaleEffect(breathingScale)
                        .opacity(glowOpacity)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeColor)
                        .font(.system(size: 16, weight: .semibold))
                        .scaleEffect(animationPhase == 1 ? 1.1 : 1.0)
                }
                
                // 成功文字
                Text("帖子已刷新")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .opacity(animationPhase >= 1 ? 1.0 : 0.7)
                
                // 活动指示器
                ZStack {
                    Circle()
                        .fill(themeColor.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .scaleEffect(animationPhase == 2 ? 2.0 : 0.8)
                        .opacity(animationPhase == 2 ? 0 : 1)
                    
                    Circle()
                        .fill(themeColor)
                        .frame(width: 4, height: 4)
                        .scaleEffect(breathingScale * 0.8)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                // 灵动岛风格背景
                Capsule()
                    .fill(.ultraThinMaterial)
                    .background(
                        Capsule()
                            .fill(.black.opacity(0.8))
                    )
                    .overlay(
                        // 边框光晕
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [themeColor.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .opacity(glowOpacity)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
                    .shadow(color: themeColor.opacity(0.3), radius: 6, x: 0, y: 0)
            )
            .scaleEffect(isVisible ? 1.0 : 0.3)
            .opacity(isVisible ? 1.0 : 0)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.3).combined(with: .opacity).combined(with: .move(edge: .top)),
                removal: .scale(scale: 0.8).combined(with: .opacity)
            ))
            .onAppear {
                // 入场动画序列
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                    animationPhase = 1
                    glowOpacity = 0.8
                }
                
                // 呼吸效果
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    breathingScale = 1.15
                }
                
                // 脉冲效果
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        animationPhase = 2
                    }
                }
                
                // 重置动画状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        animationPhase = 0
                        glowOpacity = 0.4
                    }
                }
            }
            .onChange(of: isVisible) { oldValue, newValue in
                if !newValue {
                    // 离场时停止所有动画
                    withAnimation(.none) {
                        breathingScale = 1.0
                        glowOpacity = 0
                        animationPhase = 0
                    }
                }
            }
        }
    }
}

// 智能瀑布流布局
struct WaterfallLayout: View {
    let posts: [Post]
    let geometry: GeometryProxy
    @StateObject private var viewModel = ShareViewModel()
    @StateObject private var layoutHelper = WaterfallLayoutHelper()
    
    var body: some View {
        let spacing: CGFloat = 8
        let availableWidth = geometry.size.width - 32 // 减去padding
        let itemWidth = (availableWidth - spacing) / 2.0
        
        HStack(alignment: .top, spacing: spacing) {
            // 左列
            LazyVStack(spacing: spacing) {
                ForEach(leftColumnPosts, id: \.id) { post in
                    PostCard(
                        post: post, 
                        width: itemWidth,
                        aspectRatio: viewModel.calculateImageAspectRatio(for: post)
                    )
                    .onAppear {
                        // 预加载逻辑
                        if shouldLoadMore(for: post) {
                            Task {
                                await viewModel.loadMorePosts()
                            }
                        }
                    }
                }
            }
            
            // 右列
            LazyVStack(spacing: spacing) {
                ForEach(rightColumnPosts, id: \.id) { post in
                    PostCard(
                        post: post, 
                        width: itemWidth,
                        aspectRatio: viewModel.calculateImageAspectRatio(for: post)
                    )
                    .onAppear {
                        // 预加载逻辑
                        if shouldLoadMore(for: post) {
                            Task {
                                await viewModel.loadMorePosts()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            layoutHelper.reset()
        }
    }
    
    // 智能分配到左右列，基于高度平衡
    private var leftColumnPosts: [Post] {
        var leftPosts: [Post] = []
        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0
        
        for post in posts {
            let cardHeight = viewModel.calculateCardHeight(for: post, width: (geometry.size.width - 40) / 2)
            
            if leftHeight <= rightHeight {
                leftPosts.append(post)
                leftHeight += cardHeight + 8 // 包含间距
            } else {
                rightHeight += cardHeight + 8
            }
        }
        
        return leftPosts
    }
    
    private var rightColumnPosts: [Post] {
        let leftSet = Set(leftColumnPosts.map { $0.id })
        return posts.filter { !leftSet.contains($0.id) }
    }
    
    private func shouldLoadMore(for post: Post) -> Bool {
        guard let lastPost = posts.last else { return false }
        return post.id == lastPost.id
    }
}

// 改进的异步图片组件
struct OptimizedAsyncImage: View {
    let url: String
    let aspectRatio: CGFloat?
    let width: CGFloat
    
    @State private var isLoading = true
    @State private var hasError = false
    @State private var loadAttempts = 0
    @State private var urlRequest: URLRequest?
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                // 加载中状态
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(width: width, height: width * 0.8) // 默认宽高比
                    .overlay(
                        VStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("加载中")
                                .font(.caption2)
                                .foregroundColor(.black)
                        }
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 8,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 8
                        )
                    )
                    .onAppear { 
                        isLoading = true 
                        hasError = false
                    }
                    
            case .success(let image):
                // 成功加载
                GeometryReader { imageGeometry in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: calculateImageHeight(image: image, targetWidth: width))
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 8,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 8
                            )
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
                .frame(width: width, height: calculateImageHeight(image: image, targetWidth: width))
                .onAppear {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isLoading = false
                        hasError = false
                    }
                }
                    
            case .failure(_):
                // 加载失败 - 尝试重新加载
                Button(action: retryLoad) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: width, height: width * 0.8)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: hasError ? "arrow.clockwise" : "photo")
                                    .foregroundColor(.gray)
                                    .font(.title3)
                                Text(hasError ? "点击重试" : "加载失败")
                                    .font(.caption2)
                                    .foregroundColor(.black)
                            }
                        )
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 8,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 8
                            )
                        )
                }
                .onAppear { 
                    hasError = true
                    // 增加自动重试次数和延迟
                    if loadAttempts < 5 {
                        let delay = min(pow(2.0, Double(loadAttempts)), 10.0) // 指数退避，最大10秒
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            retryLoad()
                        }
                    }
                }
                    
            @unknown default:
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: width, height: width * 0.8)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 8,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 8
                        )
                    )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
    
    private func retryLoad() {
        loadAttempts += 1
        isLoading = true
        hasError = false
    }
    
    private func calculateImageHeight(image: Image, targetWidth: CGFloat) -> CGFloat {
        // 使用传入的aspectRatio计算高度
        if let aspectRatio = aspectRatio {
            return targetWidth * aspectRatio
        }
        // 如果没有指定aspectRatio，使用合理的默认高度
        return targetWidth * 1.0
    }
}

// 帖子卡片
struct PostCard: View {
    let post: Post
    let width: CGFloat
    let aspectRatio: CGFloat
    @StateObject private var viewModel = PostCardViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面图片
            ZStack {
                OptimizedAsyncImage(
                    url: getOptimizedImageURL(post.coverImage, width: Int(width * 2)), // 2x for retina
                    aspectRatio: aspectRatio,
                    width: width
                )
                
                // 视频播放图标
                if post.postType == "video" {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.6))
                                    .frame(width: 35, height: 35)
                                
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            }
                            .padding(6)
                        }
                    }
                }
            }
            
            // 标题
            Text(post.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // 作者信息
            HStack(spacing: 6) {
                // 作者头像
                AsyncImage(url: URL(string: getOptimizedImageURL(post.author.avatar, width: 48, quality: 85))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image("default_avator")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: 0.5)
                )
                
                // 作者昵称
                Text(post.author.nickname)
                    .font(.caption)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Spacer()
                
                // 分类标签（仅显示，不可点击）
                if let category = post.category {
                    Text(category.name)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(hex: category.color).opacity(0.1))
                        .foregroundColor(Color(hex: category.color))
                        .cornerRadius(3)
                }
            }
        }
        .padding(10)
        .background(Color.clear)
        .cornerRadius(10)
        .onAppear {
            viewModel.setup(post: post)
        }
    }
}

// 优化的图片URL构建函数，支持更好的错误处理
func getOptimizedImageURL(_ imagePath: String?, width: Int = 400, quality: Int = 80) -> String {
    guard let imagePath = imagePath, !imagePath.isEmpty else { return "" }
    
    // 如果已经是完整URL，直接返回
    if imagePath.hasPrefix("http://") || imagePath.hasPrefix("https://") {
        return imagePath
    }
    
    // 构建完整URL
    let baseURL = "http://117.72.161.6:28974"
    var fullURL = ""
    
    // 如果路径以/开头，直接拼接
    if imagePath.hasPrefix("/") {
        fullURL = baseURL + imagePath
    } else {
        // 否则添加/uploads/前缀
        fullURL = baseURL + "/uploads/" + imagePath
    }
    
    // 添加优化参数，使用jpeg而不是webp以提高兼容性
    var queryParams: [String] = []
    queryParams.append("width=\(width)")
    queryParams.append("quality=\(quality)")
    queryParams.append("format=jpeg") // 使用JPEG提高兼容性
    
    if !queryParams.isEmpty {
        fullURL += "?" + queryParams.joined(separator: "&")
    }
    
    return fullURL
}

#Preview {
    ShareView()
} 