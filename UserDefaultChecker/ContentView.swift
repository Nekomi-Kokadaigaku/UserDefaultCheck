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

  @State private var searchText = ""
  @State private var selectedKey: String?

  var filteredItems: [(key: String, value: Any)] {
    let items = userDefaultsDictionary.sorted(by: { $0.key < $1.key })
    if searchText.isEmpty {
      return items
    }
    return items.filter { item in
      // 搜索键名
      if item.key.localizedCaseInsensitiveContains(searchText) {
        return true
      }

      // 搜索值类型
      let typeString = String(describing: type(of: item.value))
      if typeString.localizedCaseInsensitiveContains(searchText) {
        return true
      }

      // 搜索值内容
      switch item.value {
      case let array as [Any]:
        // 搜索数组中的每个元素
        return array.contains { element in
          String(describing: element)
            .localizedCaseInsensitiveContains(searchText)
        }
      case let dict as [String: Any]:
        // 搜索字典中的键和值
        return dict.contains { (k, v) in
          k.localizedCaseInsensitiveContains(searchText)
            || String(describing: v)
              .localizedCaseInsensitiveContains(searchText)
        }
      case let string as String:
        return string.localizedCaseInsensitiveContains(searchText)
      default:
        return String(describing: item.value)
          .localizedCaseInsensitiveContains(searchText)
      }
    }
  }

  var body: some View {
    NavigationSplitView {
      List(filteredItems, id: \.key, selection: $selectedKey) { item in
        VStack(alignment: .leading) {
          Text(item.key)
            .font(.headline)
          Text(formatValue(item.value))
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
        .padding(4)
      }
      .navigationTitle("User Defaults 内容")
      .searchable(text: $searchText, prompt: "搜索键名")
    } detail: {
      if let selectedKey,
        let value = userDefaultsDictionary[selectedKey]
      {
        DetailView(key: selectedKey, value: value)
      } else {
        Text("请选择一个键查看详情")
          .foregroundColor(.secondary)
      }
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
  @State private var isEditing = false
  @State private var editedValue: Any?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("键名: \(key)")
            .font(.headline)
          Spacer()
          Button(isEditing ? "完成" : "编辑") {
            if isEditing {
              saveChanges()
            }
            isEditing.toggle()
          }
        }

        Text("类型: \(String(describing: type(of: value)))")
          .font(.subheadline)

        Text("值:")
          .font(.headline)

        if isEditing {
          EditValueView(value: value, editedValue: $editedValue)
        } else {
          Text(String(describing: value))
            .font(.body)
            .textSelection(.enabled)
        }
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .navigationTitle(key)
  }

  private func saveChanges() {
    guard let newValue = editedValue else { return }
    UserDefaults.standard.set(newValue, forKey: key)
  }
}

struct EditValueView: View {
  let value: Any
  @Binding var editedValue: Any?

  var body: some View {
    Group {
      switch value {
      case is String:
        StringEditor(value: value as! String) { newValue in
          editedValue = newValue
        }
      case is Int:
        IntEditor(value: value as! Int) { newValue in
          editedValue = newValue
        }
      case is Bool:
        BoolEditor(value: value as! Bool) { newValue in
          editedValue = newValue
        }
      case is [Any]:
        ArrayEditor(value: value as! [Any]) { newValue in
          editedValue = newValue
        }
      case is [String: Any]:
        DictionaryEditor(value: value as! [String: Any]) { newValue in
          editedValue = newValue
        }
      case is Data:
        DataEditor(value: value as! Data) { newValue in
          editedValue = newValue
        }
      default:
        Text("不支持编辑此类型")
          .foregroundColor(.red)
      }
    }
  }
}

struct StringEditor: View {
  let value: String
  let onEdit: (String) -> Void
  @State private var text: String

  init(value: String, onEdit: @escaping (String) -> Void) {
    self.value = value
    self.onEdit = onEdit
    _text = State(initialValue: value)
  }

  var body: some View {
    TextEditor(text: $text)
      .frame(height: 100)
      .onChange(of: text) { _, newValue in
        onEdit(newValue)
      }
  }
}

struct IntEditor: View {
  let value: Int
  let onEdit: (Int) -> Void
  @State private var text: String

  init(value: Int, onEdit: @escaping (Int) -> Void) {
    self.value = value
    self.onEdit = onEdit
    _text = State(initialValue: String(value))
  }

  var body: some View {
    TextField("数值", text: $text)
      //      .keyboardType(.numberPad)
      .onChange(of: text) { _, newValue in
        if let number = Int(newValue) {
          onEdit(number)
        }
      }
  }
}

struct BoolEditor: View {
  let value: Bool
  let onEdit: (Bool) -> Void

  var body: some View {
    Toggle(
      "值",
      isOn: Binding(
        get: { value },
        set: { onEdit($0) }
      ))
  }
}

struct ArrayEditor: View {
  let value: [Any]
  let onEdit: ([Any]) -> Void
  @State private var items: [String]

  init(value: [Any], onEdit: @escaping ([Any]) -> Void) {
    self.value = value
    self.onEdit = onEdit
    _items = State(initialValue: value.map { String(describing: $0) })
  }

  var body: some View {
    VStack {
      ForEach(items.indices, id: \.self) { index in
        TextField(
          "项目 \(index + 1)",
          text: Binding(
            get: { items[index] },
            set: { newValue in
              items[index] = newValue
              onEdit(items.map { $0 })
            }
          ))
      }
      Button("添加项目") {
        items.append("")
        onEdit(items.map { $0 })
      }
    }
  }
}

struct DictionaryEditor: View {
  let value: [String: Any]
  let onEdit: ([String: Any]) -> Void
  @State private var keys: [String]
  @State private var values: [String]

  init(value: [String: Any], onEdit: @escaping ([String: Any]) -> Void) {
    self.value = value
    self.onEdit = onEdit
    _keys = State(initialValue: Array(value.keys))
    _values = State(
      initialValue: Array(value.values.map { String(describing: $0) }))
  }

  var body: some View {
    VStack {
      ForEach(keys.indices, id: \.self) { index in
        HStack {
          TextField(
            "键",
            text: Binding(
              get: { keys[index] },
              set: { newValue in
                keys[index] = newValue
                onEdit(
                  Dictionary(
                    uniqueKeysWithValues: zip(
                      keys, values.map { $0 }))
                )
              }
            ))
          TextField(
            "值",
            text: Binding(
              get: { values[index] },
              set: { newValue in
                values[index] = newValue
                onEdit(
                  Dictionary(
                    uniqueKeysWithValues: zip(
                      keys, values.map { $0 }))
                )
              }
            ))
        }
      }
      Button("添加键值对") {
        keys.append("")
        values.append("")
        onEdit(
          Dictionary(
            uniqueKeysWithValues: zip(keys, values.map { $0 }))
        )
      }
    }
  }
}

struct DataEditor: View {
  let value: Data
  let onEdit: (Data) -> Void
  @State private var text: String

  init(value: Data, onEdit: @escaping (Data) -> Void) {
    self.value = value
    self.onEdit = onEdit
    _text = State(initialValue: String(describing: value))
  }

  var body: some View {
    TextEditor(text: $text)
      .frame(height: 100)
      .onChange(of: text) { _, newValue in
        if let data = newValue.data(using: .utf8) {
          onEdit(data)
        }
      }
  }
}

#Preview {
  ContentView()
}
