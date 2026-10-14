import Foundation

/// A thread-safe boolean. Camera frames are delivered on a background queue while the
/// UI state is changed on the main thread, so shared flags must not be plain `Bool`s.
final class AtomicFlag {
    /// Guards every access to `storage`.
    private let lock = NSLock()
    /// The underlying value; only touched while `lock` is held.
    private var storage: Bool

    /// Creates a flag.
    ///
    /// - Parameter initialValue: The starting value (`false` by default).
    init(_ initialValue: Bool = false) {
        storage = initialValue
    }

    /// The current value of the flag, read and written under the lock.
    var value: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storage
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storage = newValue
        }
    }

    /// Atomically sets the flag. Returns `true` only if it was clear before (the caller "won").
    ///
    /// - Returns: `true` if this call changed the flag from `false` to `true`; `false` if it was already set.
    func testAndSet() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if storage { return false }
        storage = true
        return true
    }
}
