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
    @State private var streakCount = 5
    @State private var showingSetDailyActions = false
    @State private var showingLogToday = false
    @State private var showingEditDailyActions = false
    @State private var showingEditNorthStar = false
    
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome back, Max")
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
                            Text("\(streakCount)")
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
                            if hasBeenLoggedToday {
                                showingEditDailyActions = true
                            } else {
                                showingLogToday = true
                            }
                        } else {
                            showingSetDailyActions = true
                        }
                    }) {
                        Text(actionsAreSet ? (hasBeenLoggedToday ? "Edit Today's Actions" : "Log Today") : "Set Daily Actions")
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
                    
                    // Todays's Actions Section
                    if actionsAreSet {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Actions")
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(todaysActions) { action in
                                    ActionCard(action: action) {
                                        showingEditDailyActions = true
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
        .sheet(isPresented: $showingEditDailyActions) {
            EditDailyActionsView(actions: todaysActions)
        }
        .sheet(isPresented: $showingEditNorthStar) {
            EditNorthStarView(northStarStatement: $northStarStatement)
        }
    }
}

struct ActionCard: View {
    let action: DailyAction
    let onEdit: (() -> Void)?

    init(action: DailyAction, onEdit: (() -> Void)? = nil) {
        self.action = action
        self.onEdit = onEdit
    }

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
        .onLongPressGesture {
            onEdit?()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Pillar.self, inMemory: true)
} 