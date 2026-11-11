import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            PaperBackground(tint: Theme.paper).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("For grown-ups")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }
                toggleRow
                speedRow
                purchaseCard
                Button("Reset stars on this iPad") { confirmReset = true }
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.red)
                Text("Little Panda Chinese is made for children 3–6. No ads. No accounts. Stars stay on this iPad.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.65))
                Spacer()
            }
            .padding(28)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear { store.start() }
        .confirmationDialog("Reset stars?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset stars", role: .destructive) { progress.reset() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var toggleRow: some View {
        Toggle(isOn: $settings.musicEnabled) {
            Text("Music")
                .font(.system(size: 22, weight: .bold, design: .rounded))
        }
        .tint(Theme.green)
        .padding(16)
        .background(card)
    }

    private var speedRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Speaking speed")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Slider(value: $settings.speechRate, in: 0.34...0.52)
                .tint(Theme.red)
            Text("The Chinese voice is a placeholder until recorded lines are added.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.6))
        }
        .padding(16)
        .background(card)
    }

    private var purchaseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Episodes")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("The first two episodes are free. Unlock All is a one-time purchase for the rest, when those stories are ready.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.75))
            if store.isUnlockedAll {
                Text("All episodes are unlocked on this Apple ID.")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.green)
            } else if let product = store.unlockProduct {
                Button {
                    Task { await store.buy(product) }
                } label: {
                    Text(store.purchasing ? "Working…" : "Unlock all episodes · \(product.displayPrice)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.ink))
                }
                .disabled(store.purchasing)
            } else {
                Text("Unlock All will show here when the App Store product is available. You can still play the free episodes.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.75))
            }
            Button("Restore purchases") { Task { await store.restore() } }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.blue)
            if let error = store.lastError {
                Text(error)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.red)
            }
        }
        .padding(16)
        .background(card)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.ink.opacity(0.35), lineWidth: 2))
    }
}
