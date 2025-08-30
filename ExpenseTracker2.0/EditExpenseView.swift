//
//  EditExpenseView.swift
//  ExpenseTracker2.0
//
//  Created by Stavarache Victor on 06.08.2025.
//


import SwiftUI

struct EditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var expense: Expense
    
    let categories = ["Food", "Transport", "Housing", "Entertainment", "Other"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Expense")
                .font(.title3.bold())
            
            Form {
                TextField("Title", text: $expense.title)
                TextField("Amount", value: $expense.amount, format: .number)
                Picker("Category", selection: $expense.category) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
                DatePicker("Date", selection: $expense.date, displayedComponents: .date)
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    do {
                        try modelContext.save()
                        dismiss()
                    } catch {
                        print("Failed to save expense:", error.localizedDescription)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(expense.title.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 280)
    }
}
