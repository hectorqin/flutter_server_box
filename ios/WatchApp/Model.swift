//
//  Model.swift
//  Runner
//  WatchApp
//
//  Created by lolli on 2023/9/14.
//

import Foundation

// 设计：
// 在手机操作 urls，数据存储在 watch 的 UserDefaults 中
// WatchAction: 用于 phone 给 watch 发送请求
// WatchReply: 用于 watch 给 phone 回复

enum WatchAction {
    case add(String)
    case delete(String)
    case read
    
    func toData() -> [String: Any] {
        switch self {
        case .add(let url):
            return ["type": "add", "url": url]
        case .delete(let url):
            return ["type": "delete", "url": url]
        case .read:
            return ["type": "read"]
        }
    }

    // From data to action
    static func fromData(_ data: [String: Any]) -> WatchAction? {
        // Check data, if value is not String, return nil
        guard let type = data["type"] as? String else {
            return nil
        }
        switch type {
        case "add":
            guard let url = data["url"] as? String else {
                return nil
            }
            return .add(url)
        case "delete":
            guard let url = data["url"] as? String else {
                return nil
            }
            return .delete(url)
        case "read":
            return .read
        default:
            return nil
        }
    }

    // Do action
    func doAction() -> WatchReply {
        switch self {
        case .add(let url):
            Database.add(url)
            return .ok
        case .delete(let url):
            Database.delete(url)
            return .ok
        case .read:
            return .urls(Database.urls)
        }
    }
}

enum WatchReply {
    case ok
    // Update urls of Phone.swift
    case urls([String])
    case fail(String)

    func toData() -> [String: Any] {
        switch self {
        case .ok:
            return [:]
        case .fail(let msg):
            return ["msg": msg]
        case .urls(let data):
            return ["urls": data]
        }
    }
    
    static func fromData(_ data: [String: Any]) -> WatchReply? {
        if let msg = data["msg"] as? String {
            return .fail(msg)
        }
        if let data = data["data"] as? [String] {
            return .urls(data)
        }
        return .ok
    }
}
