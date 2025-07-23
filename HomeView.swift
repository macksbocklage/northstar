//
//  HomeView.swift
//  northstar
//
//  Created by Max Bocklage on 6/19/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pillars: [Pillar]
    @Query(sort: \DailyAction.date, order: .reverse) private var dailyActions: [DailyAction]
    
    @AppStorage("northStarStatement") private var northStarStatement = "Excellence in all areas."
    @State private var showingSetDailyActions = false
    @State private var showingLogToday = false
    @State private var showingEditNorthStar = false
    @State private var editingAction: DailyAction? = nil
    @State private var currentQuoteIndex = 0
    
    private let motivationalQuotes = [
        "Align actions with ambition.",
        "Execute the mission.",
        "Intensity is the price of excellence.",
        "Win the day.",
        "Focus on the signal, ignore the noise.",
        "Discipline equals freedom.",
        "Today's actions shape tomorrow's reality.",
        "What is the highest leverage action now?",
        "Commitment unlocks potential.",
        "Are your actions moving you closer?",
        "Obsession + Clarity = Unstoppable.",
        "Progress demands persistence.",
        "What will you accomplish today?"
    ]
    
    private var todaysActions: [DailyAction] {
        dailyActions.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    private var actionsAreSet: Bool {
        !todaysActions.isEmpty
    }
    
    private var hasBeenLoggedToday: Bool {
        guard actionsAreSet else { return false }
        return todaysActions.contains { $0.isCompleted || ($0.notes != nil && !$0.notes!.isEmpty) }
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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Home")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            
                            Text("\(Date().formatted(date: .complete, time: .omitted))")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(currentStreak)")
                                .bold()
                        }
                    }
                    .padding()
                    
                    // Excellence Card
                    Button(action: {
                        showingEditNorthStar = true
                    }) {
                        VStack(spacing: 16) {
                            Image("logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white)
                            
                            Text(northStarStatement)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Choose Daily 3 Button
                    Button(action: {
                        if actionsAreSet {
                            showingLogToday = true
                        } else {
                            showingSetDailyActions = true
                        }
                    }) {
                        Text(actionsAreSet ? "Log Today's Actions" : "Set Daily Actions")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white)
                                    .shadow(radius: 2)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Motivational Quotes Section
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentQuoteIndex = (currentQuoteIndex + 1) % motivationalQuotes.count
                        }
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "quote.opening")
                                .font(.title3)
                                .foregroundColor(.white)
                            
                            Text(motivationalQuotes[currentQuoteIndex])
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            
                            Text("Tap for another")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .opacity(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    // Today's Actions Section
                    if actionsAreSet {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Actions")
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(todaysActions) { action in
                                    ActionCard(action: action)
                                        .onTapGesture {
                                            editingAction = action
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .sheet(isPresented: $showingSetDailyActions) {
            SetDailyActionsView()
        }
        .sheet(isPresented: $showingLogToday) {
            LogTodayView(actions: todaysActions)
        }
        .sheet(isPresented: $showingEditNorthStar) {
            EditNorthStarView(northStarStatement: $northStarStatement)
        }
        .sheet(item: $editingAction) { action in
            EditDailyActionsView(actions: [action])
        }
        .onAppear {
            // Randomize initial quote
            currentQuoteIndex = Int.random(in: 0..<motivationalQuotes.count)
        }
    }
}

struct ActionCard: View {
    let action: DailyAction

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(action.pillar?.emoji ?? "❓")
                .font(.title)

            VStack(alignment: .leading, spacing: 4) {
                Text(action.pillar?.title ?? "Pillar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(action.title)
                    .font(.headline)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Pillar.self, inMemory: true)
} 
