//
//  SpaceUIComponents.swift
//  SmartSpace
//
//  Created by Максим Гайдук on 06.10.2025.
//

import SwiftUI

enum LayoutStyle: Equatable {
    case grid
    case list

    var iconName: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }

    mutating func toggle() {
        self = (self == .grid) ? .list : .grid
    }
}

struct SpaceCard: View {
    let space: Space
    let layout: LayoutStyle

    var body: some View {
        HStack(spacing: 16) {
            artworkPlaceholder
            VStack(alignment: .leading, spacing: spacing) {
                Text(space.name)
                    .font(.headline)
                if layout == .grid {
                    Text(space.type.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Label(space.mode.rawValue, systemImage: space.mode == .onDevice ? "iphone" : "cloud")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(space.type.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Label(space.mode.rawValue, systemImage: space.mode == .onDevice ? "iphone" : "cloud")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
            .foregroundStyle(Color.secondary.opacity(0.4))
            .frame(width: layout == .grid ? 72 : 64, height: layout == .grid ? 72 : 64)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: layout == .grid ? 28 : 24))
                    .foregroundStyle(.secondary)
            }
            .accessibilityHidden(true)
    }

    private var spacing: CGFloat {
        layout == .grid ? 12 : 8
    }

    private var padding: CGFloat {
        layout == .grid ? 20 : 16
    }

    private var accessibilityDescription: String {
        var components: [String] = [
            "Space \(space.name)",
            "type \(space.type.rawValue)"
        ]

        if layout == .grid {
            components.append("mode \(space.mode.rawValue)")
        } else {
            components.append("mode \(space.mode.rawValue)")
        }

        return components.joined(separator: ", ")
    }
}

struct EmptySpaceState: View {
    var body: some View {
        ContentUnavailableView {
            Label("No spaces yet", systemImage: "rectangle.on.rectangle.angled")
        } description: {
            Text("Tap \"Add new space\" below to create your first Space and start organizing your knowledge.")
        }
    }
}
