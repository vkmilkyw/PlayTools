//
//  Keymapping.swift
//  PlayTools
//
//  Created by 이승윤 on 2022/08/29.
//

import Foundation
import os.log

let keymap = Keymapping.shared

class Keymapping {
    static let shared = Keymapping()

    let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    var keymapUrl: URL
    var keymapData: KeymappingData {
        didSet {
            encode()
        }
    }

    init() {
        keymapUrl = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers/io.playcover.PlayCover")
            .appendingPathComponent("Keymapping")
        if !FileManager.default.fileExists(atPath: keymapUrl.path) {
            do {
                try FileManager.default.createDirectory(
                    atPath: keymapUrl.path,
                    withIntermediateDirectories: true,
                    attributes: [:])
            } catch {
                os_log("[PlayTools] Failed to create Keymapping directory.\n%@", type: .error, error as CVarArg)
            }
        }
        keymapUrl.appendPathComponent("\(bundleIdentifier).plist")
        keymapData = KeymappingData(bundleIdentifier: bundleIdentifier)
        if !decode() {
            encode()
        }
    }

    func encode() {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let data = try encoder.encode(keymapData)
            try data.write(to: keymapUrl)
        } catch {
            os_log("[PlayTools] Keymapping encode failed.\n%@", type: .error, error as CVarArg)
        }
    }

    func decode() -> Bool {
        do {
            let data = try Data(contentsOf: keymapUrl)
            keymapData = try PropertyListDecoder().decode(KeymappingData.self, from: data)
            return true
        } catch {
            keymapData = KeymappingData(bundleIdentifier: bundleIdentifier)
            os_log("[PlayTools] Keymapping decode failed.\n%@", type: .error, error as CVarArg)
            return false
        }
    }
}

struct KeyModelTransform: Codable {
    var size: CGFloat
    var xCoord: CGFloat
    var yCoord: CGFloat
}

struct Button: Codable {
    var keyCode: Int
    var transform: KeyModelTransform
}

struct Joystick: Codable {
    var upKeyCode: Int
    var rightKeyCode: Int
    var downKeyCode: Int
    var leftKeyCode: Int
    var transform: KeyModelTransform
}

struct MouseArea: Codable {
    var transform: KeyModelTransform
}

struct KeymappingData: Codable {
    var buttonModels: [Button] = []
    var joystickModel: [Joystick] = []
    var mouseAreaModel: [MouseArea] = []
    var bundleIdentifier: String
    var version = "2.0.0"
}
