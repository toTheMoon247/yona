//
//  LoadState.swift
//  Yona
//
//  One enum that every screen uses to render loading / empty / error / content,
//  so "online-only" never means a silent blank screen.
//

import Foundation

enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(Error)

    var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var error: Error? {
        if case let .failed(error) = self { return error }
        return nil
    }
}
