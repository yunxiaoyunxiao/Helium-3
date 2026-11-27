//
//  HeliumShortcuts.swift
//  Helium-3
//
//  Shortcuts integration for Helium.
//  Upstream project license: GPL-3.0; see LICENSE.
//

import Foundation
import AppIntents
import CoreFoundation

private enum HeliumShortcutStore {
    static let preferencesPath = "/var/mobile/Library/Preferences/com.leemin.helium.plist"
    static let widgetSetsKey = "widgetProperties"
    static let reloadNotification = "com.leemin.notification.hud.reload"

    static func readPreferences() throws -> [String: Any] {
        let url = URL(fileURLWithPath: preferencesPath)
        guard FileManager.default.fileExists(atPath: preferencesPath) else { return [:] }
        let data = try Data(contentsOf: url)
        guard let values = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            throw ShortcutError.invalidPreferences
        }
        return values
    }

    static func readWidgetSets() throws -> [[String: Any]] {
        let values = try readPreferences()
        return values[widgetSetsKey] as? [[String: Any]] ?? []
    }

    static func setWidgetSets(_ sets: [[String: Any]]) throws {
        // Reuse the project's existing plist writer so unrelated preference keys
        // and the original file handling behavior remain unchanged.
        if sets.isEmpty {
            UserDefaults.standard.removeObject(forKey: widgetSetsKey, forPath: preferencesPath)
        } else {
            UserDefaults.standard.setValue(sets, forKey: widgetSetsKey, forPath: preferencesPath)
        }

        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(reloadNotification as CFString),
            nil,
            nil,
            true
        )
    }

    static func matchingIndex(title: String, in sets: [[String: Any]]) -> Int? {
        sets.firstIndex { ($0["title"] as? String) == title }
    }

    enum ShortcutError: LocalizedError {
        case invalidPreferences
        case widgetSetNotFound(String)
        case invalidValue(String)

        var errorDescription: String? {
            switch self {
            case .invalidPreferences:
                return "Helium 配置文件格式无效。"
            case .widgetSetNotFound(let title):
                return "找不到名为「\(title)」的小部件集。"
            case .invalidValue(let key):
                return "参数值无效：\(key)"
            }
        }
    }
}

@available(iOS 16.0, *)
struct HeliumControlHUDIntent: AppIntent {
    static var title: LocalizedStringResource = "控制 Helium HUD"
    static var description = IntentDescription("开启、关闭、切换或查询 Helium HUD 总开关。")
    static var openAppWhenRun = false

    @Parameter(title: "操作", default: "status")
    var action: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let normalized = action.lowercased()
        let enabled = IsHUDEnabledBridger()
        switch normalized {
        case "on", "开启":
            SetHUDEnabledBridger(true)
            return .result(value: "Helium HUD 已开启")
        case "off", "关闭":
            SetHUDEnabledBridger(false)
            return .result(value: "Helium HUD 已关闭")
        case "toggle", "切换":
            SetHUDEnabledBridger(!enabled)
            return .result(value: !enabled ? "Helium HUD 已开启" : "Helium HUD 已关闭")
        case "status", "状态":
            return .result(value: enabled ? "Helium HUD 当前已开启" : "Helium HUD 当前已关闭")
        default:
            throw HeliumShortcutStore.ShortcutError.invalidValue("操作")
        }
    }
}

@available(iOS 16.0, *)
struct HeliumListWidgetSetsIntent: AppIntent {
    static var title: LocalizedStringResource = "列出 Helium 小部件集"
    static var description = IntentDescription("读取全部小部件集名称及启用状态。")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let sets = try HeliumShortcutStore.readWidgetSets()
        let lines = sets.enumerated().map { index, set in
            let title = set["title"] as? String ?? "未命名"
            let enabled = set["isEnabled"] as? Bool ?? true
            return "\(index + 1). \(title) — \(enabled ? "已启用" : "已停用")"
        }
        return .result(value: lines)
    }
}

@available(iOS 16.0, *)
struct HeliumGetWidgetSetIntent: AppIntent {
    static var title: LocalizedStringResource = "读取 Helium 小部件集配置"
    static var description = IntentDescription("读取指定小部件集的布局和显示配置。")
    static var openAppWhenRun = false

    @Parameter(title: "小部件集标题")
    var title: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let sets = try HeliumShortcutStore.readWidgetSets()
        guard let index = HeliumShortcutStore.matchingIndex(title: title, in: sets) else {
            throw HeliumShortcutStore.ShortcutError.widgetSetNotFound(title)
        }
        let set = sets[index]
        let keys = [
            "title", "isEnabled", "orientationMode", "updateInterval",
            "anchor", "anchorY", "offsetPX", "offsetPY", "offsetLX", "offsetLY",
            "autoResizes", "scale", "scaleY"
        ]
        let details = keys.compactMap { key -> String? in
            guard let value = set[key] else { return nil }
            return "\(key): \(value)"
        }
        return .result(value: details.joined(separator: "\n"))
    }
}

@available(iOS 16.0, *)
struct HeliumSetWidgetSetEnabledIntent: AppIntent {
    static var title: LocalizedStringResource = "启用或停用 Helium 小部件集"
    static var description = IntentDescription("只修改指定小部件集的启用状态，不改变 HUD 总开关。")
    static var openAppWhenRun = false

    @Parameter(title: "小部件集标题")
    var title: String

    @Parameter(title: "操作（on/off/toggle）", default: "toggle")
    var action: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        var sets = try HeliumShortcutStore.readWidgetSets()
        guard let index = HeliumShortcutStore.matchingIndex(title: title, in: sets) else {
            throw HeliumShortcutStore.ShortcutError.widgetSetNotFound(title)
        }

        let currentValue = sets[index]["isEnabled"] as? Bool ?? true
        let newValue: Bool
        switch action.lowercased() {
        case "on", "开启":
            newValue = true
        case "off", "关闭":
            newValue = false
        case "toggle", "切换":
            newValue = !currentValue
        default:
            throw HeliumShortcutStore.ShortcutError.invalidValue("操作")
        }

        sets[index]["isEnabled"] = newValue
        try HeliumShortcutStore.setWidgetSets(sets)
        let state = newValue ? "已启用" : "已停用"
        return .result(value: "「\(title)」\(state)；HUD 总开关未改变。")
    }
}

@available(iOS 16.0, *)
struct HeliumUpdateWidgetSetIntent: AppIntent {
    static var title: LocalizedStringResource = "更新 Helium 小部件集"
    static var description = IntentDescription("仅更新提供的字段；未提供的字段保持原值。")
    static var openAppWhenRun = false

    @Parameter(title: "小部件集标题")
    var targetTitle: String

    @Parameter(title: "新标题")
    var newTitle: String?

    @Parameter(title: "显示模式（orientationMode）")
    var orientationMode: Int?

    @Parameter(title: "更新间隔（秒）")
    var updateInterval: Double?

    @Parameter(title: "水平定位（anchor）")
    var anchor: Int?

    @Parameter(title: "垂直定位（anchorY）")
    var anchorY: Int?

    @Parameter(title: "竖屏 X 偏移")
    var offsetPX: Double?

    @Parameter(title: "竖屏 Y 偏移")
    var offsetPY: Double?

    @Parameter(title: "横屏 X 偏移")
    var offsetLX: Double?

    @Parameter(title: "横屏 Y 偏移")
    var offsetLY: Double?

    @Parameter(title: "自动调整尺寸")
    var autoResizes: Bool?

    @Parameter(title: "宽度/缩放")
    var scale: Double?

    @Parameter(title: "高度/缩放")
    var scaleY: Double?

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        var sets = try HeliumShortcutStore.readWidgetSets()
        guard let index = HeliumShortcutStore.matchingIndex(title: targetTitle, in: sets) else {
            throw HeliumShortcutStore.ShortcutError.widgetSetNotFound(targetTitle)
        }

        var changed: [String] = []
        func apply<T>(_ value: T?, key: String) {
            guard let value = value else { return }
            sets[index][key] = value
            changed.append(key)
        }

        apply(newTitle, key: "title")
        apply(orientationMode, key: "orientationMode")
        apply(updateInterval, key: "updateInterval")
        apply(anchor, key: "anchor")
        apply(anchorY, key: "anchorY")
        apply(offsetPX, key: "offsetPX")
        apply(offsetPY, key: "offsetPY")
        apply(offsetLX, key: "offsetLX")
        apply(offsetLY, key: "offsetLY")
        apply(autoResizes, key: "autoResizes")
        apply(scale, key: "scale")
        apply(scaleY, key: "scaleY")

        guard !changed.isEmpty else {
            return .result(value: "没有提供要修改的字段，原配置保持不变。")
        }
        try HeliumShortcutStore.setWidgetSets(sets)
        return .result(value: "已更新「\(targetTitle)」：\(changed.joined(separator: "、"))")
    }
}

@available(iOS 16.0, *)
struct HeliumShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: HeliumControlHUDIntent(),
            phrases: ["控制 \(.applicationName) HUD", "切换 \(.applicationName) HUD"],
            shortTitle: "HUD 开关",
            systemImageName: "switch.2"
        )
        AppShortcut(
            intent: HeliumListWidgetSetsIntent(),
            phrases: ["列出 \(.applicationName) 小部件集"],
            shortTitle: "小部件集列表",
            systemImageName: "list.bullet"
        )
        AppShortcut(
            intent: HeliumGetWidgetSetIntent(),
            phrases: ["读取 \(.applicationName) 小部件集配置"],
            shortTitle: "读取小部件集",
            systemImageName: "doc.text.magnifyingglass"
        )
        AppShortcut(
            intent: HeliumSetWidgetSetEnabledIntent(),
            phrases: ["启用或停用 \(.applicationName) 小部件集"],
            shortTitle: "小部件集开关",
            systemImageName: "power"
        )
        AppShortcut(
            intent: HeliumUpdateWidgetSetIntent(),
            phrases: ["修改 \(.applicationName) 小部件集配置"],
            shortTitle: "修改小部件集",
            systemImageName: "slider.horizontal.3"
        )
    }
}
