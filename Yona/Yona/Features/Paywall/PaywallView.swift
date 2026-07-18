//
//  PaywallView.swift
//  Yona
//
//  Shown when a free user tries to add a tile past the free limit (or taps Upgrade).
//  One-time unlock (no subscription). Price, purchase, and restore are driven by
//  RevenueCat via EntitlementStore; the sheet dismisses itself once Premium is active.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementStore.self) private var entitlement

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.l) {
                    header
                    benefits
                    priceCard
                    purchaseButton
                    Button("Restore Purchases") {
                        Task { await entitlement.restore() }
                    }
                    .font(.footnote)
                    .disabled(entitlement.isPurchasing)

                    Text(
                        "Yona is free for up to \(entitlement.freeTileLimit) subscriptions. " +
                        "Premium removes the limit — one payment, no recurring charge."
                    )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Not now") { dismiss() }
                        .disabled(entitlement.isPurchasing)
                }
            }
            // RevenueCat grants the entitlement asynchronously — dismiss once it lands
            // (covers purchase, restore, and unlocks synced from another device).
            .onChange(of: entitlement.isPremium) { _, isPremium in
                if isPremium { dismiss() }
            }
            .alert("Purchase failed", isPresented: errorBinding) {
                Button("OK", role: .cancel) { entitlement.purchaseError = nil }
            } message: {
                Text(entitlement.purchaseError ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: DesignTokens.Spacing.s) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Yona Premium")
                .font(.largeTitle.bold())
            Text("One payment. Unlock everything.")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, DesignTokens.Spacing.l)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            benefitRow("infinity", "Track as many subscriptions as you want")
            benefitRow("checkmark.seal.fill", "Everything in the free version — logos, costs, renewals, documents")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func benefitRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.m) {
            Image(systemName: icon).foregroundStyle(.tint).frame(width: 24)
            Text(text).font(.subheadline)
            Spacer(minLength: 0)
        }
    }

    private var priceCard: some View {
        VStack(spacing: 2) {
            // Real localized price from the store, or a placeholder while the offering loads.
            Text(entitlement.priceText ?? "—")
                .font(.largeTitle.bold())
                .redacted(reason: entitlement.priceText == nil ? .placeholder : [])
            Text("One-time purchase · no recurring charge")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                .fill(Color.accentColor.opacity(0.12))
        )
    }

    private var purchaseButton: some View {
        Button {
            Task { await entitlement.purchase() }
        } label: {
            HStack(spacing: DesignTokens.Spacing.s) {
                if entitlement.isPurchasing {
                    ProgressView().tint(.white)
                }
                Text("Unlock Everything")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(entitlement.isPurchasing || entitlement.unlockPackage == nil)
    }

    /// Bridges `entitlement.purchaseError` (a `String?`) to the alert's `isPresented` Bool.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { entitlement.purchaseError != nil },
            set: { if !$0 { entitlement.purchaseError = nil } }
        )
    }
}
