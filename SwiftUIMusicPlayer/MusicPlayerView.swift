//
//  MusicPlayerView.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 12.08.22.
//

import SwiftUI

struct MusicPlayerView: View {
	@ObservedObject var vm: MusicPlayerViewModel

	var body: some View {
		VStack(spacing: 20) {
			Group {
				Image(uiImage: vm.data.count == 0 ? UIImage(systemName: "hourglass")! : UIImage(data: vm.data)!)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.cornerRadius(15)
				Spacer()
			}

			Group {
				Text(vm.title)
					.font(.title)
				Spacer()
			}

			Group {
				GeometryReader { metrics in
					ZStack(alignment: .leading) {
						Capsule()
							.fill(Color.black.opacity(0.08))
							.frame(height: 8)
						Capsule()
							.fill(Color.red)
							.frame(width: vm.percentProgress * metrics.size.width, height: 8)
						Circle()
							.fill(Color.red)
							.frame(width: 18, height: 18)
							.padding(.leading, vm.percentProgress * metrics.size.width - 9)
					}
					.gesture(DragGesture()
						.onChanged({ (value) in
							let x = value.location.x
							vm.percentProgress = x / metrics.size.width
						}).onEnded({ (value) in
							let x = value.location.x
							let percent = x / metrics.size.width
							vm.playerCurrentTime = Double(percent) * vm.playerDuration
						}))
				}
				.frame(height: 20)

				HStack {
					Text(vm.playerCurrentTimeStr)
					Spacer()
					Text(vm.playerMissingTimeStr)
				}
				Spacer()
			}

			Group {
				HStack(spacing: UIScreen.main.bounds.width / 5 - 30) {
					Button(action: {
						vm.decrementSong()
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
						vm.incrementSong()
					}, label: {
						Image(systemName: "forward.fill").font(.title).foregroundColor(.primary)
					})
				}
				Spacer()
			}

			HStack(alignment: .center, spacing: UIScreen.main.bounds.width / 9 - 30) {
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
							vm.percentVolume = x / metrics.size.width
						}).onEnded({ (value) in
						   let x = value.location.x
						   // let screen = UIScreen.main.bounds.width - 40
						   // let percent = x / screen
						   let percent = x / metrics.size.width
						   vm.audioVolume = Double(percent)
						}))
				}
				.frame(height: 20)
				Button(action: {
					vm.increaseVolume()
				}, label: {
					Image("volume_up")
						.resizable()
						.frame(width: 36, height: 36)
				})
			}

			Group {
				// We need a MPVolumeView to hide the iOS volume indicator. We keep it, but hidden
				HideVolumeIndicator()
					.frame(width: 0, height: 0)

				HStack(alignment: .center) {
					Text(vm.audioSessionOutputs)

					AirPlayButton()
						.frame(width: 60, height: 60)
				}
			}
		}
		.padding()
		.onAppear {
			vm.onAppear()
		}
		.onDisappear {
			vm.onDisappear()
		}
	}
}

struct MusicPlayerView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationView {
			MusicPlayerView(vm: MusicPlayerViewModel(["tagmp3_sample1", "tagmp3_sample2", "tagmp3_sample3", "tagmp3_sample4"]))
				.navigationTitle("SwiftUI Music Player")
		}
		.navigationViewStyle(.stack)
	}
}
