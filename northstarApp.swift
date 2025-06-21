//
//  northstarApp.swift
//  northstar
//
//  Created by Max Bocklage on 6/19/25.
//

import SwiftUI
import SwiftData

@main
struct northstarApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("northStarStatement") private var northStarStatement = "Excellence in all areas."
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Pillar.self,
            SubGoal.self,
            DailyAction.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .preferredColorScheme(.dark)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .preferredColorScheme(.dark)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
