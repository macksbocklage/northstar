//
//  SubGoal.swift
//  northstar
//
//  Created by Max Bocklage on 6/19/25.
//

import Foundation
import SwiftData

@Model
final class SubGoal: Identifiable {
    var id: String
    var title: String
    var createdAt: Date
    var pillar: Pillar?
    
    init(title: String, pillar: Pillar? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.pillar = pillar
        self.createdAt = Date()
    }
} 