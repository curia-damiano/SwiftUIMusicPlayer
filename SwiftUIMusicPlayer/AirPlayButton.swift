//
//  AirplayButton.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 19.04.23.
//

import SwiftUI
import AVKit

struct AirPlayButton: UIViewRepresentable {
	func makeUIView(context: Context) -> AVRoutePickerView {
		let result = AVRoutePickerView(frame: .zero)

		// Configure the button's color.
		// result.delegate = context.coordinator
		// result.backgroundColor = UIColor.white
		result.tintColor = UIColor.label

		// Indicate whether your app prefers video content.
		result.prioritizesVideoDevices = false

		return result
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {

	}
}

struct AirPlayButton_Previews: PreviewProvider {
	static var previews: some View {
		AirPlayButton()
	}
}
