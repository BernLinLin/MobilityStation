//
//  StationStore.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/21.
//

import Foundation

actor StationStore {
    private let cacheDataSource: StationCacheDataSource
    private let favoritesStore: FavoritesStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        self.init(
            cacheDataSource: FileStationCacheDataSource(),
            favoritesStore: UserDefaultsFavoritesStore()
        )
    }

    private init(
        cacheDataSource: StationCacheDataSource,
        favoritesStore: FavoritesStore,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.cacheDataSource = cacheDataSource
        self.favoritesStore = favoritesStore
        self.encoder = encoder
        self.decoder = decoder
    }

    init(stations: [Station], favoriteIDs: Set<Int> = [], fallbackData: Data? = nil) {
        let snapshots = stations.map(StationSnapshot.init)
        let cachedData = stations.isEmpty ? nil : try? JSONEncoder().encode(snapshots)
        let cacheDataSource = InMemoryStationCacheDataSource(
            data: cachedData,
            fallbackData: fallbackData
        )
        let favoritesStore = InMemoryFavoritesStore(ids: favoriteIDs)

        self.init(
            cacheDataSource: cacheDataSource,
            favoritesStore: favoritesStore
        )
    }

    func saveCache(_ stations: [Station]) throws {
        let snapshots = stations
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map(StationSnapshot.init)
        let data = try encoder.encode(snapshots)
        try cacheDataSource.save(data)
    }

    func loadCachedStations() throws -> [Station] {
        guard let data = try cacheDataSource.loadCachedData() else {
            return []
        }

        return try decodeStations(from: data)
    }

    func loadFallbackStations() throws -> [Station] {
        let data = try cacheDataSource.loadFallbackData()
        return try decodeFallbackStations(from: data)
    }

    func setFavorite(_ isBookmarked: Bool, for stationID: Int) {
        favoritesStore.setFavorite(isBookmarked, for: stationID)
    }

    func applyFavorites(to stations: [Station]) -> [Station] {
        let favoriteIDs = favoritesStore.favoriteIDs()
        stations.forEach { station in
            station.isBookmarked = favoriteIDs.contains(station.id)
        }
        return stations
    }
}

private extension StationStore {
    func decodeStations(from data: Data) throws -> [Station] {
        let favoriteIDs = favoritesStore.favoriteIDs()
        return try decoder.decode([StationSnapshot].self, from: data)
            .map { snapshot in
                let station = snapshot.station()
                station.isBookmarked = favoriteIDs.contains(station.id)
                return station
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func decodeFallbackStations(from data: Data) throws -> [Station] {
        if let snapshotStations = try? decodeStations(from: data) {
            return snapshotStations
        }

        let response = try decoder.decode(CityBikeNetworkResponse.self, from: data)
        let favoriteIDs = favoritesStore.favoriteIDs()
        return response.network.stations
            .map { station in
                station.networkName = response.network.name
                station.city = response.network.location.city
                station.isBookmarked = favoriteIDs.contains(station.id)
                return station
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

private protocol StationCacheDataSource {
    func save(_ data: Data) throws
    func loadCachedData() throws -> Data?
    func loadFallbackData() throws -> Data
}

private final class FileStationCacheDataSource: StationCacheDataSource {
    private let cacheURL: URL
    private let fallbackFileName: String
    private let bundle: Bundle

    init(
        cacheURL: URL = FileStationCacheDataSource.defaultCacheURL,
        fallbackFileName: String = "stations_fallback",
        bundle: Bundle = .main
    ) {
        self.cacheURL = cacheURL
        self.fallbackFileName = fallbackFileName
        self.bundle = bundle
    }

    func save(_ data: Data) throws {
        try FileManager.default.createDirectory(
            at: cacheURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: cacheURL, options: [.atomic])
    }

    func loadCachedData() throws -> Data? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return nil
        }

        return try Data(contentsOf: cacheURL)
    }

    func loadFallbackData() throws -> Data {
        if let url = bundle.url(forResource: fallbackFileName, withExtension: "json") {
            return try Data(contentsOf: url)
        }

        let sourceFileURL = URL(fileURLWithPath: #filePath)
        let sourceCandidates = [
            sourceFileURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources")
                .appendingPathComponent("\(fallbackFileName).json"),
            sourceFileURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources")
                .appendingPathComponent("\(fallbackFileName).json")
        ]

        guard let sourceURL = sourceCandidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            throw AppError.missingFallbackFile
        }

        return try Data(contentsOf: sourceURL)
    }
}

private extension FileStationCacheDataSource {
    static var defaultCacheURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VelibStations", isDirectory: true)
            .appendingPathComponent("station_cache.json")
    }
}

private final class InMemoryStationCacheDataSource: StationCacheDataSource {
    private var cachedData: Data?
    private var fallbackData: Data?

    init(data: Data? = nil, fallbackData: Data? = nil) {
        self.cachedData = data
        self.fallbackData = fallbackData
    }

    func save(_ data: Data) throws {
        self.cachedData = data
    }

    func loadCachedData() throws -> Data? {
        cachedData
    }

    func loadFallbackData() throws -> Data {
        guard let fallbackData else {
            throw AppError.missingFallbackFile
        }

        return fallbackData
    }
}

private protocol FavoritesStore {
    func favoriteIDs() -> Set<Int>
    func setFavorite(_ isFavorite: Bool, for stationID: Int)
}

private final class UserDefaultsFavoritesStore: FavoritesStore {
    private let key = "favorite_station_ids"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func favoriteIDs() -> Set<Int> {
        let ids = userDefaults.array(forKey: key) as? [Int] ?? []
        return Set(ids)
    }

    func setFavorite(_ isFavorite: Bool, for stationID: Int) {
        var ids = favoriteIDs()

        if isFavorite {
            ids.insert(stationID)
        } else {
            ids.remove(stationID)
        }

        userDefaults.set(Array(ids), forKey: key)
    }
}

private final class InMemoryFavoritesStore: FavoritesStore {
    private var ids: Set<Int>

    init(ids: Set<Int> = []) {
        self.ids = ids
    }

    func favoriteIDs() -> Set<Int> {
        ids
    }

    func setFavorite(_ isFavorite: Bool, for stationID: Int) {
        if isFavorite {
            ids.insert(stationID)
        } else {
            ids.remove(stationID)
        }
    }
}

private struct StationSnapshot: Codable {
    let id: Int
    let stationIdentifier: String
    let name: String
    let networkName: String
    let city: String
    let latitude: Double
    let longitude: Double
    let availableBikes: Int
    let emptySlots: Int
    let totalDocks: Int
    let isInstalled: Bool
    let isRenting: Bool
    let isReturning: Bool
    let lastUpdated: String?
    let address: String?
    let uid: String?
    let remoteStationID: Int?
    let extraLastUpdated: String?
    let normalBikes: Int
    let electricBikes: Int
    let isVirtual: Bool
    let acceptsBankCards: Bool
    let hasPaymentTerminal: Bool
    let paymentMethods: [String]

    init(station: Station) {
        self.id = station.id
        self.stationIdentifier = station.stationIdentifier
        self.name = station.name
        self.networkName = station.networkName
        self.city = station.city
        self.latitude = station.latitude
        self.longitude = station.longitude
        self.availableBikes = station.availableBikes
        self.emptySlots = station.emptySlots
        self.totalDocks = station.totalDocks
        self.isInstalled = station.isInstalled
        self.isRenting = station.isRenting
        self.isReturning = station.isReturning
        self.lastUpdated = station.lastUpdated
        self.address = station.address
        self.uid = station.uid
        self.remoteStationID = station.remoteStationID
        self.extraLastUpdated = station.extraLastUpdated
        self.normalBikes = station.normalBikes
        self.electricBikes = station.electricBikes
        self.isVirtual = station.isVirtual
        self.acceptsBankCards = station.acceptsBankCards
        self.hasPaymentTerminal = station.hasPaymentTerminal
        self.paymentMethods = station.paymentMethods
    }

    func station() -> Station {
        Station(
            id: id,
            stationIdentifier: stationIdentifier,
            name: name,
            networkName: networkName,
            city: city,
            latitude: latitude,
            longitude: longitude,
            availableBikes: availableBikes,
            emptySlots: emptySlots,
            totalDocks: totalDocks,
            isInstalled: isInstalled,
            isRenting: isRenting,
            isReturning: isReturning,
            lastUpdated: lastUpdated,
            address: address,
            uid: uid,
            remoteStationID: remoteStationID,
            extraLastUpdated: extraLastUpdated,
            normalBikes: normalBikes,
            electricBikes: electricBikes,
            isVirtual: isVirtual,
            acceptsBankCards: acceptsBankCards,
            hasPaymentTerminal: hasPaymentTerminal,
            paymentMethods: paymentMethods
        )
    }
}
