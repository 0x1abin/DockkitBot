/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A robot face view that displays animated eyes and expressions.
*/

import SwiftUI

/// A view that displays a robot face with animated eyes that track face positions.
struct RobotFaceView: View {
    @State var robotFaceState: RobotFaceState
    
    private let faceSize: CGFloat = 300
    private let eyeSize: CGFloat = 60
    private let pupilSize: CGFloat = 30
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Robot face container
                ZStack {
                    // Face outline
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Color.gray.opacity(0.3))
                        .stroke(Color.cyan, lineWidth: 3)
                        .frame(width: faceSize, height: faceSize * 0.8)
                    
                    // Eyes container
                    HStack(spacing: 60) {
                        // Left eye
                        RobotEyeView(
                            eyePosition: robotFaceState.leftEyePosition,
                            isBlinking: robotFaceState.isBlinking,
                            mood: robotFaceState.mood,
                            eyeSize: eyeSize,
                            pupilSize: pupilSize
                        )
                        
                        // Right eye
                        RobotEyeView(
                            eyePosition: robotFaceState.rightEyePosition,
                            isBlinking: robotFaceState.isBlinking,
                            mood: robotFaceState.mood,
                            eyeSize: eyeSize,
                            pupilSize: pupilSize
                        )
                    }
                    .offset(y: -20)
                    
                    // Mouth based on mood
                    robotMouth
                        .offset(y: 60)
                }
                
                // Status indicator
                HStack {
                    Circle()
                        .fill(robotFaceState.isTracking ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut(duration: 0.5), value: robotFaceState.isTracking)
                    
                    Text(robotFaceState.isTracking ? "Tracking Face" : "Searching for Face")
                        .foregroundColor(robotFaceState.isTracking ? .green : .red)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.top, 20)
            }
        }
        .onAppear {
            startBlinkingAnimation()
        }
    }
    
    @ViewBuilder
    private var robotMouth: some View {
        switch robotFaceState.mood {
        case .normal:
            Rectangle()
                .fill(Color.cyan)
                .frame(width: 40, height: 4)
                .cornerRadius(2)
        case .happy:
            Arc(startAngle: .degrees(0), endAngle: .degrees(180))
                .stroke(Color.cyan, lineWidth: 4)
                .frame(width: 50, height: 25)
        case .sad:
            Arc(startAngle: .degrees(180), endAngle: .degrees(360))
                .stroke(Color.cyan, lineWidth: 4)
                .frame(width: 50, height: 25)
        case .excited:
            Circle()
                .fill(Color.cyan)
                .frame(width: 30, height: 30)
        case .sleepy:
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cyan.opacity(0.5))
                .frame(width: 50, height: 8)
        }
    }
    
    private func startBlinkingAnimation() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 2...5), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                robotFaceState.isBlinking = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    robotFaceState.isBlinking = false
                }
            }
        }
    }
}

/// A view that represents a single robot eye with animated pupil.
struct RobotEyeView: View {
    let eyePosition: CGPoint
    let isBlinking: Bool
    let mood: RobotMood
    let eyeSize: CGFloat
    let pupilSize: CGFloat
    
    var body: some View {
        ZStack {
            // Eye white/background
            Circle()
                .fill(Color.white)
                .frame(width: eyeSize, height: isBlinking ? 4 : eyeSize)
                .overlay(
                    Circle()
                        .stroke(Color.cyan, lineWidth: 2)
                        .frame(width: eyeSize, height: isBlinking ? 4 : eyeSize)
                )
            
            if !isBlinking {
                // Pupil
                Circle()
                    .fill(pupilColor)
                    .frame(width: pupilSize, height: pupilSize)
                    .offset(
                        x: (eyePosition.x - 0.5) * (eyeSize - pupilSize) * 0.8,
                        y: (eyePosition.y - 0.5) * (eyeSize - pupilSize) * 0.8
                    )
                    .animation(.easeOut(duration: 0.3), value: eyePosition)
                
                // Highlight
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: (eyePosition.x - 0.5) * (eyeSize - pupilSize) * 0.8 - 6,
                        y: (eyePosition.y - 0.5) * (eyeSize - pupilSize) * 0.8 - 6
                    )
                    .animation(.easeOut(duration: 0.3), value: eyePosition)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isBlinking)
    }
    
    private var pupilColor: Color {
        switch mood {
        case .normal:
            return .black
        case .happy:
            return .blue
        case .sad:
            return .gray
        case .excited:
            return .orange
        case .sleepy:
            return .black.opacity(0.6)
        }
    }
}

/// A simple arc shape for drawing mouth expressions.
struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

#Preview {
    RobotFaceView(robotFaceState: RobotFaceState())
} 