//
//  DateExt.swift
//  DataSynchronization
//
//  Created by Ryan Smetana on 1/28/25.
//

import Foundation

extension Date {
    static let initialSync: Date = {
        // Define a default date if `lastSync` is nil
        let defaultDateString = "01/01/2025"
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.date(from: defaultDateString)!
    }()
}
