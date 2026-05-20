//
//  StationService.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import Foundation

extension Network.Service {
    static var cityBikes: Network.Service {
        let url = try! "https://api.citybik.es/v2/".asURL()
        return Network.Service(server: .basic(baseURL: url))
    }
}

protocol StationServiceProtocol {
    func requestStations() async throws -> [StationViewModel]
}

final class StationService {
    private let networkService: Network.Service
    private let networkID: String

    init(
        networkService: Network.Service = .cityBikes,
        networkID: String = "velib"
    ) {
        self.networkService = networkService
        self.networkID = networkID
    }
}

extension StationService: StationServiceProtocol {
    func requestStations() async throws -> [StationViewModel] {
        let response: CityBikeNetworkResponse = try await networkService.request(StationRequest.cityBikeNetwork(networkID))
        return viewModels(from: response)
    }
}

private extension StationService {
    func viewModels(from response: CityBikeNetworkResponse) -> [StationViewModel] {
        response.network.stations
            .map { station in
                station.networkName = response.network.name
                station.city = response.network.location.city
                return station
            }
            .sorted { lhs, rhs in
                if lhs.availableBikes == rhs.availableBikes { return lhs.name < rhs.name }
                return lhs.availableBikes > rhs.availableBikes
            }
            .map { StationViewModel(station: $0) }
    }
}
