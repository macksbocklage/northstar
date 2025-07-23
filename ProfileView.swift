import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyAction.date, order: .reverse) private var dailyActions: [DailyAction]
    @Query private var pillars: [Pillar]
    @Query(sort: \WeeklyReview.weekStart, order: .reverse) private var weeklyReviews: [WeeklyReview]
    
    @AppStorage("userName") private var userName = "Max"
    @AppStorage("profileImageData") private var profileImageData: Data?
    @AppStorage("statCardOrder") private var statCardOrderData: Data = Data()
    
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var profileImage: UIImage?
    @State private var showingResetConfirmation = false
    @State private var showingSettings = false
    @State private var showingImagePicker = false
    @State private var isEditMode = false
    @State private var statCardOrder: [StatCardType] = [.currentStreak, .longestStreak, .daysLogged, .monthCompletion, .productiveDay]
    @State private var draggedItem: StatCardType?
    @State private var dragOffset: CGSize = .zero
    
    private var todaysActions: [DailyAction] {
        dailyActions.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    private var isWeeklyReviewAvailable: Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.component(.weekday, from: today) == 1 // Sunday is 1
    }
    
    private var daysUntilWeeklyReview: Int {
        let calendar = Calendar.current
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        
        // If today is Sunday (1), return 7 for next Sunday
        // Otherwise calculate days until next Sunday
        if currentWeekday == 1 {
            return 7
        } else {
            return 8 - currentWeekday // Days until next Sunday
        }
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        var currentDate = today
        
        // Check if today has been logged
        let todayActions = dailyActions.filter { calendar.isDate($0.date, inSameDayAs: today) }
        let todayLogged = todayActions.contains { $0.isCompleted || ($0.notes != nil && !$0.notes!.isEmpty) }
        
        if todayLogged {
            streak = 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        // Count backwards through consecutive days
        while true {
            let actionsForDate = dailyActions.filter { calendar.isDate($0.date, inSameDayAs: currentDate) }
            let hasLoggedActions = actionsForDate.contains { $0.isCompleted || ($0.notes != nil && !$0.notes!.isEmpty) }
            
            if hasLoggedActions {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var longestStreak: Int {
        let calendar = Calendar.current
        let sortedActions = dailyActions.sorted { $0.date < $1.date }
        
        var maxStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        // Group actions by date and check if each day has logged actions
        let dateGroups = Dictionary(grouping: sortedActions) { action in
            calendar.startOfDay(for: action.date)
        }
        
        let sortedDates = dateGroups.keys.sorted()
        
        for date in sortedDates {
            let actionsForDate = dateGroups[date] ?? []
            let hasLoggedActions = actionsForDate.contains { $0.isCompleted || ($0.notes != nil && !$0.notes!.isEmpty) }
            
            if hasLoggedActions {
                if let lastDate = lastDate,
                   calendar.dateComponents([.day], from: lastDate, to: date).day == 1 {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
                maxStreak = max(maxStreak, currentStreak)
                lastDate = date
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
    
    private var totalDaysLogged: Int {
        let calendar = Calendar.current
        let dateGroups = Dictionary(grouping: dailyActions) { action in
            calendar.startOfDay(for: action.date)
        }
        
        return dateGroups.values.compactMap { actions in
            actions.contains { $0.isCompleted || ($0.notes != nil && !$0.notes!.isEmpty) } ? 1 : nil
        }.count
    }
    
    private var mostProductiveDay: String {
        let calendar = Calendar.current
        let weekdayGroups = Dictionary(grouping: dailyActions) { action in
            calendar.component(.weekday, from: action.date)
        }
        
        var weekdayCompletions: [Int: Int] = [:]
        
        for (weekday, actions) in weekdayGroups {
            let completedCount = actions.filter { $0.isCompleted }.count
            weekdayCompletions[weekday] = (weekdayCompletions[weekday] ?? 0) + completedCount
        }
        
        guard let mostProductiveWeekday = weekdayCompletions.max(by: { $0.value < $1.value })?.key else {
            return "No data"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let date = calendar.date(from: DateComponents(weekday: mostProductiveWeekday))!
        return dateFormatter.string(from: date)
    }
    
    private var currentMonthCompletionRate: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let currentMonthActions = dailyActions.filter { action in
            calendar.isDate(action.date, equalTo: now, toGranularity: .month)
        }
        
        let totalActions = currentMonthActions.count
        let completedActions = currentMonthActions.filter { $0.isCompleted }.count
        
        guard totalActions > 0 else { return 0 }
        return Int((Double(completedActions) / Double(totalActions)) * 100)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Section
                    VStack(spacing: 16) {
                        // Profile Image
                        Button(action: {
                            if isEditMode {
                                showingImagePicker = true
                            }
                        }) {
                            ZStack {
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.title)
                                                .foregroundColor(.gray)
                                        )
                                }
                                
                                if isEditMode {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        }
                        .disabled(!isEditMode)
                        
                        // Name
                        if isEditingName {
                            TextField("Name", text: $editedName)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    userName = editedName
                                    isEditingName = false
                                }
                        } else {
                            Button(action: {
                                if isEditMode {
                                    editedName = userName
                                    isEditingName = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Text(userName)
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    if isEditMode {
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .disabled(!isEditMode)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Statistics
                    VStack(spacing: 16) {
                        HStack {
                            Text("Statistics")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Dynamic Statistics Grid
                        VStack(spacing: 12) {
                            // First row (2 cards)
                            HStack(spacing: 12) {
                                ForEach(statCardOrder.prefix(2), id: \.self) { cardType in
                                    createStatCard(for: cardType)
                                        .scaleEffect(draggedItem == cardType ? 1.05 : 1.0)
                                        .opacity(draggedItem == cardType ? 0.8 : 1.0)
                                        .offset(draggedItem == cardType ? dragOffset : .zero)
                                        .zIndex(draggedItem == cardType ? 1 : 0)
                                        .onDrag {
                                            draggedItem = cardType
                                            return NSItemProvider(object: cardType.rawValue as NSString)
                                        }
                                        .onDrop(of: [.text], delegate: StatCardDropTarget(
                                            targetItem: cardType,
                                            draggedItem: $draggedItem,
                                            statCardOrder: $statCardOrder,
                                            onOrderChanged: saveStatCardOrder
                                        ))
                                }
                            }
                            
                            // Second row (2 cards)
                            if statCardOrder.count > 2 {
                                HStack(spacing: 12) {
                                    ForEach(statCardOrder.dropFirst(2).prefix(2), id: \.self) { cardType in
                                        createStatCard(for: cardType)
                                            .scaleEffect(draggedItem == cardType ? 1.05 : 1.0)
                                            .opacity(draggedItem == cardType ? 0.8 : 1.0)
                                            .offset(draggedItem == cardType ? dragOffset : .zero)
                                            .zIndex(draggedItem == cardType ? 1 : 0)
                                            .onDrag {
                                                draggedItem = cardType
                                                return NSItemProvider(object: cardType.rawValue as NSString)
                                            }
                                            .onDrop(of: [.text], delegate: StatCardDropTarget(
                                                targetItem: cardType,
                                                draggedItem: $draggedItem,
                                                statCardOrder: $statCardOrder,
                                                onOrderChanged: saveStatCardOrder
                                            ))
                                    }
                                }
                            }
                            
                            // Full-width card (5th card)
                            if statCardOrder.count > 4 {
                                createStatCard(for: statCardOrder[4])
                                    .scaleEffect(draggedItem == statCardOrder[4] ? 1.05 : 1.0)
                                    .opacity(draggedItem == statCardOrder[4] ? 0.8 : 1.0)
                                    .offset(draggedItem == statCardOrder[4] ? dragOffset : .zero)
                                    .zIndex(draggedItem == statCardOrder[4] ? 1 : 0)
                                    .onDrag {
                                        draggedItem = statCardOrder[4]
                                        return NSItemProvider(object: statCardOrder[4].rawValue as NSString)
                                    }
                                    .onDrop(of: [.text], delegate: StatCardDropTarget(
                                        targetItem: statCardOrder[4],
                                        draggedItem: $draggedItem,
                                        statCardOrder: $statCardOrder,
                                        onOrderChanged: saveStatCardOrder
                                    ))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Quick Actions
                        VStack(spacing: 16) {
                            HStack {
                                Text("Quick Actions")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                // Weekly Review Button
                                if isWeeklyReviewAvailable {
                                    NavigationLink(destination: WeeklyReviewView()) {
                                        HStack {
                                            Image(systemName: "calendar.badge.checkmark")
                                                .font(.title2)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(weeklyReviews.isEmpty ? "Start Weekly Review" : "View Weekly Summary")
                                                    .font(.headline)
                                                Text(weeklyReviews.isEmpty ? "Reflect on your pillar progress" : "See your latest weekly insights")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.black)
                                                .stroke(Color.gray, lineWidth: 1)
                                        )
                                    }
                                    .padding(.horizontal)
                                } else {
                                    HStack {
                                        Image(systemName: "calendar.badge.checkmark")
                                            .font(.title2)
                                            .foregroundColor(.gray)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Weekly Review")
                                                .font(.headline)
                                                .foregroundColor(.gray)
                                            Text("\(daysUntilWeeklyReview) days until next review")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.black)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .padding(.horizontal)
                                }
                                
                                // Sample Data Section (for testing)
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Testing Tools")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            SampleDataGenerator.generateWeekOfData(modelContext: modelContext, pillars: pillars)
                                        }) {
                                            Text("Add Sample Week")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                        
                                        Button(action: {
                                            SampleDataGenerator.clearAllData(modelContext: modelContext)
                                        }) {
                                            Text("Clear All Data")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.red.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                                
                                // Settings Button
                                Button(action: {
                                    showingSettings = true
                                }) {
                                    HStack {
                                        Image(systemName: "gearshape.fill")
                                            .font(.title2)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Settings")
                                                .font(.headline)
                                            Text("App preferences and support")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.black)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal)
                                
                                // Reset Today's Actions Button
                                if !todaysActions.isEmpty {
                                    Button(action: {
                                        showingResetConfirmation = true
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.title2)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Reset Today's Actions")
                                                    .font(.headline)
                                                Text("Clear all actions for today")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .foregroundColor(.red)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.black)
                                                .stroke(Color.gray, lineWidth: 1)
                                        )
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "Done" : "Edit") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isEditMode.toggle()
                            if !isEditMode {
                                isEditingName = false
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .fontWeight(isEditMode ? .semibold : .regular)
                }
            }
        }
        .colorScheme(.dark)
        .onAppear {
            loadProfileImage()
            loadStatCardOrder()
        }
        .alert("Reset Today's Actions", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetTodaysActions()
            }
        } message: {
            Text("This will permanently delete all actions for today. This cannot be undone.")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(onImageSelected: { image in
                profileImage = image
                if let data = image.jpegData(compressionQuality: 0.8) {
                    profileImageData = data
                }
            })
        }
    }
    
    private func createStatCard(for cardType: StatCardType) -> some View {
        Group {
            switch cardType {
            case .currentStreak:
                StatCard(
                    title: "Current Streak",
                    value: "\(currentStreak)",
                    subtitle: "days",
                    icon: "flame.fill",
                    iconColor: .orange,
                    isEditMode: isEditMode
                )
            case .longestStreak:
                StatCard(
                    title: "Longest Streak",
                    value: "\(longestStreak)",
                    subtitle: "days",
                    icon: "trophy.fill",
                    iconColor: .yellow,
                    isEditMode: isEditMode
                )
            case .daysLogged:
                StatCard(
                    title: "Days Logged",
                    value: "\(totalDaysLogged)",
                    subtitle: "total",
                    icon: "calendar.badge.checkmark",
                    iconColor: .green,
                    isEditMode: isEditMode
                )
            case .monthCompletion:
                StatCard(
                    title: "This Month",
                    value: "\(currentMonthCompletionRate)%",
                    subtitle: "complete",
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .blue,
                    isEditMode: isEditMode
                )
            case .productiveDay:
                StatCard(
                    title: "Most Productive Day",
                    value: mostProductiveDay,
                    subtitle: "of the week",
                    icon: "star.fill",
                    iconColor: .purple,
                    isFullWidth: true,
                    isEditMode: isEditMode
                )
            }
        }
    }
    
    private func loadProfileImage() {
        if let data = profileImageData,
           let image = UIImage(data: data) {
            profileImage = image
        }
    }
    
    private func loadStatCardOrder() {
        if let decoded = try? JSONDecoder().decode([StatCardType].self, from: statCardOrderData) {
            statCardOrder = decoded
        }
    }
    
    private func saveStatCardOrder() {
        if let encoded = try? JSONEncoder().encode(statCardOrder) {
            statCardOrderData = encoded
        }
    }
    
    private func resetTodaysActions() {
        for action in todaysActions {
            modelContext.delete(action)
        }
        try? modelContext.save()
    }
}

enum StatCardType: String, CaseIterable, Codable {
    case currentStreak = "currentStreak"
    case longestStreak = "longestStreak"
    case daysLogged = "daysLogged"
    case monthCompletion = "monthCompletion"
    case productiveDay = "productiveDay"
}

struct StatCardDropTarget: DropDelegate {
    let targetItem: StatCardType
    @Binding var draggedItem: StatCardType?
    @Binding var statCardOrder: [StatCardType]
    let onOrderChanged: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            if let data = data as? Data,
               let cardTypeString = String(data: data, encoding: .utf8),
               let cardType = StatCardType(rawValue: cardTypeString) {
                
                DispatchQueue.main.async {
                    // If the dragged item is the target item, do nothing
                    if cardType == targetItem {
                        draggedItem = nil
                        return
                    }
                    
                    // Find current positions
                    guard let fromIndex = statCardOrder.firstIndex(of: cardType),
                          let toIndex = statCardOrder.firstIndex(of: targetItem) else {
                        draggedItem = nil
                        return
                    }
                    
                    // Perform the swap
                    statCardOrder.swapAt(fromIndex, toIndex)
                    
                    draggedItem = nil
                    onOrderChanged()
                }
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Visual feedback when hovering over a drop target
    }
    
    func dropExited(info: DropInfo) {
        // Reset visual feedback when leaving drop target
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    var isFullWidth: Bool = false
    var isEditMode: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                VStack(spacing: 4) {
                    Text(value)
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black)
                    .stroke(isEditMode ? Color.blue.opacity(0.5) : Color.gray, lineWidth: isEditMode ? 2 : 1)
            )
            .scaleEffect(isEditMode ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isEditMode)
            
            // Drag handle (only show in edit mode)
            if isEditMode {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.8))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .offset(x: -8, y: -8)
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyAction.date, order: .reverse) private var dailyActions: [DailyAction]
    @State private var showingResetConfirmation = false
    
    private var todaysActions: [DailyAction] {
        dailyActions.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Support Button
                Button(action: {
                    if let url = URL(string: "https://x.com/macksbuilds") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                        Text("Support & Feedback")
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .colorScheme(.dark)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: DailyAction.self, inMemory: true)
} 