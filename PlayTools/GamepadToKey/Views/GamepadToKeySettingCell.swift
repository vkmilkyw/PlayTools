//
//  GamepadToKeySettingTableCell.swift
//  PlayTools
//  
//  Created by vkmilkyw on 2024/9/10.
//

import Foundation

class GamepadToKeySettingCell: UITableViewCell {
    weak var delegate: GamepadToKeySettingCellDelegate?
    let gamepadInputLabel = UILabel()
    let keyboardOutputLabel = UILabel()
    let arrowImageView = UIImageView()
    let deleteButton = UIButton(type: .system)

    class var indentifier: String {
        String(describing: self)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.selectionStyle = .none

        // First text label setup
        gamepadInputLabel.backgroundColor = UIColor.systemGray6
        gamepadInputLabel.textColor = .black
        gamepadInputLabel.textAlignment = .center
        gamepadInputLabel.layer.cornerRadius = 5
        gamepadInputLabel.layer.masksToBounds = true
        gamepadInputLabel.layer.borderWidth = 1
        gamepadInputLabel.layer.borderColor = UIColor.gray.cgColor
        gamepadInputLabel.isUserInteractionEnabled = true

        // Add tap gesture to the first text label
        let firstTapGesture = UITapGestureRecognizer(target: self, action: #selector(gamepadInputLabelTapped))
        gamepadInputLabel.addGestureRecognizer(firstTapGesture)

        // Second text label setup
        keyboardOutputLabel.backgroundColor = UIColor.systemGray6
        keyboardOutputLabel.textColor = .black
        keyboardOutputLabel.textAlignment = .center
        keyboardOutputLabel.layer.cornerRadius = 5
        keyboardOutputLabel.layer.masksToBounds = true
        keyboardOutputLabel.layer.borderWidth = 1
        keyboardOutputLabel.layer.borderColor = UIColor.gray.cgColor
        keyboardOutputLabel.isUserInteractionEnabled = true

        // Add tap gesture to the second text label
        let secondTapGesture = UITapGestureRecognizer(target: self, action: #selector(keyboardOutputLabelTapped))
        keyboardOutputLabel.addGestureRecognizer(secondTapGesture)

        // Arrow image setup (using a right arrow system image)
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.contentMode = .scaleAspectFit

        // Delete button setup
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setTitleColor(.red, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)

        // Add the UI elements to the content view
        contentView.addSubview(gamepadInputLabel)
        contentView.addSubview(arrowImageView)
        contentView.addSubview(keyboardOutputLabel)
        contentView.addSubview(deleteButton)

        // Set up constraints
        setupConstraints()
    }

    private func setupConstraints() {
        gamepadInputLabel.translatesAutoresizingMaskIntoConstraints = false
        keyboardOutputLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // First text label constraints
            gamepadInputLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gamepadInputLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            gamepadInputLabel.widthAnchor.constraint(equalToConstant: 200),
            gamepadInputLabel.heightAnchor.constraint(equalToConstant: 30),

            // Arrow image constraints
            arrowImageView.leadingAnchor.constraint(equalTo: gamepadInputLabel.trailingAnchor, constant: 8),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 20),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20),

            // Second text label constraints
            keyboardOutputLabel.leadingAnchor.constraint(equalTo: arrowImageView.trailingAnchor, constant: 8),
            keyboardOutputLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            keyboardOutputLabel.widthAnchor.constraint(equalToConstant: 200),
            keyboardOutputLabel.heightAnchor.constraint(equalToConstant: 30),

            // Delete button constraints
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    @objc private func gamepadInputLabelTapped() {
        delegate?.didTapGamepadInputLabel(in: self)
    }

    @objc private func keyboardOutputLabelTapped() {
        delegate?.didTapKeyboardOutputLabel(in: self)
    }

    @objc private func deleteButtonTapped() {
        delegate?.didTapDeleteButton(in: self)
    }

    func setupCell(_ data: GamepadToKey) {
        gamepadInputLabel.text = data.keyName

        let keyCodeName = KeyCodeNames.keyCodes[data.targetKeyCode] ?? ""
        let modifiersName = getModifiersDisplayName(data.targetModifiers)
        keyboardOutputLabel.text = modifiersName + keyCodeName
    }

    func highlightGamepadInput(_ highlight: Bool) {
        setLabelHighlight(label: gamepadInputLabel, highlight: highlight)
    }

    func highlightKeyboardOutput(_ highlight: Bool) {
        setLabelHighlight(label: keyboardOutputLabel, highlight: highlight)
    }

    private func setLabelHighlight(label: UILabel, highlight: Bool) {
        if highlight {
            label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        } else {
            label.backgroundColor = UIColor.systemGray6
        }
    }

    private func getModifiersDisplayName(_ modifiers: Int) -> String {
        let modifierFlags = UIKeyModifierFlags(rawValue: modifiers)
        var str = ""
        if modifierFlags.contains(.control) {
            str += "⌃ "
        }
        if modifierFlags.contains(.alternate) {
            str += "⌥ "
        }
        if modifierFlags.contains(.shift) {
            str += "⇧ "
        }
        if modifierFlags.contains(.command) {
            str += "⌘ "
        }
        return str
    }
}
