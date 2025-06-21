//
//  ContentView.swift
//  northstar
//
//  Created by Max Bocklage on 6/19/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            PillarsView()
                .tabItem {
                    Image(systemName: "building.columns.fill")
                    Text("Pillars")
                }
                .tag(1)
            
            HistoryLogView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History Log")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.white) // Theme color from the image
    }
}

#Preview {
    ContentView()
}
