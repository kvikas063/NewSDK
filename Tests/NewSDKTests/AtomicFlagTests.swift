import XCTest

@testable import NewSDK

/// Tests for `AtomicFlag`, the thread-safe boolean shared between the camera queue and the main thread.
final class AtomicFlagTests: XCTestCase {

    func testInitialValueAndSetter() {
        XCTAssertFalse(AtomicFlag().value)
        XCTAssertTrue(AtomicFlag(true).value)
        let flag = AtomicFlag()
        flag.value = true
        XCTAssertTrue(flag.value)
    }

    func testTestAndSetOnlySucceedsOnce() {
        let flag = AtomicFlag()
        XCTAssertTrue(flag.testAndSet())
        XCTAssertFalse(flag.testAndSet())
        flag.value = false
        XCTAssertTrue(flag.testAndSet())
    }

    func testOnlyOneThreadWinsTestAndSet() {
        let flag = AtomicFlag()
        let winners = AtomicCounter()
        DispatchQueue.concurrentPerform(iterations: 1000) { _ in
            if flag.testAndSet() { winners.increment() }
        }
        XCTAssertEqual(winners.value, 1)
    }
}

/// Minimal lock-protected counter used to count how many threads win a race.
private final class AtomicCounter {
    private let lock = NSLock()
    private var count = 0
    func increment() { lock.lock(); count += 1; lock.unlock() }
    var value: Int { lock.lock(); defer { lock.unlock() }; return count }
}
