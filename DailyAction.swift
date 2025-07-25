import Foundation
import SwiftData

enum ActionStatus: String, Codable {
    case notLogged = "not_logged"
    case completed = "completed"
    case incomplete = "incomplete"
}

@Model
final class DailyAction: Identifiable {
    var id: UUID
    var title: String
    var date: Date
    var status: String // Will store ActionStatus.rawValue
    var notes: String?
    
    var pillar: Pillar?
    
    init(title: String, date: Date, pillar: Pillar? = nil) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.status = ActionStatus.notLogged.rawValue
        self.notes = nil
        self.pillar = pillar
    }
    
    var actionStatus: ActionStatus {
        get {
            ActionStatus(rawValue: status) ?? .notLogged
        }
        set {
            status = newValue.rawValue
        }
    }
    
    var isCompleted: Bool {
        actionStatus == .completed
    }
    
    var isLogged: Bool {
        actionStatus != .notLogged
    }
} 