//
//  ViewController+SecondChannelPositioning.swift
//  Multichannel-Streaming-iOS
//
//  Created by Max Cobb on 08/02/2021.
//

import UIKit

extension ViewController {
    /// Positioning all the AgoraSingleVideoView objects on the right hand side view
    func setVideoPositions() {
        let vidCounts = self.remoteUsersRHS.count

        // I'm always applying an NxN grid, so if there are 12
        // We take on a grid of 4x4 (16).
        let maxSqrt = ceil(sqrt(CGFloat(vidCounts)))
        let multDim = 1 / maxSqrt
        for (idx, (_, videoSessionView)) in self.remoteUsersRHS.enumerated() {
            self.rightView.videosHolder.addSubview(videoSessionView)
            videoSessionView.frame.size = CGSize(
                width: self.rightView.videosHolder.frame.width * multDim,
                height: self.rightView.videosHolder.frame.height * multDim
            )
            if idx == 0 {
                // First video goes at the top left
                videoSessionView.frame.origin = .zero
            } else {
                let posY = trunc(CGFloat(idx) / maxSqrt) * ((1 - multDim) * self.rightView.videosHolder.frame.height)
                if (idx % Int(maxSqrt)) == 0 {
                    // New row, so go to the far left, and align the top of this
                    // view with the bottom of the previous view.
                    videoSessionView.frame.origin = CGPoint(x: 0, y: posY)
                } else {
                    // Go to the end of current row
                    videoSessionView.frame.origin = CGPoint(
                        x: CGFloat(idx % Int(maxSqrt)) / maxSqrt * self.rightView.videosHolder.frame.width,
                        y: posY
                    )
                }
            }
            // autoresizingMask makes sure the views will adjust scale
            // if the device is rotated or parent view changes shape
            videoSessionView.autoresizingMask = [
                .flexibleLeftMargin, .flexibleRightMargin,
                .flexibleTopMargin, .flexibleBottomMargin,
                .flexibleWidth, .flexibleHeight
            ]
        }
    }
}
