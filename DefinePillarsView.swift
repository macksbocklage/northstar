//
//  DefinePillarsView.swift
//  northstar
//
//  Created by Max Bocklage on 6/19/25.
//

import SwiftUI
import SwiftData

struct DefinePillarsView: View {
    @Binding var currentStep: OnboardingStep
    @Environment(\.modelContext) private var modelContext
    
    @State private var pillars: [PillarInput] = [
        PillarInput(title: "", emoji: "💪", details: "", subGoals: []),
        PillarInput(title: "", emoji: "📈", details: "", subGoals: []),
        PillarInput(title: "", emoji: "📚", details: "", subGoals: [])
    ]
    
    @State private var showingSubGoalInput = false
    @State private var selectedPillarIndex: Int = 0
    @State private var newSubGoal = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        Text("define your three pillars")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                        
                        Text("these will guide your daily actions")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        VStack(spacing: 20) {
                            ForEach(0..<3) { index in
                                PillarInputCard(
                                    pillar: $pillars[index],
                                    index: index,
                                    onAddSubGoal: {
                                        selectedPillarIndex = index
                                        showingSubGoalInput = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                VStack(spacing: 16) {
                    Button(action: savePillars) {
                        Text("continue")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(canContinue ? .blue : .gray)
                            )
                    }
                    .disabled(!canContinue)
                    .padding(.horizontal, 20)
                    
                    Text("\(pillars.filter { !$0.title.isEmpty }.count) of 3 pillars defined")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                )
            }
        }
        .sheet(isPresented: $showingSubGoalInput) {
            SubGoalInputSheet(
                subGoal: $newSubGoal,
                onSave: {
                    if !newSubGoal.isEmpty {
                        pillars[selectedPillarIndex].subGoals.append(newSubGoal)
                        newSubGoal = ""
                    }
                    showingSubGoalInput = false
                }
            )
        }
    }
    
    private var canContinue: Bool {
        pillars.filter { !$0.title.isEmpty }.count == 3
    }
    
    private func savePillars() {
        for pillarInput in pillars {
            if !pillarInput.title.isEmpty {
                let pillar = Pillar(
                    title: pillarInput.title,
                    emoji: pillarInput.emoji,
                    details: pillarInput.details.isEmpty ? nil : pillarInput.details
                )
                
                for subGoalTitle in pillarInput.subGoals {
                    let subGoal = SubGoal(title: subGoalTitle, pillar: pillar)
                    pillar.subGoals.append(subGoal)
                }
                
                modelContext.insert(pillar)
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = .complete
        }
    }
}

struct PillarInputCard: View {
    @Binding var pillar: PillarInput
    let index: Int
    let onAddSubGoal: () -> Void
    
    private let commonEmojis = ["💪", "📈", "📚", "❤️", "🧠", "💰", "🏃‍♂️", "🎯", "🌟", "🔥", "⚡️", "🎨", "🌱", "🚀", "💡", "🎪"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("pillar \(index + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    TextField("e.g., health, relationships, career", text: $pillar.title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 16, weight: .medium))
                    
                    Menu {
                        ForEach(commonEmojis, id: \.self) { emoji in
                            Button(action: {
                                pillar.emoji = emoji
                            }) {
                                HStack {
                                    Text(emoji)
                                    if pillar.emoji == emoji {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(pillar.emoji)
                            .font(.title2)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                TextField("optional description", text: $pillar.details)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            if !pillar.subGoals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("sub-goals")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    ForEach(pillar.subGoals, id: \.self) { subGoal in
                        HStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 6, height: 6)
                            Text(subGoal)
                                .font(.system(size: 14, weight: .regular))
                            Spacer()
                        }
                    }
                }
            }
            
            Button(action: onAddSubGoal) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("add sub-goal")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.blue)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct SubGoalInputSheet: View {
    @Binding var subGoal: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("add a sub-goal")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.top, 20)
                
                Text("break down this pillar into specific goals")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                TextField("e.g., exercise 3x per week", text: $subGoal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16, weight: .regular))
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("add") {
                        onSave()
                    }
                    .disabled(subGoal.isEmpty)
                }
            }
        }
    }
}

struct PillarInput {
    var title: String
    var emoji: String
    var details: String
    var subGoals: [String]
}

#Preview {
    DefinePillarsView(currentStep: .constant(.definePillars))
        .modelContainer(for: Pillar.self, inMemory: true)
} 