//
//  StationListViewModel.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import Combine
import Foundation
import SwiftUI

enum StationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"

    var id: String { rawValue }
}

enum StationSortOption: String, CaseIterable, Identifiable {
    case availability = "Availability"
    case name = "Name"
    case emptyDocks = "Empty docks"
    case electricBikes = "E-Bikes"

    var id: String { rawValue }

    var title: String {
        switch self {
            case .availability:
                return "Available Bikes"
            case .name:
                return "Name"
            case .emptyDocks:
                return "Empty Slots"
            case .electricBikes:
                return "E-Bikes"
        }
    }
}

@MainActor
protocol StationListViewModelProtocol: ObservableObject {
    var stations: [StationViewModel] { get }
    var visibleStations: [StationViewModel] { get }
    var isLoading: Bool { get }
    var searchText: String { get set }
    var filter: StationFilter { get set }
    var sortOption: StationSortOption { get set }
    var errorMessage: String? { get }
    func loadIfNeeded() async
    func refresh() async
    func toggleFavorite(_ stationID: Int)
    func station(id: Int) -> StationViewModel?
    func clearError()
}

@MainActor
final class StationListViewModel: ObservableObject {
    private let stationService: StationServiceProtocol
    private let stationStore: StationStore

    @Published var stations: [StationViewModel] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filter: StationFilter = .all
    @Published var sortOption: StationSortOption = .availability
    @Published var errorMessage: String?

    init(stationStore: StationStore = StationStore()) {
        self.stationStore = stationStore
        self.stationService = StationService()
    }

    init(
        stationStore: StationStore = StationStore(),
        stationService: StationServiceProtocol
    ) {
        self.stationStore = stationStore
        self.stationService = stationService
    }
}

extension StationListViewModel: StationListViewModelProtocol {
    var visibleStations: [StationViewModel] {
        let searched = stations.filter { station in
            guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
            return station.name.localizedCaseInsensitiveContains(searchText)
                || station.address.localizedCaseInsensitiveContains(searchText)
                || station.city.localizedCaseInsensitiveContains(searchText)
        }

        let filtered = searched.filter { station in
            switch filter {
                case .all: true
                case .favorites: station.isBookmarked
            }
        }

        return filtered.sorted { lhs, rhs in
            switch sortOption {
                case .availability:
                    if lhs.availableBikes == rhs.availableBikes { return lhs.name < rhs.name }
                    return lhs.availableBikes > rhs.availableBikes
                case .name:
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                case .emptyDocks:
                    if lhs.emptySlots == rhs.emptySlots { return lhs.name < rhs.name }
                    return lhs.emptySlots > rhs.emptySlots
                case .electricBikes:
                    if lhs.electricBikes == rhs.electricBikes { return lhs.name < rhs.name }
                    return lhs.electricBikes > rhs.electricBikes
            }
        }
    }

    func loadIfNeeded() async {
        guard stations.isEmpty else { return }
        guard !isLoading else { return }
        stations = await withLoadingState {
            await loadStations()
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        stations = await withLoadingState {
            await loadStations()
        }
    }

    func toggleFavorite(_ stationID: Int) {
        guard let index = stations.firstIndex(where: { $0.id == stationID }) else { return }
        let station = stations[index].station
        station.isBookmarked.toggle()
        stations[index] = StationViewModel(station: station)
        objectWillChange.send()

        Task {
            await stationStore.setFavorite(station.isBookmarked, for: stationID)
        }
    }

    func station(id: Int) -> StationViewModel? {
        stations.first { $0.id == id }
    }

    func clearError() {
        errorMessage = nil
    }
}

private extension StationListViewModel {
    func loadStations() async -> [StationViewModel] {
        do {
            let remoteViewModels = try await stationService.requestStations()
            let remoteStations = remoteViewModels.map { $0.station }
            try await stationStore.saveCache(remoteStations)
            let stationsWithFavorites = await stationStore.applyFavorites(to: remoteStations)
            return stationsWithFavorites.map(StationViewModel.init)
        } catch {
            return await loadOfflineStations(networkError: error)
        }
    }

    func loadOfflineStations(networkError: Error) async -> [StationViewModel] {
        if let cachedStations = try? await stationStore.loadCachedStations(), !cachedStations.isEmpty {
            return cachedStations.map(StationViewModel.init)
        }

        do {
            let fallbackStations = try await stationStore.loadFallbackStations()
            if !fallbackStations.isEmpty {
                return fallbackStations.map(StationViewModel.init)
            }

            errorMessage = AppError.cacheUnavailable.localizedDescription
            return []
        } catch {
            errorMessage = networkError.localizedDescription
            return []
        }
    }

    func withLoadingState<T>(_ operation: () async throws -> T) async rethrows -> T {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        return try await operation()
    }
}
