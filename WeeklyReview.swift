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
    @State private var nextWeekFocus: [String] = []
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
    
    init() {
        // Initialize arrays based on pillar count
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if pillars.isEmpty {
                    Text("No pillars found.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
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
                                nextWeekFocus: Binding(
                                    get: { nextWeekFocus.indices.contains(index) ? nextWeekFocus[index] : "" },
                                    set: { newValue in
                                        if nextWeekFocus.indices.contains(index) {
                                            nextWeekFocus[index] = newValue
                                        }
                                    }
                                ),
                                isTextFieldFocused: $isTextFieldFocused
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Progress indicators
                    HStack(spacing: 8) {
                        ForEach(pillars.indices, id: \.self) { index in
                            Circle()
                                .fill(currentIndex == index ? Color.white : Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Weekly Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentIndex > 0 {
                        Button {
                            withAnimation { currentIndex -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentIndex < pillars.count - 1 {
                        Button {
                            withAnimation { currentIndex += 1 }
                        } label: {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                    } else {
                        Button("Complete") {
                            saveWeeklyReview()
                            dismiss()
                        }
                        .disabled(!allReviewsCompleted)
                    }
                }
            }
        }
        .colorScheme(.dark)
        .onAppear {
            initializeArrays()
        }
    }
    
    private func initializeArrays() {
        if pillarReflections.isEmpty {
            pillarReflections = Array(repeating: "", count: pillars.count)
            pillarRatings = Array(repeating: 0, count: pillars.count)
            nextWeekFocus = Array(repeating: "", count: pillars.count)
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
            pillarRatings: pillarRatings,
            nextWeekFocus: nextWeekFocus
        )
        
        modelContext.insert(weeklyReview)
        try? modelContext.save()
    }
}

struct WeeklyReviewCard: View {
    let pillar: Pillar
    let weekStats: WeeklyPillarStats
    @Binding var reflection: String
    @Binding var rating: Int
    @Binding var nextWeekFocus: String
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Pillar Header
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Text(pillar.emoji ?? "⭐️")
                                .font(.system(size: 40))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pillar.title)
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("Weekly Review")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Week Stats
                    VStack(spacing: 12) {
                        HStack {
                            Text("This Week's Progress")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 20) {
                            StatItem(title: "Actions", value: "\(weekStats.totalActions)")
                            StatItem(title: "Completed", value: "\(weekStats.completedActions)")
                            StatItem(title: "Last Action", value: weekStats.daysSinceLastAction == 0 ? "Today" : "\(weekStats.daysSinceLastAction)d ago")
                        }
                        
                        if weekStats.daysSinceLastAction > 3 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("This pillar needs attention")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Rating
                VStack(spacing: 16) {
                    HStack {
                        Text("How did this pillar serve you this week?")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                rating = star
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                        }
                        Spacer()
                    }
                }
                
                // Reflection
                VStack(spacing: 16) {
                    HStack {
                        Text("What did you learn about yourself?")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    TextField("Reflect on your growth, challenges, or insights...", text: $reflection, axis: .vertical)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                }
                
                // Next Week Focus
                VStack(spacing: 16) {
                    HStack {
                        Text("What's your focus for next week?")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    TextField("One key area to focus on...", text: $nextWeekFocus)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .focused($isTextFieldFocused)
                }
                
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
    var nextWeekFocus: [String]
    var createdAt: Date
    
    init(weekStart: Date, weekEnd: Date, pillarReflections: [String], pillarRatings: [Int], nextWeekFocus: [String]) {
        self.id = UUID()
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.pillarReflections = pillarReflections
        self.pillarRatings = pillarRatings
        self.nextWeekFocus = nextWeekFocus
        self.createdAt = Date()
    }
}

#Preview {
    WeeklyReviewView()
        .modelContainer(for: [Pillar.self, DailyAction.self, WeeklyReview.self], inMemory: true)
} 