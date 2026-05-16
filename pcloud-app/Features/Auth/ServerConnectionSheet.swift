import SwiftUI

struct ServerConnectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @StateObject private var discovery = LocalServerDiscovery()
    @State private var draftBaseURL = ""
    @State private var draftDeviceID = ""
    @State private var manualErrorMessage: String?
    @State private var relayErrorMessage: String?

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        currentConnectionCard
                        relayDeviceCard
                        savedDevicesCard
                        manualURLCard
                        nearbyServersCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle(strings.connectServerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.cancel) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                draftBaseURL = settingsStore.apiBaseURLString
                draftDeviceID = settingsStore.selectedDeviceID ?? ""
                discovery.start()
            }
        }
    }

    private var currentConnectionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: connectionModeSystemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(AppPalette.softBlue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(connectionModeText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .lineLimit(1)

                Text(settingsStore.apiBaseURLString)
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .appCard(padding: 14)
    }

    private var relayDeviceCard: some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 12) {
            Label(strings.relayDevice, systemImage: "point.3.connected.trianglepath.dotted")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)

            TextField(strings.deviceID, text: $draftDeviceID)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppPalette.cardStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppPalette.stroke, lineWidth: 1)
                )

            if let relayErrorMessage {
                Text(relayErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                saveRelayDeviceID()
            } label: {
                Label(strings.useRelay, systemImage: "checkmark")
            }
            .buttonStyle(CompactConnectionButtonStyle())
        }
        .appCard(padding: 16)
    }

    @ViewBuilder
    private var savedDevicesCard: some View {
        let strings = settingsStore.strings

        if !settingsStore.savedServers.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Label(strings.savedDevices, systemImage: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                VStack(spacing: 10) {
                    ForEach(settingsStore.savedServers) { server in
                        savedServerRow(server)
                    }
                }
            }
            .appCard(padding: 16)
        }
    }

    private func savedServerRow(_ server: SavedPCloudServer) -> some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "externaldrive.connected.to.line.below")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(server.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .lineLimit(1)

                    Text(server.deviceID)
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                if server.lanBaseURLString != nil {
                    Button {
                        selectSaved(server, mode: .lan)
                    } label: {
                        Label(strings.useLAN, systemImage: "wifi")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CompactConnectionButtonStyle())
                }

                Button {
                    selectSaved(server, mode: .relay)
                } label: {
                    Label(strings.useRelay, systemImage: "point.3.connected.trianglepath.dotted")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CompactConnectionButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppPalette.cardStrong.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected(server) ? AppPalette.accent : AppPalette.stroke, lineWidth: 1)
        )
    }

    private var manualURLCard: some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 12) {
            Label(strings.manualServer, systemImage: "link")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)

            TextField(strings.apiBaseURL, text: $draftBaseURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppPalette.cardStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppPalette.stroke, lineWidth: 1)
                )

            if let manualErrorMessage {
                Text(manualErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                saveManualURL()
            } label: {
                Label(strings.save, systemImage: "checkmark")
            }
            .buttonStyle(CompactConnectionButtonStyle())
        }
        .appCard(padding: 16)
    }

    private var nearbyServersCard: some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(strings.nearbyServers, systemImage: "dot.radiowaves.left.and.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                Spacer()

                Button {
                    discovery.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AppPalette.cardStrong)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.refresh)
            }

            discoveryContent
        }
        .appCard(padding: 16)
    }

    @ViewBuilder
    private var discoveryContent: some View {
        let strings = settingsStore.strings

        if discovery.servers.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    if discovery.isSearching {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text(discovery.isSearching ? strings.searchingNearbyServers : strings.noNearbyServers)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppPalette.textPrimary)
                }

                if let errorMessage = discovery.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: 10) {
                ForEach(discovery.servers) { server in
                    serverRow(server)
                }
            }
        }
    }

    private func serverRow(_ server: DiscoveredPCloudServer) -> some View {
        let strings = settingsStore.strings

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "externaldrive.connected.to.line.below")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(server.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                        .lineLimit(1)

                    Text(server.displayHost)
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                        .lineLimit(1)

                    if let deviceID = server.deviceID {
                        Text(deviceID)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppPalette.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(server.canUseRelay ? strings.relayReady : strings.relayUnavailable)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppPalette.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(server.canUseRelay ? AppPalette.accent.opacity(0.22) : AppPalette.softBlue)
                    )
            }

            HStack(spacing: 8) {
                Button {
                    select(server, mode: .lan)
                } label: {
                    Label(strings.useLAN, systemImage: "wifi")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CompactConnectionButtonStyle())

                Button {
                    select(server, mode: .relay)
                } label: {
                    Label(strings.useRelay, systemImage: "point.3.connected.trianglepath.dotted")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CompactConnectionButtonStyle(isProminent: server.canUseRelay))
                .disabled(!server.canUseRelay)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppPalette.cardStrong.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected(server) ? AppPalette.accent : AppPalette.stroke, lineWidth: 1)
        )
    }

    private var connectionModeText: String {
        let strings = settingsStore.strings

        switch settingsStore.serverConnectionMode {
        case .manual:
            return settingsStore.selectedServerName ?? strings.selectedManualServer
        case .lan:
            return settingsStore.selectedServerName.map { "\($0) · \(strings.selectedViaLAN)" }
                ?? strings.selectedViaLAN
        case .relay:
            return settingsStore.selectedServerName.map { "\($0) · \(strings.selectedViaRelay)" }
                ?? strings.selectedViaRelay
        }
    }

    private var connectionModeSystemImage: String {
        switch settingsStore.serverConnectionMode {
        case .manual:
            return "link"
        case .lan:
            return "wifi"
        case .relay:
            return "point.3.connected.trianglepath.dotted"
        }
    }

    private func saveManualURL() {
        do {
            try settingsStore.updateAPIBaseURL(draftBaseURL)
            manualErrorMessage = nil
            dismiss()
        } catch {
            manualErrorMessage = error.localizedDescription
        }
    }

    private func saveRelayDeviceID() {
        do {
            try settingsStore.updateRelayDeviceID(draftDeviceID)
            relayErrorMessage = nil
            dismiss()
        } catch {
            relayErrorMessage = error.localizedDescription
        }
    }

    private func select(_ server: DiscoveredPCloudServer, mode: ServerConnectionMode) {
        do {
            try settingsStore.updateDiscoveredServer(server, mode: mode)
            relayErrorMessage = nil
            dismiss()
        } catch {
            relayErrorMessage = error.localizedDescription
        }
    }

    private func selectSaved(_ server: SavedPCloudServer, mode: ServerConnectionMode) {
        do {
            try settingsStore.updateSavedServer(server, mode: mode)
            relayErrorMessage = nil
            dismiss()
        } catch {
            relayErrorMessage = error.localizedDescription
        }
    }

    private func isSelected(_ server: DiscoveredPCloudServer) -> Bool {
        settingsStore.apiBaseURLString == server.apiBaseURLString
            || settingsStore.apiBaseURLString == server.relayURLString
    }

    private func isSelected(_ server: SavedPCloudServer) -> Bool {
        settingsStore.apiBaseURLString == server.lanBaseURLString
            || settingsStore.apiBaseURLString == server.relayURLString
    }
}

private struct CompactConnectionButtonStyle: ButtonStyle {
    var isProminent = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .foregroundStyle(AppPalette.textPrimary)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isProminent ? AppPalette.accent.opacity(0.28) : AppPalette.softBlue)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppPalette.stroke, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
