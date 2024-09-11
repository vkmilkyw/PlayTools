//
//  KeyboardAndMouse.swift
//  PlayTools
//

import Foundation

class KeyboardAndMouse {
    private static var isPermissionChecked = false
    private static let candidateFlags: [UIKeyModifierFlags] = [.control, .alternate, .shift, .command]
    private static let candidateKeyCodes: [UInt16] = [0x3B, 0x3A, 0x38, 0x37]

    static func postEvent(keyCode: Int, modifiers: Int, keyDown: Bool) {
        let isGlobal = Keymapping.shared.keymapData.useGlobalEvent
        if isGlobal {
            checkAccessibilityPermission()
        }

        if KeyCodeNames.isMouseButton(keyCode) {
            AKInterface.shared?.postMouseEvent(keyCode: keyCode, keyDown: keyDown, useGlobalEvent: isGlobal)
            return
        }

        if modifiers == 0 {
            AKInterface.shared?.postKeyEvent(keyCode: UInt16(keyCode), keyDown: keyDown, useGlobalEvent: isGlobal)
        } else {
            let modifierFlags = UIKeyModifierFlags(rawValue: modifiers)
            for index in candidateFlags.indices where modifierFlags.contains(candidateFlags[index]) {
                AKInterface.shared?.postKeyEvent(keyCode: candidateKeyCodes[index],
                                                 keyDown: keyDown,
                                                 useGlobalEvent: isGlobal)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                AKInterface.shared?.postKeyEvent(keyCode: UInt16(keyCode), keyDown: keyDown, useGlobalEvent: isGlobal)
            }
        }
    }

    private static func checkAccessibilityPermission() {
        if !isPermissionChecked {
            isPermissionChecked = true
            AKInterface.shared?.checkAccessibilityPermission()
        }
    }
}
