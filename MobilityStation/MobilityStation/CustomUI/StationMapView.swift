//
//  StationListView.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import SwiftUI
import MapKit

struct StationMapView: View {
    let station: Station

    @State private var region: MKCoordinateRegion

    init(station: Station) {
        self.station = station

        let coordinate = CLLocationCoordinate2D(
            latitude: station.latitude,
            longitude: station.longitude
        )

        _region = State(
            initialValue: MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }

    var body: some View {
        Map(
            coordinateRegion: $region,
            annotationItems: [StationMapAnnotation(station: station)]
        ) { annotation in
            MapMarker(coordinate: annotation.coordinate)
        }
    }
}

private struct StationMapAnnotation: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D

    init(station: Station) {
        self.id = station.id
        self.coordinate = CLLocationCoordinate2D(
            latitude: station.latitude,
            longitude: station.longitude
        )
    }
}
