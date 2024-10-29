//
//  Keymapping.swift
//  PlayTools
//
//  Created by 이승윤 on 2022/08/29.
//

import Foundation

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
                print("[PlayTools] Failed to create Keymapping directory.\n%@")
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
            print("[PlayTools] Keymapping encode failed.\n%@")
        }
    }

    func decode() -> Bool {
        do {
            let data = try Data(contentsOf: keymapUrl)
            keymapData = try PropertyListDecoder().decode(KeymappingData.self, from: data)
            return true
        } catch {
            keymapData = KeymappingData(bundleIdentifier: bundleIdentifier)
            print("[PlayTools] Keymapping decode failed.\n%@")
            return false
        }
    }
}

struct KeymappingData: Codable {
    var buttonModels: [Button] = []
    var draggableButtonModels: [Button] = []
    var joystickModel: [Joystick] = []
    var mouseAreaModel: [MouseArea] = []
    var gamepadToKeyModels: [GamepadToKey] = []
    var useGlobalEvent = false
    var enableGamepadFakeCursor = true
    var enableCustomCameraScale = true
    var bundleIdentifier: String
    var version = "2.0.0"

    init(bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        self.buttonModels = try container.decodeIfPresent([Button].self, forKey: .buttonModels) ?? []
        self.draggableButtonModels = try container.decodeIfPresent([Button].self, forKey: .draggableButtonModels) ?? []
        self.joystickModel = try container.decodeIfPresent([Joystick].self, forKey: .joystickModel) ?? []
        self.gamepadToKeyModels = try container.decodeIfPresent([GamepadToKey].self, forKey: .gamepadToKeyModels) ?? []
        self.mouseAreaModel = try container.decodeIfPresent([MouseArea].self, forKey: .mouseAreaModel) ?? []
        self.useGlobalEvent = try container.decodeIfPresent(Bool.self, forKey: .useGlobalEvent) ?? false
        self.enableGamepadFakeCursor = try container.decodeIfPresent(Bool.self, forKey: .enableGamepadFakeCursor) ?? true
        self.enableCustomCameraScale = try container.decodeIfPresent(Bool.self, forKey: .enableCustomCameraScale) ?? true
        self.version = try container.decodeIfPresent(String.self, forKey: .version) ?? "0.0.0"
    }
}
