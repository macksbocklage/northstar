import SwiftUI

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let dailyActions: [DailyAction]
    
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 28) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding(8)
                }
                Spacer()
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Spacer()
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .padding(8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            // Day headers
            HStack(spacing: 0) {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 16) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            completionStatus: getCompletionStatus(for: date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(width: 48, height: 48)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
        }
    }
    
    private var daysInMonth: [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days in the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func getCompletionStatus(for date: Date) -> CompletionStatus {
        let actionsForDate = dailyActions.filter { calendar.isDate($0.date, inSameDayAs: date) }
        
        if actionsForDate.isEmpty {
            return .none
        }
        
        let completedCount = actionsForDate.filter { $0.isCompleted }.count
        
        switch completedCount {
        case 3:
            return .all
        case 2:
            return .partial
        default:
            return .few
        }
    }
    
    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

enum CompletionStatus {
    case none
    case few
    case partial
    case all
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let completionStatus: CompletionStatus
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)
                VStack(spacing: 3) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 17, weight: isToday ? .bold : .medium))
                        .foregroundColor(textColor)
                    if completionStatus != .none {
                        Circle()
                            .fill(dotColor)
                            .frame(width: 7, height: 7)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .gray.opacity(0.3)
        } else {
            return .clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .black
        } else {
            return .white
        }
    }
    
    private var dotColor: Color {
        switch completionStatus {
        case .all:
            return .green
        case .partial:
            return .yellow
        case .few:
            return .red
        case .none:
            return .clear
        }
    }
}

#Preview {
    CustomCalendarView(selectedDate: .constant(Date()), dailyActions: [])
        .background(Color.black)
} 