/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Fast and responsive motor action system for DockKit accessories.
*/

import Foundation
#if canImport(DockKit)
import DockKit
#endif
#if canImport(Spatial)
import Spatial
#endif

// MARK: - Required Type Imports
// 这些类型定义在 DataTypes.swift 中，确保可以访问
// ChevronType, RobotMood, TrackingMode, DockController 等类型

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

// MARK: - Fast Motor Action Types

/// 快速电机动作类型
enum FastMotorAction {
    case quickNod                    // 快速点头
    case doubleNod                   // 双次点头
    case shake                       // 摇头
    case lookup                      // 抬头
    case tiltLeft                    // 左倾
    case tiltRight                   // 右倾
    case bounce                      // 弹跳
    case tremor                      // 颤抖
    case scan                        // 扫视
    case returnToCenter              // 回中心
}

/// 快速动作步骤
struct FastMotionStep {
    let direction: ChevronType
    let speed: Double
    let duration: Double
    
    init(_ direction: ChevronType, speed: Double = 1.0, duration: Double = 0.3) {
        self.direction = direction
        self.speed = max(0.5, min(3.0, speed))  // 限制速度范围
        self.duration = max(0.1, min(1.0, duration))  // 限制时长范围
    }
}

// MARK: - Fast Motor Action Executor

/// 快速电机动作执行器
@Observable
class FastMotorActionExecutor {
    private(set) var isPerformingMotorAction: Bool = false
    private var previousTrackingMode: TrackingMode = .system
    
    /// 根据表情返回对应的快速电机动作
    func getMotorActionForMood(_ mood: RobotMood) -> FastMotorAction? {
        switch mood {
        case .happy, .joy:
            return .quickNod
            
        case .excited:
            return .bounce
            
        case .sad, .sadness:
            return .shake
            
        case .guilt, .shame:
            return .lookup  // 低头后抬头
            
        case .surprise:
            return .lookup
            
        case .anger:
            return .tremor
            
        case .fear:
            return .tremor
            
        case .curiosity:
            return .scan
            
        case .pride:
            return .lookup
            
        case .normal:
            return .returnToCenter
            
        case .disgust:
            return .tiltLeft
            
        case .trust, .acceptance:
            return .doubleNod
            
        case .contempt:
            return .tiltRight
            
        case .love:
            return .quickNod
            
        case .envy:
            return .scan
            
        default:
            return .quickNod
        }
    }
    
    /// 执行快速电机动作
    func executeMotorAction(_ action: FastMotorAction, for mood: RobotMood, dockController: (any DockController)?) async {
        guard dockController != nil else {
            print("⚠️ DockController未设置，无法执行电机动作")
            return
        }
        
        isPerformingMotorAction = true
        
        // 暂停跟随效果
        previousTrackingMode = await dockController?.dockAccessoryFeatures.trackingMode ?? .system
        print("🔄 暂停跟随效果，当前模式: \(previousTrackingMode)")
        let success = await dockController?.updateTrackingMode(to: .manual) ?? false
        
        if !success {
            print("❌ 切换到手动模式失败")
            isPerformingMotorAction = false
            return
        }
        
        // 等待模式切换完成
        try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 20) // 0.05秒，更短的等待
        
        // 执行具体的快速动作
        let actionSuccess = await performFastMotorAction(action, dockController: dockController)
        
        if actionSuccess {
            print("✅ 快速电机动作执行成功: \(action) for \(mood)")
        } else {
            print("❌ 快速电机动作执行失败: \(action) for \(mood)")
        }
        
        // 恢复跟随效果
        print("🔄 恢复跟随效果到模式: \(previousTrackingMode)")
        let restoreSuccess = await dockController?.updateTrackingMode(to: previousTrackingMode) ?? false
        if !restoreSuccess {
            print("❌ 恢复跟随模式失败")
        }
        
        isPerformingMotorAction = false
        print("🏁 快速电机动作完成")
    }
    
    /// 执行具体的快速电机动作
    private func performFastMotorAction(_ action: FastMotorAction, dockController: (any DockController)?) async -> Bool {
        switch action {
        case .quickNod:
            return await executeQuickNod(dockController: dockController)
            
        case .doubleNod:
            return await executeDoubleNod(dockController: dockController)
            
        case .shake:
            return await executeShake(dockController: dockController)
            
        case .lookup:
            return await executeLookup(dockController: dockController)
            
        case .tiltLeft:
            return await executeTilt(.panLeft, dockController: dockController)
            
        case .tiltRight:
            return await executeTilt(.panRight, dockController: dockController)
            
        case .bounce:
            return await executeBounce(dockController: dockController)
            
        case .tremor:
            return await executeTremor(dockController: dockController)
            
        case .scan:
            return await executeScan(dockController: dockController)
            
        case .returnToCenter:
            return await executeReturn(dockController: dockController)
        }
    }
    
    // MARK: - Fast Action Implementations
    
    /// 快速点头 - 平衡动作，自动回到原位
    private func executeQuickNod(dockController: (any DockController)?) async -> Bool {
        let steps = [
            FastMotionStep(.tiltDown, speed: 2.0, duration: 0.2),  // 向下
            FastMotionStep(.tiltUp, speed: 1.8, duration: 0.15),   // 回弹
            FastMotionStep(.tiltDown, speed: 1.5, duration: 0.15), // 再次向下
            FastMotionStep(.tiltUp, speed: 1.5, duration: 0.15)    // 回到原位
        ]
        return await executeSteps(steps, dockController: dockController, needsReturnToCenter: false)
    }
    
    /// 双次点头 - 平衡动作
    private func executeDoubleNod(dockController: (any DockController)?) async -> Bool {
        let steps = [
            FastMotionStep(.tiltDown, speed: 2.0, duration: 0.15), // 第一次点头
            FastMotionStep(.tiltUp, speed: 2.0, duration: 0.1),    // 快速回弹
            FastMotionStep(.tiltDown, speed: 2.2, duration: 0.15), // 第二次点头
            FastMotionStep(.tiltUp, speed: 1.8, duration: 0.1)     // 回到原位
        ]
        return await executeSteps(steps, dockController: dockController, needsReturnToCenter: false)
    }
    
    /// 摇头 - 平衡动作
    private func executeShake(dockController: (any DockController)?) async -> Bool {
        let steps = [
            FastMotionStep(.panLeft, speed: 1.8, duration: 0.2),   // 向左
            FastMotionStep(.panRight, speed: 2.0, duration: 0.3),  // 向右（更大幅度）
            FastMotionStep(.panLeft, speed: 1.5, duration: 0.2),   // 再向左
            FastMotionStep(.panRight, speed: 1.2, duration: 0.15)  // 回到中心偏右
        ]
        return await executeSteps(steps, dockController: dockController, needsReturnToCenter: false)
    }
    
    /// 抬头看 - 平衡动作
    private func executeLookup(dockController: (any DockController)?) async -> Bool {
        let steps = [
            FastMotionStep(.tiltUp, speed: 2.5, duration: 0.3),    // 抬头
            FastMotionStep(.tiltDown, speed: 1.2, duration: 0.2)   // 回到原位
        ]
        return await executeSteps(steps, dockController: dockController, needsReturnToCenter: false)
    }
    
    /// 倾斜 - 平衡动作
    private func executeTilt(_ direction: ChevronType, dockController: (any DockController)?) async -> Bool {
        let oppositeDirection: ChevronType = (direction == .panLeft) ? .panRight : .panLeft
        let steps = [
            FastMotionStep(direction, speed: 1.5, duration: 0.4),         // 倾斜
            FastMotionStep(oppositeDirection, speed: 1.2, duration: 0.3)  // 回到原位
        ]
        return await executeSteps(steps, dockController: dockController, needsReturnToCenter: false)
    }
    
    /// 弹跳 - 平衡动作
    private func executeBounce(dockController: (any DockController)?) async -> Bool {
        let steps = [
            FastMotionStep(.tiltUp, speed: 2.5, duration: 0.1),    // 快速上弹
            FastMotionStep(.tiltDown, speed: 2.8, duration: 0.12), // 下压
            FastMotionStep(.tiltUp, speed: 2.2, duration: 0.1),    // 再次上弹
            FastMotionStep(.tiltDown, speed: 1.8, duration: 0.1),  // 轻微下压
            FastMotionStep(.tiltUp, speed: 1.2, duration: 0.08)    // 回到原位
        ]
        return await executeSteps(steps, dockController: dockController, needsReturnToCenter: false)
    }
    
    /// 颤抖 - 平衡动作，通过对称设计回到原位
    private func executeTremor(dockController: (any DockController)?) async -> Bool {
        // 设计对称的颤抖序列，确保最终回到原位
        let steps = [
            FastMotionStep(.panLeft, speed: 1.5, duration: 0.08),
            FastMotionStep(.panRight, speed: 1.6, duration: 0.08),
            FastMotionStep(.tiltUp, speed: 1.4, duration: 0.08),
            FastMotionStep(.tiltDown, speed: 1.7, duration: 0.08),
            FastMotionStep(.panRight, speed: 1.3, duration: 0.08),
            FastMotionStep(.panLeft, speed: 1.5, duration: 0.08),
            FastMotionStep(.tiltDown, speed: 1.2, duration: 0.08),
            FastMotionStep(.tiltUp, speed: 1.1, duration: 0.08)
        ]
        return await executeSteps(steps, dockController: dockController, needsReturnToCenter: false)
    }
    
    /// 扫视 - 平衡动作
    private func executeScan(dockController: (any DockController)?) async -> Bool {
        let steps = [
            FastMotionStep(.panLeft, speed: 2.0, duration: 0.3),   // 向左扫视
            FastMotionStep(.panRight, speed: 2.5, duration: 0.4),  // 向右扫视
            FastMotionStep(.panLeft, speed: 1.5, duration: 0.2),   // 返回中心
            FastMotionStep(.panRight, speed: 0.8, duration: 0.1)   // 精确回位
        ]
        return await executeSteps(steps, dockController: dockController, needsReturnToCenter: false)
    }
    
    /// 回到中心 - 轻微的归中动作
    private func executeReturn(dockController: (any DockController)?) async -> Bool {
        let steps = [
            FastMotionStep(.tiltUp, speed: 0.8, duration: 0.15),
            FastMotionStep(.tiltDown, speed: 0.6, duration: 0.1),
            FastMotionStep(.panLeft, speed: 0.7, duration: 0.1),
            FastMotionStep(.panRight, speed: 0.5, duration: 0.08)
        ]
        return await executeSteps(steps, dockController: dockController, needsReturnToCenter: false)
    }
    
    /// 执行动作步骤序列
    private func executeSteps(_ steps: [FastMotionStep], dockController: (any DockController)?, needsReturnToCenter: Bool = true) async -> Bool {
        for (index, step) in steps.enumerated() {
            print("🚀 执行快速动作步骤 \(index + 1)/\(steps.count): \(step.direction) 速度:\(step.speed) 时长:\(step.duration)s")
            
            // 执行动作
            await dockController?.handleChevronTapped(chevronType: step.direction, speed: step.speed)
            
            // 等待动作时间（更短的等待）
            try? await Task.sleep(nanoseconds: UInt64(step.duration * Double(NSEC_PER_SEC)))
        }
        
        // 仅在需要时执行额外的回中心动作（用于简单动作或兜底保险）
        if needsReturnToCenter {
            print("🎯 执行额外的回中心动作")
            await dockController?.handleChevronTapped(chevronType: .tiltUp, speed: 0.5)
            try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 10) // 0.1秒
            await dockController?.handleChevronTapped(chevronType: .panLeft, speed: 0.3)
            try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 20) // 0.05秒
        }
        
        return true
    }
    
    // MARK: - Legacy Support
    
    /// 兼容旧接口
    func getEnhancedMotorActionForMood(_ mood: RobotMood) -> FastMotorAction? {
        return getMotorActionForMood(mood)
    }
    
    /// 兼容旧接口
    func executeEnhancedMotorAction(_ action: Any, for mood: RobotMood, dockController: (any DockController)?) async {
        if let fastAction = action as? FastMotorAction {
            await executeMotorAction(fastAction, for: mood, dockController: dockController)
        } else if let fastAction = getMotorActionForMood(mood) {
            await executeMotorAction(fastAction, for: mood, dockController: dockController)
        }
    }
} 