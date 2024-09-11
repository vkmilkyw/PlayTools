//
//  GamepadToKeyMouseEventAdapter.swift
//  PlayTools
//
//  Created by vkmilkyw on 2024/9/10.
//

import Foundation

// Mouse events handler when in GamepadToKey setting view

public class GamepadToKeyMouseEventAdapter: MouseEventAdapter {
    private static let buttonCode: [Int] = [
        KeyCodeNames.leftMouseButtonCode,
        KeyCodeNames.rightMouseButtonCode,
        KeyCodeNames.middleMouseButtonCode
    ]

    public static func getMouseButtonCode(_ id: Int) -> Int? {
        return id < GamepadToKeyMouseEventAdapter.buttonCode.count ?
        GamepadToKeyMouseEventAdapter.buttonCode[id] : nil
    }

    public func handleScrollWheel(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        false
    }

    public func handleMove(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        false
    }

    public func handleLeftButton(pressed: Bool) -> Bool {
        false
    }

    public func handleOtherButton(id: Int, pressed: Bool) -> Bool {
        if pressed {
            if let keyCode = GamepadToKeyMouseEventAdapter.getMouseButtonCode(id) {
                GamepadToKeySettingViewController.current?.setMouseButton(keyCode: keyCode)
            }
        }
        return true
    }

    public func cursorHidden() -> Bool {
        false
    }
}
