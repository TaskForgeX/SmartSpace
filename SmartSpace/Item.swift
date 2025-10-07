//
//  SpaceModels.swift
//  SmartSpace
//
//  Created by Максим Гайдук on 06.10.2025.
//

import Foundation
import SwiftData

@Model
final class Space {
    var name: String
    var createdAt: Date
    var type: SpaceType
    var mode: SpaceMode

    var blocks: [SpaceBlock]?
    var attachments: [SpaceAttachment] = []

    init(name: String, createdAt: Date = .now, type: SpaceType, mode: SpaceMode) {
        self.name = name
        self.createdAt = createdAt
        self.type = type
        self.mode = mode
    }
}

@Model
final class SpaceBlock {
    var title: String
    var details: String
    var kind: BlockKind
    var createdAt: Date

    @Relationship(inverse: \Space.blocks)
    var space: Space?

    init(title: String, details: String, kind: BlockKind, createdAt: Date = .now) {
        self.title = title
        self.details = details
        self.kind = kind
        self.createdAt = createdAt
    }
}

@Model
final class SpaceAttachment {
    var originalFileName: String
    var storedFileName: String
    var languageCode: String?
    var addedAt: Date

    @Relationship(inverse: \Space.attachments)
    var space: Space?

    init(
        originalFileName: String,
        storedFileName: String,
        languageCode: String?,
        addedAt: Date = .now
    ) {
        self.originalFileName = originalFileName
        self.storedFileName = storedFileName
        self.languageCode = languageCode
        self.addedAt = addedAt
    }
}

extension Space {
    enum SpaceType: String, Codable, CaseIterable, Identifiable {
        case learning = "Learning"
        case languageLearning = "Language Learning"
        case timeManagement = "Time Management"
        case informationCompression = "Information Compression"
        case researchAssistant = "Research Assistant"
        case creativeWriting = "Creative Writing"
        case productivityDashboard = "Productivity Dashboard"
        case researchPlanner = "Research Planner"

        var id: String { rawValue }
    }

    enum SpaceMode: String, Codable, CaseIterable, Identifiable {
        case onDevice = "On-device"
        case privateCloudCompute = "Private Cloud Compute"

        var id: String { rawValue }
    }
}

extension SpaceBlock {
    enum BlockKind: String, Codable, CaseIterable, Identifiable {
        case summary = "Summary"
        case flashcards = "Flashcards"
        case mainQuestion = "Main Question"
        case keyTerms = "Key Terms"
        case timeline = "Timeline"
        case mindMap = "Mind Map"
        case quiz = "Quiz"
        case insights = "Insights"

        var id: String { rawValue }
    }
}
