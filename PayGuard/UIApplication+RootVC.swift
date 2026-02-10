//
//  UIApplication+RootVC.swift
//  PayGuard
//
//  Created by Atul Tiwari on 08/01/26.
//

import UIKit

extension UIApplication {
    var rootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
