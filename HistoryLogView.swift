import SwiftUI
import SwiftData

struct HistoryLogView: View {
    @Query(sort: \DailyAction.date, order: .reverse) private var dailyActions: [DailyAction]
    @Query private var pillars: [Pillar]
    @State private var selectedDate = Date()
    @State private var showingLogYesterday = false
    
    private var actionsForSelectedDate: [DailyAction] {
        dailyActions.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    private var isYesterday: Bool {
        Calendar.current.isDateInYesterday(selectedDate)
    }
    
    private var yesterdayActions: [DailyAction] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return dailyActions.filter { Calendar.current.isDate($0.date, inSameDayAs: yesterday) }
    }
    
    private var yesterdayActionsToLog: [DailyAction] {
        yesterdayActions.filter { !$0.isLogged }
    }
    
    private var hasYesterdayActionsToLog: Bool {
        !yesterdayActionsToLog.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Calendar
            CustomCalendarView(selectedDate: $selectedDate, dailyActions: dailyActions)
                .padding(.horizontal, 8)
                .padding(.top, 16)
                .padding(.bottom, 20)
            
            // Selected Date Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedDateString)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        
                        if Calendar.current.isDateInToday(selectedDate) {
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        } else if isYesterday {
                            Text("Yesterday")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        } else {
                            Text("\(actionsForSelectedDate.count) actions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if !actionsForSelectedDate.isEmpty {
                        CompletionSummary(actions: actionsForSelectedDate)
                    }
                }
                .padding(.horizontal, 20)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 20)
            }
            
            // Actions List
            if actionsForSelectedDate.isEmpty {
                EmptyStateView(
                    date: selectedDate,
                    isYesterday: isYesterday,
                    hasYesterdayActions: hasYesterdayActionsToLog,
                    onLogYesterday: { showingLogYesterday = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(actionsForSelectedDate) { action in
                            ActionHistoryCard(action: action)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .colorScheme(.dark)
        .sheet(isPresented: $showingLogYesterday) {
            LogYesterdayView(actions: yesterdayActionsToLog)
        }
    }
}

struct ActionHistoryCard: View {
    let action: DailyAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with pillar info and completion status
            HStack(spacing: 12) {
                // Pillar emoji and info
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Text(action.pillar?.emoji ?? "❓")
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.pillar?.title ?? "No Pillar")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                        Text(action.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Completion status
                CompletionBadge(action: action)
            }
            
            // Notes if available
            if let notes = action.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct CompletionBadge: View {
    let action: DailyAction
    
    private var statusColor: Color {
        switch action.actionStatus {
        case .notLogged:
            return .gray
        case .completed:
            return .green
        case .incomplete:
            return .red
        }
    }
    
    private var statusText: String {
        switch action.actionStatus {
        case .notLogged:
            return "Not logged"
        case .completed:
            return "Done"
        case .incomplete:
            return "Incomplete"
        }
    }
    
    private var statusIcon: String {
        switch action.actionStatus {
        case .notLogged:
            return "circle"
        case .completed:
            return "checkmark.circle.fill"
        case .incomplete:
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundColor(statusColor)
            
            Text(statusText)
                .font(.caption.weight(.medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(statusColor.opacity(0.15))
        )
    }
}

struct CompletionSummary: View {
    let actions: [DailyAction]
    
    private var completedCount: Int {
        actions.filter { $0.actionStatus == .completed }.count
    }
    
    private var loggedCount: Int {
        actions.filter { $0.isLogged }.count
    }
    
    private var totalCount: Int {
        actions.count
    }
    
    private var completionRate: Double {
        guard loggedCount > 0 else { return 0 }
        return Double(completedCount) / Double(loggedCount)
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(completedCount)/\(loggedCount)")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("completed")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 4)
                
                if loggedCount > 0 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(completionRate > 0.7 ? .green : completionRate > 0.3 ? .orange : .red)
                        .frame(width: 60 * completionRate, height: 4)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let date: Date
    let isYesterday: Bool
    let hasYesterdayActions: Bool
    let onLogYesterday: () -> Void
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isFuture: Bool {
        date > Date()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: isFuture ? "calendar.badge.clock" : "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(isFuture ? "Future Date" : "No Actions Logged")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(isFuture ? 
                     "This date hasn't arrived yet" : 
                     isToday ? 
                     "Start by setting your daily actions" : 
                     isYesterday && hasYesterdayActions ?
                     "You had actions set but didn't log your progress" :
                     "No actions were recorded on this day")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if isToday && !isFuture {
                NavigationLink(destination: Text("Set Daily Actions")) {
                    Text("Set Today's Actions")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                        )
                }
                .padding(.top, 8)
            } else if isYesterday && hasYesterdayActions {
                Button(action: onLogYesterday) {
                    Text("Log Yesterday's Actions")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.orange)
                        )
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HistoryLogView()
        .modelContainer(for: DailyAction.self, inMemory: true)
} 