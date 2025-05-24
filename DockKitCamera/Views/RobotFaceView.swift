/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A robot face view that displays animated eyes and expressions.
*/

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A view that displays a robot face with animated eyes that track face positions.
struct RobotFaceView: View {
    @State var robotFaceState: RobotFaceState
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 纯黑背景
                Color.black
                    .ignoresSafeArea(.all)
                
                // 极简机器人脸部
                VStack(spacing: 0) {
                    Spacer()
                    
                    // 眼睛区域 - 固定比例
                    HStack(spacing: faceWidth(for: geometry) * 0.3) {
                        // 左眼
                        MinimalEyeView(
                            eyePosition: robotFaceState.leftEyePosition,
                            isBlinking: robotFaceState.isBlinking,
                            mood: robotFaceState.mood,
                            eyeSize: eyeSize(for: geometry)
                        )
                        
                        // 右眼
                        MinimalEyeView(
                            eyePosition: robotFaceState.rightEyePosition,
                            isBlinking: robotFaceState.isBlinking,
                            mood: robotFaceState.mood,
                            eyeSize: eyeSize(for: geometry)
                        )
                    }
                    
                    // 眼睛到嘴巴的固定间距
                    Spacer()
                        .frame(height: faceWidth(for: geometry) * 0.25)
                    
                    // 嘴巴区域
                    minimalMouth(for: geometry)
                    
                    Spacer()
                }
                
                // 简化的状态指示器
                simpleStatusIndicator(for: geometry)
            }
        }
        .ignoresSafeArea(.all)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            startBlinkingAnimation()
        }
    }
    
    // MARK: - 固定比例计算
    
    private func faceWidth(for geometry: GeometryProxy) -> CGFloat {
        // 使用固定的脸部宽度比例，不区分横竖屏
        return min(geometry.size.width, geometry.size.height) * 0.7
    }
    
    private func eyeSize(for geometry: GeometryProxy) -> CGFloat {
        // 眼睛大小为脸部宽度的18%
        return faceWidth(for: geometry) * 0.18
    }
    
    // MARK: - 极简UI组件
    
    @ViewBuilder
    private func minimalMouth(for geometry: GeometryProxy) -> some View {
        let mouthWidth = faceWidth(for: geometry) * 0.15
        
        switch robotFaceState.mood {
        case .normal:
            // 简单线条
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: mouthWidth, height: 3)
                .animation(.easeInOut(duration: 0.3), value: robotFaceState.mood)
                
        case .happy:
            // 简单弧形笑脸
            Arc(startAngle: .degrees(20), endAngle: .degrees(160))
                .stroke(Color.white.opacity(0.8), lineWidth: 4)
                .frame(width: mouthWidth, height: mouthWidth * 0.6)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: robotFaceState.mood)
                
        case .sad:
            // 简单倒弧
            Arc(startAngle: .degrees(200), endAngle: .degrees(340))
                .stroke(Color.white.opacity(0.6), lineWidth: 4)
                .frame(width: mouthWidth, height: mouthWidth * 0.4)
                .animation(.easeInOut(duration: 0.4), value: robotFaceState.mood)
                
        case .excited:
            // 简单圆形
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: mouthWidth * 0.7, height: mouthWidth * 0.7)
                .scaleEffect(robotFaceState.isTracking ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: robotFaceState.isTracking)
                
        case .sleepy:
            // 简单椭圆
            Ellipse()
                .fill(Color.white.opacity(0.5))
                .frame(width: mouthWidth, height: 4)
                .animation(.easeInOut(duration: 0.3), value: robotFaceState.mood)
        }
    }
    
    @ViewBuilder
    private func simpleStatusIndicator(for geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(robotFaceState.isTracking ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: robotFaceState.isTracking)
                    
                    Text(robotFaceState.isTracking ? "👁️" : "🔍")
                        .font(.system(size: 12))
                        .opacity(0.8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.leading, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            Spacer()
        }
    }
    
    private func startBlinkingAnimation() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...6), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                robotFaceState.isBlinking = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    robotFaceState.isBlinking = false
                }
            }
        }
    }
}

/// 极简眼睛视图
struct MinimalEyeView: View {
    let eyePosition: CGPoint
    let isBlinking: Bool
    let mood: RobotMood
    let eyeSize: CGFloat
    
    var body: some View {
        ZStack {
            // 简单的白色圆形眼白
            Circle()
                .fill(Color.white)
                .frame(width: eyeSize, height: isBlinking ? 4 : eyeSize)
                .animation(.easeInOut(duration: 0.1), value: isBlinking)
            
            if !isBlinking {
                // 简单的黑色瞳孔
                Circle()
                    .fill(pupilColor)
                    .frame(width: eyeSize * 0.5, height: eyeSize * 0.5)
                    .offset(
                        x: (eyePosition.x - 0.5) * eyeSize * 0.3,
                        y: (eyePosition.y - 0.5) * eyeSize * 0.3
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: eyePosition)
                
                // 简单的白色高光
                Circle()
                    .fill(Color.white)
                    .frame(width: eyeSize * 0.15, height: eyeSize * 0.15)
                    .offset(
                        x: (eyePosition.x - 0.5) * eyeSize * 0.3 - eyeSize * 0.1,
                        y: (eyePosition.y - 0.5) * eyeSize * 0.3 - eyeSize * 0.1
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: eyePosition)
            }
        }
    }
    
    private var pupilColor: Color {
        switch mood {
        case .normal:
            return Color.black
        case .happy:
            return Color.blue.opacity(0.9)
        case .sad:
            return Color.gray.opacity(0.8)
        case .excited:
            return Color.orange.opacity(0.9)
        case .sleepy:
            return Color.black.opacity(0.7)
        }
    }
}

/// 简单弧形形状
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