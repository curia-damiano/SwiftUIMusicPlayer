//
//  AirPlayButton.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 09.10.2024.
//

import SwiftUI
import AVKit

#if os(iOS) || os(visionOS)
struct AirPlayButton: UIViewRepresentable {
#if os(iOS)
	func makeUIView(context: Context) -> AVRoutePickerView {
		let result = AVRoutePickerView(frame: .zero)

		// Configure the button's color.
		result.tintColor = UIColor.label

		// Indicate whether your app prefers video content.
		result.prioritizesVideoDevices = false

		return result
	}

	func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
		// Update the view if needed.
	}
#else // if os(visionOS)
	func makeUIView(context: Context) -> UIView {
		return UIView() // Return an empty view for visionOS or other platforms
	}

	func updateUIView(_ uiView: UIView, context: Context) {
		// No updates needed for visionOS
	}
#endif
}
#else // if os(macOS)
struct AirPlayButton: NSViewRepresentable {
	func makeNSView(context: Context) -> AVRoutePickerView {
		let routePickerView = AVRoutePickerView()
		// routePickerView.activeTintColor = NSColor.systemBlue // Customize the button color
		routePickerView.delegate = context.coordinator // Set delegate if needed
		return routePickerView
	}

	func updateNSView(_ nsView: AVRoutePickerView, context: Context) {
		// Nothing to update for now
	}

	// Coordinator for handling AVRoutePickerView events if needed
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	class Coordinator: NSObject, AVRoutePickerViewDelegate {
		var parent: AirPlayButton

		init(_ parent: AirPlayButton) {
			self.parent = parent
		}

		// You can handle delegate methods if needed
		func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
			print("AirPlay routes are being presented.")
		}
	}
}
#endif

#Preview {
    AirPlayButton()
}
