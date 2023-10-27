//
//  MusicPlayerViewModel.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 12.08.22.
//

import Foundation
import MediaPlayer

@MainActor
class MusicPlayerViewModel: NSObject, ObservableObject {
	@Published private(set) var data: Data = .init(count: 0)
	@Published private(set) var title = ""
	@Published              var percentProgress: CGFloat = 0
	@Published private(set) var timeMisingToPlay: String = ""
	@Published private(set) var isPlaying = false
	@Published private(set) var isFinished = false
	@Published              var percentVolume: CGFloat = 0
	@Published private(set) var audioSessionOutputs: String = ""

	private(set) var songs: [String]

	private let audioSession = AVAudioSession.sharedInstance()
	@Published private var indexCurrentSong = 0
	@Published private var player: AVAudioPlayer!
	private var masterVolumeSlider: UISlider!
	private var notificationCenter = NotificationCenter.default

	init(_ songs: [String]) {
		self.songs = songs
		super.init()

		let masterVolumeView = MPVolumeView()
		masterVolumeSlider = masterVolumeView.subviews.compactMap({ $0 as? UISlider }).first

		setupRemoteTransportControls()
	}

	func onAppear() {
		do {
			try audioSession.setCategory(.playback)
		} catch {
			print("Setting category to AVAudioSessionCategoryPlayback failed.")
		}

		let url = Bundle.main.path(forResource: self.songs[self.indexCurrentSong], ofType: "mp3")
// swiftlint:disable force_try
		self.player = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: url!))
// swiftlint:enable force_try
		self.player.delegate = self
		// self.player.prepareToPlay() // Removed because it stops other audio playing from other apps
		self.getArtworkAndTitle()
		Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
			Task.detached(priority: .background) {
				await MainActor.run {
					if self.player.isPlaying {
						self.percentProgress = self.player.currentTime / self.player.duration
					}
				}
			}
		}

		let masterVolumeView = MPVolumeView()
		masterVolumeSlider = masterVolumeView.subviews.compactMap({ $0 as? UISlider }).first
		self.percentVolume = CGFloat(audioSession.outputVolume)

		notificationCenter.addObserver(self,
									   selector: #selector(systemVolumeDidChange),
									   name: Notification.Name("SystemVolumeDidChange"),
									   object: nil
		)

		updateOutputDevices()

		notificationCenter.addObserver(self,
									   selector: #selector(audioSessionRouteChanged),
									   name: AVAudioSession.routeChangeNotification,
									   object: audioSession)
	}

	func onDisappear() {
		notificationCenter.removeObserver(self, name: Notification.Name("SystemVolumeDidChange"), object: nil)
		notificationCenter.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: audioSession)
	}

	var playerCurrentTime: Double {
		get { return self.player.currentTime }
		set {
			guard newValue >= 0 && newValue <= self.player.duration else {
				return
			}

			self.player.currentTime = newValue
			self.percentProgress = self.player.currentTime / self.player.duration
			self.updateNowPlaying()
		}
	}
	var playerDuration: Double {
		self.player.duration
	}
	var playerCurrentTimeStr: String {
		if self.player == nil {
			return ""
		}
		let formatter = DateComponentsFormatter()
		formatter.zeroFormattingBehavior = .pad
		formatter.allowedUnits = [.minute, .second]
		return formatter.string(from: self.player.currentTime) ?? ""
	}
	var playerMissingTimeStr: String {
		if self.player == nil {
			return ""
		}
		let formatter = DateComponentsFormatter()
		formatter.zeroFormattingBehavior = .pad
		formatter.allowedUnits = [.minute, .second]
		let tmpResult = formatter.string(from: self.player.duration - self.player.currentTime)
		if tmpResult == nil {
			return ""
		} else {
			return "-" + tmpResult!
		}
	}

	func skipBackward() {
		self.playerCurrentTime = max(0, self.playerCurrentTime - 15)
	}
	func skipForward() {
		self.playerCurrentTime = min(self.playerDuration, self.playerCurrentTime + 30)
	}

	func decrementSong() {
		if self.indexCurrentSong > 0 {
			self.indexCurrentSong -= 1
			self.changeCurrentSong()
		}
	}
	func incrementSong() {
		if self.indexCurrentSong != self.songs.count - 1 {
			self.indexCurrentSong += 1
			self.changeCurrentSong()
		}
	}

	func playOrPause() {
		if self.player.isPlaying {
			self.player.pause()
			self.isPlaying = false
		} else {
			if self.isFinished {
				self.player.currentTime = 0
				self.percentProgress = 0
				self.isFinished = false
			}

			do {
				try audioSession.setActive(true)
			} catch {
				print("error")
			}

			self.player.prepareToPlay()
			self.player.play()
			self.isPlaying = true
		}
	}

	private func getArtworkAndTitle() {
		self.data = .init(count: 0)
		self.title = "???"

		let asset = AVAsset(url: self.player.url!)

		for i in asset.commonMetadata {
			if i.commonKey?.rawValue == "artwork" {
				if let iValue = i.value as? Data {
					let data = iValue
					self.data = data
				}
			}
			if i.commonKey?.rawValue == "title" {
				if let iValue = i.value as? String {
					let title = iValue
					self.title = title
				}
			}
		}

		self.updateNowPlaying()
	}

	public var audioVolume: Double {
		get {
			return Double(masterVolumeSlider.value)
		}
		set {
			percentVolume = newValue
			masterVolumeSlider.value = Float(newValue)
		}
	}

	@objc func systemVolumeDidChange(notification: NSNotification) {
		guard let userInfo = notification.userInfo,
			  let percVolume = userInfo["Volume"] as? Float else {
			return
		}

		Task.detached(priority: .background) {
			await MainActor.run {
				self.percentVolume = Double(percVolume)
			}
		}
	}

	func increaseVolume() {
		self.audioVolume = min(self.audioVolume + 0.1, 1)
	}
	func decreaseVolume() {
		self.audioVolume = max(self.audioVolume - 0.1, 0)
	}

	private func changeCurrentSong() {
		let url = Bundle.main.path(forResource: self.songs[self.indexCurrentSong], ofType: "mp3")
// swiftlint:disable force_try
		self.player = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: url!))
// swiftlint:enable force_try
		self.player.delegate = self
		// self.player.prepareToPlay() // Removed because it stops other audio playing from other apps
		self.getArtworkAndTitle()
		self.percentProgress = 0

		if self.isPlaying {
			do {
				try audioSession.setActive(true)
			} catch {
				print("error")
			}

			self.player.prepareToPlay()
			self.player.play()
		}
	}

	// From: https://developer.apple.com/documentation/avfoundation/media_playback/creating_a_basic_video_player_ios_and_tvos/controlling_background_audio
	private func setupRemoteTransportControls() {
		// Get the shared MPRemoteCommandCenter
		let commandCenter = MPRemoteCommandCenter.shared()

		commandCenter.playCommand.addTarget { [unowned self] _ in
			if !self.isPlaying {
				self.player.play()
				self.isPlaying = true
				return .success
			}
			return .commandFailed
		}

		commandCenter.pauseCommand.addTarget { [unowned self] _ in
			if self.isPlaying {
				self.player.pause()
				self.isPlaying = false
				return .success
			}
			return .commandFailed
		}

		commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
		commandCenter.skipBackwardCommand.addTarget { [unowned self] _ in
			self.skipBackward()
			return .success
		}

		commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 30)]
		commandCenter.skipForwardCommand.addTarget { [unowned self] _ in
			self.skipForward()
			return .success
		}

		commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
			if let event = event as? MPChangePlaybackPositionCommandEvent {
				self.player.currentTime = event.positionTime
				return .success
			}
			return .commandFailed
		}
	}

	// From: https://developer.apple.com/documentation/avfoundation/media_playback/creating_a_basic_video_player_ios_and_tvos/controlling_background_audio
	private func updateNowPlaying() {
		// Define Now Playing Info
		var nowPlayingInfo = [String: Any]()
		nowPlayingInfo[MPMediaItemPropertyTitle] = self.title
		nowPlayingInfo[MPMediaItemPropertyMediaType] = MPMediaType.anyAudio.rawValue

		let image = UIImage(data: self.data)!
		nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
			return image
		}

		nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime
		nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: self.player.duration)
		nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate
		nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: self.player.currentTime)

		// Set the metadata
		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
	}

	private func updateOutputDevices() {
		let availableOutputs = audioSession.currentRoute.outputs
		let firstOutput = availableOutputs.first
		let otherOutputs = availableOutputs.dropFirst()
		audioSessionOutputs = otherOutputs.map(\.portName).reduce(firstOutput?.portName, { ( $0 ?? "" ) + ", " + $1 }) ?? ""
	}

	@objc func audioSessionRouteChanged(notification: Notification) {
		updateOutputDevices()
	}
}

extension MusicPlayerViewModel: AVAudioPlayerDelegate {
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		self.isPlaying = false
		self.isFinished = true
	}

	func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
		self.isPlaying = false
	}
}
