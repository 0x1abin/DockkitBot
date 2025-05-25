# 自动启动机器人跟踪模式功能

## 概述

本文档描述了对DockKit Camera应用的修改，使其在完成关键服务启动后自动进入机器人跟踪模式。

## 修改内容

### 1. 新增方法：`enableRobotFaceMode()`

在 `DockControllerModel.swift` 中添加了新的方法来直接启用机器人跟踪模式：

```swift
/// Enable robot face mode automatically during startup.
func enableRobotFaceMode() async {
    guard !isRobotFaceMode else { return } // Already enabled
    
    isRobotFaceMode = true
    robotFaceState.isTracking = true
    robotFaceState.mood = .normal
    
    // Switch to front camera for robot face mode
    if let cameraDelegate = await dockControlService.cameraCaptureDelegate as? CameraModel {
        await cameraDelegate.selectCamera(position: .front)
    }
    
    logger.info("Robot face mode enabled automatically during startup")
}
```

### 2. 协议更新

在 `DockAccessoryController.swift` 协议中添加了新方法的声明：

```swift
/// Enable robot face mode automatically during startup.
func enableRobotFaceMode() async
```

### 3. Preview模型实现

在 `PreviewDockAccessoryControllerModel.swift` 中添加了对应的实现：

```swift
func enableRobotFaceMode() async {
    logger.debug("enableRobotFaceMode isn't implemented in PreviewDockAccessory.")
    isRobotFaceMode = true
}
```

### 4. 应用启动流程修改

在 `DockKit_CameraApp.swift` 中修改了启动流程，保持原有的服务启动顺序不变，并在最后自动启用机器人跟踪模式：

```swift
.task {
    // Step 1: Set up service delegates for communication between camera and dock controller
    await camera.setTrackingServiceDelegate(dockController)
    await dockController.setCameraCaptureServiceDelegate(camera)
    
    // Step 2: Start the capture pipeline and essential services
    await camera.start()
    
    // Step 3: Wait a brief moment for services to fully initialize
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    
    // Step 4: Automatically enable robot face tracking mode after core services are ready
    await dockController.enableRobotFaceMode()
    
    logger.info("All essential services started and robot face tracking mode enabled automatically")
}
```

## 启动顺序

修改后的启动顺序如下：

1. **建立服务间通信**
   - 设置跟踪服务委托 (`camera.setTrackingServiceDelegate`)
   - 设置摄像头捕获委托 (`dockController.setCameraCaptureServiceDelegate`)

2. **启动核心服务**
   - 启动摄像头管道 (`camera.start()`)
   - 包括权限验证、设备查找、捕获会话配置、元数据检测等

3. **等待服务初始化**
   - 等待0.5秒确保所有服务完全初始化

4. **自动启用机器人跟踪模式**
   - 调用 `dockController.enableRobotFaceMode()`
   - 自动切换到前置摄像头
   - 启用机器人脸部跟踪功能

## 功能特点

- **保持兼容性**: 原有的 `toggleRobotFaceMode()` 方法保持不变
- **非侵入性**: 新功能不影响现有的手动控制功能
- **自动化**: 应用启动后无需用户干预即可进入机器人跟踪模式
- **安全性**: 包含防重复启用的保护机制
- **日志记录**: 添加了详细的日志记录便于调试

## 技术细节

### 服务依赖关系

机器人跟踪模式需要以下服务正常运行：

1. **摄像头权限服务**: 验证摄像头使用权限
2. **设备查找服务**: 查找和配置前置摄像头
3. **捕获会话服务**: AVCaptureSession配置和启动
4. **元数据检测服务**: 人脸和人体检测配置
5. **DockKit管理服务**: DockKit配件连接和状态管理
6. **跟踪委托服务**: Camera和DockController之间的通信桥梁

### 自动切换前置摄像头

当启用机器人跟踪模式时，系统会自动：
- 切换到前置摄像头 (`position: .front`)
- 设置机器人状态为跟踪模式
- 初始化机器人表情为正常状态
- 准备眼部跟踪功能

## 编译验证

修改已通过Xcode编译验证，确保：
- 所有语法正确
- 协议实现完整
- 依赖关系正确
- 无编译错误或警告

## 使用说明

应用启动后，机器人跟踪模式将自动启用。用户仍可以通过UI手动切换机器人模式的开关状态，但默认情况下应用会以机器人跟踪模式启动。 