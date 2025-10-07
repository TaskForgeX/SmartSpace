//
//  SpaceDetailView.swift
//  SmartSpace
//
//  Created by Максим Гайдук on 06.10.2025.
//

import NaturalLanguage
import PDFKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SpaceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isShowingDeleteConfirmation = false
    @State private var isImportingFiles = false
    @State private var isPresentingPasteSheet = false
    @State private var isPresentingManageAttachments = false
    @State private var pastedText: String = ""
    @State private var importErrorMessage: String?

    @Bindable var space: Space

    init(space: Space) {
        self.space = space
    }

    var body: some View {
        List {
            blocksSection
        }
        .contentMargins(.top, 8, for: .scrollContent)
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(space.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.85)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isImportingFiles = true
                    } label: {
                        Label("Import files", systemImage: "tray.and.arrow.down")
                    }
                    Button {
                        isPresentingPasteSheet = true
                    } label: {
                        Label("Paste text", systemImage: "doc.on.clipboard")
                    }
                    Divider()
                    Button {
                        isPresentingManageAttachments = true
                    } label: {
                        Label("Manage attachments", systemImage: "folder")
                    }
                } label: {
                    Label("Manage files", systemImage: "paperclip")
                }
                .accessibilityLabel("Manage files")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("Details") {
                        Label("Type: \(space.type.rawValue)", systemImage: "square.grid.3x3")
                        Label("Created: \(space.createdAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                        Label(
                            "\(space.mode.rawValue)",
                            systemImage: space.mode == .onDevice ? "iphone" : "cloud"
                        )
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
        .toolbar(.hidden, for: .bottomBar)
        .fileImporter(
            isPresented: $isImportingFiles,
            allowedContentTypes: supportedContentTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                importFiles(from: urls)
            case .failure(let error):
                importErrorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $isPresentingPasteSheet) {
            PasteTextSheet(
                text: $pastedText,
                onCancel: cancelPaste,
                onSave: savePastedText
            )
        }
        .sheet(isPresented: $isPresentingManageAttachments) {
            ManageAttachmentsView(space: space)
        }
        .alert(
            "Import failed",
            isPresented: Binding(
                get: { importErrorMessage != nil },
                set: { newValue in
                    if !newValue {
                        importErrorMessage = nil
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    importErrorMessage = nil
                }
            },
            message: {
                Text(importErrorMessage ?? "")
            }
        )
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

    private var blocksSection: some View {
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
                }
            }
        }
    }
}

// MARK: - Actions

private extension SpaceDetailView {
    var supportedContentTypes: [UTType] {
        var types: [UTType] = [.pdf, .plainText, .utf8PlainText]
        if let docxType = UTType(filenameExtension: "docx") {
            types.append(docxType)
        }
        return types
    }

    func cancelPaste() {
        pastedText = ""
        isPresentingPasteSheet = false
    }

    func deleteSpace() {
        for attachment in space.attachments {
            try? AttachmentStorage.removeFile(named: attachment.storedFileName)
        }
        modelContext.delete(space)
        dismiss()
    }

    func savePastedText() {
        let trimmed = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            importErrorMessage = ImportError.emptyText.errorDescription
            return
        }

        do {
            try AttachmentStorage.ensureDirectoryExists()

            guard let language = languageCode(from: trimmed), language == "en" else {
                throw ImportError.languageUnsupported
            }

            let storedFileName = "\(UUID().uuidString)-pasted.txt"
            let destinationURL = AttachmentStorage.destinationURL(forStoredFileName: storedFileName)

            try trimmed.write(to: destinationURL, atomically: true, encoding: .utf8)

            let attachment = SpaceAttachment(
                originalFileName: "Pasted text.txt",
                storedFileName: storedFileName,
                languageCode: language
            )
            attachment.space = space
            modelContext.insert(attachment)

            pastedText = ""
            isPresentingPasteSheet = false
        } catch let error as ImportError {
            importErrorMessage = error.errorDescription
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    func importFiles(from urls: [URL]) {
        do {
            try AttachmentStorage.ensureDirectoryExists()
            for url in urls {
                try importFile(from: url)
            }
        } catch let error as ImportError {
            importErrorMessage = error.errorDescription
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    func importFile(from url: URL) throws {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let storedFileName = "\(UUID().uuidString)-\(url.lastPathComponent)"
        let destinationURL = AttachmentStorage.destinationURL(forStoredFileName: storedFileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
        } catch {
            throw error
        }

        guard let language = detectLanguage(for: destinationURL), language == "en" else {
            try? FileManager.default.removeItem(at: destinationURL)
            throw ImportError.languageUnsupported
        }

        let attachment = SpaceAttachment(
            originalFileName: url.lastPathComponent,
            storedFileName: storedFileName,
            languageCode: language
        )
        attachment.space = space
        modelContext.insert(attachment)
    }
}

// MARK: - Language Detection

private extension SpaceDetailView {
    func detectLanguage(for url: URL) -> String? {
        let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey])
        var fileType = resourceValues?.contentType

        if fileType == nil {
            fileType = UTType(filenameExtension: url.pathExtension)
        }

        guard let fileType else {
            return nil
        }

        if fileType.conforms(to: .text) {
            return detectLanguageFromPlainText(url: url)
        }

        if fileType.conforms(to: .pdf) {
            return detectLanguageFromPDF(url: url)
        }

        if let docxType = UTType(filenameExtension: "docx"),
           fileType.conforms(to: docxType) {
            return detectLanguageFromDocx(url: url)
        }

        return nil
    }

    func detectLanguageFromPlainText(url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer {
            try? handle.close()
        }

        let maximumSampleSize = 8_192
        guard
            let data = try? handle.read(upToCount: maximumSampleSize),
            !data.isEmpty,
            let sample = String(data: data, encoding: .utf8),
            !sample.isEmpty
        else {
            return nil
        }

        return languageCode(from: sample)
    }

    func detectLanguageFromPDF(url: URL) -> String? {
        guard let document = PDFDocument(url: url) else {
            return nil
        }

        var sample = ""
        let maxPagesToSample = min(document.pageCount, 3)
        for index in 0..<maxPagesToSample {
            guard let page = document.page(at: index),
                  let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !pageText.isEmpty else {
                continue
            }
            sample.append(pageText)
            sample.append(" ")
            if sample.count >= 8_192 {
                break
            }
        }

        guard !sample.isEmpty else {
            return nil
        }

        if sample.count > 8_192 {
            let endIndex = sample.index(sample.startIndex, offsetBy: 8_192)
            sample = String(sample[..<endIndex])
        }

        return languageCode(from: sample)
    }

    func detectLanguageFromDocx(url: URL) -> String? {
        guard let attributedString = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) else {
            return nil
        }

        var sample = attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sample.isEmpty else {
            return nil
        }

        if sample.count > 8_192 {
            let endIndex = sample.index(sample.startIndex, offsetBy: 8_192)
            sample = String(sample[..<endIndex])
        }

        return languageCode(from: sample)
    }

    func languageCode(from sample: String) -> String? {
        guard !sample.isEmpty else {
            return nil
        }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(sample)
        return recognizer.dominantLanguage?.rawValue
    }

}

// MARK: - Supporting Types

private enum ImportError: LocalizedError {
    case languageUnsupported
    case emptyText

    var errorDescription: String? {
        switch self {
        case .languageUnsupported:
            return "The file language is not supported. Please import English text files."
        case .emptyText:
            return "Text cannot be empty. Paste some English text to save."
        }
    }
}

// MARK: - Paste Sheet

private struct PasteTextSheet: View {
    @Binding var text: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Paste or type the text you want to attach to this Space. Only English text is supported.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $text)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.secondary.opacity(0.2))
                    )
            }
            .padding()
            .navigationTitle("Paste Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
