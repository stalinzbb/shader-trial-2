//
//  SplashScreenView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 7/23/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var phase: CGFloat = 0
    @State private var showHomeScreen = false
    
    var body: some View {
        if showHomeScreen {
            HomeScreenView()
        } else {
            ZStack {
                FlowingGradientView(phase: phase)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    Text("Your App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    Spacer()
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    phase = 2 * .pi
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showHomeScreen = true
                    }
                }
            }
        }
    }
}

struct FlowingGradientView: View {
    let phase: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            
            let gradient = Gradient(colors: [
                Color.purple,
                Color.blue,
                Color.cyan,
                Color.green,
                Color.yellow,
                Color.orange,
                Color.red,
                Color.purple
            ])
            
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = max(size.width, size.height) * 0.8
            
            let startAngle = phase
            let endAngle = phase + .pi
            
            let startPoint = CGPoint(
                x: center.x + cos(startAngle) * radius * 0.3,
                y: center.y + sin(startAngle) * radius * 0.3
            )
            
            let endPoint = CGPoint(
                x: center.x + cos(endAngle) * radius * 0.3,
                y: center.y + sin(endAngle) * radius * 0.3
            )
            
            context.fill(
                Path(rect),
                with: .linearGradient(
                    gradient,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            
            let wave1 = createWavePath(
                size: size,
                amplitude: 50,
                frequency: 2,
                phase: phase
            )
            
            let wave2 = createWavePath(
                size: size,
                amplitude: 30,
                frequency: 3,
                phase: phase + .pi / 2
            )
            
            context.addFilter(.blur(radius: 20))
            context.fill(wave1, with: .color(.white.opacity(0.1)))
            context.fill(wave2, with: .color(.white.opacity(0.1)))
        }
        .drawingGroup()
    }
    
    private func createWavePath(size: CGSize, amplitude: CGFloat, frequency: CGFloat, phase: CGFloat) -> Path {
        Path { path in
            let width = size.width
            let height = size.height
            let midY = height / 2
            
            path.move(to: CGPoint(x: 0, y: midY))
            
            for x in stride(from: 0, through: width, by: 2) {
                let relativeX = x / width
                let sine = sin((relativeX * frequency * 2 * .pi) + phase)
                let y = midY + sine * amplitude
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
    }
}

#Preview {
    SplashScreenView()
}