//
//  Theme.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/7/25.
//

import SwiftUI

struct AppTheme {
    static let customBackgroundColor = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let customTextColor = Color(red: 0.12, green: 0.12, blue: 0.15)
    static let customSecondaryTextColor = Color(red: 0.45, green: 0.45, blue: 0.50)
    static let customButtonTextColor = Color.white
}

extension Color {
    static let appBackground = AppTheme.customBackgroundColor
    static let appText = AppTheme.customTextColor
    static let appSecondaryText = AppTheme.customSecondaryTextColor
    static let appButtonText = AppTheme.customButtonTextColor
}