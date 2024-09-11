//
//  GamepadToKeySettingViewController.swift
//  PlayTools
//  
//  Created by vkmilkyw on 2024/9/10.
//

import Foundation
import GameController

class GamepadToKeySettingViewController: UIViewController {
    static weak var current: GamepadToKeySettingViewController?
    let toolbar = UIToolbar()
    let tableView = UITableView()
    var keymapData = KeymappingData(bundleIdentifier: "")
    var indexOfEditingGamepadInput: IndexPath?
    var indexOfEditingKeyboardOutput: IndexPath?
    var onDismiss: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        GamepadToKeySettingViewController.current = self
        loadData()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        ModeAutomaton.onOpenGamepadToKeySetting()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        ActionDispatcher.build()
        ModeAutomaton.onCloseGamepadToKeySetting()
        GamepadToKeySettingViewController.current = nil
    }

    deinit {
        GamepadToKeySettingViewController.current = nil
    }

    // listen for keyboard events manually
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)

        for press in presses {
            guard let key = press.key else { continue }
            guard let modifierFlags = event?.modifierFlags else { continue }
            setKeyboardKey(keyCode: key.keyCode, modifierFlags: modifierFlags)
        }
    }

    private func setupView() {
        view.backgroundColor = .white
        setupToolbar()
        setupTableView()
    }

    func loadData() {
        self.keymapData = Keymapping.shared.keymapData
    }

    func saveData() {
        Keymapping.shared.keymapData = self.keymapData
    }

    func setGamepadKey(keyName: String) {
        if let indexPath = self.indexOfEditingGamepadInput {
            keymapData.gamepadToKeyModels[indexPath.row].keyName = keyName
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    func setKeyboardKey(keyCode: UIKeyboardHIDUsage, modifierFlags: UIKeyModifierFlags) {
        if let indexPath = self.indexOfEditingKeyboardOutput {
            keymapData.gamepadToKeyModels[indexPath.row].targetKeyCode = keyCode.rawValue
            keymapData.gamepadToKeyModels[indexPath.row].targetModifiers =
                keyCode.isModifier ? 0 : modifierFlags.rawValue
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    func setMouseButton(keyCode: Int) {
        if let indexPath = self.indexOfEditingKeyboardOutput {
            keymapData.gamepadToKeyModels[indexPath.row].targetKeyCode = keyCode
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

extension UIKeyboardHIDUsage {
    var isModifier: Bool {
        return self == .keyboardLeftControl || self == .keyboardRightControl ||
            self == .keyboardLeftAlt && self == .keyboardRightAlt ||
            self == .keyboardLeftShift && self == .keyboardRightShift ||
            self == .keyboardLeftGUI && self == .keyboardRightGUI
    }
}
