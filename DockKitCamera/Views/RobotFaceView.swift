/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A robot face view that displays animated eyes and expressions.
*/

import SwiftUI

/// A view that displays a robot face with animated eyes that track face positions.
struct RobotFaceView: View {
    @State var robotFaceState: RobotFaceState
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: dynamicSpacing(for: geometry)) {
                    Spacer()
                    
                    // Robot face container
                    ZStack {
                        // Face outline
                        RoundedRectangle(cornerRadius: dynamicCornerRadius(for: geometry))
                            .fill(Color.gray.opacity(0.3))
                            .stroke(Color.cyan, lineWidth: 3)
                            .frame(width: faceWidth(for: geometry), height: faceHeight(for: geometry))
                        
                        // Eyes container
                        HStack(spacing: eyeSpacing(for: geometry)) {
                            // Left eye
                            RobotEyeView(
                                eyePosition: robotFaceState.leftEyePosition,
                                isBlinking: robotFaceState.isBlinking,
                                mood: robotFaceState.mood,
                                eyeSize: eyeSize(for: geometry),
                                pupilSize: pupilSize(for: geometry)
                            )
                            
                            // Right eye
                            RobotEyeView(
                                eyePosition: robotFaceState.rightEyePosition,
                                isBlinking: robotFaceState.isBlinking,
                                mood: robotFaceState.mood,
                                eyeSize: eyeSize(for: geometry),
                                pupilSize: pupilSize(for: geometry)
                            )
                        }
                        .offset(y: eyeOffsetY(for: geometry))
                        
                        // Mouth based on mood
                        robotMouth(for: geometry)
                            .offset(y: mouthOffsetY(for: geometry))
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    statusIndicator(for: geometry)
                        .padding(.bottom, isLandscape(geometry) ? 20 : 40)
                }
            }
        }
        .onAppear {
            startBlinkingAnimation()
        }
    }
    
    // MARK: - Layout Calculations
    
    private func isLandscape(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width > geometry.size.height
    }
    
    private func faceWidth(for geometry: GeometryProxy) -> CGFloat {
        let baseSize = min(geometry.size.width, geometry.size.height) * 0.6
        return isLandscape(geometry) ? baseSize * 0.8 : baseSize
    }
    
    private func faceHeight(for geometry: GeometryProxy) -> CGFloat {
        faceWidth(for: geometry) * 0.8
    }
    
    private func eyeSize(for geometry: GeometryProxy) -> CGFloat {
        faceWidth(for: geometry) * 0.2
    }
    
    private func pupilSize(for geometry: GeometryProxy) -> CGFloat {
        eyeSize(for: geometry) * 0.5
    }
    
    private func eyeSpacing(for geometry: GeometryProxy) -> CGFloat {
        faceWidth(for: geometry) * 0.25
    }
    
    private func eyeOffsetY(for geometry: GeometryProxy) -> CGFloat {
        -faceHeight(for: geometry) * 0.15
    }
    
    private func mouthOffsetY(for geometry: GeometryProxy) -> CGFloat {
        faceHeight(for: geometry) * 0.25
    }
    
    private func dynamicSpacing(for geometry: GeometryProxy) -> CGFloat {
        isLandscape(geometry) ? 10 : 20
    }
    
    private func dynamicCornerRadius(for geometry: GeometryProxy) -> CGFloat {
        faceWidth(for: geometry) * 0.133 // Proportional to face width
    }
    
    // MARK: - UI Components
    
    @ViewBuilder
    private func robotMouth(for geometry: GeometryProxy) -> some View {
        let mouthWidth = faceWidth(for: geometry) * 0.167 // ~50/300
        let mouthHeight = faceHeight(for: geometry) * 0.104 // ~25/240
        
        switch robotFaceState.mood {
        case .normal:
            Rectangle()
                .fill(Color.cyan)
                .frame(width: mouthWidth * 0.8, height: 4)
                .cornerRadius(2)
        case .happy:
            Arc(startAngle: .degrees(0), endAngle: .degrees(180))
                .stroke(Color.cyan, lineWidth: 4)
                .frame(width: mouthWidth, height: mouthHeight)
        case .sad:
            Arc(startAngle: .degrees(180), endAngle: .degrees(360))
                .stroke(Color.cyan, lineWidth: 4)
                .frame(width: mouthWidth, height: mouthHeight)
        case .excited:
            Circle()
                .fill(Color.cyan)
                .frame(width: mouthWidth * 0.6, height: mouthWidth * 0.6)
        case .sleepy:
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cyan.opacity(0.5))
                .frame(width: mouthWidth, height: 8)
        }
    }
    
    @ViewBuilder
    private func statusIndicator(for geometry: GeometryProxy) -> some View {
        let fontSize: CGFloat = isLandscape(geometry) ? 14 : 16
        let circleSize: CGFloat = isLandscape(geometry) ? 10 : 12
        
        if isLandscape(geometry) {
            HStack(spacing: 8) {
                Circle()
                    .fill(robotFaceState.isTracking ? Color.green : Color.red)
                    .frame(width: circleSize, height: circleSize)
                    .animation(.easeInOut(duration: 0.5), value: robotFaceState.isTracking)
                
                Text(robotFaceState.isTracking ? "Tracking Face" : "Searching for Face")
                    .foregroundColor(robotFaceState.isTracking ? .green : .red)
                    .font(.system(size: fontSize, weight: .medium))
            }
        } else {
            VStack(spacing: 8) {
                Circle()
                    .fill(robotFaceState.isTracking ? Color.green : Color.red)
                    .frame(width: circleSize, height: circleSize)
                    .animation(.easeInOut(duration: 0.5), value: robotFaceState.isTracking)
                
                Text(robotFaceState.isTracking ? "Tracking Face" : "Searching for Face")
                    .foregroundColor(robotFaceState.isTracking ? .green : .red)
                    .font(.system(size: fontSize, weight: .medium))
            }
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
                    .frame(width: pupilSize * 0.27, height: pupilSize * 0.27) // Proportional highlight
                    .offset(
                        x: (eyePosition.x - 0.5) * (eyeSize - pupilSize) * 0.8 - pupilSize * 0.2,
                        y: (eyePosition.y - 0.5) * (eyeSize - pupilSize) * 0.8 - pupilSize * 0.2
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