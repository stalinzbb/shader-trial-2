//
//  ChecklistSheetView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/15/25.
//

import SwiftUI

struct ChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    var isCompleted: Bool = false
}

struct ChecklistSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentProgress: Int
    @State private var animatedProgress: Double = 0
    @State private var checklistItems: [ChecklistItem] = [
        ChecklistItem(title: "Set Event Date", description: "Choose the perfect date for your event", iconName: "calendar", isCompleted: true),
        ChecklistItem(title: "Choose Venue", description: "Find and book the ideal location", iconName: "location"),
        ChecklistItem(title: "Send Invitations", description: "Create and send invites to your guests", iconName: "envelope"),
        ChecklistItem(title: "Plan Menu", description: "Design a delicious menu for attendees", iconName: "fork.knife"),
        ChecklistItem(title: "Arrange Entertainment", description: "Book speakers, music, or activities", iconName: "music.note"),
        ChecklistItem(title: "Prepare Materials", description: "Get all necessary supplies ready", iconName: "box")
    ]
    
    let maxProgress = 6
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with Progress
                    VStack(spacing: 20) {
                        HStack {
                            Button("Cancel") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Button("Done") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: animatedProgress)
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                            
                            Text("\(currentProgress)/\(maxProgress)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Finish setting up your event")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Text("Let's set you up for success")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Checklist Items
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(checklistItems.enumerated()), id: \.element.id) { index, item in
                                ChecklistItemRow(
                                    item: item,
                                    onToggle: {
                                        toggleItem(at: index)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            updateProgress()
            // Animate progress from 0 to current value
            animatedProgress = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animatedProgress = Double(currentProgress) / Double(maxProgress)
            }
        }
    }
    
    private func toggleItem(at index: Int) {
        checklistItems[index].isCompleted.toggle()
        updateProgress()
    }
    
    private func updateProgress() {
        currentProgress = checklistItems.filter { $0.isCompleted }.count
        // Update animated progress when items are toggled
        withAnimation(.easeInOut(duration: 0.5)) {
            animatedProgress = Double(currentProgress) / Double(maxProgress)
        }
    }
}

struct ChecklistItemRow: View {
    let item: ChecklistItem
    let onToggle: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: item.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(item.isCompleted ? .green : .gray)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Completion indicator and caret
                HStack(spacing: 8) {
                    if item.isCompleted {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.05),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    ChecklistSheetView(currentProgress: .constant(1))
}