//
//  GamepadToKeySettingCellDelegate.swift
//  PlayTools
//  
//  Created by vkmilkyw on 2024/9/10.
//

protocol GamepadToKeySettingCellDelegate: AnyObject {
    func didTapGamepadInputLabel(in cell: UITableViewCell)
    func didTapKeyboardOutputLabel(in cell: UITableViewCell)
    func didTapDeleteButton(in cell: UITableViewCell)
}
