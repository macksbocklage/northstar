import Foundation
import SwiftData

@Model
final class DailyAction: Identifiable {
    var id: UUID
    var title: String
    var date: Date
    var isCompleted: Bool
    var notes: String?
    
    var pillar: Pillar?
    
    init(title: String, date: Date, pillar: Pillar? = nil) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.isCompleted = false
        self.notes = nil
        self.pillar = pillar
    }
} 