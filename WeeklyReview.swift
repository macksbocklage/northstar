import SwiftUI
import SwiftData

struct WeeklyReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var pillars: [Pillar]
    @Query(sort: \DailyAction.date, order: .reverse) private var dailyActions: [DailyAction]
    
    @State private var currentIndex: Int = 0
    @State private var pillarReflections: [String] = []
    @State private var pillarRatings: [Int] = []
    @FocusState private var isTextFieldFocused: Bool
    
    private var weekStart: Date {
        let calendar = Calendar.current
        let today = Date()
        return calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
    }
    
    private var weekEnd: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 6, to: weekStart) ?? Date()
    }
    
    private var weekDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startString = formatter.string(from: weekStart)
        let endString = formatter.string(from: weekEnd)
        return "\(startString) - \(endString)"
    }
    
    init() {
        // Initialize arrays based on pillar count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Weekly Review")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(weekDateRange)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            if pillars.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "building.columns")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No pillars found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Main content
                TabView(selection: $currentIndex) {
                    ForEach(pillars.indices, id: \.self) { index in
                        WeeklyReviewCard(
                            pillar: pillars[index],
                            weekStats: getWeekStats(for: pillars[index]),
                            reflection: Binding(
                                get: { pillarReflections.indices.contains(index) ? pillarReflections[index] : "" },
                                set: { newValue in
                                    if pillarReflections.indices.contains(index) {
                                        pillarReflections[index] = newValue
                                    }
                                }
                            ),
                            rating: Binding(
                                get: { pillarRatings.indices.contains(index) ? pillarRatings[index] : 0 },
                                set: { newValue in
                                    if pillarRatings.indices.contains(index) {
                                        pillarRatings[index] = newValue
                                    }
                                }
                            ),
                            isTextFieldFocused: $isTextFieldFocused
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom section with progress and navigation
                VStack(spacing: 20) {
                    // Progress indicators
                    HStack(spacing: 8) {
                        ForEach(pillars.indices, id: \.self) { index in
                            Circle()
                                .fill(currentIndex == index ? Color.white : Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentIndex == index ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentIndex > 0 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentIndex -= 1
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                        .font(.caption.bold())
                                    Text("Back")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.gray.opacity(0.2))
                                )
                            }
                        } else {
                            Spacer()
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentIndex < pillars.count - 1 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentIndex += 1
                                }
                            } else {
                                saveWeeklyReview()
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentIndex < pillars.count - 1 ? "Next" : "Complete")
                                    .font(.headline.bold())
                                if currentIndex < pillars.count - 1 {
                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                }
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(allReviewsCompleted || currentIndex < pillars.count - 1 ? Color.white : Color.gray.opacity(0.3))
                            )
                        }
                        .disabled(!allReviewsCompleted && currentIndex >= pillars.count - 1)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .colorScheme(.dark)
        .onAppear {
            initializeArrays()
        }
    }
    
    private func initializeArrays() {
        if pillarReflections.isEmpty {
            pillarReflections = Array(repeating: "", count: pillars.count)
            pillarRatings = Array(repeating: 0, count: pillars.count)
        }
    }
    
    private var allReviewsCompleted: Bool {
        pillarRatings.allSatisfy { $0 > 0 }
    }
    
    private func getWeekStats(for pillar: Pillar) -> WeeklyPillarStats {
        let calendar = Calendar.current
        let weekActions = dailyActions.filter { action in
            guard let actionPillar = action.pillar, actionPillar.id == pillar.id else { return false }
            return calendar.isDate(action.date, equalTo: weekStart, toGranularity: .weekOfYear)
        }
        
        let completedActions = weekActions.filter { $0.isCompleted }.count
        let totalActions = weekActions.count
        let daysSinceLastAction = daysSinceLastAction(for: pillar)
        
        return WeeklyPillarStats(
            totalActions: totalActions,
            completedActions: completedActions,
            daysSinceLastAction: daysSinceLastAction,
            completionRate: totalActions > 0 ? Double(completedActions) / Double(totalActions) : 0.0
        )
    }
    
    private func daysSinceLastAction(for pillar: Pillar) -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        let pillarActions = dailyActions.filter { action in
            guard let actionPillar = action.pillar else { return false }
            return actionPillar.id == pillar.id
        }
        
        guard let lastAction = pillarActions.first else { return 999 }
        return calendar.dateComponents([.day], from: lastAction.date, to: today).day ?? 999
    }
    
    private func saveWeeklyReview() {
        let weeklyReview = WeeklyReview(
            weekStart: weekStart,
            weekEnd: weekEnd,
            pillarReflections: pillarReflections,
            pillarRatings: pillarRatings
        )
        
        modelContext.insert(weeklyReview)
        
        // Create DailyAction entries for each pillar's weekly review
        let today = Date()
        for (index, pillar) in pillars.enumerated() {
            if index < pillarRatings.count && pillarRatings[index] > 0 {
                let ratingText = String(repeating: "⭐", count: pillarRatings[index])
                let reflection = index < pillarReflections.count ? pillarReflections[index] : ""
                
                var actionTitle = "Weekly Review: \(ratingText)"
                if !reflection.isEmpty {
                    actionTitle += " - \(reflection)"
                }
                
                let reviewAction = DailyAction(
                    title: actionTitle,
                    date: today,
                    pillar: pillar
                )
                reviewAction.isCompleted = true
                reviewAction.notes = "Weekly pillar review completed"
                
                modelContext.insert(reviewAction)
            }
        }
        
        try? modelContext.save()
    }
}

struct WeeklyReviewCard: View {
    let pillar: Pillar
    let weekStats: WeeklyPillarStats
    @Binding var reflection: String
    @Binding var rating: Int
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Pillar Header
                VStack(spacing: 24) {
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 70, height: 70)
                            Text(pillar.emoji ?? "⭐️")
                                .font(.system(size: 32))
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(pillar.title)
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("How did this week go?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Week Stats Card
                    VStack(spacing: 16) {
                        HStack {
                            Text("This Week")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 0) {
                            StatItem(
                                title: "Actions",
                                value: "\(weekStats.totalActions)",
                                color: .blue
                            )
                            
                            Divider()
                                .frame(height: 40)
                                .background(Color.gray.opacity(0.3))
                            
                            StatItem(
                                title: "Completed",
                                value: "\(weekStats.completedActions)",
                                color: .green
                            )
                            
                            Divider()
                                .frame(height: 40)
                                .background(Color.gray.opacity(0.3))
                            
                            StatItem(
                                title: "Last Action",
                                value: weekStats.daysSinceLastAction == 0 ? "Today" : "\(weekStats.daysSinceLastAction)d ago",
                                color: weekStats.daysSinceLastAction > 3 ? .orange : .gray
                            )
                        }
                        
                        if weekStats.daysSinceLastAction > 3 {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("This pillar could use some attention")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // Rating Section
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("How did this pillar serve you?")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Rate your week")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    
                    HStack(spacing: 16) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    rating = star
                                }
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title)
                                    .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.4))
                                    .scaleEffect(star <= rating ? 1.1 : 1.0)
                            }
                        }
                        Spacer()
                    }
                }
                
                // Reflection Section
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Reflection")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack {
                            Text("What did you learn about yourself?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    
                    TextField("Share your insights, challenges, or breakthroughs...", text: $reflection)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            isTextFieldFocused = false
                        }
                }
                
                Spacer(minLength: 60)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeeklyPillarStats {
    let totalActions: Int
    let completedActions: Int
    let daysSinceLastAction: Int
    let completionRate: Double
}

@Model
final class WeeklyReview: Identifiable {
    var id: UUID
    var weekStart: Date
    var weekEnd: Date
    var pillarReflections: [String]
    var pillarRatings: [Int]
    var createdAt: Date
    
    init(weekStart: Date, weekEnd: Date, pillarReflections: [String], pillarRatings: [Int]) {
        self.id = UUID()
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.pillarReflections = pillarReflections
        self.pillarRatings = pillarRatings
        self.createdAt = Date()
    }
}

#Preview {
    WeeklyReviewView()
        .modelContainer(for: [Pillar.self, DailyAction.self, WeeklyReview.self], inMemory: true)
} 