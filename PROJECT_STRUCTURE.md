# Robot Face Tracking App - Project Structure

## Overview
This document describes the simplified project structure after removing all camera-related UI components and keeping only the essential files for robot face tracking functionality.

## Core Files Structure

```
DockKitCamera/
├── DockKit_CameraApp.swift          # Main app entry point
├── ContentView.swift                # Simplified main view (robot face only)
├── CaptureService.swift             # Camera service for face detection
│
├── Model/
│   ├── Camera.swift                 # Camera protocol
│   ├── CameraModel.swift            # Simplified camera model
│   ├── DataTypes.swift              # Core data types and protocols
│   ├── DockAccessoryController.swift # DockKit controller protocol
│   └── DockControllerModel.swift    # DockKit controller implementation
│
├── Views/
│   ├── CameraPreview.swift          # Hidden camera preview
│   ├── RobotFaceView.swift          # Main robot face interface
│   ├── VerticalLEDEyeView.swift     # Robot eye component
│   ├── MoodAnimations.swift         # Animation controller
│   └── MotorActions.swift           # Motor action controller
│
├── Camera/
│   └── DeviceLookup.swift           # Camera device management
│
├── DockControlService.swift        # DockKit service implementation
├── Support/
│   └── ViewExtensions.swift        # UI helper extensions
│
└── Preview Content/
    ├── PreviewCameraModel.swift     # Preview camera stub
    └── PreviewDockAccessoryControllerModel.swift # Preview dock controller stub
```

## Removed Files

The following files were removed as they are not needed for robot face tracking:

### Camera UI Components
- `CameraUI.swift` - Camera interface
- `MainToolbar.swift` - Camera toolbar
- `CaptureButton.swift` - Recording button
- `SwitchCameraButton.swift` - Camera switch button
- `PreviewContainer.swift` - Camera preview container

### Overlay Components
- `ZoomView.swift` - Zoom indicator
- `RecordingTimeView.swift` - Recording timer
- `StatusView.swift` - Connection status
- `RegionOfInterestView.swift` - ROI selection
- `TrackingSummaryView.swift` - Tracking overlay

### Control Components
- `ChevronView.swift` - Manual control arrows
- `ConnectionView.swift` - Connection indicator
- `BatteryView.swift` - Battery status
- `DockKitMenu.swift` - Settings menu

### Media Components
- `MediaLibrary.swift` - Photo/video saving
- `MovieCapture.swift` - Video recording
- `FoundationExtensions.swift` - File URL helpers

## Key Simplifications

### 1. ContentView.swift
- Removed all camera UI elements
- Always shows RobotFaceView
- Runs hidden 1x1 pixel camera preview for face detection
- Full screen immersive experience

### 2. CameraModel.swift
- Removed video recording functionality
- Removed media library dependencies
- Simplified to focus on face detection only
- Kept coordinate conversion for robot eye tracking

### 3. CaptureService.swift
- Removed movie capture outputs
- Kept only video and metadata outputs for face detection
- Simplified device management
- Focused on providing face detection data

### 4. DataTypes.swift
- Removed movie-related types
- Simplified capture activity states
- Kept only essential DockKit types
- Added robot face mood system

### 5. DockControllerModel.swift
- Kept DockKit integration for enhanced tracking
- Maintained robot face state management
- Simplified feature set for robot face mode

## Core Functionality Flow

1. **App Launch** (`DockKit_CameraApp.swift`)
   - Initialize camera and dock controller
   - Start essential services
   - Automatically enable robot face mode

2. **Face Detection** (`CaptureService.swift`)
   - Run hidden camera for face detection
   - Process metadata for face positions
   - Forward data to dock controller

3. **Robot Face Display** (`RobotFaceView.swift`)
   - Show animated robot face
   - Update eye positions based on face tracking
   - Handle user interactions and mood changes

4. **DockKit Integration** (`DockControllerModel.swift`)
   - Process face detection data
   - Update robot eye positions
   - Manage DockKit accessory if connected

## Benefits of Simplification

1. **Cleaner Codebase**: Removed ~15 unnecessary files
2. **Focused Purpose**: Clear robot companion app identity
3. **Easier Maintenance**: Less code to maintain and debug
4. **Better Performance**: No unused UI components
5. **Clearer Architecture**: Simplified data flow

## Development Guidelines

- **Never add camera UI back**: This is a robot face app, not a camera app
- **Keep face detection hidden**: Camera is just a sensor
- **Maintain service startup sequence**: Critical for proper functionality
- **Focus on robot experience**: All features should enhance the robot companion experience 