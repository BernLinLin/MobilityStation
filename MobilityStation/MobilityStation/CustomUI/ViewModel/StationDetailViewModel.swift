//
//  StationDetailViewModel.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import Combine
import Foundation
import SwiftUI

@MainActor
protocol StationDetailViewModelProtocol: ObservableObject {
    var station: StationViewModelProtocol { get }
    var isFavorite: Bool { get }
    func toggleFavorite()
}

@MainActor
final class StationDetailViewModel: ObservableObject {
    let station: StationViewModelProtocol
    private let stationStore: StationStore
    private let onToggleFavorite: (() -> Void)?

    @Published var isFavorite: Bool

    init(
        station: StationViewModelProtocol,
        stationStore: StationStore = StationStore(),
        onToggleFavorite: (() -> Void)? = nil
    ) {
        self.station = station
        self.stationStore = stationStore
        self.onToggleFavorite = onToggleFavorite
        self.isFavorite = station.isBookmarked
    }
}

extension StationDetailViewModel: StationDetailViewModelProtocol {
    func toggleFavorite() {
        if let onToggleFavorite {
            onToggleFavorite()
            isFavorite = station.station.isBookmarked
            return
        }

        station.station.isBookmarked.toggle()
        isFavorite = station.station.isBookmarked

        Task {
            await stationStore.setFavorite(
                station.station.isBookmarked,
                for: station.id
            )
        }
    }
}
