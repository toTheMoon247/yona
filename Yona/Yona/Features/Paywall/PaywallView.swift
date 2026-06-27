//
//  PaywallView.swift
//  Yona
//
//  Shown when a free user tries to add a tile past the free limit (or taps Upgrade).
//  Prices/plans are placeholders until RevenueCat + store products are configured;
//  the purchase action is a DEBUG dev-unlock for now and becomes a real purchase later.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementStore.self) private var entitlement

    enum Plan: Hashable { case yearly, lifetime }
    @State private var selectedPlan: Plan = .yearly

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.l) {
                    header
                    benefits
                    plans
                    purchaseButton
                    Button("Restore Purchases") { /* TODO: RevenueCat restore */ }
                        .font(.footnote)

                    Text(
                        "Yona is free for up to \(entitlement.freeTileLimit) subscriptions. " +
                        "Premium adds unlimited subscriptions. Cancel anytime."
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
                }
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
            Text("Track unlimited subscriptions")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, DesignTokens.Spacing.l)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            benefitRow("infinity", "Unlimited subscriptions (free includes \(entitlement.freeTileLimit))")
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

    private var plans: some View {
        VStack(spacing: DesignTokens.Spacing.m) {
            planCard(.yearly, title: "Yearly", price: "$1.99 / year", note: "Billed annually")
            planCard(.lifetime, title: "Lifetime", price: "$4.99 once", note: "Pay once, yours forever")
        }
    }

    private func planCard(_ plan: Plan, title: String, price: String, note: String) -> some View {
        let selected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(price).font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                    .fill(selected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var purchaseButton: some View {
        Button {
            purchase()
        } label: {
            Text(selectedPlan == .lifetime ? "Unlock Lifetime" : "Start Yearly")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private func purchase() {
        if AppBuild.usesMockPurchases {
            // Mock unlock in Debug + TestFlight so testers can go past the free limit.
            // App Store production falls through to the real purchase path below.
            entitlement.setDevPremium(true)
            dismiss()
        } else {
            // TODO: real purchase via RevenueCat (selectedPlan).
        }
    }
}
