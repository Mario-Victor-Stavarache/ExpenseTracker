//
//  ExpenseRowView.swift
//  ExpenseTracker2.0
//
//  Created by Stavarache Victor on 30.07.2025.
//


import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @State private var isHovering = false
    @State private var gradientAngle: Double = 0
    
    private var gradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [.red, .green, .blue, .red]),
            center: .center,
            angle: .degrees(gradientAngle)
        )
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(expense.title)
                    .font(.headline)
                Text(expense.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(expense.amount, format: .currency(code: "USD"))
                .foregroundColor(expense.amount < 0 ? .red : .green)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                if isHovering {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(gradient)
                        .opacity(0.15)
                        .blur(radius: 1)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                colors: [.red, .green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                }
            }
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
            if hovering {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    gradientAngle = 360
                }
            } else {
                withAnimation {
                    gradientAngle = 0
                }
            }
        }
        .contextMenu {
            Button("Edit") {
                onEdit?()
            }
            Divider()
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit?()
        }
    }
}

#Preview {
    ExpenseRowView(
        expense: Expense(
            title: "Sample",
            amount: 19.99,
            category: "Food",
            date: Date()
        ),
        onEdit: { print("Edit pressed") },
        onDelete: { print("Delete pressed") }
    )
    .padding()
    .frame(width: 300)
}
