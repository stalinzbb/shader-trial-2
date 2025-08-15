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
                            HStack(spacing: 12) {
                                Text("My Checklist")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                        .frame(width: 28, height: 28)
                                    
                                    Circle()
                                        .trim(from: 0, to: Double(currentProgress) / Double(maxProgress))
                                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .frame(width: 28, height: 28)
                                        .rotationEffect(.degrees(-90))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(hex: "#323232"))
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Content
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
                        
                        Spacer()
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
    }
}


#Preview {
    ChecklistProgressView()
}