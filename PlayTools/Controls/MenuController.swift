/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Menu construction extensions for this sample.
 */

import UIKit

class RotateViewController: UIViewController {
    static let orientationList: [UIInterfaceOrientation] = [
        .landscapeLeft, .portrait, .landscapeRight, .portraitUpsideDown]
    static var orientationTraverser = 0

    static func rotate() {
        orientationTraverser += 1
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        RotateViewController.orientationList[
            RotateViewController.orientationTraverser % RotateViewController.orientationList.count]
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override var modalPresentationStyle: UIModalPresentationStyle { get {.fullScreen} set {} }
}

extension UIApplication {
    @objc
    func switchEditorMode(_ sender: AnyObject) {
        EditorController.shared.switchMode()
    }

    @objc
    func removeElement(_ sender: AnyObject) {
        EditorController.shared.removeControl()
    }

    @objc
    func upscaleElement(_ sender: AnyObject) {
        EditorController.shared.focusedControl?.resize(down: false)
    }

    @objc
    func downscaleElement(_ sender: AnyObject) {
        EditorController.shared.focusedControl?.resize(down: true)
    }

    // put a mark in the toucher log, so as to align with tester description
    @objc
    func markToucherLog(_ sender: AnyObject) {
        Toucher.writeLog(logMessage:"mark")
        Toast.showHint(title: "Log marked")
    }
}

extension UIViewController {
    @objc
    func rotateView(_ sender: AnyObject) {
        RotateViewController.rotate()
        let viewController = RotateViewController(nibName: nil, bundle: nil)
        self.present(viewController, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
            self.dismiss(animated: true)
        })
    }
}

struct CommandsList {
    static let KeymappingToolbox = "keymapping"
}
// have to use a customized name, in case it conflicts with the game's localization file
var keymapping = [
    NSLocalizedString("menu.keymapping.toggleEditor", tableName: "Playtools",
                      value: "Open/Close Keymapping Editor", comment: ""),
    NSLocalizedString("menu.keymapping.deleteElement", tableName: "Playtools",
                      value: "Delete selected element", comment: ""),
    NSLocalizedString("menu.keymapping.upsizeElement", tableName: "Playtools",
                      value: "Upsize selected element", comment: ""),
    NSLocalizedString("menu.keymapping.downsizeElement", tableName: "Playtools",
                      value: "Downsize selected element", comment: ""),
    NSLocalizedString("menu.keymapping.rotateDisplay", tableName: "Playtools",
                      value: "Rotate display area", comment: ""),
    NSLocalizedString("menu.keymapping.markLog", tableName: "Playtools",
                      value: "Put a mark in toucher log", comment: "")
  ]
var keymappingSelectors = [#selector(UIApplication.switchEditorMode(_:)),
                           #selector(UIApplication.removeElement(_:)),
                           #selector(UIApplication.upscaleElement(_:)),
                           #selector(UIApplication.downscaleElement(_:)),
                           #selector(UIViewController.rotateView(_:)),
                           #selector(UIApplication.markToucherLog)]

class MenuController {
    init(with builder: UIMenuBuilder) {
        builder.insertSibling(MenuController.keymappingMenu(), afterMenu: .view)
    }

    class func keymappingMenu() -> UIMenu {
        let keyCommands = [ "K", UIKeyCommand.inputDelete, UIKeyCommand.inputUpArrow, UIKeyCommand.inputDownArrow, "R", "L"]

        let arrowKeyChildrenCommands = zip(keyCommands, keymapping).map { (command, btn) in
            UIKeyCommand(title: btn,
                         image: nil,
                         action: keymappingSelectors[keymapping.firstIndex(of: btn)!],
                         input: command,
                         modifierFlags: .command,
                         propertyList: [CommandsList.KeymappingToolbox: btn]
            )
        }

        let arrowKeysGroup = UIMenu(title: "",
                                    image: nil,
                                    identifier: .keymappingOptionsMenu,
                                    options: .displayInline,
                                    children: arrowKeyChildrenCommands)

        return UIMenu(title: NSLocalizedString("menu.keymapping", tableName: "Playtools",
                                               value: "Keymapping", comment: ""),
                      image: nil,
                      identifier: .keymappingMenu,
                      options: [],
                      children: [arrowKeysGroup])
    }
}

extension UIMenu.Identifier {
    static var keymappingMenu: UIMenu.Identifier { UIMenu.Identifier("io.playcover.PlayTools.menus.editor") }
    static var keymappingOptionsMenu: UIMenu.Identifier { UIMenu.Identifier("io.playcover.PlayTools.menus.keymapping") }
}
