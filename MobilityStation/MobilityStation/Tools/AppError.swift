//
//  AppError.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/21.
//

import Foundation

enum AppError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badStatusCode(Int)
    case decodingFailed(String)
    case cacheUnavailable
    case missingFallbackFile
    case transportError(Error)

    var errorDescription: String? {
        switch self {
            case .invalidURL:
                return "The request URL is invalid."
            case .invalidResponse:
                return "Invalid server response."
            case .badStatusCode(let code):
                return "Server returned status code \(code)."
            case .decodingFailed(let reason):
                return "Failed to decode station data: \(reason)"
            case .cacheUnavailable:
                return "Cached station data is unavailable."
            case .missingFallbackFile:
                return "Fallback station data was not found."
            case .transportError(let error):
                return error.localizedDescription
        }
    }
}
