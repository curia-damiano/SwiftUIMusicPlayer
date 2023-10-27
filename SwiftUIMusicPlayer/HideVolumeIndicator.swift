//
//  HideVolumeIndicator.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 16.01.23.
//

import SwiftUI
import MediaPlayer

struct HideVolumeIndicator: UIViewRepresentable {
	func makeUIView(context: Context) -> MPVolumeView {
		let result = MPVolumeView(frame: .zero)
		result.alpha = 0.001
		return result
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {
	}
}

struct HideVolumeIndicator_Previews: PreviewProvider {
	static var previews: some View {
		HideVolumeIndicator()
	}
}
