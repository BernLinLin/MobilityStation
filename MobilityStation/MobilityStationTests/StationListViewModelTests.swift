import Foundation
import Testing
@testable import MobilityStation

@MainActor
struct StationListViewModelTests {
    @Test func visibleStationsSearchesByNameAddressAndCity() async throws {
        let viewModel = StationListViewModel(
            stationStore: StationStore(stations: []),
            stationService: SuccessfulStationService(stations: Self.sampleStations)
        )

        await viewModel.refresh()
        viewModel.searchText = "opera"

        #expect(viewModel.visibleStations.map(\.name) == ["Opera Station"])

        viewModel.searchText = "river"
        #expect(viewModel.visibleStations.map(\.name) == ["River Dock"])

        viewModel.searchText = "lyon"
        #expect(viewModel.visibleStations.map(\.name) == ["Lyon Hub"])
    }

    @Test func visibleStationsSortsByAvailabilityNameEmptyDocksAndElectricBikes() async throws {
        let viewModel = StationListViewModel(
            stationStore: StationStore(stations: []),
            stationService: SuccessfulStationService(stations: Self.sampleStations)
        )

        await viewModel.refresh()

        viewModel.sortOption = .availability
        #expect(viewModel.visibleStations.map(\.name) == ["River Dock", "Opera Station", "Lyon Hub"])

        viewModel.sortOption = .name
        #expect(viewModel.visibleStations.map(\.name) == ["Lyon Hub", "Opera Station", "River Dock"])

        viewModel.sortOption = .emptyDocks
        #expect(viewModel.visibleStations.map(\.name) == ["Lyon Hub", "Opera Station", "River Dock"])

        viewModel.sortOption = .electricBikes
        #expect(viewModel.visibleStations.map(\.name) == ["Lyon Hub", "River Dock", "Opera Station"])
    }

    @Test func visibleStationsFiltersFavorites() async throws {
        let viewModel = StationListViewModel(
            stationStore: StationStore(stations: []),
            stationService: SuccessfulStationService(stations: Self.sampleStations)
        )

        await viewModel.refresh()
        viewModel.toggleFavorite(Self.operaID)
        viewModel.filter = .favorites

        #expect(viewModel.visibleStations.map(\.id) == [Self.operaID])
    }

    @Test func toggleFavoritePersistsInStationStore() async throws {
        let store = StationStore(stations: Self.sampleStations)
        let viewModel = StationListViewModel(
            stationStore: store,
            stationService: SuccessfulStationService(stations: Self.sampleStations)
        )

        await viewModel.refresh()
        viewModel.toggleFavorite(Self.riverID)

        var didPersistFavorite = false
        for _ in 0..<20 {
            let cachedStations = try await store.loadCachedStations()
            let cachedRiver = try #require(cachedStations.first { $0.id == Self.riverID })
            if cachedRiver.isBookmarked {
                didPersistFavorite = true
                break
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(didPersistFavorite)
    }

    @Test func networkFailureUsesCacheBeforeFallback() async throws {
        let store = StationStore(
            stations: [Self.cachedStation],
            fallbackData: Self.fallbackResponseData
        )
        let viewModel = StationListViewModel(
            stationStore: store,
            stationService: FailingStationService()
        )

        await viewModel.refresh()

        #expect(viewModel.visibleStations.map(\.name) == ["Cached Station"])
        #expect(viewModel.errorMessage == nil)
    }

    @Test func offlineLoadUsesFallbackJSONWhenNetworkFailsAndCacheIsEmpty() async throws {
        let viewModel = StationListViewModel(
            stationStore: StationStore(stations: [], fallbackData: Self.fallbackResponseData),
            stationService: FailingStationService()
        )

        await viewModel.refresh()

        let station = try #require(viewModel.visibleStations.first)
        #expect(viewModel.visibleStations.count == 1)
        #expect(station.name == "Fallback Central")
        #expect(station.networkName == "Fallback Network")
        #expect(station.city == "Paris")
        #expect(station.availableBikes == 7)
        #expect(station.emptySlots == 13)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func stationStoreDecodesCityBikeFallbackResponse() async throws {
        let store = StationStore(stations: [], fallbackData: Self.fallbackResponseData)

        let stations = try await store.loadFallbackStations()

        let station = try #require(stations.first)
        #expect(stations.count == 1)
        #expect(station.name == "Fallback Central")
        #expect(station.networkName == "Fallback Network")
        #expect(station.city == "Paris")
        #expect(station.normalBikes == 4)
        #expect(station.electricBikes == 3)
        #expect(station.acceptsBankCards)
        #expect(station.hasPaymentTerminal)
    }
}

private struct SuccessfulStationService: StationServiceProtocol {
    let stations: [Station]

    func requestStations() async throws -> [StationViewModel] {
        stations.map(StationViewModel.init)
    }
}

private struct FailingStationService: StationServiceProtocol {
    func requestStations() async throws -> [StationViewModel] {
        throw AppError.transportError(URLError(.notConnectedToInternet))
    }
}

private extension StationListViewModelTests {
    static let operaID = 2001
    static let riverID = 2002
    static let lyonID = 2003

    static var sampleStations: [Station] {
        [
            Station(
                id: operaID,
                stationIdentifier: "opera",
                name: "Opera Station",
                networkName: "Test Network",
                city: "Paris",
                latitude: 48.8719,
                longitude: 2.3316,
                availableBikes: 6,
                emptySlots: 12,
                totalDocks: 18,
                isInstalled: true,
                isRenting: true,
                isReturning: true,
                lastUpdated: "2026-05-20T10:00:00Z",
                address: "Place de l'Opera",
                normalBikes: 5,
                electricBikes: 1
            ),
            Station(
                id: riverID,
                stationIdentifier: "river",
                name: "River Dock",
                networkName: "Test Network",
                city: "Paris",
                latitude: 48.8584,
                longitude: 2.2945,
                availableBikes: 10,
                emptySlots: 2,
                totalDocks: 12,
                isInstalled: true,
                isRenting: true,
                isReturning: true,
                lastUpdated: "2026-05-20T10:01:00Z",
                address: "River Walk",
                normalBikes: 8,
                electricBikes: 2
            ),
            Station(
                id: lyonID,
                stationIdentifier: "lyon",
                name: "Lyon Hub",
                networkName: "Test Network",
                city: "Lyon",
                latitude: 45.7640,
                longitude: 4.8357,
                availableBikes: 1,
                emptySlots: 20,
                totalDocks: 21,
                isInstalled: true,
                isRenting: true,
                isReturning: true,
                lastUpdated: "2026-05-20T10:02:00Z",
                address: "Central Plaza",
                normalBikes: 0,
                electricBikes: 4
            )
        ]
    }

    static var cachedStation: Station {
        Station(
            id: 3001,
            stationIdentifier: "cached",
            name: "Cached Station",
            networkName: "Cached Network",
            city: "Paris",
            latitude: 48.85,
            longitude: 2.35,
            availableBikes: 3,
            emptySlots: 6,
            totalDocks: 9,
            isInstalled: true,
            isRenting: true,
            isReturning: true,
            lastUpdated: "2026-05-20T09:00:00Z",
            address: "Cached Street"
        )
    }

    static let fallbackResponseData = Data(
        """
        {
          "network": {
            "id": "fallback-network",
            "name": "Fallback Network",
            "location": {
              "latitude": 48.856614,
              "longitude": 2.3522219,
              "city": "Paris",
              "country": "FR"
            },
            "stations": [
              {
                "id": "fallback-central",
                "name": "Fallback Central",
                "latitude": 48.856614,
                "longitude": 2.3522219,
                "timestamp": "2026-05-20T13:39:38Z",
                "free_bikes": 7,
                "empty_slots": 13,
                "extra": {
                  "uid": "fallback-1",
                  "renting": 1,
                  "returning": 1,
                  "slots": 20,
                  "normal_bikes": 4,
                  "ebikes": 3,
                  "banking": true,
                  "payment-terminal": true,
                  "payment": ["creditcard"]
                }
              }
            ]
          }
        }
        """.utf8
    )
}
