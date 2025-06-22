//
//  SignInView.swift
//  FractureGo
//
//  Created by FlyDinosaur on 2025/6/19.
//

import SwiftUI

// MARK: - 签到数据模型
struct SignInData {
    let year: Int
    let month: Int
    let signedDays: Set<Int>        // 已打卡日期
    let unsignedDays: Set<Int>      // 未打卡日期
    let giftDays: Set<Int>          // 礼盒日期
    let targetDays: Set<Int>        // 目标日期
    let continuousDays: Int         // 连续打卡天数
}

// MARK: - 主视图
struct SignInView: View {
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var showPicker = false
    
    // 示例数据 - 将来可从服务器获取
    @State private var signInData: SignInData = SignInData(
        year: Calendar.current.component(.year, from: Date()),
        month: Calendar.current.component(.month, from: Date()),
        signedDays: [6, 8, 9, 10, 11],
        unsignedDays: [7],
        giftDays: [13],
        targetDays: [24],
        continuousDays: 4
    )
    
    let greenColor = Color(red: 158/255, green: 205/255, blue: 87/255)
    let grayColor = Color(red: 0.8, green: 0.8, blue: 0.8)
    
    var body: some View {
        CalendarSignInCardView(
            selectedYear: $selectedYear,
            selectedMonth: $selectedMonth,
            showPicker: $showPicker,
            signInData: signInData,
            greenColor: greenColor,
            grayColor: grayColor,
            onDateChanged: { year, month in
                // 这里将来可以调用API获取指定年月的数据
                loadSignInData(for: year, month: month)
            }
        )
    }
    
    // MARK: - 数据加载方法
    private func loadSignInData(for year: Int, month: Int) {
        // TODO: 从服务器获取指定年月的签到数据
        // 示例：NetworkService.shared.getSignInData(year: year, month: month) { result in ... }
        print("加载 \(year)年\(month)月 的签到数据")
        
        // 暂时使用示例数据
        signInData = SignInData(
            year: year,
            month: month,
            signedDays: [6, 8, 9, 10, 11],
            unsignedDays: [7],
            giftDays: [13],
            targetDays: [24],
            continuousDays: 4
        )
    }
}

// MARK: - 日历签到卡片组件
struct CalendarSignInCardView: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    @Binding var showPicker: Bool
    
    let signInData: SignInData
    let greenColor: Color
    let grayColor: Color
    let onDateChanged: (Int, Int) -> Void
    
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
            Spacer()
        }
        .edgesIgnoringSafeArea(.top) // 让内容扩展到顶部
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
            .padding(.bottom, 8)
            
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
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
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