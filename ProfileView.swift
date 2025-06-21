import SwiftUI
import SwiftData

struct ProfileView: View {
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Profile")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
                // Reset Data Button
                Button(action: {
                    showingResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                        Text("Reset Today's Actions")
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(todaysActions.isEmpty)
                
                // Support Button
                Button(action: {
                    if let url = URL(string: "https://x.com/macksbuilds") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                        Text("Support")
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundColor(.purple)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Reset Today's Actions", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetTodaysActions()
            }
        } message: {
            Text("This will delete all of today's actions and their progress. This action cannot be undone.")
        }
    }
    
    private func resetTodaysActions() {
        for action in todaysActions {
            modelContext.delete(action)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ProfileView()
} 