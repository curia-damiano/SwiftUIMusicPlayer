//
//  ContentView.swift
//  SwiftUIMusicPlayer
//
//  Created by Damiano Curia on 09.10.2024.
//

import SwiftUI

struct ContentView: View {
	var body: some View {
		NavigationStack {
			Spacer()

			MusicPlayerView(vm: MusicPlayerViewModel(["tagmp3_sample1", "tagmp3_sample2", "tagmp3_sample3", "tagmp3_sample4"]))
			Spacer()
		}
	}
}

#Preview {
	ContentView()
}
