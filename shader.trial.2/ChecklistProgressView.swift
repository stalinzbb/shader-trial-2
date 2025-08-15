//
//  ChecklistProgressView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/15/25.
//

import SwiftUI

struct ChecklistProgressView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showChecklistSheet = false
    @State private var currentProgress = 1
    @State private var animatedProgress: Double = 0
    let maxProgress = 6
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Floating Button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showChecklistSheet = true
                        }) {
                            HStack(spacing: 14) {
                                Text("My Checklist")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                        .frame(width: 32, height: 32)
                                    
                                    Circle()
                                        .trim(from: 0, to: animatedProgress)
                                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .frame(width: 32, height: 32)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(hex: "#323232"))
                                    .shadow(
                                        color: Color.black.opacity(0.15),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Scrollable Content
                    ScrollView {
                        VStack(spacing: 30) {
                            VStack(spacing: 16) {
                                Text("Checklist Progress")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding(.top, 40)
                                
                                Text("Track your progress with an interactive checklist system. This feature demonstrates how progress indicators can be used to guide users through multi-step processes and provide visual feedback on completion status.")
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .padding(.horizontal, 20)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("How it works:")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("• Tap the 'My Checklist' button to open the checklist sheet")
                                        Text("• Complete items by tapping on them")
                                        Text("• Watch the progress indicator update in real-time")
                                        Text("• Progress is synchronized across all views")
                                    }
                                    .font(.body)
                                    .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Sample Content Section
                            VStack(spacing: 20) {
                                HStack {
                                    Text("Sample Content")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Text("Demo")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.orange)
                                        )
                                }
                                .padding(.horizontal, 20)
                                
                                Text("This content demonstrates the floating button behavior. Scroll down to see how the 'My Checklist' button stays fixed at the top while the content scrolls underneath.")
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                
                                // Sample Cards
                                ForEach(1...8, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Text("\(index)")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.blue)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Sample Item \(index)")
                                                    .font(.headline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.black)
                                                
                                                Text("This is a sample content item to demonstrate scrolling behavior with the fixed floating button.")
                                                    .font(.body)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
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
                                    .padding(.horizontal, 20)
                                }
                                
                                // Bottom spacing
                                Color.clear
                                    .frame(height: 100)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $showChecklistSheet) {
            ChecklistSheetView(currentProgress: $currentProgress)
        }
        .onAppear {
            // Animate progress indicator on page load
            animatedProgress = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animatedProgress = Double(currentProgress) / Double(maxProgress)
            }
        }
        .onChange(of: currentProgress) { _, newValue in
            // Update animated progress when currentProgress changes
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = Double(newValue) / Double(maxProgress)
            }
        }
    }
}


#Preview {
    ChecklistProgressView()
}