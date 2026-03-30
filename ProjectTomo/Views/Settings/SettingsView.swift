import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @State private var notificationsEnabled = false
    @State private var debugLogExpanded = false
    @Environment(\.dismiss) private var dismiss

    private var debugLog: DebugLogStore { .shared }

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                notificationsSection
                debugLogSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .tomoBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(TomoTheme.tomoTitle)
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker("Appearance", selection: Binding(
                get: { AppearanceMode(rawValue: appearanceMode) ?? .system },
                set: { appearanceMode = $0.rawValue }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(TomoTheme.cardFill)
        } header: {
            Text("Appearance")
        }
    }

    private var notificationsSection: some View {
        Section {
            HStack {
                Toggle("Push Notifications", isOn: $notificationsEnabled)
                    .tint(TomoTheme.tomoTitle)
                    .disabled(true)
            }
            .listRowBackground(TomoTheme.cardFill)

            Text("Coming soon")
                .font(TomoTheme.captionFont)
                .foregroundStyle(TomoTheme.secondaryText)
                .listRowBackground(TomoTheme.cardFill)
        } header: {
            Text("Notifications")
        }
    }

    private var debugLogSection: some View {
        Section {
            DisclosureGroup(isExpanded: $debugLogExpanded) {
                if debugLog.entries.isEmpty {
                    Text("No log entries yet. Add a story to trigger LLM detection.")
                        .font(TomoTheme.captionFont)
                        .foregroundStyle(TomoTheme.secondaryText)
                        .padding(.vertical, 8)
                } else {
                    ForEach(debugLog.entries) { entry in
                        logEntryRow(entry)
                    }

                    Button {
                        debugLog.clear()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Clear Log")
                                .font(TomoTheme.smallActionFont)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                }
            } label: {
                HStack {
                    Text("API Debug Log")
                    Spacer()
                    if !debugLog.entries.isEmpty {
                        Text("\(debugLog.entries.count)")
                            .font(TomoTheme.captionFont)
                            .foregroundStyle(TomoTheme.pageBackground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(TomoTheme.secondaryText))
                    }
                }
            }
            .listRowBackground(TomoTheme.cardFill)
        } header: {
            Text("Debug")
        }
    }

    private func logEntryRow(_ entry: LogEntry) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconForLevel(entry.level))
                .font(.system(size: 11))
                .foregroundStyle(colorForLevel(entry.level))
                .frame(width: 16)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.formattedTimestamp)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(TomoTheme.secondaryText)
                Text(entry.message)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(colorForLevel(entry.level))
                    .lineLimit(4)
            }
        }
        .padding(.vertical, 2)
        .listRowBackground(TomoTheme.cardFill)
    }

    private func iconForLevel(_ level: LogLevel) -> String {
        switch level {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    private func colorForLevel(_ level: LogLevel) -> Color {
        switch level {
        case .info: return TomoTheme.secondaryText
        case .warning: return .orange
        case .error: return .red
        }
    }
}
