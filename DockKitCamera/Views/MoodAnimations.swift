/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Mood animation logic for robot face expressions.
*/

import SwiftUI
import Foundation

// MARK: - Mood Animation Controller

/// 表情动画控制器
@Observable
class MoodAnimationController {
    // 特殊动画状态
    private(set) var specialAnimationOffset: CGFloat = 0
    private(set) var rotationAngle: Double = 0
    private(set) var scaleEffect: Double = 1.0
    private(set) var colorShift: Double = 0
    
    // LED动画状态
    private(set) var ledBrightness: Double = 1.0
    private(set) var ledGlow: Double = 0.8
    
    private var animationTimers: [Timer] = []
    
    // MARK: - LED Animations
    
    func startLEDAnimations() {
        // LED呼吸效果
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            ledBrightness = 1.2
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            ledGlow = 1.0
        }
    }
    
    func startMoodAnimations() {
        // 启动持续的表情相关动画
        let timer1 = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // 这里会在RobotFaceView中调用updateMoodAnimations
        }
        
        // 启动高级动画定时器
        let timer2 = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            // 这里会在RobotFaceView中调用updateAdvancedAnimations
        }
        
        animationTimers.append(contentsOf: [timer1, timer2])
    }
    
    func stopAnimations() {
        animationTimers.forEach { $0.invalidate() }
        animationTimers.removeAll()
    }
    
    // MARK: - Mood Specific Animations
    
    func updateMoodAnimations(for mood: RobotMood) {
        switch mood {
        case .excited, .anticipation:
            // 兴奋状态：快速闪烁
            withAnimation(.easeInOut(duration: 0.3)) {
                ledBrightness = ledBrightness > 1.0 ? 0.8 : 1.3
            }
            
        case .sleepy:
            // 困倦状态：缓慢呼吸
            withAnimation(.easeInOut(duration: 3.0)) {
                ledBrightness = ledBrightness > 1.0 ? 0.5 : 1.0
            }
            
        case .anger:
            // 愤怒状态：红色闪烁
            withAnimation(.easeInOut(duration: 0.5)) {
                colorShift = colorShift > 0.5 ? 0.0 : 1.0
            }
            
        case .fear:
            // 恐惧状态：颤抖效果
            withAnimation(.easeInOut(duration: 0.2)) {
                specialAnimationOffset = specialAnimationOffset > 0 ? -2 : 2
            }
            
        case .surprise:
            // 惊讶状态：放大效果
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                scaleEffect = scaleEffect > 1.0 ? 1.0 : 1.2
            }
            
        case .joy:
            // 欢喜状态：旋转效果
            withAnimation(.linear(duration: 2.0)) {
                rotationAngle += 5
            }
            
        case .love:
            // 爱恋状态：强烈心跳效果
            withAnimation(.easeInOut(duration: 0.6)) {
                scaleEffect = scaleEffect > 1.0 ? 1.0 : 1.4  // 更大的心跳幅度
                ledBrightness = ledBrightness > 1.0 ? 0.8 : 1.5  // 更强的亮度变化
                ledGlow = ledGlow > 0.8 ? 0.6 : 1.3  // 添加发光效果
                colorShift = colorShift > 0.5 ? 0.2 : 0.9  // 粉色心跳
            }
            
        case .curiosity:
            // 好奇状态：微妙摆动
            withAnimation(.easeInOut(duration: 1.5)) {
                specialAnimationOffset = specialAnimationOffset > 0 ? 0 : 1
            }
            
        case .disgust:
            // 厌恶状态：不规则颤抖
            withAnimation(.easeInOut(duration: 0.3)) {
                specialAnimationOffset = Double.random(in: -1...1)
            }
            
        case .envy:
            // 嫉妒状态：绿色波动
            withAnimation(.easeInOut(duration: 1.2)) {
                colorShift = colorShift > 0.5 ? 0.2 : 0.8
                ledBrightness = ledBrightness > 1.0 ? 0.8 : 1.1
            }
            
        case .pride:
            // 骄傲状态：橙色光芒
            withAnimation(.easeInOut(duration: 2.0)) {
                ledGlow = ledGlow > 0.8 ? 0.6 : 1.2
                scaleEffect = scaleEffect > 1.0 ? 1.0 : 1.05
            }
            
        case .shame, .guilt:
            // 羞耻/内疚状态：微弱闪烁
            withAnimation(.easeInOut(duration: 2.5)) {
                ledBrightness = ledBrightness > 0.7 ? 0.4 : 0.7
            }
            
        default:
            // 恢复默认状态
            withAnimation(.easeInOut(duration: 1.0)) {
                specialAnimationOffset = 0
                rotationAngle = 0
                scaleEffect = 1.0
                colorShift = 0
            }
        }
    }
    
    func updateAdvancedAnimations(for mood: RobotMood) {
        // 高频率的精细动画更新
        switch mood {
        case .trust:
            // 信任状态：温和的波动
            let time = Date().timeIntervalSince1970
            withAnimation(.linear(duration: 0.1)) {
                ledBrightness = 1.0 + sin(time * 2) * 0.1
            }
            
        case .acceptance:
            // 接纳状态：柔和的呼吸
            let time = Date().timeIntervalSince1970
            withAnimation(.linear(duration: 0.1)) {
                scaleEffect = 1.0 + sin(time * 1.5) * 0.05
                ledGlow = 0.8 + sin(time * 1.2) * 0.2
            }
            
        case .contempt:
            // 蔑视状态：缓慢的不屑摆动
            let time = Date().timeIntervalSince1970
            withAnimation(.linear(duration: 0.1)) {
                specialAnimationOffset = sin(time * 0.8) * 1.5
            }
            
        case .love:
            // 爱恋状态：持续的心跳律动
            let time = Date().timeIntervalSince1970
            let heartbeatRate = 1.2  // 心跳频率
            let heartbeat = sin(time * heartbeatRate)
            
            withAnimation(.linear(duration: 0.1)) {
                // 双重心跳效果 (lub-dub)
                let doubleBeat = sin(time * heartbeatRate * 2) * 0.3 + heartbeat * 0.7
                scaleEffect = 1.0 + doubleBeat * 0.25  // 持续的缩放心跳
                ledBrightness = 1.0 + doubleBeat * 0.3  // 亮度心跳
                ledGlow = 0.8 + abs(doubleBeat) * 0.4  // 发光心跳
                colorShift = 0.5 + doubleBeat * 0.3  // 粉色强度变化
            }
            
        default:
            break
        }
    }
    
    func triggerMoodAnimation(for mood: RobotMood) {
        switch mood {
        case .surprise:
            // 惊讶时的爆发式放大
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scaleEffect = 1.5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.scaleEffect = 1.0
                }
            }
            
        case .fear:
            // 恐惧时的快速颤抖
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    withAnimation(.easeInOut(duration: 0.05)) {
                        self.specialAnimationOffset = (i % 2 == 0) ? 3 : -3
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.specialAnimationOffset = 0
                }
            }
            
        case .joy:
            // 欢喜时的旋转庆祝
            withAnimation(.linear(duration: 1.0)) {
                rotationAngle += 360
            }
            
        case .anger:
            // 愤怒时的红色闪烁
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.colorShift = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            self.colorShift = 0.0
                        }
                    }
                }
            }
            
        case .love:
            // 爱恋时的壮观心跳动画序列
            for i in 0..<5 {  // 增加到5次心跳
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8) {
                    // 第一阶段：强烈放大
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                        self.scaleEffect = 1.6  // 更大的放大效果
                        self.colorShift = 1.0   // 完全粉色
                        self.ledBrightness = 1.8  // 超亮
                        self.ledGlow = 1.5      // 强发光
                    }
                    
                    // 第二阶段：快速回缩但保持温暖
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                            self.scaleEffect = 1.1   // 稍微保持放大
                            self.colorShift = 0.6    // 保持粉色调
                            self.ledBrightness = 1.2
                            self.ledGlow = 1.0
                        }
                    }
                    
                    // 第三阶段：温柔回到正常（最后一次心跳后）
                    if i == 4 {  // 最后一次心跳
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                self.scaleEffect = 1.0
                                self.colorShift = 0.3  // 保留淡淡的粉色
                                self.ledBrightness = 1.0
                                self.ledGlow = 0.8
                            }
                        }
                    }
                }
            }
            
        case .excited:
            // 兴奋时的快速彩虹效果
            for i in 0..<8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.colorShift = Double(i) / 7.0
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.colorShift = 0.0
                }
            }
            
        case .sleepy:
            // 困倦时的缓慢眨眼
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.5) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self.ledBrightness = 0.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            self.ledBrightness = 1.0
                        }
                    }
                }
            }
            
        case .curiosity:
            // 好奇时的探索动画
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        self.specialAnimationOffset = (i % 2 == 0) ? 2 : -2
                        self.scaleEffect = 1.1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            self.specialAnimationOffset = 0
                            self.scaleEffect = 1.0
                        }
                    }
                }
            }
            
        case .disgust:
            // 厌恶时的后退动画
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scaleEffect = 0.8
                specialAnimationOffset = -3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.scaleEffect = 1.0
                    self.specialAnimationOffset = 0
                }
            }
            
        case .pride:
            // 骄傲时的挺立动画
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scaleEffect = 1.2
                rotationAngle = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.scaleEffect = 1.0
                    self.rotationAngle = 0
                }
            }
            
        case .shame:
            // 羞耻时的缩小隐藏
            withAnimation(.easeInOut(duration: 0.5)) {
                scaleEffect = 0.7
                ledBrightness = 0.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.scaleEffect = 1.0
                    self.ledBrightness = 1.0
                }
            }
            
        case .guilt:
            // 内疚时的低头效果
            withAnimation(.easeInOut(duration: 0.6)) {
                specialAnimationOffset = 0
                scaleEffect = 0.9
                ledBrightness = 0.6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.scaleEffect = 1.0
                    self.ledBrightness = 1.0
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - Tap Feedback Animation
    
    func triggerTapFeedback() {
        // 先触发点击反馈动画
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            scaleEffect = 0.95  // 轻微缩小表示点击
        }
        
        // 延迟一点再恢复，营造按压感
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.scaleEffect = 1.0  // 恢复原大小
            }
            
            // 添加轻微的屏幕震动效果（通过快速缩放）
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                self.scaleEffect = 1.05
            }
            
            // 立即恢复正常大小
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.scaleEffect = 1.0
                }
            }
        }
    }
}

// MARK: - Mood Helper Functions
// Note: RobotMood extensions are defined in DataTypes.swift 