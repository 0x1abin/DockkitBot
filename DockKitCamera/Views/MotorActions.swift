/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Motor action types and execution logic for DockKit accessories.
*/

import Foundation
#if canImport(DockKit)
import DockKit
#endif
#if canImport(Spatial)
import Spatial
#endif

// Import required types
// 导入必要的类型定义

// MARK: - Required Types Import

// 从 DataTypes.swift 导入的类型
// RobotMood, TrackingMode 需要从 DataTypes.swift 导入

// 从 DockAccessoryController.swift 导入的类型  
// DockController 需要从 DockAccessoryController.swift 导入

// 为模拟器环境提供类型定义
#if !canImport(DockKit) || !canImport(Spatial)
// 模拟器中的替代类型定义
struct DockAccessory {
    func setOrientation(_ rotation: Rotation3D, duration: TimeInterval, relative: Bool) async throws -> Progress {
        return Progress()
    }
    
    func setAngularVelocity(_ vector: Vector3D) async throws {
        // 模拟器中的空实现
    }
}

struct Rotation3D {
    init(eulerAngles: EulerAngles) {}
}

struct EulerAngles {
    enum Order { case xyz }
    init(x: Angle2D, y: Angle2D, z: Angle2D, order: Order) {}
}

struct Angle2D {
    init(degrees: Double) {}
}

struct Vector3D {
    init(x: Double = 0, y: Double = 0, z: Double = 0) {}
}

extension TimeInterval {
    static func seconds(_ value: Double) -> TimeInterval { return value }
}
#endif

// MARK: - Motor Action Types

/// 电机动作类型
enum MotorAction {
    case orientationSequence([OrientationStep])  // 方向序列动作
    case velocitySequence([VelocityStep])        // 角速度序列动作
}

/// 方向步骤
enum OrientationStep {
    case nod(angle: Double, duration: Double)     // 点头/抬头 (pitch角度，度数)
    case shake(angle: Double, duration: Double)   // 摇头 (yaw角度，度数)
    case roll(angle: Double, duration: Double)    // 翻滚 (roll角度，度数)
    case center(duration: Double)                 // 回到中心位置
    case pause(duration: Double)                  // 暂停保持当前位置
}

/// 角速度步骤
enum VelocityStep {
    case angularVelocity(pitch: Double = 0, yaw: Double = 0, roll: Double = 0, duration: Double)
    case tremble(intensity: Double, duration: Double)  // 颤抖效果
    case stop(duration: Double)                        // 停止运动
    case center(duration: Double)                      // 回到中心
}

// MARK: - Motor Action Executor

/// 电机动作执行器
@Observable
class MotorActionExecutor {
    private(set) var isPerformingMotorAction: Bool = false
    private var previousTrackingMode: TrackingMode = .system
    
    /// 根据表情返回对应的电机动作
    func getMotorActionForMood(_ mood: RobotMood) -> MotorAction? {
        switch mood {
        case .happy, .joy:
            return .orientationSequence([
                .nod(angle: -15, duration: 0.4),  // 点头向下
                .nod(angle: 5, duration: 0.3),   // 回弹
                .nod(angle: -10, duration: 0.3), // 再次点头
                .center(duration: 0.4)           // 回到中心
            ])
        case .excited:
            return .orientationSequence([
                .nod(angle: -20, duration: 0.2),  // 快速点头
                .nod(angle: 10, duration: 0.2),   // 快速抬头
                .nod(angle: -15, duration: 0.2),  // 再次点头
                .center(duration: 0.3)
            ])
        case .sad, .sadness:
            return .orientationSequence([
                .shake(angle: -25, duration: 0.5), // 摇头向左
                .shake(angle: 25, duration: 0.6),  // 摇头向右
                .shake(angle: -15, duration: 0.4), // 轻微左摇
                .center(duration: 0.5)
            ])
        case .guilt:
            return .orientationSequence([
                .nod(angle: 20, duration: 0.8),   // 慢慢低头
                .pause(duration: 1.0),            // 保持低头
                .center(duration: 0.6)            // 缓慢抬头
            ])
        case .surprise:
            return .orientationSequence([
                .nod(angle: -30, duration: 0.15), // 快速抬头
                .pause(duration: 0.3),            // 保持惊讶姿态
                .center(duration: 0.4)
            ])
        case .anger:
            return .velocitySequence([
                .angularVelocity(yaw: -1.5, duration: 0.2), // 快速左摇
                .angularVelocity(yaw: 1.8, duration: 0.2),  // 快速右摇
                .angularVelocity(yaw: -1.2, duration: 0.15), // 左摇
                .angularVelocity(yaw: 1.0, duration: 0.15),  // 右摇
                .stop(duration: 0.1)
            ])
        case .fear:
            return .velocitySequence([
                .tremble(intensity: 0.8, duration: 1.2), // 多轴颤抖
                .center(duration: 0.4)
            ])
        case .curiosity:
            return .orientationSequence([
                .shake(angle: -20, duration: 0.6),  // 缓慢向左看
                .pause(duration: 0.4),              // 观察
                .shake(angle: 40, duration: 0.8),   // 向右看
                .pause(duration: 0.4),              // 观察
                .center(duration: 0.5)              // 回到中心
            ])
        case .pride:
            return .orientationSequence([
                .nod(angle: -25, duration: 0.6),   // 抬头
                .pause(duration: 1.5),             // 保持骄傲姿态
                .center(duration: 0.5)
            ])
        case .shame:
            return .orientationSequence([
                .nod(angle: 25, duration: 0.7),    // 低头
                .pause(duration: 1.2),             // 保持羞耻姿态
                .center(duration: 0.6)
            ])
        case .normal:
            return .orientationSequence([
                .center(duration: 0.5)             // 平滑回到中心
            ])
        case .disgust:
            return .orientationSequence([
                .shake(angle: -15, duration: 0.3), // 轻微后退摇头
                .nod(angle: 10, duration: 0.3),    // 略微抬头表示不屑
                .center(duration: 0.4)
            ])
        case .trust, .acceptance:
            return .orientationSequence([
                .nod(angle: -8, duration: 0.8),    // 轻微点头表示认同
                .center(duration: 0.4)
            ])
        case .contempt:
            return .orientationSequence([
                .nod(angle: -15, duration: 0.4),   // 抬头表示蔑视
                .shake(angle: 15, duration: 0.4),  // 轻微偏头
                .center(duration: 0.5)
            ])
        case .love:
            return .orientationSequence([
                .nod(angle: -10, duration: 0.5),   // 轻柔点头
                .shake(angle: -8, duration: 0.4),  // 轻微偏头
                .nod(angle: -5, duration: 0.4),    // 再次轻点
                .center(duration: 0.5)
            ])
        case .envy:
            return .orientationSequence([
                .shake(angle: -20, duration: 0.5), // 侧视
                .nod(angle: 8, duration: 0.4),     // 轻微低头
                .center(duration: 0.4)
            ])
        default:
            return nil
        }
    }
    
    /// 执行电机动作
    func executeMotorAction(_ action: MotorAction, for mood: RobotMood, dockController: (any DockController)?) async {
        guard dockController != nil else {
            print("⚠️ DockController未设置，无法执行电机动作")
            return
        }
        
        isPerformingMotorAction = true
        
        // 暂停跟随效果 - 保存当前跟踪模式
        previousTrackingMode = await dockController?.dockAccessoryFeatures.trackingMode ?? .system
        
        print("🔄 暂停跟随效果，当前模式: \(previousTrackingMode)")
        let success = await dockController?.updateTrackingMode(to: .manual) ?? false
        
        if !success {
            print("❌ 切换到手动模式失败")
            isPerformingMotorAction = false
            return
        }
        
        // 等待模式切换完成
        try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 10) // 0.1秒
        
        // 执行具体的电机动作
        let actionSuccess = await performSpecificMotorAction(action, dockController: dockController)
        
        if actionSuccess {
            print("✅ 电机动作执行成功: \(action) for \(mood)")
        } else {
            print("❌ 电机动作执行失败: \(action) for \(mood)")
        }
        
        // 恢复跟随效果
        print("🔄 恢复跟随效果到模式: \(previousTrackingMode)")
        let restoreSuccess = await dockController?.updateTrackingMode(to: previousTrackingMode) ?? false
        if !restoreSuccess {
            print("❌ 恢复跟随模式失败")
        }
        
        isPerformingMotorAction = false
        print("🏁 电机动作完成")
    }
    
    /// 执行具体的电机动作
    private func performSpecificMotorAction(_ action: MotorAction, dockController: (any DockController)?) async -> Bool {
        guard dockController != nil else { return false }
        
        switch action {
        case .orientationSequence(let steps):
            return await executeOrientationSequence(steps, dockController: dockController)
            
        case .velocitySequence(let steps):
            return await executeVelocitySequence(steps, dockController: dockController)
        }
    }
    
    /// 执行方向序列动作
    private func executeOrientationSequence(_ steps: [OrientationStep], dockController: (any DockController)?) async -> Bool {
        print("🎯 开始执行方向序列动作，共 \(steps.count) 步")
        
        for (index, step) in steps.enumerated() {
            print("📍 执行第 \(index + 1) 步: \(step)")
            
            let success = await executeOrientationStep(step, dockController: dockController)
            if !success {
                print("❌ 第 \(index + 1) 步执行失败")
                return false
            }
        }
        
        print("✅ 方向序列动作执行完成")
        return true
    }
    
    /// 执行单个方向步骤
    private func executeOrientationStep(_ step: OrientationStep, dockController: (any DockController)?) async -> Bool {
        // 修复关键问题：直接使用DockController的handleChevronTapped方法
        do {
            switch step {
            case .nod(let angle, let duration):
                // 使用现有的handleChevronTapped方法来模拟点头动作
                if angle > 0 {
                    // 向下点头
                    await dockController?.handleChevronTapped(chevronType: .tiltDown, speed: abs(angle) / duration / 100)
                    return true
                } else {
                    // 向上抬头
                    await dockController?.handleChevronTapped(chevronType: .tiltUp, speed: abs(angle) / duration / 100)
                    return true
                }
                
            case .shake(let angle, let duration):
                // 使用现有的handleChevronTapped方法来模拟摇头动作
                if angle > 0 {
                    // 向右摇头
                    await dockController?.handleChevronTapped(chevronType: .panRight, speed: abs(angle) / duration / 100)
                    return true
                } else {
                    // 向左摇头
                    await dockController?.handleChevronTapped(chevronType: .panLeft, speed: abs(angle) / duration / 100)
                    return true
                }
                
            case .roll(_, let duration):
                // 翻滚动作暂时不支持，直接等待
                try await Task.sleep(nanoseconds: UInt64(duration * Double(NSEC_PER_SEC)))
                return true
                
            case .center(let duration):
                // 回到中心位置 - 使用小幅度的相反运动来归中
                await dockController?.handleChevronTapped(chevronType: .tiltUp, speed: 0.1)
                try await Task.sleep(nanoseconds: UInt64(duration * 0.5 * Double(NSEC_PER_SEC)))
                await dockController?.handleChevronTapped(chevronType: .tiltDown, speed: 0.1)
                try await Task.sleep(nanoseconds: UInt64(duration * 0.5 * Double(NSEC_PER_SEC)))
                return true
                
            case .pause(let duration):
                // 暂停等待
                try await Task.sleep(nanoseconds: UInt64(duration * Double(NSEC_PER_SEC)))
                return true
            }
            
        } catch {
            print("❌ 执行方向步骤失败: \(error)")
            return false
        }
    }
    
    /// 执行角速度序列动作
    private func executeVelocitySequence(_ steps: [VelocityStep], dockController: (any DockController)?) async -> Bool {
        print("⚡ 开始执行角速度序列动作，共 \(steps.count) 步")
        
        for (index, step) in steps.enumerated() {
            print("📍 执行第 \(index + 1) 步: \(step)")
            
            let success = await executeVelocityStep(step, dockController: dockController)
            if !success {
                print("❌ 第 \(index + 1) 步执行失败")
                return false
            }
        }
        
        print("✅ 角速度序列动作执行完成")
        return true
    }
    
    /// 执行单个角速度步骤
    private func executeVelocityStep(_ step: VelocityStep, dockController: (any DockController)?) async -> Bool {
        do {
            switch step {
            case .angularVelocity(let pitch, let yaw, let _, let duration):
                // 使用连续的小动作来模拟角速度
                let steps = Int(duration * 10) // 每0.1秒一个动作
                
                for _ in 0..<steps {
                    if yaw != 0 {
                        let speed = abs(yaw) * 0.1 // 调整速度比例
                        if yaw > 0 {
                            await dockController?.handleChevronTapped(chevronType: .panRight, speed: speed)
                        } else {
                            await dockController?.handleChevronTapped(chevronType: .panLeft, speed: speed)
                        }
                    }
                    
                    if pitch != 0 {
                        let speed = abs(pitch) * 0.1 // 调整速度比例
                        if pitch > 0 {
                            await dockController?.handleChevronTapped(chevronType: .tiltDown, speed: speed)
                        } else {
                            await dockController?.handleChevronTapped(chevronType: .tiltUp, speed: speed)
                        }
                    }
                    
                    try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10) // 0.1秒
                }
                return true
                
            case .tremble(let intensity, let duration):
                // 颤抖效果 - 快速随机运动
                let steps = Int(duration * 10) // 每0.1秒改变一次
                
                for _ in 0..<steps {
                    let randomDirection = Int.random(in: 0...3)
                    let speed = intensity * 0.1
                    
                    switch randomDirection {
                    case 0:
                        await dockController?.handleChevronTapped(chevronType: .panLeft, speed: speed)
                    case 1:
                        await dockController?.handleChevronTapped(chevronType: .panRight, speed: speed)
                    case 2:
                        await dockController?.handleChevronTapped(chevronType: .tiltUp, speed: speed)
                    case 3:
                        await dockController?.handleChevronTapped(chevronType: .tiltDown, speed: speed)
                    default:
                        break
                    }
                    
                    try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10) // 0.1秒
                }
                return true
                
            case .stop(let duration):
                // 停止运动
                try await Task.sleep(nanoseconds: UInt64(duration * Double(NSEC_PER_SEC)))
                return true
                
            case .center(let duration):
                // 回到中心位置
                return await executeOrientationStep(.center(duration: duration), dockController: dockController)
            }
            
        } catch {
            print("❌ 执行角速度步骤失败: \(error)")
            return false
        }
    }
} 