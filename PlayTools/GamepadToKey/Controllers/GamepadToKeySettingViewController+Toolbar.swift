//
//  GamepadToKeySettingViewController+Toolbar.swift
//  PlayTools
//  
//  Created by vkmilkyw on 2024/9/10.
//

import Foundation

extension GamepadToKeySettingViewController {

    func setupToolbar() {
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        // Create toolbar items
        let closeButton = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeDialog))
        let addButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addNewRow))

        // Create a flexible space to center the title
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        // Create a custom title label to be added to the toolbar
        let titleLabel = UILabel()
        titleLabel.text = "Gamepad to Key Setting"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center

        // Wrap the titleLabel in a UIBarButtonItem
        let titleItem = UIBarButtonItem(customView: titleLabel)

        // Set the toolbar items (close button, flexible space, title, flexible space, and add button)
        toolbar.items = [closeButton, flexibleSpace, titleItem, flexibleSpace, addButton]

        self.navigationController?.view.addSubview(toolbar)

        // Add the toolbar to the view
        view.addSubview(toolbar)

        // Set up toolbar constraints (pinned to top of the view)
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)  // Standard toolbar height
        ])
    }

    @objc func closeDialog() {
        saveData()
        dismiss(animated: false) {
            self.onDismiss?()
        }
    }

    @objc func addNewRow() {
        indexOfEditingGamepadInput = nil
        indexOfEditingKeyboardOutput = nil
        keymapData.gamepadToKeyModels.append(GamepadToKey(keyName: "", targetKeyCode: -1, targetModifiers: 0))
        tableView.reloadData()
    }
}
