//
//  LogoImageCache.swift
//  Yona
//
//  Small in-memory decoded-logo cache, backed by the shared URLCache for bytes.
//  Lets a logo that's already been fetched (e.g. on the grid) render synchronously
//  on the detail screen — no AsyncImage load cycle, so no placeholder flash.
//

import UIKit

enum LogoImageCache {
    private static let memory = NSCache<NSURL, UIImage>()

    /// The decoded logo for `url` if we already have its bytes cached, else nil.
    static func image(for url: URL) -> UIImage? {
        let key = url as NSURL
        if let cached = memory.object(forKey: key) {
            return cached
        }
        guard let data = URLCache.shared.cachedResponse(for: URLRequest(url: url))?.data,
              let image = UIImage(data: data) else {
            return nil
        }
        memory.setObject(image, forKey: key)
        return image
    }
}
