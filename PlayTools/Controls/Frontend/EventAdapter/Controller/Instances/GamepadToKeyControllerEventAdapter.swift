//
//  GamepadToKeyControllerEventAdapter.swift
//  PlayTools
//
//  Created by vkmilkyw on 2024/9/10.
//

import Foundation
import GameController

// Controller events handler when in GamepadToKey setting view

public class GamepadToKeyControllerEventAdapter: ControllerEventAdapter {
    public func handleValueChanged(_ profile: GCExtendedGamepad, _ element: GCControllerElement) {
        var alias: String = element.aliases.first!
        if let dpad = element as? GCControllerDirectionPad {
            var subAlias: String?
            let deltaX = dpad.xAxis.value
            let deltaY = dpad.yAxis.value
            if abs(deltaX) > 0 || abs(deltaY) > 0 {
                if abs(deltaX) > abs(deltaY) {
                    subAlias = deltaX < 0 ? dpad.left.aliases.first! : dpad.right.aliases.first!
                } else {
                    subAlias = deltaY > 0 ? dpad.up.aliases.first! : dpad.down.aliases.first!
                }
            }
            if subAlias != nil {
                alias = subAlias!
            } else {
                return
            }
        }
        GamepadToKeySettingViewController.current?.setGamepadKey(keyName: alias)
    }
}
