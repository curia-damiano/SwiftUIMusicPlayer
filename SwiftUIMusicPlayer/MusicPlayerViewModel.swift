//
//  MusicPlayerViewModel.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 09.10.2024.
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

#if os(iOS) || os(visionOS)
	private let audioSession = AVAudioSession.sharedInstance()
#else // if os(macOS)
#endif
	@Published private var indexCurrentSong = 0
	@Published private var player: AVAudioPlayer!
#if os(iOS) || os(visionOS)
	private var masterVolumeSlider: UISlider!
#else // if os(macOS)
#endif
	private var notificationCenter = NotificationCenter.default

	init(_ songs: [String]) {
		self.songs = songs
		super.init()

#if os(iOS) || os(visionOS)
		let masterVolumeView = MPVolumeView()
		masterVolumeSlider = masterVolumeView.subviews.compactMap({ $0 as? UISlider }).first
#else // if os(macOS)
#endif

		setupRemoteTransportControls()
	}

	func onAppear() async {
		do {
#if os(iOS) || os(visionOS)
			try audioSession.setCategory(.playback)
#else // if os(macOS)
#endif
		} catch {
			print("Setting category to AVAudioSessionCategoryPlayback failed.")
		}

		let url = Bundle.main.path(forResource: self.songs[self.indexCurrentSong], ofType: "mp3")
// swiftlint:disable force_try
		self.player = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: url!))
// swiftlint:enable force_try
		self.player.delegate = self
		// self.player.prepareToPlay() // Removed because it stops other audio playing from other apps
		await self.getArtworkAndTitle()
		Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
			Task.detached(priority: .background) {
				await MainActor.run {
					if self.player.isPlaying {
						self.percentProgress = self.player.currentTime / self.player.duration
					}
				}
			}
		}

#if os(iOS) || os(visionOS)
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
#else // if os(macOS)
#endif
	}

	func onDisappear() {
		notificationCenter.removeObserver(self, name: Notification.Name("SystemVolumeDidChange"), object: nil)
#if os(iOS) || os(visionOS)
		notificationCenter.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: audioSession)
#else // if os(macOS)
#endif
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

	func decrementSong() async {
		if self.indexCurrentSong > 0 {
			self.indexCurrentSong -= 1
			await self.changeCurrentSong()
		}
	}
	func incrementSong() async {
		if self.indexCurrentSong != self.songs.count - 1 {
			self.indexCurrentSong += 1
			await self.changeCurrentSong()
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
#if os(iOS) || os(visionOS)
				try audioSession.setActive(true)
#else // if os(macOS)
#endif
			} catch {
				print("error")
			}

			self.player.prepareToPlay()
			self.player.play()
			self.isPlaying = true
		}
	}

	private func getArtworkAndTitle() async {
		self.data = .init(count: 0)
		self.title = "???"

		let asset = AVAsset(url: self.player.url!)

		do {
			let metadata = try await asset.load(.commonMetadata)

			for i in metadata {
				if i.commonKey?.rawValue == "artwork" {
					if let data = try? await i.load(.value) as? Data {
						self.data = data
					}
				}
				if i.commonKey?.rawValue == "title" {
					if let title = try? await i.load(.value) as? String {
						self.title = title
					}
				}
			}
		} catch {
			print("Failed to load metadata: \(error.localizedDescription)")
		}

		self.updateNowPlaying()
	}

#if os(iOS) || os(visionOS)
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
#else // if os(macOS)
#endif

	private func changeCurrentSong() async {
		let url = Bundle.main.path(forResource: self.songs[self.indexCurrentSong], ofType: "mp3")
// swiftlint:disable force_try
		self.player = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: url!))
// swiftlint:enable force_try
		self.player.delegate = self
		// self.player.prepareToPlay() // Removed because it stops other audio playing from other apps
		await self.getArtworkAndTitle()
		self.percentProgress = 0

		if self.isPlaying {
			do {
#if os(iOS) || os(visionOS)
				try audioSession.setActive(true)
#else // if os(macOS)
#endif
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

#if os(iOS) || os(visionOS)
		let image = UIImage(data: self.data)!
		nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
			return image
		}
#else // if os(macOS)
#endif

		nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime
		nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: self.player.duration)
		nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate
		nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: self.player.currentTime)

		// Set the metadata
		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
	}

#if os(iOS) || os(visionOS)
	private func updateOutputDevices() {
		let availableOutputs = audioSession.currentRoute.outputs
		let firstOutput = availableOutputs.first
		let otherOutputs = availableOutputs.dropFirst()
		audioSessionOutputs = otherOutputs.map(\.portName).reduce(firstOutput?.portName, { ( $0 ?? "" ) + ", " + $1 }) ?? ""
	}

	@objc func audioSessionRouteChanged(notification: Notification) {
		updateOutputDevices()
	}
#else // if os(macOS)
#endif
}

extension MusicPlayerViewModel: AVAudioPlayerDelegate {
	nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		Task { @MainActor in
			self.isPlaying = false
			self.isFinished = true
		}
	}

	nonisolated func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
		Task { @MainActor in self.isPlaying = false }
	}
}
