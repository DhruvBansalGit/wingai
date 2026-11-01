import XCTest
@testable import WingAICore

final class WingAITests: XCTestCase {
    func testAppGroupStoreGeneratesPersistentUserIdAndStoresSnapshot() {
        let store = AppGroupStore(suiteName: "com.wingai.keyboard.tests.\(UUID().uuidString)")
        let uid1 = store.getOrCreateUserId()
        let uid2 = store.getOrCreateUserId()
        XCTAssertTrue(uid1.hasPrefix("wing_"))
        XCTAssertEqual(uid1, uid2)

        let fakeJpeg = Data("fake-jpeg-snapshot".utf8)
        store.savePendingSnapshotData(fakeJpeg)
        XCTAssertTrue(store.hasPendingSnapshot())

        let consumed = store.consumePendingSnapshotData()
        XCTAssertEqual(consumed, fakeJpeg)
        XCTAssertFalse(store.hasPendingSnapshot())
    }

    func testKeyboardViewModelBilingualPredictionsAndSelectFlow() {
        let vm = WingAiKeyboardViewModel()
        vm.currentWordPrefix = "ha"
        XCTAssertTrue(vm.typingPredictions.contains("haan"))

        let fakeClip = Data("clipboard-image".utf8)
        vm.startSelectAndSearch(clipboardImageData: fakeClip)
        XCTAssertTrue(vm.isAiPanelOpen)
        XCTAssertTrue(vm.isCroppingSnapshot)
        XCTAssertEqual(vm.rawSnapshotData, fakeClip)

        vm.cancelCrop()
        XCTAssertFalse(vm.isCroppingSnapshot)
        XCTAssertNil(vm.rawSnapshotData)
    }
}
