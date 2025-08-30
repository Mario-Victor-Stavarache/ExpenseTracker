//
//  ContentView.swift
//  ExpenseTracker2.0
//
//  Created by Stavarache Victor on 30.07.2025.
//

import SwiftUI
import SwiftData

private struct MainToolbar: ToolbarContent {
    @Binding var showingAddSheet: Bool
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { showingAddSheet.toggle() }) {
                Label("Add Expense", systemImage: "plus")
            }
            .keyboardShortcut("n")
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Expense> { !$0.isArchived },
        sort: \Expense.date,
        order: .reverse
    ) private var expenses: [Expense]
    
    @State private var showingAddSheet = false
    @State private var editingExpense: Expense? = nil
    @State private var showingArchive = false
    
    var body: some View {
        NavigationSplitView {
            Group {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses",
                        systemImage: "list.bullet",
                        description: Text("Add your first expense")
                    )
                } else {
                    List {
                        ForEach(expenses) { expense in
                            ExpenseRowView(
                                expense: expense,
                                onEdit: { editingExpense = expense },
                                onDelete: { deleteExpense(expense) }
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteExpense(expense)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    archiveExpense(expense)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .animation(.default, value: expenses)
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet.toggle()
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .keyboardShortcut("n")
                }
                
                ToolbarItem(placement: .navigation) {
                    Button {
                        showingArchive = true
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                }
            }
        } detail: {
            ChartsView(expenses: expenses)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddExpenseView()
                .frame(minWidth: 400, minHeight: 300)
        }
        .sheet(item: $editingExpense) { expense in
            EditExpenseView(expense: expense)
                .frame(minWidth: 400, minHeight: 300)
        }
        .sheet(isPresented: $showingArchive) {
            ArchiveView()
                .frame(minWidth: 600, minHeight: 500)
        }
        .onAppear {
            autoArchiveOldExpenses()
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
            do {
                try modelContext.save()
            } catch {
                print("Failed to save after delete:", error.localizedDescription)
            }
        }
    }
    
    private func archiveExpense(_ expense: Expense) {
        withAnimation {
            expense.isArchived = true
            do {
                try modelContext.save()
            } catch {
                print("Failed to archive expense:", error.localizedDescription)
            }
        }
    }
    
    private func autoArchiveOldExpenses() {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        withAnimation {
            for expense in expenses where expense.date < oneWeekAgo {
                expense.isArchived = true
            }
            do {
                try modelContext.save()
            } catch {
                print("Failed to auto-archive expenses:", error.localizedDescription)
            }
        }
    }
}

// Archive View
struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Expense> { $0.isArchived },
        sort: \Expense.date,
        order: .reverse
    ) private var archivedExpenses: [Expense]
    
    @State private var selectedTimeRange: ArchiveTimeRange = .month
    @Environment(\.dismiss) private var dismiss
    
    enum ArchiveTimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .week:
            let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return archivedExpenses.filter { $0.date >= oneWeekAgo }
        case .month:
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return archivedExpenses.filter { $0.date >= oneMonthAgo }
        case .year:
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return archivedExpenses.filter { $0.date >= oneYearAgo }
        case .all:
            return archivedExpenses
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(ArchiveTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Statistics
                ArchiveStatsView(expenses: filteredExpenses)
                    .padding(.horizontal)
                
                // Archived expenses list
                if filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        "No Archived Expenses",
                        systemImage: "archivebox",
                        description: Text("Expenses older than 1 week are automatically archived")
                    )
                } else {
                    List {
                        ForEach(filteredExpenses) { expense in
                            ExpenseRowView(
                                expense: expense,
                                onEdit: nil,
                                onDelete: nil
                            )
                            .swipeActions(edge: .trailing) {
                                Button {
                                    restoreExpense(expense)
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.left")
                                }
                                .tint(.green)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Archived Expenses")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Restore All") {
                        restoreAllExpenses()
                    }
                    .disabled(archivedExpenses.isEmpty)
                }
            }
        }
    }
    
    private func restoreExpense(_ expense: Expense) {
        expense.isArchived = false
        try? modelContext.save()
    }
    
    private func restoreAllExpenses() {
        for expense in archivedExpenses {
            expense.isArchived = false
        }
        try? modelContext.save()
    }
}

// Archive Statistics View
struct ArchiveStatsView: View {
    let expenses: [Expense]
    
    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var averageDaily: Double {
        guard !expenses.isEmpty else { return 0 }
        let days = Set(expenses.map { Calendar.current.startOfDay(for: $0.date) }).count
        return totalSpent / Double(max(days, 1))
    }
    
    var categoryBreakdown: [String: Double] {
        Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Analysis")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatView(title: "Total", value: totalSpent, format: FloatingPointFormatStyle<Double>.Currency(code: "USD"))
                StatView(title: "Daily Avg", value: averageDaily, format: FloatingPointFormatStyle<Double>.Currency(code: "USD"))
                StatView(title: "Transactions", value: expenses.count, format: .number)
            }
            
            // Category breakdown
            if !categoryBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("By Category:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(categoryBreakdown.sorted(by: { $0.value > $1.value })), id: \.key) { category, amount in
                        HStack {
                            Text(category)
                                .font(.caption)
                            Spacer()
                            Text(amount, format: FloatingPointFormatStyle<Double>.Currency(code: "USD"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatView<Value: Comparable, Format: FormatStyle>: View where Format.FormatInput == Value, Format.FormatOutput == String {
    let title: String
    let value: Value
    let format: Format
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value, format: format)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }
}

#Preview("With Sample Data") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, configurations: config)
        
        let sampleExpenses = [
            Expense(title: "Coffee", amount: 3.50, category: "Food", date: .now),
            Expense(title: "Taxi", amount: 15.00, category: "Transport", date: .now.addingTimeInterval(-86400)),
            Expense(title: "Movie", amount: 12.50, category: "Entertainment", date: .now.addingTimeInterval(-172800)),
            Expense(title: "Groceries", amount: 45.75, category: "Food", date: .now.addingTimeInterval(-259200))
        ]
        
        sampleExpenses.forEach { container.mainContext.insert($0) }
        
        return ContentView()
            .modelContainer(container)
    } catch {
        fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
}

#Preview("Empty State") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, configurations: config)
        
        return ContentView()
            .modelContainer(container)
    } catch {
        fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
}

#Preview("Archive View") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, configurations: config)
        
        // Create archived expenses
        let archivedExpenses = [
            Expense(title: "Old Coffee", amount: 3.50, category: "Food", date: .now.addingTimeInterval(-86400 * 10), isArchived: true),
            Expense(title: "Old Taxi", amount: 15.00, category: "Transport", date: .now.addingTimeInterval(-86400 * 20), isArchived: true)
        ]
        
        archivedExpenses.forEach { container.mainContext.insert($0) }
        
        return ArchiveView()
            .modelContainer(container)
    } catch {
        fatalError("Failed to create preview container: \(error.localizedDescription)")
    }
}
