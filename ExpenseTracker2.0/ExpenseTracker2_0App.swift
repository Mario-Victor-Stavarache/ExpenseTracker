//
//  ExpenseTracker2_0App.swift
//  ExpenseTracker2.0
//
//  Created by Stavarache Victor on 30.07.2025.
//

import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .modelContainer(for: Expense.self)
    }
}
