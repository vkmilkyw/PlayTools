//
//  GameToKeyController.swift
//  PlayTools
//  
//  Created by vkmilkyw on 2024/9/10.
//

import Foundation

class GamepadToKeyController {
    static let shared = GamepadToKeyController()
    let lock = NSLock()
    var gameToKeyWindow: UIWindow?
    weak var previousWindow: UIWindow?

    func showSettingView() {
        if isWindowShown() {
            return
        }
        createWindow()
        let settingVc = GamepadToKeySettingViewController()
        settingVc.modalPresentationStyle = .formSheet
        settingVc.isModalInPresentation = true
        settingVc.onDismiss = {
            self.destroyWindow()
        }
        gameToKeyWindow?.rootViewController?.present(settingVc, animated: false)
    }

    private func createWindow() {
        lock.lock()
        previousWindow = screen.keyWindow
        gameToKeyWindow = UIWindow(windowScene: screen.windowScene!)
        gameToKeyWindow?.rootViewController = GameToKeyRootViewController()
        gameToKeyWindow?.makeKeyAndVisible()
        lock.unlock()
    }

    private func destroyWindow() {
        lock.lock()
        gameToKeyWindow?.isHidden = true
        gameToKeyWindow?.windowScene = nil
        gameToKeyWindow?.rootViewController = nil
        gameToKeyWindow = nil
        previousWindow?.makeKeyAndVisible()
        lock.unlock()
    }

    private func isWindowShown() -> Bool {
        return gameToKeyWindow != nil
    }
}

class GameToKeyRootViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
}
