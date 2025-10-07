//
//  NewSpaceSheet.swift
//  SmartSpace
//
//  Created by Максим Гайдук on 06.10.2025.
//

import SwiftData
import SwiftUI

struct NewSpaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingSpaces: [Space]

    @State private var name: String = ""
    @State private var type: Space.SpaceType = .learning
    @State private var mode: Space.SpaceMode = .privateCloudCompute

    private let nameLimit = 24

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicateName: Bool {
        guard !trimmedName.isEmpty else { return false }
        return existingSpaces.contains {
            $0.name.compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private var isCreateDisabled: Bool {
        trimmedName.isEmpty || isDuplicateName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name your space", text: $name)
                        .textInputAutocapitalization(.words)
                        .onChange(of: name) { newValue in
                            guard newValue.count > nameLimit else { return }
                            name = String(newValue.prefix(nameLimit))
                        }
                        .padding(6)
                }

                Section("Type") {
                    HStack{
                        Spacer()
                        Picker("Type", selection: $type) {
                            ForEach(Space.SpaceType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }.labelsHidden()
                        Spacer()
                    }
                }

                Section("Mode") {
                    Picker("Mode", selection: $mode) {
                        ForEach(Space.SpaceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(6)
                    
                }

                if isDuplicateName {
                    Section {
                        DuplicateWarning()
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
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
        guard !trimmedName.isEmpty else { return }

        let newSpace = Space(name: trimmedName, type: type, mode: mode)
        modelContext.insert(newSpace)
        dismiss()
    }
}

private struct DuplicateWarning: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("A space with this name already exists.")
                .font(.callout)
                .foregroundStyle(.orange)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.orange.opacity(0.1))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Helpers
