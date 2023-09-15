//
//  Conn.swift
//  WatchApp
//
//  Created by lolli on 2023/9/15.
//

import Foundation
import WatchConnectivity

class PhoneConnMgr: NSObject, WCSessionDelegate {
    var session: WCSession?
    var urls: [String] {
        get {
            let appCtx = session?.applicationContext ?? [:]
            return appCtx["urls"] as? [String] ?? []
        }
    }
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // Send message to watch
    func sendToWatch(_ action: WatchAction) {
        guard WCSession.isSupported() else {
            return
        }
        
        session?.sendMessage(action.toData()) { result in
            guard let reply = WatchReply.fromData(result) else {
                print("Send to app fail: WatchReply is nil, raw: \(result)")
                return
            }
            switch reply {
            case .ok:
                print("Send to app success")
            case .fail(let msg):
                print("Send to app fail: \(msg)")
            case .urls(_):
                // Pass
                break
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let action = WatchAction.fromData(message) else {
            replyHandler(WatchReply.fail("WatchAction is nil, raw: \(message)").toData())
            return
        }

        replyHandler(action.doAction().toData())
    }
}

