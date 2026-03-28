import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: AppSettingsStore

    @State private var draftBaseURL = ""
    @State private var errorMessage: String?

    var body: some View {
        let strings = settingsStore.strings

        NavigationStack {
            Form {
                Section {
                    TextField(strings.apiBaseURL, text: $draftBaseURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text(strings.server)
                }

                Section {
                    Text(strings.serverNotes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(strings.notes)
                }
            }
            .navigationTitle(strings.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(strings.save) {
                        do {
                            try settingsStore.updateAPIBaseURL(draftBaseURL)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .onAppear {
                draftBaseURL = settingsStore.apiBaseURLString
            }
        }
    }
}
