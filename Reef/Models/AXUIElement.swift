//
//  AXUIElement.swift
//  Reef
//
//  Created by Xander Gouws on 16-09-2025.
//

import Foundation
import Cocoa


// Adds Swift wrappers around the accessibility object class.
extension AXUIElement {
    func getAttributeValue<T>(_ attribute: NSAccessibility.Attribute) -> T? {
        var value: AnyObject?
        
        let result = AXUIElementCopyAttributeValue(self, attribute.rawValue as CFString, &value)
        
        guard result == .success else {
            return nil
        }
        
        return value as? T
    }
    
    func performAction(_ action: NSAccessibility.Action) throws(AXError) {
        let result = AXUIElementPerformAction(self, action.rawValue as CFString)
        
        guard result == .success else {
            throw result
        }
    }
    
    func getWindowID() -> CGWindowID? {
        var windowID = CGWindowID(0)
        
        let result = _AXUIElementGetWindow(self, &windowID)
        
        guard result == .success else {
            return nil
        }
        
        return windowID
    }
    
    func test() -> Int? {
        return self.getAttributeValue(.identifier)
    }

    func getPosition() -> CGPoint? {
        var raw: AnyObject?
        guard AXUIElementCopyAttributeValue(self, "AXPosition" as CFString, &raw) == .success,
              let axVal = raw else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(axVal as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }

    func getSize() -> CGSize? {
        var raw: AnyObject?
        guard AXUIElementCopyAttributeValue(self, "AXSize" as CFString, &raw) == .success,
              let axVal = raw else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(axVal as! AXValue, .cgSize, &size) else { return nil }
        return size
    }

    func setPosition(_ point: CGPoint) {
        var p = point
        guard let axVal = AXValueCreate(.cgPoint, &p) else { return }
        AXUIElementSetAttributeValue(self, "AXPosition" as CFString, axVal)
    }
}


// Make AXError conform to Error protocol
extension AXError: @retroactive _BridgedNSError {}
extension AXError: @retroactive _ObjectiveCBridgeableError {}
extension AXError: @retroactive Error {}


// Private Core Accessibility API
@_silgen_name("_AXUIElementGetWindow") @discardableResult
func _AXUIElementGetWindow(_ axUiElement: AXUIElement, _ wid: UnsafeMutablePointer<CGWindowID>) -> AXError
