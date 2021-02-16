//
//  ViewForm.swift
//  Multichannel-Streaming-iOS
//
//  Created by Max Cobb on 09/02/2021.
//

import UIKit
import AgoraRtcKit

class ViewForm: UIView {
    let role: AgoraClientRole
    /// Used by the second channel only
    var agChannel: AgoraRtcChannel?
    /// Used to hold all the video views
    var videosHolder = UIView()
    init(role: AgoraClientRole) {
        self.role = role
        super.init(frame: .zero)
    }

    /// UITextField where the user will enter the channel to join
    lazy var channelField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "channel-name"
        tf.borderStyle = .roundedRect
        return tf
    }()

    /// Label to display the role
    lazy var roleLabel: UILabel = {
        let myLabel = UILabel(frame: .zero)
        myLabel.text = self.role == .audience ? "Audience" : "Streaming"
        myLabel.textAlignment = .center
        myLabel.backgroundColor = .secondarySystemBackground
        myLabel.layer.cornerRadius = 10
        myLabel.layer.cornerCurve = .continuous
        return myLabel
    }()


    /// Method to place the subviews
    func placeFields() {
        [self.roleLabel, self.channelField]
            .enumerated().forEach { (idx, field) in
            self.addSubview(field)
            field.frame = CGRect(
                origin: CGPoint(
                    x: 25,
                    y: 30 + idx * 55),
                size: CGSize(width: self.bounds.width - 50, height: 50)
            )
            field.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        }
        self.addSubview(videosHolder)
        self.videosHolder.frame = CGRect(
            origin: CGPoint(x: 25, y: 30 + 3 * 55),
            size: CGSize(
                width: self.bounds.width - 50,
                height: self.bounds.height - 60 - 3 * 55
            )
        )
        self.videosHolder.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
