//
//  ChartsView.swift
//  ExpenseTracker2.0
//
//  Created by Stavarache Victor on 06.08.2025.
//

import SwiftUI
import Charts

extension Color {
    static func byCategory(_ category: String) -> Color {
        let colorMap: [String: Color] = [
            "Food": .orange,
            "Transport": .blue,
            "Entertainment": .purple,
            "Shopping": .green,
            "Utilities": .yellow,
            "Healthcare": .red,
            "Travel": .teal,
            "Housing": .mint,
            "Other": .gray,
        ]
        return colorMap[category] ?? random
    }
    
    static var random: Color {
        Color(
            red: Double.random(in: 0.3...0.8),
            green: Double.random(in: 0.3...0.8),
            blue: Double.random(in: 0.3...0.8)
        )
    }
}

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadius: CGFloat = 0.6
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * innerRadius
        
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addLine(to: CGPoint(
            x: center.x + innerRadius * cos(endAngle.radians),
            y: center.y + innerRadius * sin(endAngle.radians)
        ))
        path.addArc(center: center, radius: innerRadius,
                    startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        
        return path
    }
}

private struct CategoryLegend: View {
    let categories: [String]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 28) {
            ForEach(categories, id: \.self) { category in
                HStack(spacing: 6) {
                    Circle()
                        .fill(
                            Color.byCategory(category)
                                .opacity(colorScheme == .dark ? 0.9 : 1.0)
                        )
                        .frame(width: 12, height: 12)
                    Text(category)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(8)
    }
}

private struct CategoryTooltipView: View {
    let category: String
    let expenses: [Expense]
    let total: Double
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(
                        Color.byCategory(category)
                            .opacity(colorScheme == .dark ? 0.9 : 1.0)
                    )
                    .frame(width: 10, height: 10)
                Text(category)
                    .font(.headline)
            }
            
            Divider()
            
            ForEach(expenses) { expense in
                HStack(spacing: 10) {
                    Circle()
                        .fill(
                            Color.byCategory(category)
                                .opacity(colorScheme == .dark ? 0.9 : 1.0)
                        )
                        .frame(width: 6, height: 6)
                    Text(expense.title)
                    Spacer()
                    Text(expense.amount, format: .currency(code: "USD"))
                        .foregroundColor(expense.amount < 0 ? .red : .green)
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .bold()
                Spacer()
                Text(total, format: .currency(code: "USD"))
                    .bold()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(radius: 5)
        )
        .frame(width: 220)
    }
}

// Main ChartsView struct
struct ChartsView: View {
    let expenses: [Expense]
    @Environment(\.colorScheme) private var colorScheme
    @State private var hoveredCategory: String? = nil
    @State private var tooltipPosition: CGPoint = .zero
    @State private var viewSize: CGSize = .zero
    
    // Calculate angles for each category
    private var categoryAngles: [(category: String, startAngle: Double, endAngle: Double)] {
        let total = expenses.reduce(0) { $0 + $1.amount }
        var angles: [(String, Double, Double)] = []
        var currentAngle: Double = 0
        
        for expense in expenses {
            let angle = 360 * (expense.amount / total)
            angles.append((expense.category, currentAngle, currentAngle + angle))
            currentAngle += angle
        }
        
        return angles
    }
    
    private var nonArchivedExpenses: [Expense] {
        expenses.filter { !$0.isArchived }
    }
    
    var body: some View {
        TabView {
            pieChartTab
            barChartTab
        }
        .frame(width: 600, height: 400)
    }
    
    // Extracted pie chart view
    private var pieChartTab: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(Array(categoryAngles.enumerated()), id: \.offset) { index, angleData in
                    PieSlice(startAngle: .degrees(angleData.startAngle),
                             endAngle: .degrees(angleData.endAngle),
                             innerRadius: 0.6)
                    .fill(
                        hoveredCategory == angleData.category ?
                        AnyShapeStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.byCategory(angleData.category),
                                    Color.byCategory(angleData.category).opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) :
                        AnyShapeStyle(Color.byCategory(angleData.category))
                    )
                    .opacity(colorScheme == .dark ? 0.9 : 1.0)
                    .scaleEffect(hoveredCategory == angleData.category ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hoveredCategory)
                }
                .frame(width: 300, height: 300)
                
                // Mouse tracking area
                GeometryReader { geometry in
                    Color.clear
                        .contentShape(Circle().size(width: 300, height: 300)) // Constrain to pie chart area
                        .onContinuousHover { phase in
                            let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                            let radius: CGFloat = 150
                            
                            switch phase {
                            case .active(let location):
                                let dx = location.x - center.x
                                let dy = location.y - center.y
                                let distance = sqrt(dx*dx + dy*dy)
                                
                                if distance <= radius {
                                    let positionChanged = abs(location.x - tooltipPosition.x) > 2 || abs(location.y - tooltipPosition.y) > 2
                                    if positionChanged {
                                        tooltipPosition = location
                                        handleHover(at: location, in: geometry.size)
                                    }
                                } else {
                                    // Mouse outside pie chart - clear hover state
                                    if hoveredCategory != nil {
                                        hoveredCategory = nil
                                    }
                                }
                                
                            case .ended:
                                if hoveredCategory != nil {
                                    hoveredCategory = nil
                                }
                            }
                        }
                        .onAppear { viewSize = geometry.size }
                }
                // Tooltip
                if let category = hoveredCategory {
                    let categoryExpenses = nonArchivedExpenses.filter { $0.category == category }
                    let total = categoryExpenses.reduce(0) { $0 + $1.amount }
                    
                    CategoryTooltipView(
                        category: category,
                        expenses: categoryExpenses,
                        total: total
                    )
                    .position(
                        x: min(max(tooltipPosition.x, 200), viewSize.width - 200),
                        y: min(max(tooltipPosition.y - 60, 60), viewSize.height - 300)
                    )
                }
            }
            
            // Category legend
            CategoryLegend(categories: Array(Set(nonArchivedExpenses.map(\.category)).sorted()))
        }
        .padding()
        .tabItem { Label("Categories", systemImage: "chart.pie") }
    }
    
    // Extracted bar chart view
    private var barChartTab: some View {
        VStack {
            Chart(lastWeekExpenses) { expense in
                BarMark(
                    x: .value("Date", expense.date, unit: .day),
                    y: .value("Amount", expense.amount)
                )
                .foregroundStyle(by: .value("Category", expense.category))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.day().month(.abbreviated))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 300)
            .padding()
            
            Text("Showing expenses from the past 7 days")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .tabItem { Label("Timeline", systemImage: "chart.bar") }
    }

    private var lastWeekExpenses: [Expense] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return expenses.filter { expense in
            !expense.isArchived && expense.date >= oneWeekAgo
        }
    }
    
    private func handleHover(at location: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let radius = min(size.width, size.height) * 0.4
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx*dx + dy*dy)
        
        guard distance <= radius else {
            hoveredCategory = nil
            return
        }
        
        var angle = atan2(dy, dx) * 180 / .pi
        if angle < 0 { angle += 360 }
        
        for (category, start, end) in categoryAngles {
            if angle >= start && angle < end {
                hoveredCategory = category
                return
            }
        }
        
        hoveredCategory = nil
    }
}
