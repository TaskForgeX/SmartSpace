//
//  ContentView.swift
//  SmartSpace
//
//  Created by Максим Гайдук on 06.10.2025.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: [SortDescriptor(\Space.createdAt, order: .reverse)]) private var spaces: [Space]

    @State private var isPresentingCreation = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Text("Spacec")
                .font(.system(size: 40, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
            
            VStack(spacing: 14) {
                if spaces.isEmpty {
                    Spacer(minLength: 0)
                    EmptySpaceState()
                    Spacer(minLength: 0)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 5) {
                            ForEach(spaces) { space in
                                NavigationLink(value: space.persistentModelID) {
                                    SpaceCard(space: space, layout: .list)
                                        .frame(height: 120)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .sheet(isPresented: $isPresentingCreation) {
                NewSpaceSheet()
                    .presentationDetents([.medium, .large])
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PersistentIdentifier.self) { identifier in
                if let selectedSpace = spaces.first(where: { $0.persistentModelID == identifier }) {
                    SpaceDetailView(space: selectedSpace)
                } else {
                    Text("Space not found")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                if navigationPath.isEmpty {
                    Button {
                        isPresentingCreation = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                            Text("Add new Space")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Space.self, SpaceBlock.self, SpaceAttachment.self], inMemory: true)
}
