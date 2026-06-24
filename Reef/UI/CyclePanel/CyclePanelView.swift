//
//  CyclePanelView.swift
//  Reef
//
//  Window switcher panel UI
//

import SwiftUI

struct CyclePanelView: View {
    @ObservedObject var state: CyclePanelState
    var onActivate: (Int) -> Void = { _ in }

    private let headerPadding: Double = 10
    
    private func itemTitle(_ item: CyclePanelItem) -> String {
        switch item {
        case .window(let window):
            return window.title
        case .action(let action):
            return action.title
        }
    }

    private func itemThumbnail(_ item: CyclePanelItem) -> CGImage? {
        guard case let .window(window) = item, let windowID = window.cgWindowID else {
            return nil
        }

        return state.thumbnails[windowID]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: app icon + name.
            HStack(spacing: 8) {
                if let icon = state.applicationIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 22, height: 22)
                }

                Text(state.applicationTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.vertical, headerPadding)

            Divider()
            
            // Window list
            // Always a ScrollView: when everything fits it simply doesn't
            // scroll, and oversized lists get a scrollbar instead of clipping.
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(state.items.enumerated()), id: \.offset) { index, item in
                            CyclePanelRow(
                                title: itemTitle(item),
                                showsPreview: state.previewsEnabled,
                                thumbnail: itemThumbnail(item),
                                fallbackIcon: state.applicationIcon,
                                isSelected: index == state.selectedIndex
                            )
                            .id(index)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onActivate(index)
                            }
                        }
                    }
                    .padding(6)
                }
                .onChange(of: state.selectedIndex) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(state.selectedIndex, anchor: .center)
                    }
                }
            }

            // One-time hint on first auto mode open, pointing to Preferences.
            if state.showsAutoModeHint {
                Divider()

                HStack(spacing: 6) {
                    Button("Switch to Bindings mode in Preferences → General") {
                        state.dismissAutoModeHint()
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                    .buttonStyle(.link)
                    .font(.caption)

                    Spacer()

                    Button {
                        state.dismissAutoModeHint()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Don't show again")
                }
                .padding(.horizontal, 12)
                .frame(height: 26)
            }

            // Optional, dismissible nudge towards window previews. Kept out of
            // the cycle list: previews are taste, not a requirement.
            if state.showsPreviewHint {
                Divider()

                HStack(spacing: 6) {
                    Button("Enable window previews…") {
                        SystemSettingsPane.screenRecording.open()
                        state.dismissPreviewHint()
                    }
                    .buttonStyle(.link)
                    .font(.caption)

                    Spacer()

                    Button {
                        state.dismissPreviewHint()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Don't show again")
                }
                .padding(.horizontal, 12)
                .frame(height: 26)
            }
        }
        .frame(width: 400)
        .background(Color.clear)
    }
}

struct CyclePanelRow: View {
    let title: String
    let showsPreview: Bool
    let thumbnail: CGImage?
    let fallbackIcon: NSImage?
    let isSelected: Bool

    // Compact text-only rows when previews are off — the header
    // already shows the app icon.
    private var rowHeight: CGFloat { showsPreview ? 88 : 36 }
    private let previewSize = CGSize(width: 128, height: 80)

    var body: some View {
        HStack(spacing: 10) {
            if showsPreview {
                // Window preview; the app icon stands in until the
                // capture for this window arrives (or fails).
                Group {
                    if let thumbnail {
                        Image(decorative: thumbnail, scale: 2)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let fallbackIcon {
                        Image(nsImage: fallbackIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                    }
                }
                .frame(width: previewSize.width, height: previewSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.separator, lineWidth: thumbnail == nil ? 0 : 1)
                )
            }

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, showsPreview ? 8 : 12)
        .frame(height: rowHeight)
        .background(
            // Menu-style selection: solid accent pill with white text.
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
    }
}
