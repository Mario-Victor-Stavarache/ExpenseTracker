//
//  Expense.swift
//  ExpenseTracker2.0
//
//  Created by Stavarache Victor on 30.07.2025.
//

import SwiftData
import Foundation

@Model
final class Expense {
    var title: String
    var amount: Double
    var category: String
    var date: Date
    var isArchived: Bool = false
    
    init(title: String, amount: Double, category: String, date: Date, isArchived: Bool = false) {
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.isArchived = isArchived
    }
}

// The following comments are supposed to offer a clear sight upon the duration of making this project.
// This project was finished on 31.08.2025.
// From the date that the files were created (the date when I started to work on the project), until the 31.08.2025 I have also taken a break from working on this project for more than a half of the month of August.
