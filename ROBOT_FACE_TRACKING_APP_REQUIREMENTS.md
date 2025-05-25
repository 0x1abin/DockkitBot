# Robot Face Tracking App - Core Requirements Document

## 1. App Overview

### Product Name
**Robot Face Tracking App** - An immersive robot companion application that uses DockKit technology to create an interactive robot face that tracks and responds to human faces.

### Core Concept
This is NOT a camera app. This is a **robot companion app** that happens to use camera technology for face tracking. The camera is merely a sensor, not the main feature. Users should experience interacting with a friendly robot face, not using a camera.

## 2. Core Requirements

### 2.1 Primary Function
- **Robot Face Display**: The app displays an animated robot face as the primary interface
- **Face Tracking**: The robot's eyes follow detected human faces in real-time
- **Emotional Response**: The robot shows different emotions based on tracking status and user interaction
- **DockKit Integration**: Utilizes DockKit accessory for enhanced tracking capabilities

### 2.2 User Experience Principles
1. **Immediate Immersion**: App launches directly into robot face mode
2. **No Camera UI**: Camera preview and controls are completely hidden
3. **Full Screen Experience**: No status bars, home indicators, or system UI elements
4. **Natural Interaction**: Robot responds naturally to human presence and movement

### 2.3 Technical Architecture

#### Service Startup Sequence (CRITICAL - DO NOT MODIFY)
```swift
1. Set up service delegates for communication
2. Start camera capture pipeline
3. Wait for services initialization (0.5 seconds)
4. Enable robot face mode automatically
```

This sequence ensures:
- Camera services are running before face tracking begins
- DockKit communication is established
- Face detection metadata is available for robot eye tracking

#### Hidden Camera Operation
- Camera runs in background (1x1 pixel, 0 opacity, hidden)
- Provides face detection metadata for tracking
- No user-visible camera preview or controls

## 3. Feature Specifications

### 3.1 Robot Face Design
- **Eyes**: Vertical LED strip design with dynamic animations
- **Expressions**: 21 different moods including basic and complex emotions
- **Animations**: Blinking, breathing, mood transitions, and special effects
- **Responsiveness**: Real-time eye tracking following detected faces

### 3.2 Interaction Modes

#### Automatic Mode (Default)
- Eyes automatically track detected faces
- Mood changes based on tracking confidence
- Natural blinking and idle animations

#### Manual Expression Mode
- Tap to cycle through expressions
- Long press for random expression mode
- Motor actions synchronized with expressions

### 3.3 Visual Design
- **Minimalist Aesthetic**: Clean, modern robot face design
- **Full Screen Canvas**: Entire screen is the robot's face
- **Dark Theme**: Black background with white/colored LED elements
- **Smooth Animations**: Spring physics for natural movement

## 4. Implementation Details

### 4.1 Key Components

#### ContentView.swift
- Always displays RobotFaceView
- Runs hidden camera preview for face detection
- Full screen with no system UI

#### DockKit_CameraApp.swift
- Maintains critical service startup sequence
- Automatically enables robot face mode after initialization

#### RobotFaceView.swift
- Main robot face interface
- Handles all animations and user interactions
- Processes face tracking data for eye movement

#### DockControllerModel.swift
- Manages DockKit integration
- Processes face detection metadata
- Updates robot eye positions based on tracking

### 4.2 Critical Code Sections

#### Service Initialization (DO NOT MODIFY)
```swift
.task {
    // Step 1: Set up service delegates
    await camera.setTrackingServiceDelegate(dockController)
    await dockController.setCameraCaptureServiceDelegate(camera)
    
    // Step 2: Start capture pipeline
    await camera.start()
    
    // Step 3: Wait for initialization
    try? await Task.sleep(nanoseconds: 500_000_000)
    
    // Step 4: Enable robot face mode
    await dockController.enableRobotFaceMode()
}
```

#### Hidden Camera Implementation
```swift
CameraPreview(source: camera.previewSource)
    .frame(width: 1, height: 1)
    .opacity(0)
    .allowsHitTesting(false)
    .hidden()
```

## 5. User Journey

### 5.1 App Launch
1. User taps app icon
2. App immediately shows robot face (no splash screen)
3. Robot eyes center, showing "STANDBY" status
4. Face detection begins automatically

### 5.2 Face Detection
1. When user's face is detected:
   - Status changes to "TRACKING"
   - Robot eyes follow user's face position
   - Expression changes to happy/engaged
2. When face is lost:
   - Eyes return to center
   - Status returns to "STANDBY"
   - Expression remains neutral

### 5.3 Interaction
- **Single Tap**: Cycle through expressions manually
- **Long Press**: Activate random expression mode
- **Face Movement**: Robot eyes follow in real-time

## 6. Performance Requirements

### 6.1 Responsiveness
- Eye tracking latency: < 200ms
- Expression changes: Smooth spring animations
- No visible lag or stuttering

### 6.2 Resource Usage
- Minimal camera preview overhead (1x1 pixel)
- Efficient face detection processing
- Smooth 60fps animations

## 7. Future Enhancements (Not in Current Scope)

### 7.1 Potential Features
- Voice interaction and responses
- Multiple face tracking
- Gesture recognition
- Customizable robot appearances
- AR mode with environment interaction

### 7.2 Platform Expansion
- watchOS companion app
- macOS version with webcam support
- visionOS adaptation for spatial computing

## 8. Development Guidelines

### 8.1 Code Maintenance
- **NEVER** expose camera UI elements
- **ALWAYS** maintain service startup sequence
- **PRESERVE** hidden camera implementation
- **ENSURE** full screen immersive experience

### 8.2 Testing Checklist
- [ ] App launches directly to robot face
- [ ] No camera preview visible
- [ ] Face tracking works correctly
- [ ] All expressions cycle properly
- [ ] DockKit integration functions
- [ ] No system UI elements visible

## 9. Summary

This app is fundamentally a **robot companion experience**, not a camera app. Every design decision should reinforce the illusion that users are interacting with a friendly, responsive robot face. The camera technology is merely the invisible infrastructure that enables the magic of face tracking.

The core value proposition is: **"Your personal robot companion that sees and responds to you."** 