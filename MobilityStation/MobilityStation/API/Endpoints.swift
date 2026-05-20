//
//  Endpoint.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import Foundation

enum Endpoint {
    case networkDetails(String)
}

extension Endpoint: EndpointType {
    var path: String {
        switch self {
            case .networkDetails(let id): return "networks/\(id)"
        }
    }
}
