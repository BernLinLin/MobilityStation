//
//  StationRequest.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import Foundation

enum StationRequest: Requestable {
    case cityBikeNetwork(String)

    var encoding: Request.Encoding { .query }
    var httpMethod: HTTP.Method { .get }

    var endpoint: EndpointType {
        switch self {
            case .cityBikeNetwork(let id): Endpoint.networkDetails(id)
        }
    }

    var parameters: HTTP.Parameters { HTTP.Parameters() }
}
