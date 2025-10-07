//
//  ContentView.swift
//  SmartSpace
//
//  Created by Максим Гайдук on 06.10.2025.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    fileprivate enum LayoutStyle {
        case grid
        case list

        mutating func toggle() {
            self = self == .grid ? .list : .grid
        }

        var iconName: String {
            switch self {
            case .grid:
                return "square.grid.2x2"
            case .list:
                return "list.bullet"
            }
        }
    }

    @Query(sort: [SortDescriptor(\Space.createdAt, order: .reverse)]) private var spaces: [Space]

    @State private var layoutStyle: LayoutStyle = .grid
    @State private var isPresentingCreation = false
    @State private var selectedSpaceID: PersistentIdentifier? = nil

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
    }

    var body: some View {
        NavigationStack {
            Group {
                if spaces.isEmpty {
                    EmptySpaceState()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if layoutStyle == .grid {
                                LazyVGrid(columns: gridColumns, spacing: 20) {
                                    ForEach(spaces) { space in
                                        NavigationLink(
                                            tag: space.persistentModelID,
                                            selection: $selectedSpaceID
                                        ) {
                                            SpaceDetailView(space: space)
                                        } label: {
                                            SpaceCard(space: space, layout: layoutStyle)
                                                .aspectRatio(1, contentMode: .fit)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(spaces) { space in
                                        NavigationLink(
                                            tag: space.persistentModelID,
                                            selection: $selectedSpaceID
                                        ) {
                                            SpaceDetailView(space: space)
                                        } label: {
                                            SpaceCard(space: space, layout: layoutStyle)
                                                .frame(height: 120)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        layoutStyle.toggle()
                    } label: {
                        Image(systemName: layoutStyle.iconName)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(layoutStyle == .grid ? "Switch to list view" : "Switch to grid view")
                }
            }
            .sheet(isPresented: $isPresentingCreation) {
                NewSpaceSheet()
                    .presentationDetents([.medium, .large])
            }
            .navigationTitle("Spacec")
            .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                if selectedSpaceID == nil {
                    Button {
                        isPresentingCreation = true
                    } label: {
                        Label("Add new space", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .labelStyle(.titleAndIcon)
                }
            }
        }
    }
}

private struct SpaceCard: View {
    let space: Space
    let layout: ContentView.LayoutStyle

    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.secondary.opacity(0.12))
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(space.name)
                        .font(.headline)
                    Text(space.type.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Label(space.mode.rawValue, systemImage: space.mode == .onDevice ? "iphone" : "cloud")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("\(space.blocks?.count ?? 0) blocks", systemImage: "square.grid.3x3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(space.createdAt, format: .dateTime.day().month().year())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Space \(space.name), type \(space.type.rawValue), \(space.blocks?.count ?? 0) blocks")
    }
}

private struct EmptySpaceState: View {
    var body: some View {
        ContentUnavailableView {
            Label("No spaces yet", systemImage: "rectangle.on.rectangle.angled")
        } description: {
            Text("Tap \"Add new space\" below to create your first Space and start organizing your knowledge.")
        }
    }
}

private struct NewSpaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingSpaces: [Space]

    @State private var name: String = ""
    @State private var type: Space.SpaceType = .learning
    @State private var mode: Space.SpaceMode = .privateCloudCompute

    private var isDuplicateName: Bool {
        existingSpaces.contains { $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }

    private var isCreateDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDuplicateName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    Picker("Type", selection: $type) {
                        ForEach(Space.SpaceType.allCases) { spaceType in
                            Text(spaceType.rawValue).tag(spaceType)
                        }
                    }
                    Picker("Mode", selection: $mode) {
                        ForEach(Space.SpaceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    if isDuplicateName && !name.isEmpty {
                        Text("A space with this name already exists.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSpace()
                    }
                    .disabled(isCreateDisabled)
                }
            }
        }
    }

    private func createSpace() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newSpace = Space(name: trimmedName, type: type, mode: mode)
        modelContext.insert(newSpace)
        dismiss()
    }
}

private struct SpaceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isShowingDeleteConfirmation = false

    @Bindable var space: Space

    init(space: Space) {
        self.space = space
    }

    var body: some View {
        List {
            Section("Blocks") {
                if (space.blocks?.isEmpty ?? true) {
                    Text("No blocks yet. They’ll appear here when available.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(space.blocks ?? []) { block in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(block.title)
                                .font(.headline)
                            Text(block.kind.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if !block.details.isEmpty {
                                Text(block.details)
                                    .font(.body)
                            }
                            Text(block.createdAt, format: .dateTime.day().month().year())
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(space.name)
                        .font(.headline)
                    Text(space.mode.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Import files") { }
                    Button("Manage attachments") { }
                } label: {
                    Label("Manage files", systemImage: "folder.badge.gearshape")
                }
                .accessibilityLabel("Manage files")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("Details") {
                        Label("Type: \(space.type.rawValue)", systemImage: "square.grid.3x3")
                        Label("Created: \(space.createdAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                        Label("Blocks: \(space.blocks?.count)", systemImage: "rectangle.grid.2x2")
                    }
                    Divider()
                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("Delete Space", systemImage: "trash")
                    }
                } label: {
                    Label("Space info", systemImage: "info.circle")
                }
                .accessibilityLabel("Space info")
            }
        }
        .confirmationDialog(
            "Delete this space?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Space", role: .destructive) {
                deleteSpace()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action removes the space and its blocks.")
        }
    }

    private func deleteSpace() {
        modelContext.delete(space)
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Space.self, SpaceBlock.self], inMemory: true)
}
