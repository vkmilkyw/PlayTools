//
//  GamepadToKeySettingViewController+TableVIew.swift
//  PlayTools
//  
//  Created by vkmilkyw on 2024/9/10.
//

import Foundation

extension GamepadToKeySettingViewController: UITableViewDelegate,
                                             UITableViewDataSource,
                                             GamepadToKeySettingCellDelegate {

    func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self

        // Register the custom cell
        tableView.register(GamepadToKeySettingCell.self, forCellReuseIdentifier: GamepadToKeySettingCell.indentifier)

        // Add the table view to the view
        view.addSubview(tableView)

        // Set up table view constraints (below the toolbar)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keymapData.gamepadToKeyModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: GamepadToKeySettingCell.indentifier, for: indexPath) as? GamepadToKeySettingCell else {
            return UITableViewCell()
        }

        let data = keymapData.gamepadToKeyModels[indexPath.row]
        cell.setupCell(data)
        cell.highlightGamepadInput(indexPath == indexOfEditingGamepadInput)
        cell.highlightKeyboardOutput(indexPath == indexOfEditingKeyboardOutput)
        cell.delegate = self
        return cell
    }

    func didTapGamepadInputLabel(in cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            indexOfEditingGamepadInput = indexPath
            indexOfEditingKeyboardOutput = nil
            tableView.reloadData()
        }
    }

    func didTapKeyboardOutputLabel(in cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            indexOfEditingGamepadInput = nil
            indexOfEditingKeyboardOutput = indexPath
            tableView.reloadData()
        }
    }

    func didTapDeleteButton(in cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            indexOfEditingGamepadInput = nil
            indexOfEditingKeyboardOutput = nil
            keymapData.gamepadToKeyModels.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
}
