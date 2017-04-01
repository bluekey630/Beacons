//
//  NATOperationCell.swift
//  HiBeacons
//
//  Created by bluekey630 on 4/1/17.
//  Copyright © 2017 bluekey630. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import UIKit

/// The custom cell that is used for presenting the user with the three possible app operations.
final class NATOperationCell : UITableViewCell
{
    /// The activity indicator view, showing if an operation is working.
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    /// Sets up the contraints for the various cell elements.
    override func updateConstraints() {
        // We wouldn't normally need this, since constraints can be set in Interface Builder. However, there seems
        // to be a bug that removes all constraints from our cells upon dequeueing, so we need to re-add them here.

        contentView.translatesAutoresizingMaskIntoConstraints = false

        let rightAccessoryViewMarginConstraint = NSLayoutConstraint(item: accessoryView!, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -14.0)
        let topAccessoryViewMarginConstraint = NSLayoutConstraint(item: accessoryView!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 7.0)
        let activityViewWidthConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 20.0)
        let activityViewHeightConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 20.0)
        let rightActivityViewMarginConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .right, relatedBy: .equal, toItem: accessoryView, attribute: .left, multiplier: 1.0, constant: -8.0)
        let topActivityViewMarginConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: accessoryView!, attribute: .centerY, multiplier: 1.0, constant: 0.0)

        addConstraints([rightAccessoryViewMarginConstraint,
                        topAccessoryViewMarginConstraint,
                        activityViewWidthConstraint,
                        activityViewHeightConstraint,
                        rightActivityViewMarginConstraint,
                        topActivityViewMarginConstraint])
//
        super.updateConstraints()
    }

    /// Ensures that the activity indicator is at the front of the cell.
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.contentView.bringSubview(toFront: activityIndicator)
    }
}
