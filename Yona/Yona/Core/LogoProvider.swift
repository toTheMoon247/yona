//
//  LogoProvider.swift
//  Yona
//
//  Builds Brandfetch Logo API URLs from a tile's website. Returns nil when there's
//  no usable domain or no client ID — callers then show the letter-tile fallback.
//  `fallback/404` makes Brandfetch 404 on a miss so the image load fails cleanly.
//

import Foundation

enum LogoProvider {
    /// A Brandfetch icon URL for the given website, or nil if we can't build one.
    static func logoURL(forWebsite website: String, size: Int = 128) -> URL? {
        guard let domain = URLHelpers.domain(from: website),
              let clientID = AppConfig.shared.brandfetchClientID else {
            return nil
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "cdn.brandfetch.io"
        components.path = "/\(domain)/icon/fallback/404/w/\(size)/h/\(size)"
        components.queryItems = [URLQueryItem(name: "c", value: clientID)]
        return components.url
    }
}
