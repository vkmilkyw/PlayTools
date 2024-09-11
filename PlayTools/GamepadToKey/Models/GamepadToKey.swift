//
//  GamepadToKey.swift
//  PlayTools
//  
//  Created by vkmilkyw on 2024/9/10.
//

import Foundation

struct GamepadToKey: Codable {
    var keyName: String
    var targetKeyCode: Int
    var targetModifiers: Int

    var thumbstickName: String? {
        if let range = keyName.range(of: "Thumbstick") {
            return String(keyName[..<range.upperBound])
        }
        return nil
    }
}
