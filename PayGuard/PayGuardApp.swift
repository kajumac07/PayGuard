//
//  PayGuardApp.swift
//  PayGuard
//
//  Created by Atul Tiwari on 08/01/26.
//

import SwiftUI
import GoogleSignIn

@main
struct PayGuardApp: App {

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
