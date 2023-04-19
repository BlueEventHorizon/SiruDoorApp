//
//  UserDefaultsWrapper.swift
//  BwTools
//
//  Created by k2moons on 2020/02/29.
//  Copyright © 2020 k2moons. All rights reserved.
//

import Foundation

typealias UserDefault = UserDefaultsWrapper
typealias OptionalUserDefault = UserDefaultsWrapperOptional

// MARK: - None Optional

@propertyWrapper
/// オプショナル型ではないUserDefaultを利用するためのpropertyWrapper
public struct UserDefaultsWrapper<T: Codable>: UserDefaultSupportCheckable {
    private let key: String
    private let defaultValue: T // <--- None Optional

    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            getValue() ?? getDefaultValue()
        }

        set {
            setValue(newValue)
        }
    }

    private func getDefaultValue() -> T {
        setValue(defaultValue)
        return defaultValue
    }

    private func getValue() -> T? {
        let object = UserDefaults.standard.object(forKey: key)

        if let data = object as? Data,
           let value = try? JSONDecoder().decode(T.self, from: data) {
            return value
        }

        return object as? T
    }

    private func setValue(_ value: T) {
        // UserDefaultsが直接扱える型かどうかを判定する
        if isSupported(value) {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            if let data = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(data, forKey: key)
            } else {
                assertionFailure("Couldn't encode \(value)")
            }
        }
    }
}

// MARK: - Optional

@propertyWrapper
public struct UserDefaultsWrapperOptional<T: Codable>: UserDefaultSupportCheckable {
    private let key: String
    private let defaultValue: T? // <--- Optional

    public init(_ key: String, defaultValue: T? = nil) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T? {
        get {
            getValue() ?? getDefaultValue()
        }

        set {
            setValue(newValue)
        }
    }

    private func getDefaultValue() -> T? {
        setValue(defaultValue)
        return defaultValue
    }

    private func getValue() -> T? {
        let object = UserDefaults.standard.object(forKey: key)

        if let data = object as? Data,
           let value = try? JSONDecoder().decode(T.self, from: data) {
            return value
        }

        return object as? T
    }

    private func setValue(_ value: T?) {
        guard let value = value else {
            UserDefaults.standard.removeObject(forKey: key)

            return
        }

        // UserDefaultsが直接扱える型かどうかを判定する
        if isSupported(value) {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            if let data = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(data, forKey: key)
            } else {
                assertionFailure("Couldn't encode \(value)")
            }
        }
    }
}

// MARK: - UserDefaultSupported protocol

protocol UserDefaultSupportCheckable {
    func isSupported(_ value: Any) -> Bool
}

extension UserDefaultSupportCheckable {
    // https://qiita.com/BlueEventHorizon/items/8b9b39dfae48ce4436e9

    /// UserDefaultsが直接扱える型かどうかを判定する
    /// - Parameter value: 対象となる型を持つ値
    /// - Returns: 判定 真ならばUserDefaultsが直接扱える
    func isSupported(_ value: Any) -> Bool {
        switch value {
            case is Bool:
                return true

            case is Int:
                return true

            case is Float:
                return true

            case is Double:
                return true

            case is String:
                return true

            case let array as [Any]:
                return array.allSatisfy(isSupported)

            case let dic as [String: Any]:
                return dic.allSatisfy { isSupported($0.value) }

            default:
                return false
        }
    }

//    func isSupported(_ value: Any) -> Bool {
//        switch value {
//            case is Bool: return true
//            case is Int: return true
//            case is Float: return true
//            case is Double: return true
//            case is String: return true
//            case let array as [Any]: return array.allSatisfy(isSupported)
//            case let dic as [String: Any]: return dic.allSatisfy { isSupported($0.value) }
//            default: return false
//        }
//    }
}
