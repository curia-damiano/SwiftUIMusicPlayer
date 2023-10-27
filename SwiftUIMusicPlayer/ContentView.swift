//
//  ContentView.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 12.08.22.
//

import SwiftUI

struct ContentView: View {
	var body: some View {
		NavigationView {
			MusicPlayerView(vm: MusicPlayerViewModel(["tagmp3_sample1", "tagmp3_sample2", "tagmp3_sample3", "tagmp3_sample4"]))
				.navigationTitle("SwiftUI Music Player")
		}
		.navigationViewStyle(.stack)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
