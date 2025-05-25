/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Extensions and supporting SwiftUI types.
*/

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

let largeButtonSize = CGSize(width: 64, height: 64)
let smallButtonSize = CGSize(width: 32, height: 32)

struct ClearRectangleWithBorder: View {
    let rect: CGRect
    
    var body: some View {
        let path = Path(rect)
        path.fill(Color.clear).overlay(path.stroke(Color.black, lineWidth: 2))
    }
}

struct DefaultButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled: Bool

    enum Size: CGFloat {
        case small = 22
        case large = 24
    }
    
    private let size: Size
    
    init(size: Size) {
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? .primary : Color(white: 0.4))
            .font(.system(size: size.rawValue))
            // Pad the buttons on devices that use the `regular` size class,
            // and also when explicitly requesting large buttons.
            .padding(size == .large ? 10.0 : 0)
            .background(.black.opacity(0.4))
            .clipShape(size == .small ? AnyShape(Rectangle()) : AnyShape(Circle()))
    }
}

extension View {
    func hidden(_ shouldHide: Bool) -> some View {
        opacity(shouldHide ? 0 : 1)
    }
}

extension Image {
    init(_ image: CGImage) {
        #if canImport(UIKit)
        self.init(uiImage: UIImage(cgImage: image))
        #else
        self.init(decorative: image, scale: 1.0)
        #endif
    }
}

// MARK: - Screen Wake Lock
struct KeepScreenAwake: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // 应用启动时设置屏幕常亮
                setIdleTimerDisabled(true)
            }
            .onDisappear {
                // 应用退出时恢复系统默认锁屏行为
                setIdleTimerDisabled(false)
            }
    }
    
    private func setIdleTimerDisabled(_ disabled: Bool) {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = disabled
        #endif
    }
}

extension View {
    /// 保持屏幕常亮
    func keepScreenAwake() -> some View {
        modifier(KeepScreenAwake())
    }
}
