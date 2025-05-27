import SwiftUI

struct PreferencesView: View {
    @Binding var isDarkMode: Bool?
    @EnvironmentObject var uiSettings: UISettings
    @Environment(\.dismiss) var dismiss
    var isPresentedAsSheet: Bool

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Appearance").font(.title3)) { // Dynamic Type for Section Header
                    Picker("Theme", selection: $isDarkMode) {
                        Text("System").tag(nil as Bool?); Text("Light").tag(false as Bool?); Text("Dark").tag(true as Bool?)
                    }
                    .pickerStyle(.segmented).frame(width: 250 * uiSettings.layoutScaleFactor)
                    // Text within picker segments generally scales with system settings
                }
                .padding(.bottom, uiSettings.padding(10))

                Section(header: Text("About").font(.title3)) { // Dynamic Type
                    HStack {
                        Text("WishCraft Version").font(.body) // Dynamic Type
                        Spacer()
                        Text("1.4.0").font(.body) // Dynamic Type
                    }
                }
            }
            .formStyle(.grouped)
            .font(.body) // Base font for form content, will scale with Dynamic Type

            if isPresentedAsSheet {
                let doneButtonPaddingSet = uiSettings.edgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }.font(.body).keyboardShortcut(.defaultAction) // Dynamic Type
                }
                .padding(doneButtonPaddingSet)
                .frame(height: 50 * uiSettings.layoutScaleFactor).background(Material.bar)
            }
        }
        .navigationTitle("Preferences") // Dynamic Type for navigation titles
        .frame(minWidth: 400 * uiSettings.layoutScaleFactor, idealWidth: 450 * uiSettings.layoutScaleFactor,
               minHeight: (isPresentedAsSheet ? 280 : 240) * uiSettings.layoutScaleFactor,
               idealHeight: (isPresentedAsSheet ? 320 : 270) * uiSettings.layoutScaleFactor)
        .onAppear {
            // When presented as a sheet, its local @AppStorage for uiSize might be stale
            // if changed via the main settings window. Binding picker to uiSettings.appSize directly handles this.
        }
    }
}
