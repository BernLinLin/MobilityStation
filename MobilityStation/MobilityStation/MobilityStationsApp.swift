//
//  MobilityStationsApp.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import SwiftUI

@main
struct MobilityStationsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - Root view
private struct RootView: View {
    var body: some View {
        StationListView(
            viewModel: StationListViewModel()
        )
    }
}
