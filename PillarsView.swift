import SwiftUI
import SwiftData

struct PillarsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pillars: [Pillar]
    @Query(sort: \DailyAction.date, order: .reverse) private var dailyActions: [DailyAction]
    @State private var selectedPillar: Pillar?
    @State private var showingAddAction = false
    @State private var selectedPillarForAction: Pillar?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Pillars")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Pillar Balance Overview
                    if !pillars.isEmpty {
                        PillarBalanceView(pillars: pillars, dailyActions: dailyActions)
                            .padding(.horizontal)
                    }
                    
                    // Enhanced Pillar Cards
                    VStack(spacing: 16) {
                        ForEach(pillars) { pillar in
                            EnhancedPillarCard(
                                pillar: pillar,
                                dailyActions: dailyActions,
                                onTap: { selectedPillar = pillar },
                                onAddAction: { 
                                    selectedPillarForAction = pillar
                                    showingAddAction = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .sheet(item: $selectedPillar) { pillar in
                PillarDetailView(pillar: pillar, dailyActions: dailyActions)
            }
            .sheet(isPresented: $showingAddAction) {
                if let pillar = selectedPillarForAction {
                    QuickAddActionView(pillar: pillar)
                }
            }
        }
        .colorScheme(.dark)
    }
}

struct PillarBalanceView: View {
    let pillars: [Pillar]
    let dailyActions: [DailyAction]
    
    private var thisWeekActions: [DailyAction] {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return dailyActions.filter { action in
            calendar.isDate(action.date, equalTo: now, toGranularity: .weekOfYear)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("This Week's Balance")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach(pillars) { pillar in
                    let pillarActions = thisWeekActions.filter { $0.pillar?.id == pillar.id }
                    let loggedActions = pillarActions.filter { $0.isLogged }
                    let completedActions = pillarActions.filter { $0.actionStatus == .completed }
                    
                    VStack(spacing: 8) {
                        Text(pillar.emoji ?? "⭐️")
                            .font(.title2)
                        
                        Text("\(completedActions.count)/\(loggedActions.count)")
                            .font(.title3.bold())
                            .foregroundColor(.white)

                        // Progress indicator
                        Circle()
                            .fill(loggedActions.count > 0 ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.02))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct EnhancedPillarCard: View {
    let pillar: Pillar
    let dailyActions: [DailyAction]
    let onTap: () -> Void
    let onAddAction: () -> Void
    
    private var pillarActions: [DailyAction] {
        dailyActions.filter { $0.pillar?.id == pillar.id }
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        var currentDate = today
        
        // Check if today has been logged for this pillar
        let todayActions = pillarActions.filter { calendar.isDate($0.date, inSameDayAs: today) }
        let todayLogged = todayActions.contains { $0.isLogged }
        
        if todayLogged {
            streak = 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        // Count backwards through consecutive days
        while true {
            let actionsForDate = pillarActions.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
            let hasLoggedActions = actionsForDate.contains { $0.isLogged }
            
            if hasLoggedActions {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var recentActions: [DailyAction] {
        Array(pillarActions.prefix(3))
    }
    
    private var thisWeekProgress: Double {
        let calendar = Calendar.current
        let now = Date()
        let weekActions = pillarActions.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        let loggedActions = weekActions.filter { $0.isLogged }
        let completedActions = weekActions.filter { $0.actionStatus == .completed }
        
        guard !loggedActions.isEmpty else { return 0 }
        return Double(completedActions.count) / Double(loggedActions.count)
    }
    
    private var hasActionToday: Bool {
        let today = Date()
        return pillarActions.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Header with emoji, title, and streak
                HStack(alignment: .top, spacing: 12) {
                    Text(pillar.emoji ?? "⭐️")
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pillar.title)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        if currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("\(currentStreak) day streak")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        } else {
                            Text("No current streak")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Quick action button
                    Button(action: onAddAction) {
                        Image(systemName: hasActionToday ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(hasActionToday ? .green : .blue)
                    }
                    .buttonStyle(.plain)
                }
                
                // Weekly progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("This Week")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(thisWeekProgress * 100))%")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [Color.blue, Color.green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: geometry.size.width * thisWeekProgress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Recent actions preview
                if !recentActions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent Actions")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        VStack(spacing: 6) {
                            ForEach(recentActions.prefix(2)) { action in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(action.isCompleted ? Color.green : Color.gray.opacity(0.5))
                                        .frame(width: 6, height: 6)
                                    
                                    Text(action.title)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text(action.date, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PillarDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let pillar: Pillar
    let dailyActions: [DailyAction]
    
    @State private var title: String
    @State private var emoji: String
    @State private var details: String
    @State private var showingEmojiPicker = false
    
    private var pillarActions: [DailyAction] {
        dailyActions.filter { $0.pillar?.id == pillar.id }
    }
    
    private var recentActions: [DailyAction] {
        Array(pillarActions.prefix(10))
    }
    
    private var pillarStats: PillarStats {
        let calendar = Calendar.current
        let now = Date()
        
        // This month's actions
        let monthActions = pillarActions.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        let monthCompleted = monthActions.filter { $0.isCompleted }
        
        // All time stats
        let totalActions = pillarActions.count
        let totalCompleted = pillarActions.filter { $0.isCompleted }.count
        
        // Days since last action
        let daysSinceLastAction = pillarActions.isEmpty ? 999 : 
            calendar.dateComponents([.day], from: pillarActions.first!.date, to: now).day ?? 0
        
        return PillarStats(
            totalActions: totalActions,
            totalCompleted: totalCompleted,
            monthActions: monthActions.count,
            monthCompleted: monthCompleted.count,
            daysSinceLastAction: daysSinceLastAction
        )
    }
    
    init(pillar: Pillar, dailyActions: [DailyAction]) {
        self.pillar = pillar
        self.dailyActions = dailyActions
        self._title = State(initialValue: pillar.title)
        self._emoji = State(initialValue: pillar.emoji ?? "⭐️")
        self._details = State(initialValue: pillar.details ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pillar Overview Section
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: { showingEmojiPicker = true }) {
                            Text(emoji)
                                .font(.system(size: 48))
                        }
                        
                        TextField("Pillar Name", text: $title, axis: .vertical)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                        
                        TextField("Description", text: $details, axis: .vertical)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .textFieldStyle(.plain)
                            .placeholder(when: details.isEmpty) {
                                Text("Add a description for this pillar...")
                                    .foregroundColor(.secondary.opacity(0.6))
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.02))
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Performance Stats
                    PillarPerformanceSection(stats: pillarStats)
                    
                    // Sub-goals Section (if any exist)
                    if !pillar.subGoals.isEmpty {
                        SubGoalsSection(pillar: pillar)
                    }
                    
                    // Recent Actions
                    if !recentActions.isEmpty {
                        RecentActionsSection(actions: recentActions)
                    }
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
                    .presentationDetents([.medium])
            }
        }
        .colorScheme(.dark)
    }
    
    private func saveChanges() {
        pillar.title = title
        pillar.emoji = emoji
        pillar.details = details.isEmpty ? nil : details
        
        try? modelContext.save()
    }
}

struct PillarPerformanceSection: View {
    let stats: PillarStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                StatBox(
                    title: "Total Actions",
                    value: "\(stats.totalActions)",
                    subtitle: "\(stats.totalCompleted) completed",
                    color: .blue
                )
                
                StatBox(
                    title: "This Month",
                    value: "\(stats.monthActions)",
                    subtitle: "\(stats.monthCompleted) completed",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                StatBox(
                    title: "Completion Rate",
                    value: stats.totalActions > 0 ? "\(Int(Double(stats.totalCompleted) / Double(stats.totalActions) * 100))%" : "0%",
                    subtitle: "all time",
                    color: .orange
                )
                
                StatBox(
                    title: "Last Action",
                    value: stats.daysSinceLastAction == 0 ? "Today" : "\(stats.daysSinceLastAction)d ago",
                    subtitle: "days since",
                    color: stats.daysSinceLastAction > 7 ? .red : .gray
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.02))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct SubGoalsSection: View {
    let pillar: Pillar
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sub-goals")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(pillar.subGoals, id: \.id) { subGoal in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        
                        Text(subGoal.title)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.02))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct RecentActionsSection: View {
    let actions: [DailyAction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(actions) { action in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(action.isCompleted ? Color.green : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.title)
                                .font(.body)
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Text(action.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if action.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.02))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct QuickAddActionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let pillar: Pillar
    @State private var actionTitle = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 20) {
                    Text(pillar.emoji ?? "⭐️")
                        .font(.system(size: 60))
                    
                    Text("Add action for")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(pillar.title)
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                TextField("What will you do today?", text: $actionTitle)
                    .font(.title3)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        saveAction()
                    }
                
                Spacer()
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        saveAction()
                    }
                    .foregroundColor(.blue)
                    .disabled(actionTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .colorScheme(.dark)
    }
    
    private func saveAction() {
        let title = actionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        let action = DailyAction(title: title, date: Date(), pillar: pillar)
        modelContext.insert(action)
        
        try? modelContext.save()
        dismiss()
    }
}

struct PillarStats {
    let totalActions: Int
    let totalCompleted: Int
    let monthActions: Int
    let monthCompleted: Int
    let daysSinceLastAction: Int
}

// Helper extension for placeholder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss
    private let commonEmojis = ["💪", "📈", "📚", "❤️", "🧠", "💰", "🏃‍♂️", "🎯", "🌟", "🔥", "⚡️", "🎨", "🌱", "🚀", "💡", "🎪"]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                    ForEach(commonEmojis, id: \.self) { emojiOption in
                        Button(action: {
                            selectedEmoji = emojiOption
                            dismiss()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedEmoji == emojiOption ? Color.blue : Color(.systemGray6))
                                    .aspectRatio(1.0, contentMode: .fit)

                                Text(emojiOption)
                                    .font(.title)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Select Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .colorScheme(.dark)
    }
}

#Preview {
    PillarsView()
        .modelContainer(for: Pillar.self, inMemory: true)
} 
