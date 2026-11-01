#if canImport(ReplayKit) && canImport(UIKit)
import ReplayKit
import UIKit
import CoreImage

/// 1-Frame ReplayKit Broadcast Extension (`WingAIBroadcast`):
/// Captures a single screen video sample buffer into `group.com.wingai.keyboard/pending_snapshot.jpg`
/// and immediately terminates the broadcast so live recording never stays active.
public final class SampleHandler: RPBroadcastSampleHandler {
    private var hasCapturedSingleFrame = false
    private let ciContext = CIContext()

    public override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        hasCapturedSingleFrame = false
    }

    public override func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        guard sampleBufferType == .video, !hasCapturedSingleFrame else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        hasCapturedSingleFrame = true
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let rect = ciImage.extent
        if let cgImage = ciContext.createCGImage(ciImage, from: rect) {
            let uiImage = UIImage(cgImage: cgImage)
            if let jpegData = uiImage.jpegData(compressionQuality: 0.85) {
                AppGroupStore.shared.savePendingSnapshotData(jpegData)
            }
        }

        let userInfo = [
            NSLocalizedFailureReasonErrorKey: "WingAI captured 1 snapshot frame. Return to the keyboard and tap Select to crop."
        ]
        finishBroadcastWithError(
            NSError(domain: "com.wingai.keyboard.broadcast", code: 0, userInfo: userInfo)
        )
    }
}
#endif
