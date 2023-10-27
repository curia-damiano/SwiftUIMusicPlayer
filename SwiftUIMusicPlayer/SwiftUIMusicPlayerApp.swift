//
//  SwiftUIMusicPlayerApp.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 12.08.22.
//

import SwiftUI
import AVKit

@main
struct SwiftUIMusicPlayerApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}

// From: https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-an-appdelegate-to-a-swiftui-app
class AppDelegate: NSObject, UIApplicationDelegate {
	private var backgroundCompletionHandler: (() -> Void)? = nil

	func application(_ application: UIApplication,
					 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let audioSession = AVAudioSession.sharedInstance()
		do {
			try audioSession.setCategory(.playback)
		} catch {
			print("Setting category to AVAudioSessionCategoryPlayback failed.")
		}

		return true
	}
}
