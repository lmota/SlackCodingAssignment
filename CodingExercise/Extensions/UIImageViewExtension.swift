//
//  UIImageViewExtension.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation
import UIKit

extension UIImageView {
    
    /**
     * UIImageView extension to create rounded border
     */
    func createRoundedBorder() {
        self.layer.cornerRadius = CGFloat(Constants.imageViewCornerRadius)
        self.clipsToBounds = true
    }
    
}
