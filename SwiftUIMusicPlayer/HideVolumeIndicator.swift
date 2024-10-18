//
//  HideVolumeIndicator.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 09.10.2024.
//

import SwiftUI
import MediaPlayer

#if os(iOS) || os(visionOS)
struct HideVolumeIndicator: UIViewRepresentable {
	func makeUIView(context: Context) -> MPVolumeView {
		let result = MPVolumeView(frame: .zero)
		result.alpha = 0.001
		return result
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {
	}
}

#Preview {
    HideVolumeIndicator()
}
#else // if os(macOS)
#endif
