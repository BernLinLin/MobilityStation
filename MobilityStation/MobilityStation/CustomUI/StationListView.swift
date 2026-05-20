//
//  StationListView.swift
//  MobilityStations
//
//  Created by Bern on 2026/5/20.
//

import SwiftUI

struct StationListView<ViewModel: StationListViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterControls
                content
            }
            .navigationTitle("Vélib Stations")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Search stations")
            .task {
                await viewModel.loadIfNeeded()
            }
            .alert("Unable to load stations", isPresented: errorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.stations.isEmpty {
            LoadingView(text: "Loading stations...")
        } else {
            List {
                if viewModel.visibleStations.isEmpty {
                    EmptyStateView(
                        title: "No stations found",
                        message: "Try changing the search text, list type, or sort option."
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.visibleStations, id: \.id) { station in
                        StationItemView(
                            viewModel: viewModel,
                            station: station
                        )
                        .id("\(station.id)-\(station.isBookmarked)")
                        .swipeActions(edge: .trailing) {
                                Button {
                                    viewModel.toggleFavorite(station.id)
                                } label: {
                                    Label(
                                        station.isBookmarked ? "Remove" : "Favorite",
                                        systemImage: station.isBookmarked ? "star.slash" : "star"
                                    )
                                }
                                .tint(.yellow)
                            }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await viewModel.refresh()
            }

        }
    }

    private var filterControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("List Type", selection: $viewModel.filter) {
                Text("All").tag(StationFilter.all)
                Text("Favorites").tag(StationFilter.favorites)
            }
            .pickerStyle(.segmented)

            HStack {
                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(StationSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Text("\(viewModel.visibleStations.count)")
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .accessibilityLabel("\(viewModel.visibleStations.count) visible stations")
            }
            .font(.subheadline)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }
}

private struct StationItemView<ListViewModel: StationListViewModelProtocol>: View {
    @ObservedObject var viewModel: ListViewModel
    var station: StationViewModel

    var body: some View {
        NavigationLink {
            if let station = viewModel.station(id: station.id) {
                StationDetailView(
                    viewModel: StationDetailViewModel(
                        station: station,
                        onToggleFavorite: {
                            viewModel.toggleFavorite(station.id)
                        }
                    )
                )
            } else {
                EmptyStateView(
                    title: "Station not found",
                    message: "This station may no longer be available."
                )
            }
        } label: {
            StationRowView(viewModel: station)
        }
        .accessibilityLabel(station.name)
        .accessibilityHint("Double tap for station details")
    }
}

#Preview {
    StationListView(
        viewModel: StationListViewModel(stationStore: StationStore(stations: Station.fallbackStations))
    )
}
