//
//  StationViewModel.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import Foundation

protocol StationViewModelProtocol {
    var id: Int { get }
    var name: String { get }
    var networkName: String { get }
    var city: String { get }
    var availableBikes: Int { get }
    var emptySlots: Int { get }
    var totalDocks: Int { get }
    var normalBikes: Int { get }
    var electricBikes: Int { get }
    var availabilityRatio: Double { get }
    var statusSummary: String { get }
    var lastUpdatedSummary: String { get }
    var address: String { get }
    var uid: String? { get }
    var latitude: Double { get }
    var longitude: Double { get }
    var isBookmarked: Bool { get }
    var isOperational: Bool { get }
    var isRenting: Bool { get }
    var isReturning: Bool { get }
    var acceptsBankCards: Bool { get }
    var hasPaymentTerminal: Bool { get }
    var station: Station { get }
}

struct StationViewModel {
    private(set) var station: Station

    init(station: Station) {
        self.station = station
    }
}

extension StationViewModel: StationViewModelProtocol {
    var id: Int { station.id }
    var name: String { station.name }
    var networkName: String { station.networkName }
    var city: String { station.city }
    var availableBikes: Int { station.availableBikes }
    var emptySlots: Int { station.emptySlots }
    var totalDocks: Int { max(station.totalDocks, station.availableBikes + station.emptySlots) }
    var normalBikes: Int { station.normalBikes }
    var electricBikes: Int { station.electricBikes }
    var isBookmarked: Bool { station.isBookmarked }
    var isOperational: Bool { station.isInstalled && station.isRenting && station.isReturning }
    var isRenting: Bool { station.isRenting }
    var isReturning: Bool { station.isReturning }
    var acceptsBankCards: Bool { station.acceptsBankCards }
    var hasPaymentTerminal: Bool { station.hasPaymentTerminal }
    var uid: String? { station.uid }
    var latitude: Double { station.latitude }
    var longitude: Double { station.longitude }
    var availabilityRatio: Double {
        guard totalDocks > 0 else { return 0 }
        return Double(availableBikes) / Double(totalDocks)
    }
    var statusSummary: String {
        if !station.isInstalled { return "Station offline" }
        if !station.isRenting && !station.isReturning { return "Unavailable" }
        if !station.isRenting { return "Returns only" }
        if !station.isReturning { return "Pickup only" }
        if availableBikes == 0 { return "No bikes available" }
        if emptySlots == 0 { return "No empty docks" }
        return "Operational"
    }
    var lastUpdatedSummary: String {
        guard let lastUpdated = station.lastUpdated, !lastUpdated.isEmpty else { return "Updated from cached data" }
        return "Updated \(lastUpdated.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: " UTC"))"
    }
    var address: String { station.address ?? "No street address provided" }
}

extension StationViewModelProtocol {
    var networkName: String { "Sample Mobility" }
    var city: String { "Sample City" }
    var availableBikes: Int { 0 }
    var emptySlots: Int { 0 }
    var totalDocks: Int { availableBikes + emptySlots }
    var normalBikes: Int { 0 }
    var electricBikes: Int { 0 }
    var availabilityRatio: Double { 0 }
    var statusSummary: String { "Operational" }
    var lastUpdatedSummary: String { "Updated from cached data" }
    var address: String { "No street address provided" }
    var uid: String? { nil }
    var latitude: Double { 0 }
    var longitude: Double { 0 }
    var isBookmarked: Bool { false }
    var isOperational: Bool { true }
    var isRenting: Bool { true }
    var isReturning: Bool { true }
    var acceptsBankCards: Bool { false }
    var hasPaymentTerminal: Bool { false }
    var station: Station { .sampleStation }
}

extension StationViewModel: Equatable {
    static func == (lhs: StationViewModel, rhs: StationViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
