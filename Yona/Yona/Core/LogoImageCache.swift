//
//  LogoImageCache.swift
//  Yona
//
//  In-memory decoded-logo cache (backed by the shared URLCache for bytes). The
//  grid fills it as it displays logos, so the detail screen can render the same
//  logo synchronously on its first frame — no AsyncImage load cycle, no flash.
//

import UIKit

enum LogoImageCache {
    private static let memory = NSCache<NSURL, UIImage>()

    /// In-memory only — fast, no decode. Safe to call during a view's body.
    static func inMemory(for url: URL) -> UIImage? {
        memory.object(forKey: url as NSURL)
    }

    /// Memory first, then decode from any cached bytes on disk. May be slower.
    static func image(for url: URL) -> UIImage? {
        if let cached = inMemory(for: url) { return cached }
        guard let data = URLCache.shared.cachedResponse(for: URLRequest(url: url))?.data,
              let image = UIImage(data: data) else { return nil }
        memory.setObject(image, forKey: url as NSURL)
        return image
    }

    static func store(_ image: UIImage, for url: URL) {
        memory.setObject(image, forKey: url as NSURL)
    }
}
