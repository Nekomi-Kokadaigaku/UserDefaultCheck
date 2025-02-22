//
//  ContentView.swift
//  UserDefaultChecker
//
//  Created by Iris on 2025-02-23.
//

import SwiftUI

struct ContentView: View {
    // 获取 UserDefaults 中所有的键值对
    var userDefaultsDictionary: [String: Any] {
        UserDefaults.standard.dictionaryRepresentation()
    }

    @State private var selectedKey: String?

    var body: some View {
        NavigationView {
            List(
                userDefaultsDictionary.sorted(by: { $0.key < $1.key }),
                id: \.key
            ) { key, value in
                NavigationLink(
                    destination: DetailView(key: key, value: value),
                    tag: key,
                    selection: $selectedKey
                ) {
                    VStack {
                        Text(key)
                            .font(.headline)
                        Spacer()
                        Text(formatValue(value))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(4)
                }
            }
            .navigationTitle("User Defaults 内容")

            // 初始详情视图
            Text("选择一个配置项查看详情")
                .foregroundColor(.secondary)
        }
    }

    private func formatValue(_ value: Any) -> String {
        switch value {
        case let array as [Any]:
            return "[\(array.count) 个项目]"
        case let dict as [String: Any]:
            return "{\(dict.count) 个键值对}"
        case let data as Data:
            return "Data(\(data.count) bytes)"
        default:
            return String(describing: value)
        }
    }
}

struct DetailView: View {
    let key: String
    let value: Any

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("键名: \(key)")
                    .font(.headline)

                Text("类型: \(String(describing: type(of: value)))")
                    .font(.subheadline)

                Text("值:")
                    .font(.headline)
                Text(String(describing: value))
                    .font(.body)
                    .textSelection(.enabled)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(key)
    }
}

#Preview {
    ContentView()
}
