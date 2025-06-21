import SwiftUI
import SwiftData

struct HistoryLogView: View {
    @Query(sort: \DailyAction.date, order: .reverse) private var dailyActions: [DailyAction]
    @State private var selectedDate = Date()
    
    private var actionsForSelectedDate: [DailyAction] {
        dailyActions.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("History Log")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                
                if actionsForSelectedDate.isEmpty {
                    VStack {
                        Spacer()
                        Text("No actions logged for this day.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List(actionsForSelectedDate) { action in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(action.pillar?.title ?? "No Pillar")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(action.title)
                                    .font(.headline)
                                if let notes = action.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if action.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Spacer()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
        }
        .colorScheme(.dark)
    }
}

#Preview {
    HistoryLogView()
        .modelContainer(for: DailyAction.self, inMemory: true)
} 