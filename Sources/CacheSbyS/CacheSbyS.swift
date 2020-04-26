
//
//  Cache.swift
//
//
//  Created by Radislav Gaynanov on 09.04.2020.
//

import Foundation

public final class Cache<Key: Hashable, Value> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let dateProvider: () -> Date?
    private let entryLifeTime: TimeInterval?
    private let keyTracker = KeyTracker()
    
    
   public init(dateProvider: @escaping () -> Date? = Date.init, entryLifeTime: TimeInterval? = nil, maximumCountLimit: Int = 100) {
        self.dateProvider = dateProvider
        self.entryLifeTime = entryLifeTime
        self.wrapped.countLimit = maximumCountLimit
        self.wrapped.delegate = keyTracker
    }
    
    public func insert (_ value: Value, for key: Key) {
        var entry: Entry
        if let date = dateProvider(), let lifeTime = entryLifeTime {
            entry = Entry.init(key: key, value: value, expirationDate: date.addingTimeInterval(lifeTime))
        } else {
            entry = Entry.init(key: key, value: value)
        }
        keyTracker.keys.insert(key)
        wrapped.setObject(entry, forKey: WrappedKey.init(key))
    }
    
    public func value(forKey key: Key) -> Value? {
        guard let entry = wrapped.object(forKey: WrappedKey.init(key)) else {return nil}
        if let date = dateProvider(), let lifeTime = entry.expirationDate, date > lifeTime{
            removeValue(forKey: key)
            return nil
        } else {
            return entry.value
        }
    }
    
    public func removeValue(forKey key: Key) {
        wrapped.removeObject(forKey: WrappedKey.init(key))
    }
}

private extension Cache {
    final class WrappedKey: NSObject {
        let key: Key
        
        init(_ key: Key) {
            self.key = key
        }
        
        override var hash: Int {
            return key.hashValue
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {return false}
            return value.key == key
        }
    }
}

private extension Cache {
    final class Entry {
        let key: Key
        let value: Value
        let expirationDate: Date?
        
        init(key: Key, value: Value, expirationDate: Date? = nil) {
            self.key = key
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

extension Cache.Entry: Codable where Key: Codable, Value:Codable {}

private extension Cache {
    func entry(forKey key: Key) -> Entry? {
        guard let entry = wrapped.object(forKey: WrappedKey.init(key)) else {return nil}
        if let date = dateProvider(), let lifeTime = entry.expirationDate, date > lifeTime{
            removeValue(forKey: key)
            return nil
        } else {
            return entry
        }
    }
    
    func insert(_ entry: Entry) {
        wrapped.setObject(entry, forKey: WrappedKey.init(entry.key))
        keyTracker.keys.insert(entry.key)
    }
    
}

extension Cache: Codable where Key: Codable, Value: Codable {
    convenience public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.singleValueContainer()
        let entries = try container.decode([Entry].self)
        entries.forEach(insert)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(keyTracker.keys.compactMap(entry))
    }
    
}

extension Cache where Key: Codable, Value: Codable {
    func saveToDisk(withName name: String, using fileManager: FileManager = .default) throws {
        let folders = fileManager.urls(for:.cachesDirectory, in: .userDomainMask)
        let fileURL = folders[0].appendingPathComponent(name + ".cache")
        let data = try JSONEncoder().encode(self)
        try data.write(to: fileURL)
    }
}

extension Cache {
   public subscript(key: Key) -> Value? {
        get {
            return value(forKey: key)
        }
        
        set {
            guard let value = newValue else {
                removeValue(forKey: key)
                return
            }
            insert(value, for: key)
        }
    }
}

private extension Cache {
    final class KeyTracker: NSObject, NSCacheDelegate {
        var keys = Set<Key>()
        
        func cache(_ cache: NSCache<AnyObject, AnyObject>,
                   willEvictObject obj: Any) {
            guard let entry = obj as? Entry else { return }
            keys.remove(entry.key)
        }
    }
}
