//
//  SceneDelegate.swift
//  Triage
//
//  Created by Francis Li on 9/24/26.
//  Copyright © 2026 Francis Li. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = InterstitialViewController()
        window?.makeKeyAndVisible()
    }
}
