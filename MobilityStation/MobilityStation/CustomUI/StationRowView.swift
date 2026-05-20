//
//  StationRowView.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import SwiftUI

struct StationRowView<ViewModel: StationViewModelProtocol>: View {
    let viewModel: ViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(viewModel.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Image(systemName: viewModel.isBookmarked ? "star.fill" : "star")
                        .foregroundColor(viewModel.isBookmarked ? .yellow : .secondary)
                        .accessibilityLabel(viewModel.isBookmarked ? "Favorite" : "Not favorite")
                }

                HStack(spacing: 12) {
                    MiniStatView(
                        title: "Bikes",
                        value: "\(viewModel.availableBikes)",
                        systemImage: "bicycle"
                    )

                    MiniStatView(
                        title: "Slots",
                        value: "\(viewModel.emptySlots)",
                        systemImage: "parkingsign.circle"
                    )

                    MiniStatView(
                        title: "E-Bikes",
                        value: "\(viewModel.electricBikes)",
                        systemImage: "bolt.fill"
                    )
                }

                HStack(spacing: 8) {
                    AvailabilityBadge(title: "Rent", isEnabled: viewModel.isRenting)
                    AvailabilityBadge(title: "Return", isEnabled: viewModel.isReturning)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    StationRowView(viewModel: StationViewModel(station: .sampleStation))
}
