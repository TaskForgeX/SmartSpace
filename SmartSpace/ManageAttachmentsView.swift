//
//  ManageAttachmentsView.swift
//  SmartSpace
//
//  Created by Максим Гайдук on 07.10.2025.
//

import SwiftData
import SwiftUI

struct ManageAttachmentsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var space: Space

    @State private var removalErrorMessage: String?

    private var sortedAttachments: [SpaceAttachment] {
        space.attachments.sorted { $0.addedAt > $1.addedAt }
    }

    var body: some View {
        NavigationStack {
            List {
                if sortedAttachments.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No attachments yet",
                            systemImage: "paperclip",
                            description: Text("Import files or paste text to see them listed here.")
                        )
                    }
                } else {
                    Section {
                        ForEach(sortedAttachments) { attachment in
                            AttachmentRow(
                                attachment: attachment,
                                deleteAction: { deleteAttachment(attachment) }
                            )
                        }
                        .onDelete(perform: deleteAttachments(at:))
                    } header: {
                        Text("Attachments")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Manage Attachments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(
                "Removal failed",
                isPresented: Binding(
                    get: { removalErrorMessage != nil },
                    set: { newValue in
                        if !newValue {
                            removalErrorMessage = nil
                        }
                    }
                ),
                actions: {
                    Button("OK", role: .cancel) { }
                },
                message: {
                    Text(removalErrorMessage ?? "")
                }
            )
        }
    }
}

private extension ManageAttachmentsView {
    func deleteAttachments(at offsets: IndexSet) {
        let attachmentsToDelete = offsets.compactMap { index in
            sortedAttachments[safe: index]
        }
        attachmentsToDelete.forEach { deleteAttachment($0) }
    }

    func deleteAttachment(_ attachment: SpaceAttachment) {
        do {
            try AttachmentStorage.removeFile(named: attachment.storedFileName)
        } catch {
            removalErrorMessage = error.localizedDescription
        }

        withAnimation {
            modelContext.delete(attachment)
        }
    }

}

private struct AttachmentRow: View {
    let attachment: SpaceAttachment
    let deleteAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(attachment.originalFileName)
                    .font(.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(languageDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(attachment.addedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if FileManager.default.fileExists(atPath: attachment.fileURL.path) {
                ShareLink(item: attachment.fileURL) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Share \(attachment.originalFileName)")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteAction()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var languageDescription: String {
        guard let code = attachment.languageCode, !code.isEmpty else {
            return "Language unknown"
        }
        return Locale.current.localizedString(forLanguageCode: code) ?? code
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
