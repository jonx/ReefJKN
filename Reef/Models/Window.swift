//
//  Window.swift
//  Reef
//
//  Created by Xander Gouws on 12-09-2025.
//

import Foundation
import Cocoa


enum ScreenDirection { case previous, next }

class Window: Identifiable {
    var id: CGWindowID { cgWindowID ?? 0 }
    var element: AXUIElement
    var cgWindowID: CGWindowID?
    var application: Application

    init(_ element: AXUIElement, _ application: Application) {
        self.element = element
        self.cgWindowID = element.getWindowID()
        self.application = application
    }
    
    var title: String {
        if let title: String = self.element.getAttributeValue(.title) {
            return title
        }
        
        return application.title
    }
    
    func focus() {
        do {
            try self.element.performAction(.raise)
            self.application.activate()
        } catch {
            try? self.application.reopen()
        }
    }
    
    func moveToAdjacentScreen(direction: ScreenDirection) {
        guard let position = element.getPosition(),
              let size = element.getSize() else { return }

        // Sort screens left-to-right so left/right arrows are geometrically meaningful.
        let screens = NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }
        guard screens.count > 1 else { return }

        let center = CGPoint(x: position.x + size.width / 2, y: position.y + size.height / 2)
        let currentIndex = screens.firstIndex { $0.axFrame.contains(center) } ?? 0

        let targetIndex: Int
        switch direction {
        case .previous: targetIndex = (currentIndex - 1 + screens.count) % screens.count
        case .next:     targetIndex = (currentIndex + 1) % screens.count
        }

        let src = screens[currentIndex].axFrame
        let dst = screens[targetIndex].axFrame

        // Preserve offset within screen, clamped so window stays fully on target.
        // Guard upper bounds: a window larger than the screen would invert the range and trap.
        let clampMaxX = Swift.max(dst.minX, dst.maxX - size.width)
        let clampMaxY = Swift.max(dst.minY, dst.maxY - size.height)
        let newX = (dst.minX + (position.x - src.minX)).clamped(to: dst.minX...clampMaxX)
        let newY = (dst.minY + (position.y - src.minY)).clamped(to: dst.minY...clampMaxY)
        element.setPosition(CGPoint(x: newX, y: newY))
    }

    static func getFrontWindow() -> Window? {
        guard let frontApplication = Application.getFrontApplication() else {
            return nil
        }
        
        if let focusedWindow = frontApplication.getFocusedWindow() {
            return focusedWindow
        }
        
        if let firstWindow = frontApplication.getFirstWindow() {
            return firstWindow
        }
        
        return nil
    }
}

private extension NSScreen {
    // AX coordinates: top-left origin, y increases downward.
    // NSScreen coordinates: bottom-left origin, y increases upward.
    var axFrame: CGRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? frame.height
        return CGRect(
            x: frame.origin.x,
            y: primaryHeight - frame.origin.y - frame.height,
            width: frame.width,
            height: frame.height
        )
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
