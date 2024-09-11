//
//  MacPlugin.swift
//  AKInterface
//
//  Created by Isaac Marovitz on 13/09/2022.
//

import AppKit
import CoreGraphics
import Foundation

class AKPlugin: NSObject, Plugin {
    required override init() {
    }

    var screenCount: Int {
        NSScreen.screens.count
    }

    var mousePoint: CGPoint {
        NSApplication.shared.windows.first?.mouseLocationOutsideOfEventStream ?? CGPoint()
    }

    var windowFrame: CGRect {
        NSApplication.shared.windows.first?.frame ?? CGRect()
    }

    var isMainScreenEqualToFirst: Bool {
        return NSScreen.main == NSScreen.screens.first
    }

    var mainScreenFrame: CGRect {
        return NSScreen.main!.frame as CGRect
    }

    var isFullscreen: Bool {
        NSApplication.shared.windows.first!.styleMask.contains(.fullScreen)
    }

    var cmdPressed: Bool = false
    var cursorHideLevel = 0
    func hideCursor() {
        NSCursor.hide()
        cursorHideLevel += 1
        CGAssociateMouseAndMouseCursorPosition(0)
        warpCursor()
    }

    func warpCursor() {
        guard let firstScreen = NSScreen.screens.first else {return}
        let frame = windowFrame
        // Convert from NS coordinates to CG coordinates
        CGWarpMouseCursorPosition(CGPoint(x: frame.midX, y: firstScreen.frame.height - frame.midY))
    }

    func unhideCursor() {
        NSCursor.unhide()
        cursorHideLevel -= 1
        if cursorHideLevel <= 0 {
            CGAssociateMouseAndMouseCursorPosition(1)
        }
    }

    private var cursor: NSCursor?
    public func setupCustomCursor(imageUrl: URL, size: CGSize, hotSpot: CGPoint) {
        if let image = scaledImage(image: NSImage(contentsOfFile: imageUrl.path), to: size) {
            self.cursor = NSCursor(image: image, hotSpot: hotSpot)

            NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: { event in
                self.updateCustomCursor()
                return event
            })
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.updateCustomCursor()
                    }
            }
        }
    }

    private func updateCustomCursor() {
        if let cursor = self.cursor {
            if self.isMousePointInContentView() {
                if NSCursor.current != cursor {
                    cursor.set()
                }
            } else {
                if NSCursor.current != NSCursor.arrow {
                    NSCursor.arrow.set()
                }
            }
        }
    }

    private func scaledImage(image: NSImage?, to size: NSSize) -> NSImage? {
        guard let originalImage = image else {
            return nil
        }
        if originalImage.size == size {
            return originalImage
        }
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        let originalRect = NSRect(origin: .zero, size: originalImage.size)
        let targetRect = NSRect(origin: .zero, size: size)
        originalImage.draw(in: targetRect, from: originalRect, operation: .sourceOver, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    private func isMousePointInContentView() -> Bool {
        guard let window = NSApplication.shared.windows.first else { return false }
        if !window.isKeyWindow { return false }
        guard let view = window.contentView else { return false }
        return view.isMousePoint(window.mouseLocationOutsideOfEventStream, in: view.frame)
    }

    func terminateApplication() {
        NSApplication.shared.terminate(self)
    }

    private var modifierFlag: UInt = 0

    // swiftlint:disable:next function_body_length
    func setupKeyboard(keyboard: @escaping (UInt16, Bool, Bool, Bool) -> Bool,
                       swapMode: @escaping () -> Bool) {
        func checkCmd(modifier: NSEvent.ModifierFlags) -> Bool {
            if modifier.contains(.command) {
                self.cmdPressed = true
                return true
            } else if self.cmdPressed {
                self.cmdPressed = false
            }
            return false
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event in
            if checkCmd(modifier: event.modifierFlags) {
                return event
            }
            let consumed = keyboard(event.keyCode, true, event.isARepeat,
                                    event.modifierFlags.contains(.control))
            if consumed {
                return nil
            }
            return event
        })
        NSEvent.addLocalMonitorForEvents(matching: .keyUp, handler: { event in
            if checkCmd(modifier: event.modifierFlags) {
                return event
            }
            let consumed = keyboard(event.keyCode, false, false,
                                    event.modifierFlags.contains(.control))
            if consumed {
                return nil
            }
            return event
        })
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: { event in
            if checkCmd(modifier: event.modifierFlags) {
                return event
            }
            let pressed = self.modifierFlag < event.modifierFlags.rawValue
            let changed = self.modifierFlag ^ event.modifierFlags.rawValue
            self.modifierFlag = event.modifierFlags.rawValue
            let changedFlags = NSEvent.ModifierFlags(rawValue: changed)
            if pressed && changedFlags.contains(.option) {
                if swapMode() {
                    return nil
                }
                return event
            }
            let consumed = keyboard(event.keyCode, pressed, false,
                                    event.modifierFlags.contains(.control))
            if consumed {
                return nil
            }
            return event
        })
    }

    func setupMouseMoved(_ mouseMoved: @escaping (CGFloat, CGFloat) -> Bool) {
        let mask: NSEvent.EventTypeMask = [.leftMouseDragged, .otherMouseDragged, .rightMouseDragged]
        NSEvent.addLocalMonitorForEvents(matching: mask, handler: { event in
            let consumed = mouseMoved(event.deltaX, event.deltaY)
            if consumed {
                return nil
            }
            return event
        })
        // transpass mouse moved event when no button pressed, for traffic light button to light up
        NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: { event in
            _ = mouseMoved(event.deltaX, event.deltaY)
            return event
        })
    }

    func setupMouseButton(left: Bool, right: Bool, _ consumed: @escaping (Int, Bool) -> Bool) {
        let downType: NSEvent.EventTypeMask = left ? .leftMouseDown : right ? .rightMouseDown : .otherMouseDown
        let upType: NSEvent.EventTypeMask = left ? .leftMouseUp : right ? .rightMouseUp : .otherMouseUp
        NSEvent.addLocalMonitorForEvents(matching: downType, handler: { event in
            // For traffic light buttons when fullscreen
            if event.window != NSApplication.shared.windows.first! {
                return event
            }
            if consumed(event.buttonNumber, true) {
                return nil
            }
            return event
        })
        NSEvent.addLocalMonitorForEvents(matching: upType, handler: { event in
            if consumed(event.buttonNumber, false) {
                return nil
            }
            return event
        })
    }

    func setupScrollWheel(_ onMoved: @escaping (CGFloat, CGFloat) -> Bool) {
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.scrollWheel, handler: { event in
            var deltaX = event.scrollingDeltaX, deltaY = event.scrollingDeltaY
            if !event.hasPreciseScrollingDeltas {
                deltaX *= 16
                deltaY *= 16
            }
            let consumed = onMoved(deltaX, deltaY)
            if consumed {
                return nil
            }
            return event
        })
    }

    func urlForApplicationWithBundleIdentifier(_ value: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: value)
    }

    func setMenuBarVisible(_ visible: Bool) {
        NSMenu.setMenuBarVisible(visible)
    }

    func postKeyEvent(keyCode: UInt16, keyDown: Bool, useGlobalEvent: Bool) {
        if useGlobalEvent {
            postGlobalKeyEvent(keyCode: keyCode, keyDown: keyDown)
        } else {
            postLocalKeyEvent(keyCode: keyCode, keyDown: keyDown)
        }
    }

    func postMouseEvent(keyCode: Int, keyDown: Bool, useGlobalEvent: Bool) {
        if useGlobalEvent {
            postGlobalMouseEvent(keyCode: keyCode, keyDown: keyDown)
        } else {
            postLocalMouseEvent(keyCode: keyCode, keyDown: keyDown)
        }
    }

    private func postLocalKeyEvent(keyCode: UInt16, keyDown: Bool) {
        if let keyEvent = NSEvent.keyEvent(
            with: keyDown ? .keyDown : .keyUp,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: NSApplication.shared.keyWindow?.windowNumber ?? 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: keyCode) {
            DispatchQueue.main.async {
                NSApplication.shared.postEvent(keyEvent, atStart: false)
            }
        }
    }

    private func postLocalMouseEvent(keyCode: Int, keyDown: Bool) {
        var eventType = NSEvent.EventType.leftMouseDown
        if keyCode == -1 {
            eventType = keyDown ? .leftMouseDown : .leftMouseUp
        } else if keyCode == -2 {
            eventType = keyDown ? .rightMouseDown : .rightMouseUp
        } else if keyCode == -3 {
            eventType = keyDown ? .otherMouseDown : .otherMouseUp
        }
        if let mouseEvent = NSEvent.mouseEvent(
            with: eventType,
            location: NSPoint(),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: NSApplication.shared.keyWindow?.windowNumber ?? 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1.0) {
            DispatchQueue.main.async {
                NSApplication.shared.postEvent(mouseEvent, atStart: false)
            }
        }
    }

    private func postGlobalKeyEvent(keyCode: UInt16, keyDown: Bool) {
        let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown)
        keyEvent?.post(tap: .cghidEventTap)
    }

    private func postGlobalMouseEvent(keyCode: Int, keyDown: Bool) {
        var mouseButton = CGMouseButton.left
        var mouseType = CGEventType.leftMouseDown
        if keyCode == -1 {
           mouseButton = .left
           mouseType = keyDown ? .leftMouseDown : .leftMouseUp
        } else if keyCode == -2 {
           mouseButton = .right
           mouseType = keyDown ? .rightMouseDown : .rightMouseUp
        } else if keyCode == -3 {
           mouseButton = .center
           mouseType = keyDown ? .otherMouseDown : .otherMouseUp
        }
        let mousePosition = CGEvent(source: nil)?.location ?? CGPoint()
        let mouseEvent = CGEvent(mouseEventSource: nil, mouseType: mouseType,
                                mouseCursorPosition: mousePosition, mouseButton: mouseButton)
        mouseEvent?.post(tap: .cghidEventTap)
    }

    func checkAccessibilityPermission() {
        AXIsProcessTrusted()
    }
}
