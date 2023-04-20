import Foundation
import GameController
import UIKit

class PlayInput {
    static let shared = PlayInput()
    var actions = [Action]()
    static var keyboardMapped = true
    static var shouldLockCursor = true

    static var touchQueue = DispatchQueue.init(label: "playcover.toucher", qos: .userInteractive,
                                               autoreleaseFrequency: .workItem)
    static public var buttonHandlers: [String: [(Bool) -> Void]] = [:]

    func invalidate() {
        for action in self.actions {
            action.invalidate()
        }
    }

    static public func registerButton(key: String, handler: @escaping (Bool) -> Void) {
        if ["LMB", "RMB", "MMB"].contains(key) {
            PlayInput.shouldLockCursor = true
        }
        if PlayInput.buttonHandlers[key] == nil {
            PlayInput.buttonHandlers[key] = []
        }
        PlayInput.buttonHandlers[key]!.append(handler)
    }

    func keyboardHandler(_ keyCode: UInt16, _ pressed: Bool) -> Bool {
        let name = KeyCodeNames.virtualCodes[keyCode] ?? "Btn"
        guard let handlers = PlayInput.buttonHandlers[name] else {
            return false
        }
        var mapped = false
        for handler in handlers {
            PlayInput.touchQueue.async(qos: .userInteractive, execute: {
                handler(pressed)
            })
            mapped = true
        }
        return mapped
    }

    func controllerButtonHandler(_ profile: GCExtendedGamepad, _ element: GCControllerElement) {
        let name: String = element.aliases.first!
        if let buttonElement = element as? GCControllerButtonInput {
            guard let handlers = PlayInput.buttonHandlers[name] else { return }
//            Toast.showOver(msg: name + ": \(buttonElement.isPressed)")
            for handler in handlers {
                handler(buttonElement.isPressed)
            }
        } else if let dpadElement = element as? GCControllerDirectionPad {
            PlayMice.shared.handleControllerDirectionPad(profile, dpadElement)
        } else {
            Toast.showOver(msg: "unrecognised controller element input happens")
        }
    }

    func parseKeymap() {
        actions = []
        PlayInput.shouldLockCursor = false
        PlayInput.buttonHandlers.removeAll(keepingCapacity: true)
        for button in keymap.keymapData.buttonModels {
            actions.append(ButtonAction(data: button))
        }

        for draggableButton in keymap.keymapData.draggableButtonModels {
            actions.append(DraggableButtonAction(data: draggableButton))
        }

        for mouse in keymap.keymapData.mouseAreaModel {
            actions.append(CameraAction(data: mouse))
        }

        for joystick in keymap.keymapData.joystickModel {
            // Left Thumbstick, Right Thumbstick, Mouse
            if joystick.keyName.contains(Character("u")) {
                actions.append(ContinuousJoystickAction(data: joystick))
            } else { // Keyboard
                actions.append(JoystickAction(data: joystick))
            }
        }
        if !PlayInput.shouldLockCursor {
            PlayInput.shouldLockCursor = PlayMice.shared.mouseMovementMapped()
        }
    }

    public func toggleEditor(show: Bool) {
        PlayInput.keyboardMapped = !show
        Toucher.writeLog(logMessage: "editor opened? \(show)")
        if show {
            self.invalidate()
            mode.show(show)
            if let keyboard = GCKeyboard.coalesced!.keyboardInput {
                keyboard.keyChangedHandler = { _, _, keyCode, _ in
                    if !PlayInput.cmdPressed()
                        && !PlayInput.FORBIDDEN.contains(keyCode)
                        && self.isSafeToBind(keyboard)
                        && KeyCodeNames.keyCodes[keyCode.rawValue] != nil {
                        EditorController.shared.setKey(keyCode.rawValue)
                    }
                }
            }
            if let controller = GCController.current?.extendedGamepad {
                controller.valueChangedHandler = { _, element in
                    // This is the index of controller buttons, which is String, not Int
                    var alias: String = element.aliases.first!
                    if alias == "Direction Pad" {
                        guard let dpadElement = element as? GCControllerDirectionPad else {
                            Toast.showOver(msg: "cannot map direction pad: element type not recognizable")
                            return
                        }
                        if dpadElement.xAxis.value > 0 {
                            alias = dpadElement.right.aliases.first!
                        } else if dpadElement.xAxis.value < 0 {
                            alias = dpadElement.left.aliases.first!
                        }
                        if dpadElement.yAxis.value > 0 {
                            alias = dpadElement.down.aliases.first!
                        } else if dpadElement.yAxis.value < 0 {
                            alias = dpadElement.up.aliases.first!
                        }
                    }
                    EditorController.shared.setKey(alias)
                }
            }
        } else {
            setup()
            parseKeymap()
            _ = self.swapMode()
        }
    }

    func setup() {
        GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler = nil
        GCController.current?.extendedGamepad?.valueChangedHandler = controllerButtonHandler
    }

    static public func cmdPressed() -> Bool {
        return AKInterface.shared!.cmdPressed
    }

    private func isSafeToBind(_ input: GCKeyboardInput) -> Bool {
           var result = true
           for forbidden in PlayInput.FORBIDDEN where input.button(forKeyCode: forbidden)?.isPressed ?? false {
               result = false
               break
           }
           return result
       }

    private static let FORBIDDEN: [GCKeyCode] = [
        .leftGUI,
        .rightGUI,
        .leftAlt,
        .rightAlt,
        .printScreen
    ]

    private func swapMode() -> Bool {
        if PlayInput.shouldLockCursor {
            mode.show(!mode.visible)
            return true
        }
        mode.show(true)
        return false
    }

    var root: UIViewController? {
        return screen.window?.rootViewController
    }

    func setupHotkeys() {
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            keyboard.button(forKeyCode: .leftGUI)?.pressedChangedHandler = { _, _, pressed in
                PlayInput.lCmdPressed = pressed
            }
            keyboard.button(forKeyCode: .rightGUI)?.pressedChangedHandler = { _, _, pressed in
                PlayInput.rCmdPressed = pressed
            }
        }
    }

    func syncUserDefaults() -> Float {
        let persistenceKeyname = "playtoolsKeymappingDisabledAt"
        let lastUse = UserDefaults.standard.float(forKey: persistenceKeyname)
        var thisUse = lastUse
        if lastUse < 1 {
            thisUse = 2
        } else {
            thisUse = Float(Date.timeIntervalSinceReferenceDate)
        }
        var token2: NSObjectProtocol?
        let center = NotificationCenter.default
        token2 = center.addObserver(forName: NSNotification.Name.playtoolsKeymappingWillDisable,
                                    object: nil, queue: OperationQueue.main) { _ in
            center.removeObserver(token2!)
            UserDefaults.standard.set(thisUse, forKey: persistenceKeyname)
        }
        return lastUse
    }

    func initializeToasts() {
        if !settings.mouseMapping || !mode.visible {
            return
        }
        self.parseKeymap()
        if self.actions.count <= 0 {
            return
        }
        self.invalidate()
        let lastUse = syncUserDefaults()
        if lastUse > Float(Date.now.addingTimeInterval(-86400*14).timeIntervalSinceReferenceDate) {
            return
        }
        Toast.showHint(title: NSLocalizedString("hint.enableKeymapping.title",
                                                tableName: "Playtools",
                                                value: "Keymapping Disabled", comment: ""),
                       text: [NSLocalizedString("hint.enableKeymapping.content.before",
                                                tableName: "Playtools",
                                                value: "Press", comment: ""),
                              " option ⌥ ",
                              NSLocalizedString("hint.enableKeymapping.content.after",
                                                tableName: "Playtools",
                                                value: "to enable keymapping", comment: "")],
                       timeout: 10,
                       notification: NSNotification.Name.playtoolsKeymappingWillEnable)
        let center = NotificationCenter.default
        var token: NSObjectProtocol?
        token = center.addObserver(forName: NSNotification.Name.playtoolsKeymappingWillEnable,
                                   object: nil, queue: OperationQueue.main) { _ in
            center.removeObserver(token!)
            Toast.showHint(title: NSLocalizedString("hint.disableKeymapping.title",
                                                    tableName: "Playtools",
                                                    value: "Keymapping Enabled", comment: ""),
                           text: [NSLocalizedString("hint.disableKeymapping.content.before",
                                                    tableName: "Playtools",
                                                    value: "Press", comment: ""),
                                  " option ⌥ ",
                                  NSLocalizedString("hint.disableKeymapping.content.after",
                                                    tableName: "Playtools",
                                                    value: "to disable keymapping", comment: "")],
                           timeout: 10,
                           notification: NSNotification.Name.playtoolsKeymappingWillDisable)
        }
    }

    func initialize() {
        if !PlaySettings.shared.keymapping {
            return
        }

        let centre = NotificationCenter.default
        let main = OperationQueue.main

        centre.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: main) { _ in
            if EditorController.shared.editorMode {
                self.toggleEditor(show: true)
            } else {
                self.setup()
            }
        }
        parseKeymap()
        centre.addObserver(forName: UIApplication.keyboardDidHideNotification, object: nil, queue: main) { _ in
            PlayInput.keyboardMapped = true
            Toucher.writeLog(logMessage: "virtual keyboard did hide")
        }
        centre.addObserver(forName: UIApplication.keyboardWillShowNotification, object: nil, queue: main) { _ in
            PlayInput.keyboardMapped = false
            Toucher.writeLog(logMessage: "virtual keyboard will show")
        }
        centre.addObserver(forName: NSNotification.Name(rawValue: "NSWindowDidBecomeKeyNotification"), object: nil,
            queue: main) { _ in
            if !mode.visible {
                AKInterface.shared!.warpCursor()
            }
        }
        setupHotkeys()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, qos: .utility, execute: initializeToasts)

        AKInterface.shared!.initialize(keyboard: {keycode, pressed, isRepeat in
            if !PlayInput.keyboardMapped {
                // explicitly ignore repeated Enter key
                return isRepeat && keycode == 36
            }
            if isRepeat {
                return true
            }
            let mapped = self.keyboardHandler(keycode, pressed)
            return mapped
        }, mouseMoved: {deltaX, deltaY in
            if !PlayInput.keyboardMapped {
                return false
            }
            PlayInput.touchQueue.async(qos: .userInteractive, execute: {
                if mode.visible {
                    PlayMice.shared.handleFakeMouseMoved(deltaX: deltaX, deltaY: deltaY)
                } else {
                    PlayMice.shared.handleMouseMoved(deltaX: deltaX, deltaY: deltaY)
                }
            })
            return true
        }, swapMode: self.swapMode)
        PlayMice.shared.initialize()
    }
}
