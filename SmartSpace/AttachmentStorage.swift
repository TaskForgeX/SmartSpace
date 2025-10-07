//
//  AttachmentStorage.swift
//  SmartSpace
//
//  Created by Максим Гайдук on 06.10.2025.
//

import Foundation

enum AttachmentStorage {
    private static let directoryName = "Attachments"

    static func ensureDirectoryExists() throws {
        var directory = baseDirectoryURL
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try directory.setResourceValues(resourceValues)
        }
    }

    static func destinationURL(forStoredFileName fileName: String) -> URL {
        baseDirectoryURL.appendingPathComponent(fileName, isDirectory: false)
    }

    static func removeFile(named fileName: String) throws {
        let url = destinationURL(forStoredFileName: fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static var baseDirectoryURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(directoryName, isDirectory: true)
    }
}

extension SpaceAttachment {
    var fileURL: URL {
        AttachmentStorage.destinationURL(forStoredFileName: storedFileName)
    }
}
