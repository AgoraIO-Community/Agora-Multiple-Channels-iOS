# Connecting to Multiple Channels with Agora

Since Agora's SDK 3.0.0 users are now able to join an unlimited number of channels. The only limit is that you can only publish your own camera feed to one channel at a time.

This may be useful in one instance if you have a classroom channel where a teacher would stream to, and want the students to do smaller group work, while keeping an eye on them!

## Prerequisites

- An Agora developer account (see [How To Get Started with Agora](https://www.agora.io/en/blog/how-to-get-started-with-agora?utm_source=medium&utm_medium=blog&utm_campaign=ios-multi-channel))
- Xcode 11.0 or later
- iOS device with minimum iOS 13.0
- A basic understanding of iOS development
- CocoaPods

## Setup

Create an iOS project in Xcode, then install the CocoaPod AgoraUIKit_iOS. This pod contains some useful classes that make the setup of our project and utilisation of the Agora SDK much easier, although it is by no means a requirement of streaming multiple channels.

To see how to set up the video canvases yourself instead of with AgoraUIKit, check out the [Quickstart Guide for iOS](https://docs.agora.io/en/Video/start_call_ios?platform=iOS).

To install the CocoaPod, your Podfile should look like this:
```swift
target 'My-Agora-Project' do
  pod 'AgoraUIKit_iOS', '1.3.2'
end
```

> The latest AgoraUIKit release at the time of writing this post is v1.3.2.

Run `pod init`, and open the .xcworkspace file to get started.

## Set Up the UI

In this example, we will just have the option to join two different channels; one with a "broadcaster" role and the other as "audience".

If we make a class for this view called `ViewForm` which accepts one parameter, stating whether it is for an audience view or a streamer view. We make two of these views, each to fill up either the left or right side of the screen.

```swift
class ViewController: UIViewController {
    var leftView = ViewForm(role: .broadcaster)
    var rightView = ViewForm(role: .audience)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.layoutBothSides()
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

        // addButtons explained below
        self.addButtons()
    }
}
```

At this stage, the ViewForm object looks like this:

```swift
class ViewForm: UIView {
    let role: AgoraClientRole
    /// Used by the second channel only
    var agChannel: AgoraRtcChannel?

    init(role: AgoraClientRole) {
        self.role = role
        super.init(frame: .zero)
    }
}
```

Now that the views are in place, we need to add the buttons and other parts to our views. Each ViewForm has a method `placeFields()` to do this. This could be called directly from the initialiser, but the steps have been broken up for this guide:

```swift
class ViewForm: UIView {
    // ...
    // Previous ViewForm snippet goes here
    // ...
  
    /// Used to hold all the video views
    var videosHolder = UIView()

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
        self.videosHolder.autoresizingMask = [
            .flexibleWidth, .flexibleHeight, .flexibleBottomMargin
        ]
    }
}

class ViewController: UIViewController {
    // ...
    // Previous ViewController snippet goes here
    // ...
  
    /// AgoraVideoViewer is a class from AgoraUIKit_iOS
    lazy var agoraVideoView = AgoraVideoViewer(
        connectionData: AgoraConnectionData(
            appId: "<#Your App ID#>"
        )
    )

    // Button to join/leave channels
    lazy var submitButton: UIButton = {
        let btn = UIButton(type: .roundedRect)
        btn.setTitle("Join", for: .normal)
        btn.backgroundColor = .secondarySystemBackground
        btn.layer.cornerRadius = 10
        btn.addTarget(
            self,
            action: #selector(toggleJoinChannels),
            for: .touchUpInside
        )
        return btn
    }()

    /// Flag showing if the channels have been joined or not
    var joinedChannels = false

    /// Calls the functionality to join or leave channels,
    /// depending on the value of joinedChannels.
    /// joinChannels and leaveChannels will be explained below.
    @objc func toggleJoinChannels() {
        if joinedChannels {
            self.leaveChannels()
        } else {
            self.joinChannels()
        }
    }

    func addButtons() {
        leftView.placeFields()
        rightView.placeFields()

        // Position the submitButton in our frame
        self.submitButton.frame = CGRect(
            origin: CGPoint(
                x: 25,
                y: 30 + 2 * 55),
            size: CGSize(width: self.view.bounds.width - 50, height: 50)
        )
        self.submitButton.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        self.view.addSubview(self.submitButton)

        // Add AgoraVideoViewer to the left view, where we
        // will be publishing our camera feed.
        self.leftView.videosHolder.addSubview(self.agoraVideoView)
        self.agoraVideoView.frame = self.leftView.videosHolder.bounds
        self.agoraVideoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}

```

This is what those views look like so far in both light and dark mode on iOS:

![Alternating light and dark mode of channel selection form](https://cdn-images-1.medium.com/max/1200/1*w-OOqAxagPeEGxIxTTLMWA.gif)

The grey box showing where the video streams will be has only been added to make it clear where those views are, it is an empty view in the actual project so far.

## Connect to Both Channels

To know what channels we need to connect to, we must fetch the values from left left and right view's `channelField` UITextFields, and ensure they are not nil or empty:

```swift
guard let leftChannel = self.leftView.channelField.text,
      let rightChannel = self.rightView.channelField.text,
      !leftChannel.isEmpty, !rightChannel.isEmpty else {
    return
}
```

When connecting to a video channel with Agora you would typically call the method `joinChannel`, on your instance of the `AgoraRtcEngineKit`, explained in the iOS quickstart guide [here](https://docs.agora.io/en/Video/start_call_ios?platform=iOS#a-namejoinchannela5-join-a-channel). This is the method we will use to connect to the channel we intend to stream to - in the `leftView`.

As we are using `AgoraUIKit_iOS`, we can just call the [join method](https://agoraio-community.github.io/iOS-UIKit/Classes/AgoraVideoViewer.html#/s:14AgoraUIKit_iOS0A11VideoViewerC4join7channel4with2as3uidySS_SSSgSo0A10ClientRoleVSuSgtF) on the AgoraVideoViewer class being used, this joins the channel using the `AgoraRtcEngineKit.joinChannel` method.

```swift
// Join channel as broadcaster with AgoraVideoViewer
self.agoraVideoView.join(channel: leftChannel, as: .broadcaster)
```

In order to connect to the second channel we need to create an `AgoraRtcChannel` object and assign the `AgoraRtcChannelDelegate`.

```swift
// Join second channel as audience directly
self.rightView.agChannel = self.agkit.createRtcChannel(rightChannel)
self.rightView.agChannel?.setRtcChannelDelegate(self)
self.rightView.agChannel?.join(
		byToken: nil, info: nil, uid: 0,
		options: AgoraRtcChannelMediaOptions()
)
```

To assign the delegate we must have the ViewController inherit `AgoraRtcChannelDelegate`.

At this point, when the user clicks "Join" we need to change the "Join" button to a "Leave" button, and toggle the value of joinedChannels:

```swift
self.submitButton.setTitle("Leave", for: .normal)
self.joinedChannels = true
```

Now the user will join the channel on the left by streaming their local camera feed, and join the channel on the right as an audience member.

Functionality for leaving the channels will be explained later in this blog.

## Display Video Feeds

The video feeds in the example on the left is completely handled by [AgoraUIKit_iOS](https://github.com/AgoraIO-Community/iOS-UIKit), but if you want to see how to do this manually, it is fully explained in [this section](https://docs.agora.io/en/Video/start_call_ios?platform=iOS#6-set-the-remote-video-view) in the iOS Quickstart Guide.

What typically happens is an AgoraRtcVideoCanvas is created, its uid set to the user ID, a UIView is assigned to display the video, and setupRemoteVideo or setupLocalVideo is called on the engine object:

```swift
extension ViewController: AgoraRtcEngineDelegate {
    // Monitors the remoteVideoStateChangedOfUid callback
    func rtcEngine(
        _ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt,
        state: AgoraVideoRemoteState, reason: AgoraVideoRemoteStateReason, elapsed: Int
    ) {
      	switch state {
          	case .starting:
            		let videoCanvas = AgoraRtcVideoCanvas()
								videoCanvas.uid = uid
                videoCanvas.view = remoteView
                // Set the remote video view
                engine.setupRemoteVideo(videoCanvas)
						default: break
        }
    }
}
```

The difference with our second channel, is that we are instead using the `AgoraRtcChannelDelegate`. The methods in `AgoraRtcChannelDelegate` are very similar to those in `AgoraRtcEngineDelegate`, the main visual difference is that the first parameter is the `AgoraRtcChannel` object, rather than the engine:

```swift
extension ViewController: AgoraRtcChannelDelegate {
    // Monitors the remoteVideoStateChangedOfUid callback
    func rtcEngine(
        _ rtcChannel: AgoraRtcChannel, remoteVideoStateChangedOfUid uid: UInt,
        state: AgoraVideoRemoteState, reason: AgoraVideoRemoteStateReason, elapsed: Int
    ) {
      	switch state {
          	case .starting:
            		let videoCanvas = AgoraRtcVideoCanvas()
								videoCanvas.uid = uid
								// remoteView is any UIView to show the video feed on
                videoCanvas.view = remoteView
            		// Specify the channelId of the remote user
  							videoCanvas.channelId = rtcChannel.getId()
                // Set the remote video view
                self.agkit.setupRemoteVideo(videoCanvas)
						default: break
        }
    }
}
```

The main difference in the above snippet is that we are using an extra property of AgoraRtcVideoCanvas, `channelId`. At the point of telling the engine to setup the remote video, the engine is aware of what channel it needs to do so for - rather than the channel that has been joined directly, without first creating a channel object.

In our example, we are going to utilise another class from AgoraUIKit_iOS to display the video feeds; this class is [AgoraSingleVideoView](https://agoraio-community.github.io/iOS-UIKit/Classes/AgoraSingleVideoView.html). AgoraSingleVideoView can be useful for quickly displaying a remote user's state with a basic design, see the [documentation here](https://agoraio-community.github.io/iOS-UIKit/Classes/AgoraSingleVideoView.html).

To create AgoraSingleVideoView we will add a method to our ViewController called getOrCreateUserVideo, which also keeps a record of the created video views in a dictionary `remoteUsersRHS`:

```swift
extension ViewController: AgoraRtcChannelDelegate {
    func getOrCreateUserVideo(
    		_ rtcChannel: AgoraRtcChannel, with userId: UInt
    ) -> AgoraSingleVideoView {
        if let remoteView = self.remoteUsersRHS[userId] {
            return remoteView
        }
        let remoteVideoView = AgoraSingleVideoView(uid: userId, micColor: .systemBlue)
        remoteVideoView.canvas.channelId = rtcChannel.getId()

        self.agkit.setupRemoteVideo(remoteVideoView.canvas)
        self.remoteUsersRHS[userId] = remoteVideoView
        return remoteVideoView
    }
}
```

remoteUsersRHS here is declared in ViewController with the type: `[UInt: AgoraSingleVideoView]`.

We now only need to add three methods from the `AgoraRtcChannelDelegate`; `remoteVideoStateChangedOfUid` for checking when the video state changes, `remoteAudioStateChangedOfUid` for audio state changes, and `didOfflineOfUid` for removing a view when a remote user leave:

```swift
extension ViewController: AgoraRtcChannelDelegate {
    public func rtcChannel(
        _ rtcChannel: AgoraRtcChannel,
        remoteVideoStateChangedOfUid uid: UInt,
        state: AgoraVideoRemoteState,
        reason: AgoraVideoRemoteStateReason,
        elapsed: Int
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
            getOrCreateUserVideo(
                rtcChannel, with: uid
            ).audioMuted = state == .stopped
        }
    }

    func rtcChannel(
        _ rtcChannel: AgoraRtcChannel,
        didOfflineOfUid uid: UInt,
        reason: AgoraUserOfflineReason
    ) {
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
```

Now that we are creating AgoraSingleVideoView objects for each streaming member of the channel, we need to display them within the ViewForm videosHolder.

The positioning will need to be updated each time a new member is added or removed from `remoteUsersRHS`, one way to do that is to add a `didSet` to that variable. The declaration of `remoteUsersRHS` inside the ViewController will now look like this:

```swift
/// Dictionary of User ID to AgoraSingleVideo Views
var remoteUsersRHS: [UInt: AgoraSingleVideoView] = [:] {
    didSet { self.setVideoPositions() }
}
```

And the functionality of setVideoPositions adds all the remote users in a grid formation, similar to AgoraVideoViewer - except this time we must write out the functionality ourselves.

```swift
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
```

Now you are receiving sound and video from both channels, as well as streaming yourself into the channel connected on the left:

![img](https://cdn-images-1.medium.com/max/1200/1*kTAIrdxovKmT8ft2jbisow.jpeg)

## Leaving the Channels

As well as joining, we must also add functionality to leave the channels.

Whenever leaving channels, we should do several things, including removing all the remote video streams from the view, otherwise they may get stuck displaying the last frame before leaving.

In this case, AgoraVideoViewer handles the views to gracefully leave a channel, but with the manually connected to secondary channel we will do those things ourselves.

We call `.leave()` and `.destroy()` on the AgoraRtcChannel instance. Then set each canvas’ view to nil, remove the views from their parents, and clear the `remoteUsersRHS` dictionary.

```swift
extension ViewController {
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

        // Change button back to "Join"
        self.joinedChannels = false
        self.submitButton.setTitle("Join", for: .normal)
    }
}
```

## Summary

Now you have a working example that connects to two channels; both of which receive remote video streams, and one that your camera feed is also streaming into. You could repeat the receiving only channel connection as many times as you wish, to view many channel feeds at the same time.

See the following link for a 

## Other Resources

For more information about building applications using Agora.io SDKs, take a look at the [Agora Video Call Quickstart Guide](https://docs.agora.io/en/Video/start_call_ios?platform=iOS&utm_source=medium&utm_medium=blog&utm_campaign=real-time-messaging-video-dynamic-channels) and [Agora API Reference](https://docs.agora.io/en/Video/API Reference/oc/docs/headers/Agora-Objective-C-API-Overview.html?utm_source=medium&utm_medium=blog&utm_campaign=real-time-messaging-video-dynamic-channels).

I also invite you to [join the Agoira.io Developer Slack community](http://bit.ly/2IWexJQ).

