//
//  AddExpenseView.swift
//  ExpenseTracker2.0
//
//  Created by Stavarache Victor on 30.07.2025.
//


import SwiftUI

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var amount = ""
    @State private var category = "Food"
    @State private var date = Date()
    
    let categories = ["Food", "Utilities", "Shopping", "Healthcare", "Travel", "Transport", "Housing", "Entertainment", "Other"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add New Expense")
                .font(.title3.bold())
            
            Form {
                TextField("Title", text: $title)
                TextField("Amount", text: $amount)
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    if let amountValue = Double(amount) {
                        let expense = Expense(
                            title: title,
                            amount: amountValue,
                            category: category,
                            date: date
                        )
                        modelContext.insert(expense)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty || Double(amount) == nil)
            }
        }
        .padding()
        .frame(width: 400, height: 280)
    }
}
