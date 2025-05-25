# Robot Face Tracking App

An immersive robot companion application that uses DockKit technology to create an interactive robot face that tracks and responds to human faces.

## Overview

This is **NOT a camera app**. This is a **robot companion app** that creates an engaging, interactive robot face on your device. The robot's eyes follow your face in real-time, creating a lifelike companion experience.

## Key Features

- **Immersive Robot Face**: Full-screen animated robot face with LED-style eyes
- **Real-time Face Tracking**: Robot eyes follow detected human faces naturally
- **21 Emotional Expressions**: From happy to sad, excited to sleepy
- **Interactive Modes**: 
  - Tap to cycle through expressions
  - Long press for random expression mode
- **DockKit Integration**: Enhanced tracking with DockKit accessories

## User Experience

1. **Instant Immersion**: App launches directly into robot face mode
2. **No Camera UI**: The camera is invisible - you only see the robot
3. **Natural Interaction**: The robot responds to your presence and movement
4. **Full Screen Experience**: No distractions, just you and your robot companion

## Technical Architecture

The app uses camera technology purely as a sensor for face detection. The camera preview is completely hidden (1x1 pixel, 0 opacity), providing face tracking data while maintaining the illusion of interacting with a robot, not a camera.

## Requirements

- iOS 17.0 or later
- iPhone or iPad with front-facing camera
- Optional: DockKit-compatible accessory for enhanced tracking

## Privacy

The app uses the camera solely for face detection to enable robot eye tracking. No photos or videos are captured or stored.

## Build and Run

1. Open `DockKitCamera.xcodeproj` in Xcode
2. Select your target device
3. Build and run
4. Grant camera permissions when prompted
5. Enjoy your robot companion!

## Core Concept

> "Your personal robot companion that sees and responds to you."

This app transforms your device into an interactive robot face, creating a unique companion experience through the magic of face tracking technology.

## Configure the sample code project
Because Simulator doesn't have access to device cameras and can't connect to a DockKit device, it isn't suitable for running the sample app. To run the app, you need an iPhone with iOS 18 or later.


## Write a basic camera app to take photos
See [AVCam: Building a camera app](https://developer.apple.com/documentation/avfoundation/capture_setup/avcam_building_a_camera_app) to learn how to write a basic camera app to capture videos using an iPhone's front and rear cameras.


## Configure the DockKit accessory manager
[`AVCaptureSession`](https://developer.apple.com/documentation/avfoundation/avcapturesession) is a singleton class that provides connection and disconnection notifications with a DockKit accessory by subscribing to the [`accessoryStateChanges`](https://developer.apple.com/documentation/dockkit/dockaccessorymanager/accessorystatechanges) API.

The dock control service subscribes to `accessoryStateChanges` in its `setUp(features: DockAccessoryFeatures)` method.

```swift
// Subscribe to accessory state changes.
for await stateEvent in try DockAccessoryManager.shared.accessoryStateChanges {
    // Save the DockKit accessory when docked (connected).
    if let newAccessory = stateEvent.accessory, stateEvent.state == .docked {
        dockkitAccessory = newAccessory
        await setupAccessorySubscriptions(for: newAccessory)
    }
}
```

When an accessory connects, DockKit sets it up to use system tracking, and to listen to accessory events and battery states in `setupAccessorySubscriptions(for accesory: DockAccessory)`.

```swift
func setupAccessorySubscriptions(for accesory: DockAccessory) async {
    // Enable system tracking on the first connection.
    try await DockAccessoryManager.shared.setSystemTrackingEnabled(true)
    // Start the necessary subscriptions to accessory events and battery states.
    subscribeToAccessoryEvents(for: accesory)
    toggleBatterySummary(to: true, for: accesory)
}
```

## Change the tracking mode
The app provides a tracking mode menu to switch between system tracking, custom tracking, and manual tracking. The default is system tracking, which the app sets by calling [`setSystemTrackingEnabled(_:)`](https://developer.apple.com/documentation/dockkit/dockaccessorymanager/setsystemtrackingenabled(_:)) to `true`.

```swift
func updateTrackingMode(to trackingMode: TrackingMode) async {
    self.trackingMode = trackingMode
    // Call `systemTrackingEnabled` with `true` to enable the system tracking mode.
    try await DockAccessoryManager.shared.setSystemTrackingEnabled(trackingMode == .system ? true : false)
}
```

The app provides various menus and options to configure the selected subjects, selected frame, region to track, and more. All menus and buttons primarily live in the main DockKit menu.
## Tap to track the subject

The app provides a tap-to-track toggle to enable or disable selecting a specific subject to track by tapping the camera view. When the tap-to-track toggle is enabled, the `selectSubject(at point: CGPoint?)` method allows people to select tapped subjects.

```swift
func selectSubject(at point: CGPoint?) async -> Bool {
    if let point = point {
        // Select a specific subject at the point.
        try await accessory.selectSubject(at: point)
    } else {
        // Clear the selected subjects.
        try await accessory.selectSubjects([])
    }
}
```

## Set the region of interest
The app provides a region-of-interest toggle to enable or disable setting a region of interest to frame the selected subjects by holding and dragging the camera view. When toggling the region of interest, the `setRegionOfInterest(to region: CGRect)` method allows setting a region [`CGRect`](https://developer.apple.com/documentation/corefoundation/cgrect/) in the camera view. The dock accessory keeps the subjects framed in the selected region.

```swift
func setRegionOfInterest(to region: CGRect) async {
    try await accessory.setRegionOfInterest(region)
}
```

## Set the framing mode
The app provides a framing mode menu to select a [`FramingMode`](https://developer.apple.com/documentation/dockkit/dockaccessory/framingmode-swift.enum).

```swift
func updateFraming(to framing: FramingMode) async -> Bool {
    try await accessory.setFramingMode(dockKitFramingMode(from: framing))
}
```

The app uses the helper function `dockKitFramingMode(from: framing)` to map a local `FramingMode` enumeration to `DockAccessory.FramingMode`.

```swift
func dockKitFramingMode(from framingMode: FramingMode) -> DockAccessory.FramingMode {
    switch framingMode {
    case .auto:
        return DockAccessory.FramingMode.automatic
    case .center:
        return DockAccessory.FramingMode.center
    case .left:
        return DockAccessory.FramingMode.left
    case .right:
        return DockAccessory.FramingMode.right
    }
}
```

## Implement manual control using actuator velocities
When someone sets the `TrackingMode` to `TrackingMode.manual`, the app provides chevrons to move `DockAccessory` up, left, right, and down by using the [`setAngularVelocity(_:)`](https://developer.apple.com/documentation/dockkit/dockaccessory/setangularvelocity(_:)/) API.

```swift
func handleChevronTapped(chevronType: ChevronType, speed: Double = 0.2) async {
    var velocity = Vector3D()
    switch chevronType {
    case .tiltUp:
        velocity.x = -speed
        break
    case .tiltDown:
        velocity.x = speed
        break
    case .panLeft:
        velocity.y = -speed
        break
    case .panRight:
        velocity.y = speed
        break
    }
    try await dockkitAccessory.setAngularVelocity(velocity)
}
```    

## Run the default animations
The app provides buttons to run the four default animations that `DockAccessory` provides. Before running the animation, the app disables system tracking. When the animation is complete, the app restores system tracking to its prior value.

```swift
// Disable the system tracking before running the animation.
try await DockAccessoryManager.shared.setSystemTrackingEnabled(false)

// Run the animation and wait for it to finish.
let progress = try await dockkitAccessory.animate(motion: dockKitAnimation(from: animation))
while(!progress.isCancelled && !progress.isFinished) {
    try await Task.sleep(nanoseconds: NSEC_PER_SEC/10) // 0.1 sec
}
            
// Restore the system tracking after running the animation.
try await DockAccessoryManager.shared.setSystemTrackingEnabled(trackingMode == .system ? true : false)
```

The app uses the helper function `dockKitAnimation(from animation: Animation)` to map a local animation enumeration to [`DockAccessory.Animation`](https://developer.apple.com/documentation/dockkit/dockaccessory/animation).

```swift
func dockKitAnimation(from animation: Animation) -> DockAccessory.Animation {
    switch animation {
    case .yes:
        return DockAccessory.Animation.yes
    case .nope:
        return DockAccessory.Animation.nope
    case .wakeup:
        return DockAccessory.Animation.wakeup
    case .kapow:
        return DockAccessory.Animation.kapow
    }
}
```

The DockKit menu provides toggles to subscribe to various states, like battery and tracking, and displays them in the app's UI.

##  Implement the battery state
The dock control service subscribes to [`batteryStates`](https://developer.apple.com/documentation/dockkit/dockaccessory/batterystates-swift.property) to acquire the current battery state of the accessory. The current battery state includes the battery level, charging indicator, and so forth.

```swift
for await batterySummaryState in try dockkitAccessory.batteryStates {
    battery = .available(percentage: batterySummaryState.batteryLevel, charging: batterySummaryState.chargeState == .charging)
}
```

##  Implement the tracking states
The dock control service subscribes to [`trackingStates`](https://developer.apple.com/documentation/dockkit/dockaccessory/trackingstates-swift.struct?changes=_8) to get a list of tracked subjects with attributes like saliency and speaking confidence. The dock control service delegates the handling of the conversion from a normalized subject rectangle to camera view space coordinates to the `CameraModel`, which uses the capture service for the operation. The app uses these states, along with the transformed subject rectangle, to show an overlay on the faces of the subjects.

```swift
for await trackingSummaryState in try dockkitAccessory.trackingStates {
    for subject in trackingSummaryState.trackedSubjects {
        switch subject {
        case .person(let person):
            if let rect = await cameraCaptureDelegate?.convertToViewSpace(from: person.rect) {
                // Create a `DockAccessoryTrackedPerson` object from `TrackingState`.
                trackedPersons.append(DockAccessoryTrackedPerson(saliency: person.saliencyRank, rect: rect,
                                                                 speaking: person.speakingConfidence, looking: person.lookingAtCameraConfidence))
            }
        default:
            // Do nothing.
            break
        }
    }
}
```

## Implement camera control using accessory events
The dock control service subscribes to an `async` stream of [`AccessoryEvents`](https://developer.apple.com/documentation/dockkit/dockaccessory/accessoryevents-swift.struct). A physical input on the [`DockAccessory`](https://developer.apple.com/documentation/dockkit/dockaccessory) triggers an accessory event. When the app receives an accessory event, it delegates handling of the event to the `CameraModel`, which uses the capture service to perform camera operations.

```swift
for await event in try accesory.accessoryEvents {
    switch (event) {
    case let .button(id, pressed):
        break
    case .cameraZoom(factor: let factor):
        let zoomType = factor > 0 ? CameraZoomType.increase : CameraZoomType.decrease
        // Implement the camera zoom.
        cameraCaptureDelegate?.zoom(type: zoomType, factor: 0.2)
        break
    case .cameraShutter:
        if (Date.now.timeIntervalSince(lastShutterEventTime) > 0.2) {
            // Implement the camera start capture or stop capture.
            cameraCaptureDelegate?.startOrStartCapture()
            lastShutterEventTime = .now
        }
        break
    case .cameraFlip:
        // Implement the camera flip.
        cameraCaptureDelegate?.switchCamera()
        break
    default: break
    }
}
```

`CameraModel` implements the sample's `CameraCaptureDelegate` protocol and provides the helper methods to control the camera.

## Implement the camera zoom
The capture service implements the `updateMagnification(for zoomType: CameraZoomType, by scale: Double = 0.2)` method in response to a zoom event from the accessory. 

```swift 
func updateMagnification(for zoomType: CameraZoomType, by scale: Double = 0.2) {
    try? currentDevice.lockForConfiguration()
    let magnification = (zoomType == .increase ? 1.0 : -1.0) * scale
    var newZoomFactor = currentDevice.videoZoomFactor + magnification
    newZoomFactor = max(min(newZoomFactor, self.maxZoomFactor), self.minZoomFactor)
    newZoomFactor = Double(round(10 * newZoomFactor) / 10)
    currentDevice.videoZoomFactor = newZoomFactor
    currentDevice.unlockForConfiguration()
    self.zoomFactor = newZoomFactor
}
```

## Implement the camera shutter
The capture service implements the `startRecording()` method in response to a start-capture shutter event, and a `stopRecording()` method in response to a stop-capture shutter event.

```swift
func startRecording() {
    movieCapture.startRecording()
}

func stopRecording() async throws -> Movie {
    try await movieCapture.stopRecording()
}
```

## Implement the camera flip
The capture service implements the `selectNextVideoDevice()` method in reponse to the camera flip event.

```swift 
func selectNextVideoDevice() {
    // Change the session's active capture device.
    changeCaptureDevice(to: nextDevice)
}
```
