#if canImport(UIKit)
import UIKit
import SwiftUI

public final class KeyboardViewController: UIInputViewController {
    private let viewModel = WingAiKeyboardViewModel()
    private var hostingController: UIHostingController<WingAiKeyboardRootView>?

    public override func viewDidLoad() {
        super.viewDidLoad()

        let rootView = WingAiKeyboardRootView(
            viewModel: viewModel,
            onInsertText: { [weak self] text in
                self?.textDocumentProxy.insertText(text)
            },
            onDeleteBackward: { [weak self] in
                self?.textDocumentProxy.deleteBackward()
            },
            onNextKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            },
            onReadClipboardImage: {
                guard let image = UIPasteboard.general.image else { return nil }
                return image.jpegData(compressionQuality: 0.85)
            },
            onReadClipboardText: {
                UIPasteboard.general.string
            },
            onCropImageData: { rawData, normalizedRect in
                Self.cropImageData(rawData, normalizedRect: normalizedRect)
            }
        )

        let host = UIHostingController(rootView: rootView)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear

        addChild(host)
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        self.hostingController = host
    }

    public static func cropImageData(_ data: Data, normalizedRect: CGRect) -> Data? {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return nil
        }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let cropZone = CGRect(
            x: max(0, normalizedRect.minX * width),
            y: max(0, normalizedRect.minY * height),
            width: min(width, normalizedRect.width * width),
            height: min(height, normalizedRect.height * height)
        ).integral

        guard let croppedCg = cgImage.cropping(to: cropZone) else {
            return data
        }
        return UIImage(cgImage: croppedCg, scale: image.scale, orientation: image.imageOrientation)
            .jpegData(compressionQuality: 0.82)
    }
}
#endif
