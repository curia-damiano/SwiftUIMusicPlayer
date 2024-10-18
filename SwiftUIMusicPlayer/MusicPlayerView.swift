//
//  MusicPlayerView.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 09.10.2024.
//

import SwiftUI

struct MusicPlayerView: View {
	@ObservedObject var vm: MusicPlayerViewModel

	var body: some View {
		GeometryReader { geometry in
			if geometry.size.height > geometry.size.width {
				// Portrait view
				VStack(spacing: 20) {
					HStack {
						Spacer()
						AlbumArtworkView(vm: vm, geometry: geometry)
						Spacer()
					}
					Spacer()

					ControlsInMusicPlayerView(vm: vm)
				}
			} else {
				// Landscape view
				HStack {
					VStack {
						Spacer()
						AlbumArtworkView(vm: vm, geometry: geometry)
						Spacer()
					}
					Spacer()

					ControlsInMusicPlayerView(vm: vm)
						.padding(.leading)
				}
			}
		}
		.padding(20)
		.task {
			await vm.onAppear()
		}
		.onDisappear {
			vm.onDisappear()
		}
	}
}

struct AlbumArtworkView: View {
	@ObservedObject var vm: MusicPlayerViewModel
	@State var geometry: GeometryProxy

	var frameSize: Double {
		if geometry.size.height > geometry.size.width {
			return geometry.size.width * 0.8
		} else {
			return geometry.size.height * 0.8
		}
	}

	var body: some View {
#if os(iOS) || os(visionOS)
		Image(uiImage: vm.data.count == 0 ? UIImage(systemName: "hourglass")! : UIImage(data: vm.data)!)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.cornerRadius(15)
			.frame(width: frameSize, height: frameSize)
#else // if os(macOS)
		Image(nsImage: vm.data.count == 0 ? NSImage(systemSymbolName: "hourglass", accessibilityDescription: nil)! : NSImage(data: vm.data)!)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.cornerRadius(15)
			.frame(width: frameSize, height: frameSize)
#endif
	}
}

struct ControlsInMusicPlayerView: View {
	@ObservedObject var vm: MusicPlayerViewModel

	var body: some View {
		GeometryReader { geometry in
			VStack {
				Group {
					Text(vm.title)
						.font(.title)
					Spacer()
				}

				Group {
					ZStack(alignment: .leading) {
						Capsule()
							.fill(Color.black.opacity(0.08))
							.frame(height: 8)
							.padding([.leading, .trailing], 20)
						Capsule()
							.fill(Color.red)
							.frame(width: vm.percentProgress * (geometry.size.width - 40), height: 8)
							.padding([.leading, .trailing], 20)
						Circle()
							.fill(Color.red)
							.frame(width: 18, height: 18)
							.padding(.leading, 20 + vm.percentProgress * (geometry.size.width - 40))
					}
					.gesture(DragGesture()
						.onChanged({ (value) in
							let x = value.location.x
							vm.percentProgress = max(min(x / geometry.size.width, 1), 0)
						}).onEnded({ (value) in
							let x = value.location.x
							let percent = max(min(x / geometry.size.width, 1), 0)
							vm.playerCurrentTime = Double(percent) * vm.playerDuration
						}))
					.frame(height: 20)

					HStack {
						Text(vm.playerCurrentTimeStr)
						Spacer()
						Text(vm.playerMissingTimeStr)
					}
					Spacer()
				}

				Group {
					HStack(spacing: geometry.size.width / 5 - 30) {
						Button(action: {
							Task {
								await vm.decrementSong()
							}
						}, label: {
							Image(systemName: "backward.fill").font(.title).foregroundColor(.primary)
						})
						Button(action: {
							vm.skipBackward()
						}, label: {
							Image(systemName: "gobackward.15").font(.title).foregroundColor(.primary)
						})
						Button(action: {
							vm.playOrPause()
						}, label: {
							Image(systemName: vm.isPlaying && !vm.isFinished ? "pause.fill" : "play.fill").font(.title).foregroundColor(.primary)
						})
						Button(action: {
							vm.skipForward()
						}, label: {
							Image(systemName: "goforward.30").font(.title).foregroundColor(.primary)
						})
						Button(action: {
							Task {
								await vm.incrementSong()
							}
						}, label: {
							Image(systemName: "forward.fill").font(.title).foregroundColor(.primary)
						})
					}
					Spacer()
				}

#if os(iOS) || os(visionOS)
				Group {
					HStack(alignment: .center, spacing: geometry.size.width / 9 - 30) {
						Button(action: {
							vm.decreaseVolume()
						}, label: {
							Image("volume_down")
								.resizable()
								.frame(width: 36, height: 36)
						})
						GeometryReader { metrics in
							ZStack(alignment: .leading) {
								Capsule()
									.fill(Color.black.opacity(0.08))
									.frame(height: 8)
								Capsule()
									.fill(Color.red)
									.frame(width: vm.percentVolume * metrics.size.width, height: 8)
								Circle()
									.fill(Color.red)
									.frame(width: 18, height: 18)
									.padding(.leading, vm.percentVolume * metrics.size.width - 9)
							}
							.gesture(DragGesture()
								.onChanged({ (value) in
									let x = value.location.x
									vm.percentVolume = max(min(x / metrics.size.width, 1), 0)
								}).onEnded({ (value) in
									let x = value.location.x
									// let screen = UIScreen.main.bounds.width - 40
									// let percent = x / screen
									let percent = max(min(x / metrics.size.width, 1), 0)
									vm.audioVolume = Double(percent)
								}))
						}
						.frame(height: 20)
						.padding(.trailing, 10)

						Button(action: {
							vm.increaseVolume()
						}, label: {
							Image("volume_up")
								.resizable()
								.frame(width: 36, height: 36)
						})
					}
					Spacer()
				}
#else // if os(macOS)
#endif

				Group {
#if os(iOS) || os(visionOS)
					// We need a MPVolumeView to hide the iOS volume indicator. We keep it, but hidden
					HideVolumeIndicator()
						.frame(width: 0, height: 0)
#else // if os(macOS)
#endif

					HStack(alignment: .center) {
						Text(vm.audioSessionOutputs)

						AirPlayButton()
							.frame(width: 60, height: 60)
					}
					Spacer()
				}
			}
		}
	}
}

#Preview {
	NavigationStack {
		Spacer()

		MusicPlayerView(vm: MusicPlayerViewModel(["tagmp3_sample1", "tagmp3_sample2", "tagmp3_sample3", "tagmp3_sample4"]))
		Spacer()
	}
}
