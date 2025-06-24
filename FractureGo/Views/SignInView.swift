//
//  SignInView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI
import Combine

// MARK: - 签到数据模型
struct SignInData {
    let year: Int
    let month: Int
    let signedDays: Set<Int>        // 已打卡日期
    let unsignedDays: Set<Int>      // 未打卡日期 (暂时不使用，保持接口兼容性)
    let giftDays: Set<Int>          // 礼盒日期
    let targetDays: Set<Int>        // 目标日期
    let continuousDays: Int         // 连续打卡天数
}

// MARK: - 签到数据管理器
class SignInDataManager: ObservableObject {
    @Published var signInData: SignInData
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let currentDate = Date()
        let year = Calendar.current.component(.year, from: currentDate)
        let month = Calendar.current.component(.month, from: currentDate)
        
        // 初始化为空数据
        self.signInData = SignInData(
            year: year,
            month: month,
            signedDays: [],
            unsignedDays: [],
            giftDays: [],
            targetDays: [],
            continuousDays: 0
        )
        
        // 加载当前月份数据
        loadSignInData(for: year, month: month)
    }
    
    func loadSignInData(for year: Int, month: Int) {
        isLoading = true
        errorMessage = nil
        
        // 同时获取月度数据和统计数据
        let group = DispatchGroup()
        var monthlyData: SignInDataResponse?
        var statsData: SignInStatsResponse?
        var loadError: NetworkError?
        
        // 获取月度签到数据
        group.enter()
        networkService.getSignInData(year: year, month: month) { result in
            defer { group.leave() }
            switch result {
            case .success(let data):
                monthlyData = data
            case .failure(let error):
                loadError = error
            }
        }
        
        // 获取签到统计数据
        group.enter()
        networkService.getSignInStats { result in
            defer { group.leave() }
            switch result {
            case .success(let data):
                statsData = data
            case .failure(let error):
                if loadError == nil {
                    loadError = error
                }
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
            
            if let error = loadError {
                self.errorMessage = self.handleNetworkError(error)
                return
            }
            
            guard let monthly = monthlyData, let stats = statsData else {
                self.errorMessage = "数据加载失败"
                return
            }
            
            self.processSignInData(monthly: monthly, stats: stats)
        }
    }
    
    private func processSignInData(monthly: SignInDataResponse, stats: SignInStatsResponse) {
        var signedDays = Set<Int>()
        var giftDays = Set<Int>()
        var targetDays = Set<Int>()
        
        for record in monthly.signIns {
            signedDays.insert(record.day)
            
            switch record.signInType {
            case "gift":
                giftDays.insert(record.day)
            case "target":
                targetDays.insert(record.day)
            default:
                break // "normal" 类型不需要特殊处理
            }
        }
        
        signInData = SignInData(
            year: monthly.year,
            month: monthly.month,
            signedDays: signedDays,
            unsignedDays: [], // 不再使用
            giftDays: giftDays,
            targetDays: targetDays,
            continuousDays: stats.currentStreak
        )
    }
    
    private func handleNetworkError(_ error: NetworkError) -> String {
        switch error {
        case .      noConnection:
            return "网络连接失败，请检查网络设置"
        case .requestFailed(let message):
            return message
        case .decodingError(let message):
            return "数据解析失败: \(message)"
        case .invalidResponse:
            return "服务器响应异常"
        case .invalidData:
            return "数据格式错误"
        case .unauthorized:
            return "未授权访问，请重新登录"
        case .forbidden:
            return "访问被禁止"
        case .rateLimited:
            return "请求过于频繁，请稍后再试"
        case .serverError:
            return "服务器内部错误"
        }
    }
    
    func performSignIn(completion: @escaping (Bool, String) -> Void) {
        networkService.signIn { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // 签到成功，刷新当前月份数据
                    let currentDate = Date()
                    let year = Calendar.current.component(.year, from: currentDate)
                    let month = Calendar.current.component(.month, from: currentDate)
                    self.loadSignInData(for: year, month: month)
                    completion(true, response.message)
                case .failure(let error):
                    completion(false, self.handleNetworkError(error))
                }
            }
        }
    }
}

// MARK: - 主视图
struct SignInView: View {
    @StateObject private var dataManager = SignInDataManager()
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var showPicker = false
    
    let greenColor = Color(red: 158/255, green: 205/255, blue: 87/255)
    let grayColor = Color(red: 0.8, green: 0.8, blue: 0.8)
    
    var body: some View {
        CalendarSignInCardView(
            selectedYear: $selectedYear,
            selectedMonth: $selectedMonth,
            showPicker: $showPicker,
            signInData: dataManager.signInData,
            isLoading: dataManager.isLoading,
            errorMessage: dataManager.errorMessage,
            greenColor: greenColor,
            grayColor: grayColor,
            onDateChanged: { year, month in
                dataManager.loadSignInData(for: year, month: month)
            },
            onSignIn: {
                dataManager.performSignIn { success, message in
                    // 可以在这里显示签到结果
                    print("签到结果: \(success ? "成功" : "失败") - \(message)")
                }
            }
        )
    }
}

// MARK: - 日历签到卡片组件
struct CalendarSignInCardView: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var showPicker: Bool
    
    let signInData: SignInData
    let isLoading: Bool
    let errorMessage: String?
    let greenColor: Color
    let grayColor: Color
    let onDateChanged: (Int, Int) -> Void
    let onSignIn: () -> Void
    
    // 英文年月格式
    var monthYearString: String {
        let dateComponents = DateComponents(year: selectedYear, month: selectedMonth)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents) ?? Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack {
            // 整体内容加左右padding，避免贴边
            VStack(spacing: 0) {
                // 日历卡片
                CalendarCardComponent(
                    monthYearString: monthYearString,
                    selectedYear: selectedYear,
                    selectedMonth: selectedMonth,
                    signInData: signInData,
                    isLoading: isLoading,
                    greenColor: greenColor,
                    grayColor: grayColor,
                    showPicker: $showPicker
                )
                
                // 卡片下方内容
                CardBottomContentView(
                    continuousDays: signInData.continuousDays,
                    greenColor: greenColor
                )
            }
            .padding(.horizontal, 18) // 整体左右留白
            .padding(.top, 100) // 增大与顶部遮盖的间距
            
            // 错误信息显示
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
            }
            
            Spacer()
        }
        .background(Color(hex: "f5f5f0").ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showPicker) {
            YearMonthPickerView(
                selectedYear: $selectedYear,
                selectedMonth: $selectedMonth,
                showPicker: $showPicker,
                onDateChanged: onDateChanged
            )
        }
    }
}

// MARK: - 日历卡片组件
struct CalendarCardComponent: View {
    let monthYearString: String
    let selectedYear: Int
    let selectedMonth: Int
    let signInData: SignInData
    let isLoading: Bool
    let greenColor: Color
    let grayColor: Color
    @Binding var showPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部栏
            HStack {
                Button(action: { showPicker = true }) {
                    HStack(spacing: 4) {
                        Text(monthYearString)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
                Image("default_avator")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 24) // 年月与日历之间添加24pt间距
            
            // 日历头
            HStack(spacing: 0) {
                ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 6)
            .padding(.horizontal, 8)
            
            // 日历主体
            ZStack {
                CalendarGridView(
                    year: selectedYear,
                    month: selectedMonth,
                    signedDays: signInData.signedDays,
                    unsignedDays: signInData.unsignedDays,
                    giftDays: signInData.giftDays,
                    targetDays: signInData.targetDays,
                    greenColor: greenColor,
                    grayColor: grayColor
                )
                .opacity(isLoading ? 0.3 : 1.0)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .foregroundColor(greenColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 24) // 日历与卡片下缘添加24pt间距
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 0)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 卡片底部内容
struct CardBottomContentView: View {
    let continuousDays: Int
    let greenColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // 连续打卡天数
            HStack(spacing: 0) {
                Text("已连续打卡")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                Text("\(continuousDays)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.red)
                Text("天")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
            }
            .padding(.top, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 26)
            
            // 激励语和吉祥物
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("离恢复又")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundColor(greenColor)
                        .rotationEffect(.degrees(-12))
                        .padding(.bottom, -4)
                    Text("近了一步！")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundColor(greenColor)
                        .rotationEffect(.degrees(-12))
                }
                .padding(.leading, 8)
                Spacer(minLength: 8)
                Image("mascot2d")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 120)
                    .padding(.trailing, 8)
            }
            .padding(.top, 2)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - 日历网格视图
struct CalendarGridView: View {
    let year: Int
    let month: Int
    let signedDays: Set<Int>
    let unsignedDays: Set<Int>
    let giftDays: Set<Int>
    let targetDays: Set<Int>
    let greenColor: Color
    let grayColor: Color
    
    var daysInMonth: Int {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents) ?? Date()
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }
    
    var firstWeekday: Int {
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents) ?? Date()
        return calendar.component(.weekday, from: date) - 1 // 0=Sunday
    }
    
    // 检查某一天是否为已打卡
    func isSignedDay(_ day: Int) -> Bool {
        return signedDays.contains(day)
    }
    
    // 获取某行的连续已打卡段
    func getConsecutiveSignedSegments(for row: Int) -> [ClosedRange<Int>] {
        var segments: [ClosedRange<Int>] = []
        var start: Int? = nil
        
        for col in 0..<7 {
            let day = row * 7 + col - firstWeekday + 1
            let isValidDay = day > 0 && day <= daysInMonth
            let isSigned = isValidDay && isSignedDay(day)
            
            if isSigned {
                if start == nil {
                    start = col
                }
            } else {
                if let startCol = start {
                    segments.append(startCol...(col-1))
                    start = nil
                }
            }
        }
        
        // 处理行末的连续段
        if let startCol = start {
            segments.append(startCol...6)
        }
        
        return segments
    }
    
    var body: some View {
        let totalCells = daysInMonth + firstWeekday
        let rows = Int(ceil(Double(totalCells) / 7.0))
        VStack(spacing: 8) {
            ForEach(0..<rows, id: \.self) { row in
                ZStack {
                    // 绘制连续已打卡背景
                    let consecutiveSegments = getConsecutiveSignedSegments(for: row)
                    ForEach(consecutiveSegments.indices, id: \.self) { segmentIndex in
                        let segment = consecutiveSegments[segmentIndex]
                        if segment.count > 1 {
                            // 连续段用圆角矩形
                            RoundedRectangle(cornerRadius: 16)
                                .fill(greenColor)
                                .frame(height: 32)
                                .offset(x: CGFloat(segment.lowerBound + segment.upperBound - 6) * (UIScreen.main.bounds.width - 52) / 14, y: 0)
                                .frame(width: CGFloat(segment.count) * (UIScreen.main.bounds.width - 52) / 7)
                        }
                    }
                    
                    // 日期内容
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { col in
                            let day = row * 7 + col - firstWeekday + 1
                            Group {
                                if day > 0 && day <= daysInMonth {
                                    ZStack {
                                        // 单独的圆圈（非连续或未打卡）
                                        let consecutiveSegments = getConsecutiveSignedSegments(for: row)
                                        let isInConsecutiveSegment = consecutiveSegments.contains { segment in
                                            segment.contains(col) && segment.count > 1
                                        }
                                        
                                        if signedDays.contains(day) && !isInConsecutiveSegment {
                                            Circle()
                                                .fill(greenColor)
                                                .frame(width: 32, height: 32)
                                        } else if unsignedDays.contains(day) {
                                            Circle()
                                                .fill(grayColor)
                                                .frame(width: 32, height: 32)
                                        }
                                        
                                        if giftDays.contains(day) {
                                            Image("gift2d")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 22, height: 22)
                                        } else if targetDays.contains(day) {
                                            Image("star")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 22, height: 22)
                                        } else {
                                            Text("\(day)")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(signedDays.contains(day) || unsignedDays.contains(day) ? .white : .black)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                } else {
                                    Spacer().frame(maxWidth: .infinity, minHeight: 38)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 年月选择器
struct YearMonthPickerView: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var showPicker: Bool
    let onDateChanged: (Int, Int) -> Void
    
    var years: [Int] { (2020...2030).map { $0 } }
    var months: [Int] { (1...12).map { $0 } }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("年份", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text("\(year)年").tag(year)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 120)
                
                Picker("月份", selection: $selectedMonth) {
                    ForEach(months, id: \.self) { month in
                        Text("\(month)月").tag(month)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 120)
                
                Spacer()
            }
            .navigationTitle("选择年月")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showPicker = false
                        onDateChanged(selectedYear, selectedMonth)
                    }
                }
            }
        }
    }
}

// MARK: - 预览
#Preview {
    SignInView()
} 
