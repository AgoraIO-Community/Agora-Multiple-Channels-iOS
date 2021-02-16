//
//  ViewController+SecondChannelDelegate.swift
//  Multichannel-Streaming-iOS
//
//  Created by Max Cobb on 08/02/2021.
//

import AgoraRtcKit
import AgoraUIKit_iOS

extension ViewController: AgoraRtcChannelDelegate, AgoraRtcEngineDelegate {
    func getOrCreateUserVideo(_ rtcChannel: AgoraRtcChannel, with userId: UInt) -> AgoraSingleVideoView {
        if let remoteView = self.remoteUsersRHS[userId] {
            return remoteView
        }
        let remoteVideoView = AgoraSingleVideoView(uid: userId, micColor: .systemBlue)
        remoteVideoView.canvas.channelId = rtcChannel.getId()

        self.agkit.setupRemoteVideo(remoteVideoView.canvas)
        self.remoteUsersRHS[userId] = remoteVideoView
        return remoteVideoView
    }

    func rtcEngine(
        _ engine: AgoraRtcEngineKit, didJoinChannel channel: String,
        withUid uid: UInt, elapsed: Int
    ) {
        let remoteVideoView = AgoraSingleVideoView(
            uid: uid, micColor: .systemBlue
        )
        engine.setupRemoteVideo(remoteVideoView.canvas)

        // position the remoteVideoView in your scene
    }

    public func rtcChannel(
        _ rtcChannel: AgoraRtcChannel, remoteVideoStateChangedOfUid uid: UInt,
        state: AgoraVideoRemoteState, reason: AgoraVideoRemoteStateReason, elapsed: Int
    ) {
        let myUserVideo = getOrCreateUserVideo(rtcChannel, with: uid)
        switch state {
        case .decoding, .starting:
            myUserVideo.videoMuted = false
        case .stopped:
            myUserVideo.videoMuted = true
        default:
            break
        }
    }
    func rtcChannel(
        _ rtcChannel: AgoraRtcChannel, remoteAudioStateChangedOfUid uid: UInt,
        state: AgoraAudioRemoteState, reason: AgoraAudioRemoteStateReason, elapsed: Int
    ) {
        if state == .stopped || state == .starting {
            getOrCreateUserVideo(rtcChannel, with: uid).audioMuted = state == .stopped
        }
    }

    func rtcChannel(_ rtcChannel: AgoraRtcChannel, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        guard let userSingleView = remoteUsersRHS[uid],
              let canView = userSingleView.canvas.view else {
            return
        }
        rtcChannel.muteRemoteVideoStream(uid, mute: true)
        userSingleView.canvas.view = nil
        canView.removeFromSuperview()
        self.remoteUsersRHS.removeValue(forKey: uid)
    }
}
