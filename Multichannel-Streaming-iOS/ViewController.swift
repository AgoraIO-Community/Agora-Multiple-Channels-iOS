//
//  ViewController.swift
//  Multichannel-Streaming-iOS
//
//  Created by Max Cobb on 05/02/2021.
//

import UIKit
import AgoraRtcKit
import AgoraUIKit_iOS

class ViewController: UIViewController {
    var joinedChannels = false
    var leftView = ViewForm(role: .broadcaster)
    var rightView = ViewForm(role: .audience)

    lazy var agoraVideoView = AgoraVideoViewer(
        connectionData: AgoraConnectionData(appId: <#Agora App ID#>)
    )

    var agkit: AgoraRtcEngineKit {
        self.agoraVideoView.agkit
    }

    // Button to join/leave channels
    lazy var submitButton: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.setTitle("Join", for: .normal)
        btn.backgroundColor = .secondarySystemBackground
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(toggleJoinChannels), for: .touchUpInside)
        return btn
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.layoutBothSides()
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        self.addButtons()
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }


    func layoutBothSides() {
        // Setup the view on the left (Streamer view)
        leftView.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: self.view.bounds.width / 2,
                height: self.view.bounds.height
            )
        )
        leftView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleRightMargin]
        self.view.addSubview(leftView)

        // Setup the view on the right (Audience view)
        rightView.frame = CGRect(
            origin: CGPoint(x: self.view.bounds.width / 2, y: 0),
            size: CGSize(
                width: self.view.bounds.width / 2,
                height: self.view.bounds.height
            )
        )
        rightView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleLeftMargin]
        self.view.addSubview(rightView)
    }

    func addButtons() {
        leftView.placeFields()
        rightView.placeFields()

        self.submitButton.frame = CGRect(
            origin: CGPoint(
                x: 25,
                y: 30 + 2 * 55),
            size: CGSize(width: self.view.bounds.width - 50, height: 50)
        )
        self.submitButton.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        self.view.addSubview(self.submitButton)

        self.leftView.videosHolder.addSubview(self.agoraVideoView)
        self.agoraVideoView.frame = self.leftView.videosHolder.bounds
        self.agoraVideoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    @objc func toggleJoinChannels() {
        if joinedChannels {
            self.leaveChannels()
        } else {
            self.joinChannels()
        }
    }

    func joinChannels() {
        guard let leftChannel = self.leftView.channelField.text,
              let rightChannel = self.rightView.channelField.text,
              !leftChannel.isEmpty, !rightChannel.isEmpty else {
            return
        }
        self.submitButton.setTitle("Leave", for: .normal)
        self.submitButton.isEnabled = false
        self.leftView.channelField.isEnabled = false
        self.rightView.channelField.isEnabled = false

        // Join channel as broadcaster with AgoraVideoViewer
        self.agoraVideoView.join(channel: leftChannel, as: .broadcaster)

        // Join channel as audience with AgoraSingleVideoViews
        self.rightView.agChannel = self.agkit.createRtcChannel(rightChannel)
        self.rightView.agChannel?.setRtcChannelDelegate(self)
        self.rightView.agChannel?.join(byToken: nil, info: nil, uid: 0, options: AgoraRtcChannelMediaOptions())
        self.submitButton.isEnabled = true
        self.joinedChannels = true
    }
    func leaveChannels() {
        // Leave the one we are streaming to
        self.agoraVideoView.leaveChannel()

        // Leave the channel we are the audience in
        self.rightView.agChannel?.leave()
        rightView.agChannel?.destroy()
        rightView.agChannel = nil

        // Clean-up the channel feeds
        self.remoteUsersRHS.forEach { users in
            users.value.canvas.view = nil
            users.value.removeFromSuperview()
        }
        self.remoteUsersRHS.removeAll()

        // Re-enable channel options
        self.joinedChannels = false
        self.leftView.channelField.isEnabled = true
        self.rightView.channelField.isEnabled = true
        self.submitButton.setTitle("Join", for: .normal)
    }
    /// Dictionary of User ID to AgoraSingleVideo Views
    var remoteUsersRHS: [UInt: AgoraSingleVideoView] = [:] {
        didSet { self.setVideoPositions() }
    }
}
