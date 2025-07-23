import SwiftUI
import SwiftData
import Foundation

struct SampleDataGenerator {
    static func generateWeekOfData(modelContext: ModelContext, pillars: [Pillar]) {
        let calendar = Calendar.current
        let today = Date()
        
        // Generate actions for the past 7 days
        for dayOffset in 0...6 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // Create 1-3 actions per day, randomly distributed across pillars
            let actionsCount = Int.random(in: 1...3)
            let shuffledPillars = pillars.shuffled()
            
            for actionIndex in 0..<min(actionsCount, pillars.count) {
                let pillar = shuffledPillars[actionIndex]
                let action = createSampleAction(for: pillar, date: date, dayOffset: dayOffset)
                modelContext.insert(action)
            }
        }
        
        try? modelContext.save()
    }
    
    private static func createSampleAction(for pillar: Pillar, date: Date, dayOffset: Int) -> DailyAction {
        let sampleActions = getSampleActions(for: pillar)
        let randomAction = sampleActions.randomElement() ?? "Work on \(pillar.title)"
        
        let action = DailyAction(title: randomAction, date: date, pillar: pillar)
        
        // Higher chance of completion for more recent days
        let completionChance = dayOffset < 3 ? 0.8 : 0.6
        action.isCompleted = Double.random(in: 0...1) < completionChance
        
        // Add notes sometimes
        if Double.random(in: 0...1) < 0.3 {
            action.notes = getSampleNote(for: pillar)
        }
        
        return action
    }
    
    private static func getSampleActions(for pillar: Pillar) -> [String] {
        let title = pillar.title.lowercased()
        
        if title.contains("health") || title.contains("fitness") || title.contains("wellness") {
            return [
                "30-minute morning workout",
                "Meal prep for the week",
                "Evening meditation session",
                "Go for a nature walk",
                "Yoga and stretching",
                "Prepare healthy breakfast",
                "Drink 8 glasses of water",
                "Get 8 hours of sleep"
            ]
        } else if title.contains("career") || title.contains("work") || title.contains("business") {
            return [
                "Complete project milestone",
                "Network with industry peers",
                "Learn new skill online",
                "Update LinkedIn profile",
                "Review quarterly goals",
                "Prepare for client meeting",
                "Write technical documentation",
                "Attend professional workshop"
            ]
        } else if title.contains("relationship") || title.contains("family") || title.contains("social") {
            return [
                "Call family member",
                "Plan date night",
                "Meet friend for coffee",
                "Write thank you note",
                "Organize family dinner",
                "Check in with old friend",
                "Plan weekend activities",
                "Practice active listening"
            ]
        } else if title.contains("learning") || title.contains("education") || title.contains("growth") {
            return [
                "Read for 30 minutes",
                "Complete online course module",
                "Practice new language",
                "Watch educational video",
                "Write in journal",
                "Research interesting topic",
                "Listen to educational podcast",
                "Take notes on book"
            ]
        } else if title.contains("creative") || title.contains("art") || title.contains("design") {
            return [
                "Work on creative project",
                "Sketch in notebook",
                "Learn new technique",
                "Visit art gallery",
                "Practice instrument",
                "Write creative piece",
                "Experiment with new medium",
                "Share work with others"
            ]
        } else {
            return [
                "Make progress on \(pillar.title)",
                "Focus on \(pillar.title) goals",
                "Dedicate time to \(pillar.title)",
                "Advance \(pillar.title) objectives",
                "Work on \(pillar.title) improvement"
            ]
        }
    }
    
    private static func getSampleNote(for pillar: Pillar) -> String {
        let notes = [
            "Felt really good about this today",
            "Challenging but rewarding",
            "Need to be more consistent",
            "Great progress this week",
            "Found a new approach that works",
            "Inspired to do more tomorrow",
            "Struggled a bit but pushed through",
            "This is becoming a habit",
            "Noticed positive changes",
            "Want to focus more on this area"
        ]
        return notes.randomElement() ?? "Good progress today"
    }
    
    static func clearAllData(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: DailyAction.self)
            try modelContext.delete(model: WeeklyReview.self)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
} 