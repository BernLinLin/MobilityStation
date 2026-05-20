//
//  StationModels.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import Foundation

final class Station: Decodable {
    var id: Int
    var stationIdentifier: String
    var name: String
    var networkName: String
    var city: String
    var latitude: Double
    var longitude: Double
    var availableBikes: Int
    var emptySlots: Int
    var totalDocks: Int
    var isInstalled: Bool
    var isRenting: Bool
    var isReturning: Bool
    var lastUpdated: String?
    var address: String?
    var uid: String?
    var remoteStationID: Int?
    var extraLastUpdated: String?
    var normalBikes: Int
    var electricBikes: Int
    var isVirtual: Bool
    var acceptsBankCards: Bool
    var hasPaymentTerminal: Bool
    var paymentMethods: [String]
    var isBookmarked: Bool = false

    private enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, timestamp, extra
        case freeBikes = "free_bikes"
        case emptySlots = "empty_slots"
    }

    fileprivate enum ExtraKeys: String, CodingKey {
        case uid, renting, returning, slots, virtual, banking, payment
        case lastUpdated = "last_updated"
        case stationID = "station_id"
        case paymentTerminal = "payment-terminal"
        case normalBikes = "normal_bikes"
        case electricBikes = "ebikes"
        case address
    }

    init(
        id: Int,
        stationIdentifier: String,
        name: String,
        networkName: String,
        city: String,
        latitude: Double,
        longitude: Double,
        availableBikes: Int,
        emptySlots: Int,
        totalDocks: Int,
        isInstalled: Bool,
        isRenting: Bool,
        isReturning: Bool,
        lastUpdated: String?,
        address: String?,
        uid: String? = nil,
        remoteStationID: Int? = nil,
        extraLastUpdated: String? = nil,
        normalBikes: Int = 0,
        electricBikes: Int = 0,
        isVirtual: Bool = false,
        acceptsBankCards: Bool = false,
        hasPaymentTerminal: Bool = false,
        paymentMethods: [String] = [],
        isBookmarked: Bool = false
    ) {
        self.id = id
        self.stationIdentifier = stationIdentifier
        self.name = name
        self.networkName = networkName
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.availableBikes = availableBikes
        self.emptySlots = emptySlots
        self.totalDocks = totalDocks
        self.isInstalled = isInstalled
        self.isRenting = isRenting
        self.isReturning = isReturning
        self.lastUpdated = lastUpdated
        self.address = address
        self.uid = uid
        self.remoteStationID = remoteStationID
        self.extraLastUpdated = extraLastUpdated
        self.normalBikes = normalBikes
        self.electricBikes = electricBikes
        self.isVirtual = isVirtual
        self.acceptsBankCards = acceptsBankCards
        self.hasPaymentTerminal = hasPaymentTerminal
        self.paymentMethods = paymentMethods
        self.isBookmarked = isBookmarked
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let extra = try? container.nestedContainer(keyedBy: ExtraKeys.self, forKey: .extra)

        let decodedIdentifier = try container.decode(String.self, forKey: .id)
        let decodedAvailableBikes = try container.decodeIfPresent(Int.self, forKey: .freeBikes) ?? 0
        let decodedEmptySlots = try container.decodeIfPresent(Int.self, forKey: .emptySlots) ?? 0
        let decodedNormalBikes = try extra?.decodeIfPresent(Int.self, forKey: .normalBikes) ?? 0
        let decodedElectricBikes = try extra?.decodeIfPresent(Int.self, forKey: .electricBikes) ?? 0

        id = Self.stableID(for: decodedIdentifier)
        stationIdentifier = decodedIdentifier
        name = try container.decode(String.self, forKey: .name)
        networkName = ""
        city = ""
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        availableBikes = decodedAvailableBikes
        emptySlots = decodedEmptySlots
        totalDocks = try extra?.decodeIfPresent(Int.self, forKey: .slots) ?? decodedAvailableBikes + decodedEmptySlots
        isInstalled = true
        isRenting = extra?.decodeFlexibleBool(forKey: .renting) ?? true
        isReturning = extra?.decodeFlexibleBool(forKey: .returning) ?? true
        lastUpdated = try container.decodeIfPresent(String.self, forKey: .timestamp)
        address = try extra?.decodeIfPresent(String.self, forKey: .address)
        uid = try extra?.decodeIfPresent(String.self, forKey: .uid)
        remoteStationID = try extra?.decodeIfPresent(Int.self, forKey: .stationID)
        extraLastUpdated = try extra?.decodeIfPresent(String.self, forKey: .lastUpdated)
        normalBikes = decodedNormalBikes
        electricBikes = decodedElectricBikes
        isVirtual = try extra?.decodeIfPresent(Bool.self, forKey: .virtual) ?? false
        acceptsBankCards = try extra?.decodeIfPresent(Bool.self, forKey: .banking) ?? false
        hasPaymentTerminal = try extra?.decodeIfPresent(Bool.self, forKey: .paymentTerminal) ?? false
        paymentMethods = try extra?.decodeIfPresent([String].self, forKey: .payment) ?? []
    }
}

private extension KeyedDecodingContainer where Key == Station.ExtraKeys {
    func decodeFlexibleBool(forKey key: Key) -> Bool? {
        if let boolValue = try? decodeIfPresent(Bool.self, forKey: key) {
            return boolValue
        }
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return intValue != 0
        }
        return nil
    }
}

extension Station {
    static var sampleStation: Station {
        Station(
            id: 1001,
            stationIdentifier: "sample-central-park-south",
            name: "Central Park South & 6 Ave",
            networkName: "Citi Bike NYC",
            city: "New York",
            latitude: 40.765909,
            longitude: -73.976342,
            availableBikes: 12,
            emptySlots: 19,
            totalDocks: 31,
            isInstalled: true,
            isRenting: true,
            isReturning: true,
            lastUpdated: "2026-05-20T08:15:00Z",
            address: "Central Park South & 6 Ave",
            uid: "sample-uid",
            remoteStationID: 1001,
            normalBikes: 8,
            electricBikes: 4,
            acceptsBankCards: true,
            hasPaymentTerminal: true,
            paymentMethods: ["creditcard"]
        )
    }

    static var fallbackStations: [Station] {
        [
            sampleStation,
            Station(id: 1002, stationIdentifier: "sample-bryant-park", name: "Bryant Park - 42 St", networkName: "Citi Bike NYC", city: "New York", latitude: 40.753597, longitude: -73.983233, availableBikes: 5, emptySlots: 34, totalDocks: 39, isInstalled: true, isRenting: true, isReturning: true, lastUpdated: "2026-05-20T08:14:00Z", address: "6 Ave & W 42 St"),
            Station(id: 1003, stationIdentifier: "sample-union-square", name: "Union Square E & E 15 St", networkName: "Citi Bike NYC", city: "New York", latitude: 40.735367, longitude: -73.987974, availableBikes: 0, emptySlots: 27, totalDocks: 27, isInstalled: true, isRenting: false, isReturning: true, lastUpdated: "2026-05-20T08:13:00Z", address: "Union Square East"),
            Station(id: 1004, stationIdentifier: "sample-brooklyn-bridge", name: "Brooklyn Bridge Park - Pier 2", networkName: "Citi Bike NYC", city: "New York", latitude: 40.69878, longitude: -73.99712, availableBikes: 18, emptySlots: 8, totalDocks: 26, isInstalled: true, isRenting: true, isReturning: true, lastUpdated: "2026-05-20T08:12:00Z", address: "Furman St & Pier 2")
        ]
    }

    static func stableID(for text: String) -> Int {
        var hash = 5381
        for scalar in text.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return abs(hash)
    }
}

extension Station: @unchecked Sendable {}

struct CityBikeNetworkResponse: Decodable, Sendable {
    let network: CityBikeNetwork
}

struct CityBikeNetwork: Decodable, Sendable {
    let id: String
    let name: String
    let location: CityBikeLocation
    let stations: [Station]
}

struct CityBikeLocation: Decodable, Sendable {
    let latitude: Double?
    let longitude: Double?
    let city: String
    let country: String
}

