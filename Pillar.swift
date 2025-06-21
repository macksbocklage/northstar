//
//  Pillar.swift
//  northstar
//
//  Created by Max Bocklage on 6/19/25.
//

import Foundation
import SwiftData

@Model
final class Pillar: Identifiable {
    var id: String
    var title: String
    var emoji: String?
    var details: String?
    var createdAt: Date
    var subGoals: [SubGoal] = []
    
    init(title: String, emoji: String? = "⭐️", details: String? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.emoji = emoji
        self.details = details
        self.createdAt = Date()
    }
} 