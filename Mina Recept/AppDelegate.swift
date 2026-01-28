//
//  AppDelegate.swift
//  Mina Recept
//
//  Created by Leif Tarvainen on 2026-01-13.
//


import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }
}
