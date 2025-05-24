/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Vertical LED strip eye view component for robot face.
*/

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 垂直LED条眼睛视图（根据设计图）
struct VerticalLEDEyeView: View {
    let eyePosition: CGPoint
    let isBlinking: Bool
    let mood: RobotMood
    let eyeWidth: CGFloat
    let eyeHeight: CGFloat
    let isLeftEye: Bool
    let ledBrightness: Double
    let ledGlow: Double
    
    // 特殊动画状态
    let specialAnimationOffset: CGFloat
    let rotationAngle: Double
    let scaleEffect: Double
    let colorShift: Double
    
    // 眼球预测跟随状态
    @State private var previousPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @State private var predictedPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @State private var positionHistory: [CGPoint] = []
    
    var body: some View {
        ZStack {
            if !isBlinking || shouldShowSpecialEye {
                // 根据设计图的垂直LED条
                verticalLEDStrip
            } else {
                // LED条眨眼效果 - 极细的线条
                blinkingStrip
            }
        }
        .rotationEffect(.degrees(rotationAngle * (isLeftEye ? 1 : -1)))
        .scaleEffect(scaleEffect)
        .offset(x: specialAnimationOffset * (isLeftEye ? 1 : -1), y: 0)
        .animation(.easeInOut(duration: 0.15), value: isBlinking)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: predictedPosition)
        .onChange(of: eyePosition) { oldValue, newValue in
            updatePredictedPosition(newPosition: newValue)
        }
    }
    
    // MARK: - Special Eye Effects
    
    private var shouldShowSpecialEye: Bool {
        // 某些表情即使在眨眼时也要显示特殊效果
        switch mood {
        case .anger, .fear, .surprise, .joy:
            return true
        default:
            return false
        }
    }
    
    // MARK: - LED Strip Components
    
    @ViewBuilder
    private var verticalLEDStrip: some View {
        ZStack {
            // 外发光效果 (模糊70, 透明度55%)
            RoundedRectangle(cornerRadius: moodCornerRadius)
                .fill(
                    RadialGradient(
                        colors: [
                            moodLEDColor.opacity(0.55 * ledGlow), // 55%透明度
                            moodLEDColor.opacity(0.3 * ledGlow),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: eyeWidth * 0.3,
                        endRadius: eyeWidth * 3.5
                    )
                )
                .frame(width: eyeWidth * glowScale, height: eyeHeight * glowScale)
                .blur(radius: 70 * ledGlow / 10) // 模糊70效果
                .offset(eyeTrackingOffset) // 发光效果也跟随移动
            
            // 主LED条 - 垂直渐变（带眼球跟随效果）
            RoundedRectangle(cornerRadius: moodCornerRadius)
                .fill(moodGradient)
                .frame(width: eyeWidth * moodWidthScale, height: eyeHeight * moodHeightScale)
                .shadow(color: moodLEDColor.opacity(0.8), radius: 8, x: 0, y: 0)
                .scaleEffect(ledBrightness)
                .offset(eyeTrackingOffset) // LED条跟随眼球位置移动
                .overlay(
                    // 特殊表情的额外效果
                    moodSpecialOverlay
                )
        }
    }
    
    @ViewBuilder
    private var blinkingStrip: some View {
        // LED条眨眼 - 根据表情调整
        RoundedRectangle(cornerRadius: 1)
            .fill(
                LinearGradient(
                    colors: [
                        moodLEDColor.opacity(0.8),
                        moodLEDColor.opacity(0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: eyeWidth, height: blinkHeight)
            .shadow(color: moodLEDColor.opacity(0.4), radius: 2, x: 0, y: 0)
    }
    
    // MARK: - Mood-Specific Properties
    
    private var moodLEDColor: Color {
        let baseColor = designBlueColor
        
        switch mood {
        case .anger:
            return Color.lerp(baseColor, Color.red, factor: colorShift)
        case .fear:
            return Color.lerp(baseColor, Color.gray, factor: 0.7)
        case .disgust:
            return Color.lerp(baseColor, Color.green, factor: 0.6)
        case .love:
            return Color.lerp(baseColor, Color.pink, factor: 0.8)
        case .envy:
            return Color.lerp(baseColor, Color.green, factor: 0.5)
        case .joy, .happy:
            return Color.lerp(baseColor, Color.yellow, factor: 0.4)
        case .sadness, .sad, .guilt:
            return Color.lerp(baseColor, Color.purple, factor: 0.3)
        case .sleepy:
            return Color.lerp(baseColor, Color.purple, factor: 0.5)
        case .surprise:
            return Color.lerp(baseColor, Color.cyan, factor: 0.6)
        case .pride:
            return Color.lerp(baseColor, Color.orange, factor: 0.5)
        default:
            return baseColor
        }
    }
    
    private var moodGradient: LinearGradient {
        let color = moodLEDColor
        
        switch mood {
        case .anger:
            return LinearGradient(
                colors: [
                    color,
                    Color.red.opacity(0.8),
                    color
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .love:
            return LinearGradient(
                colors: [
                    color,
                    Color.pink.opacity(0.6),
                    Color.red.opacity(0.4),
                    color
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .joy, .happy:
            return LinearGradient(
                colors: [
                    Color.yellow.opacity(0.8),
                    color,
                    Color.yellow.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [
                    color,
                    color.opacity(0.8),
                    color.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    @ViewBuilder
    private var moodSpecialOverlay: some View {
        switch mood {
        case .surprise:
            // 惊讶：中心爆炸效果
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 4, height: 4)
                .scaleEffect(ledBrightness * 1.5)
                .blur(radius: 2)
                
        case .love:
            // 爱心：心形光点
            Image(systemName: "heart.fill")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.7))
                .scaleEffect(ledBrightness)
                
        case .anger:
            // 愤怒：锯齿边缘
            Rectangle()
                .fill(Color.red.opacity(0.5))
                .frame(width: eyeWidth * 0.1, height: eyeHeight)
                .opacity(colorShift)
                
        case .curiosity:
            // 好奇：问号
            Text("?")
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .scaleEffect(ledBrightness)
                
        default:
            EmptyView()
        }
    }
    
    // MARK: - Mood-Specific Scaling
    
    private var moodWidthScale: CGFloat {
        switch mood {
        case .surprise: return 1.2
        case .fear: return 0.8
        case .sleepy: return 0.6
        case .anger: return 1.1
        default: return 1.0
        }
    }
    
    private var moodHeightScale: CGFloat {
        switch mood {
        case .surprise: return 1.3
        case .fear: return 0.9
        case .sleepy: return 0.7
        case .excited, .joy: return 1.2
        default: return 1.0
        }
    }
    
    private var moodCornerRadius: CGFloat {
        switch mood {
        case .anger: return 2  // 更尖锐
        case .love: return 8   // 更圆润
        case .sleepy: return 6 // 更柔和
        default: return 4
        }
    }
    
    private var glowScale: CGFloat {
        switch mood {
        case .surprise, .joy: return 3.0
        case .fear: return 2.0
        case .sleepy: return 1.5
        default: return 2.5
        }
    }
    
    private var blinkHeight: CGFloat {
        switch mood {
        case .sleepy: return 1   // 非常细
        case .anger: return 4    // 稍粗
        default: return 2
        }
    }
    
    // MARK: - Base Colors and Tracking
    
    private var designBlueColor: Color {
        // 使用设计图中的蓝色
        Color(red: 0.2, green: 0.8, blue: 1.0) // #33CBFE
    }
    
    private var eyeTrackingOffset: CGSize {
        let baseOffset = CGSize(
            width: (predictedPosition.x - 0.5) * eyeWidth * 2.0, // 添加水平跟踪，使用2倍放大让移动更明显
            height: (predictedPosition.y - 0.5) * eyeHeight * 0.4 // 使用预测位置进行垂直跟踪
        )
        
        // 根据表情调整跟踪敏感度
        let sensitivity: CGFloat
        switch mood {
        case .surprise, .fear: sensitivity = 1.5
        case .sleepy: sensitivity = 0.5
        default: sensitivity = 1.0
        }
        
        return CGSize(
            width: baseOffset.width * sensitivity,
            height: baseOffset.height * sensitivity
        )
    }
    
    // MARK: - Eye Tracking Logic
    
    private func updatePredictedPosition(newPosition: CGPoint) {
        // 简化预测算法，让眼球跟随更直接
        // 如果位置变化不大，直接使用当前位置
        let positionChange = sqrt(pow(newPosition.x - previousPosition.x, 2) + pow(newPosition.y - previousPosition.y, 2))
        
        if positionChange < 0.01 {
            // 位置变化很小，保持当前预测位置
            return
        }
        
        // 计算移动方向和速度
        let velocity = CGPoint(
            x: newPosition.x - previousPosition.x,
            y: newPosition.y - previousPosition.y
        )
        
        // 简单的预测：当前位置 + 小量的预测
        let predictionFactor: CGFloat = 0.3 // 减少预测量
        var predicted = CGPoint(
            x: newPosition.x + velocity.x * predictionFactor,
            y: newPosition.y + velocity.y * predictionFactor
        )
        
        // 限制在合理范围内
        predicted.x = max(0.1, min(0.9, predicted.x))
        predicted.y = max(0.2, min(0.8, predicted.y))
        
        // 直接设置预测位置，使用快速动画
        withAnimation(.easeOut(duration: 0.2)) {
            predictedPosition = predicted
        }
        
        previousPosition = newPosition
    }
}

// MARK: - Color Extension for lerp function

extension Color {
    static func lerp(_ color1: Color, _ color2: Color, factor: Double) -> Color {
        let factor = max(0, min(1, factor))
        
        #if canImport(UIKit)
        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 + (r2 - r1) * factor
        let g = g1 + (g2 - g1) * factor
        let b = b1 + (b2 - b1) * factor
        let a = a1 + (a2 - a1) * factor
        
        return Color(red: r, green: g, blue: b, opacity: a)
        #else
        // 简化版本，适用于macOS等平台
        return factor < 0.5 ? color1 : color2
        #endif
    }
} 