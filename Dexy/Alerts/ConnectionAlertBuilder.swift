//
//  ConnectionAlertViewController.swift
//  Dexy
//
//  Created by Tudor Croitoru on 02/04/2022.
//

import UIKit
import Alamofire

struct ConnectionAlertBuilder {
    
    public enum ErrorKind {
        case generalError
        case connectionError
        case shareError
    }
    
    private init() {}
    
    public static func getAlertViewController(errorKind: ErrorKind, error: AFError) -> UIAlertController {
        let alert: UIAlertController
        if errorKind == .generalError {
            alert = ConnectionAlertBuilder.buildGeneralErrorAlert(error: error)
        } else {
            alert = ConnectionAlertBuilder.buildConnectionErrorAlert(error: error)
        }
        return alert
    }
    
    public static func getAlertViewController(errorKind: ErrorKind, error: Error) -> UIAlertController {
        let alert: UIAlertController = ConnectionAlertBuilder.buildGeneralErrorAlert(error: error)
        // if more error kinds are added later, this is the catch-all method. Do a switch-default to choose the error controller
        return alert
    }
    
    private static func buildGeneralErrorAlert(error: Error) -> UIAlertController {
        let alert = UIAlertController(title: "Am dat cu mucii-n fasole...",
                                      message: "Uite eroarea: \nDescriere: \(error.localizedDescription)",
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "Bine", style: .default))
        return alert
    }
    
    private static func buildGeneralErrorAlert(error: AFError) -> UIAlertController {
        let alert = UIAlertController(title: "Am dat cu mucii-n fasole...",
                                      message: "Uite eroarea: \nCod: \(String(describing: error.responseCode))\nDescriere: \(error.localizedDescription)",
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "Bine", style: .default))
        return alert
    }
    
    private static func buildConnectionErrorAlert(error: AFError) -> UIAlertController {
        let alert = UIAlertController(title: "Nu-ți merge netul",
                                      message: "Incearcă să pornești WiFi-ul sau datele mobile din setări",
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "Haide!", style: .default, handler: { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }))
        alert.addAction(.init(title: "Mai încolo", style: .cancel))
        return alert
    }

}
