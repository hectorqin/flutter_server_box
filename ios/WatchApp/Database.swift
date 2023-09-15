//
//  Db.swift
//  WatchApp
//
//  Created by lolli on 2023/9/14.
//

import Foundation

class Database {
    static let _defaults = UserDefaults.standard
    static let _urlsKey = "urls"

    static var urls: [String] = _defaults.stringArray(forKey: _urlsKey) ?? []

    static func add(_ url: String) {
        self.urls.append(url)
        _defaults.set(urls, forKey: _urlsKey)
    }
    
    static func delete(_ url: String) {
        self.urls.removeAll { $0 == url }
        _defaults.set(urls, forKey: _urlsKey)
    }
}
