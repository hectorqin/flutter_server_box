//
//  ContentView.swift
//  WatchApp Watch App
//
//  Created by lolli on 2023/9/14.
//

import SwiftUI

let _mgr = PhoneConnMgr()

struct ContentView: View {
    let _count = _mgr.urls.count == 0 ? 1 : _mgr.urls.count
    var body: some View {
        TabView {
            ForEach(0 ..< _count, id:\.self) { index in
                PageView(index: index, state: .loading)
            }
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

struct PageView: View {
    var index: Int
    @State var state: ContentState
    
    var body: some View {
        if index == 0 && _mgr.urls.count == 0 {
            VStack {
                Text("Use iOS app to config")
                    .padding()
            }
        } else {
            switch state {
            case .loading:
                ProgressView().padding().onAppear {
                    getStatus(url: _mgr.urls[index])
                }
            case .error(let string):
                Text(string).padding()
            case .normal(let status):
                VStack(alignment: .leading) {
                    HStack {
                        Text(status.name).font(.system(.title))
                        Spacer()
                        Button(action: {
                            state = .loading
                        }){
                            Image(systemName: "arrow.clockwise")
                        }.buttonStyle(.plain)
                    }
                    Spacer()
                    DetailItem(icon: "cpu", text: status.cpu)
                    DetailItem(icon: "memorychip", text: status.mem)
                    DetailItem(icon: "externaldrive", text: status.disk)
                    DetailItem(icon: "network", text: status.net)
                }.frame(maxWidth: .infinity, maxHeight: .infinity).padding([.horizontal], 7)
            }
        }
    }
    
    func getStatus(url: String) {
        state = .loading
        if url.count < 12 {
            state = .error("url is too short")
            return
        }
        guard let url = URL(string: url) else {
            state = .error("url is invalid")
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                state = .error(error!.localizedDescription)
                return
            }
            guard let data = data else {
                state = .error("data is nil")
                return
            }
            guard let jsonAll = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                state = .error("json parse fail")
                return
            }
            guard let code = jsonAll["code"] as? Int else {
                state = .error("code is nil")
                return
            }
            if (code != 0) {
                let msg = jsonAll["msg"] as? String ?? ""
                state = .error(msg)
                return
            }

            let json = jsonAll["data"] as? [String: Any] ?? [:]
            let name = json["name"] as? String ?? ""
            let disk = json["disk"] as? String ?? ""
            let cpu = json["cpu"] as? String ?? ""
            let mem = json["mem"] as? String ?? ""
            let net = json["net"] as? String ?? ""
            state = .normal(Status(name: name, cpu: cpu, mem: mem, disk: disk, net: net))
        }
        task.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct DetailItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 5.7) {
            Image(systemName: icon).resizable().foregroundColor(.white).frame(width: 11, height: 11, alignment: .center)
            Text(text)
                .font(.system(.caption2))
                .foregroundColor(.white)
        }
    }
}

enum ContentState {
    case loading
    case error(String)
    case normal(Status)
}

struct Status {
    let name: String
    let cpu: String
    let mem: String
    let disk: String
    let net: String
}
