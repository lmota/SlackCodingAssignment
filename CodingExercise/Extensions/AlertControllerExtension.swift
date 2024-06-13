//
//  AlertControllerExtension.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation
import UIKit

/**
 * Extension on UIViewController for UIAlertController methods
 */
extension UIViewController{
    /**
     * Convenience method on UIViewController for presenting an alert
     */
    func displayAlert(with title: String, message: String, actions: [UIAlertAction]? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions?.forEach { action in
            alertController.addAction(action)
        }
        present(alertController, animated: true)
    }
    
    /**
     * Convenience method on UIViewController for presenting an alert action sheet
     */
    func displayActionSheet(with title: String, message: String, actions:[UIAlertAction]? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        actions?.forEach { action in
            alertController.addAction(action)
        }
        
        if (UIUserInterfaceIdiom.pad !=  UIDevice().userInterfaceIdiom) {
            present(alertController, animated: true)
        } else {
            if let currentPopoverpresentioncontroller = alertController.popoverPresentationController {
                currentPopoverpresentioncontroller.permittedArrowDirections = []
                currentPopoverpresentioncontroller.sourceRect = CGRect(x: (self.view.bounds.midX), y: (self.view.bounds.midY), width: 0, height: 0)
                currentPopoverpresentioncontroller.sourceView = self.view
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

