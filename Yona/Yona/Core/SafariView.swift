//
//  SafariView.swift
//  Yona
//
//  Thin SwiftUI wrapper around SFSafariViewController so "Open Website" opens
//  the page in-app rather than kicking out to Safari.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
