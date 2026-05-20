//
//  StationDetailView.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import MapKit
import SwiftUI

struct StationDetailView<ViewModel: StationDetailViewModelProtocol>: View {
    @ObservedObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                availabilityGrid
                statusSection
                mapSection
                informationSection
                openAppleMapButton
            }
            .padding()
        }
        .navigationTitle("Station Detail")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

private extension StationDetailView {
    var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.station.name)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)

                if let uid = viewModel.station.uid, !uid.isEmpty {
                    Text("Station UID: \(uid)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text(viewModel.station.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button {
                viewModel.toggleFavorite()
            } label: {
                Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(viewModel.isFavorite ? .yellow : .secondary)
            }
            .accessibilityLabel(viewModel.isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    var availabilityGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            StatCardView(title: "Available Bikes", value: "\(viewModel.station.availableBikes)", systemImage: "bicycle")
            StatCardView(title: "Empty Slots", value: "\(viewModel.station.emptySlots)", systemImage: "parkingsign.circle")
            StatCardView(title: "Normal Bikes", value: "\(viewModel.station.normalBikes)", systemImage: "figure.outdoor.cycle")
            StatCardView(title: "E-Bikes", value: "\(viewModel.station.electricBikes)", systemImage: "bolt.fill")
            StatCardView(title: "Total Slots", value: "\(viewModel.station.totalDocks)", systemImage: "square.grid.3x3")
            StatCardView(title: "Availability", value: "\(Int(viewModel.station.availabilityRatio * 100))%", systemImage: "chart.pie")
        }
    }

    var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status")
                .font(.headline)

            HStack(spacing: 8) {
                AvailabilityBadge(title: "Renting", isEnabled: viewModel.station.isRenting)
                AvailabilityBadge(title: "Returning", isEnabled: viewModel.station.isReturning)
                AvailabilityBadge(title: "Payment", isEnabled: viewModel.station.hasPaymentTerminal)
            }
        }
        .sectionCardStyle()
    }

    var mapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Location")
                .font(.headline)

            StationMapView(station: viewModel.station.station)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .sectionCardStyle()
    }

    var informationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(.headline)

            InfoRow(title: "Network", value: viewModel.station.networkName)
            InfoRow(title: "City", value: viewModel.station.city)
            InfoRow(title: "Latitude", value: String(format: "%.6f", viewModel.station.latitude))
            InfoRow(title: "Longitude", value: String(format: "%.6f", viewModel.station.longitude))
            InfoRow(title: "Banking", value: viewModel.station.acceptsBankCards ? "Yes" : "No")
            InfoRow(title: "Payment Terminal", value: viewModel.station.hasPaymentTerminal ? "Yes" : "No")
            InfoRow(title: "Last Updated", value: viewModel.station.lastUpdatedSummary)
        }
        .sectionCardStyle()
    }
    
    var openAppleMapButton: some View {
        Button {
            openInAppleMaps()
        } label: {
            Label("Open in Apple Maps", systemImage: "map")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    func openInAppleMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: viewModel.station.latitude,
            longitude: viewModel.station.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = viewModel.station.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        ])
    }
}

private extension View {
    func sectionCardStyle() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    let vm = StationDetailViewModel(station: StationViewModel(station: .sampleStation))
    StationDetailView(viewModel: vm)
}
