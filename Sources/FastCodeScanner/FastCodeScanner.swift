import Vision
import AVFoundation
import Foundation
import SwiftUI

/// An enum describing the ways CodeScannerView can hit scanning problems.
public enum ScanError: Error {
    /// The camera could not be accessed.
    case badInput
    
    /// The camera was not capable of scanning the requested codes.
    case badOutput
    
    /// Initialization failed.
    case initError(_ error: Error)
}

public typealias CodeBoundingBox = CGRect

/// The result from a successful scan: the string that was scanned, and also the type of data that was found.
/// The type is useful for times when you've asked to scan several different code types at the same time, because
/// it will report the exact code type that was found.
public struct ScanResult {
    /// The contents of the code.
    public let string: String
    
    /// The type of code that was matched.
    public let type: VNBarcodeSymbology
    
    /// Bounding box for scanned code
    public let boundingBox: CodeBoundingBox
}

public struct FastCodeScannerView: UIViewControllerRepresentable {
    
    @Binding var isScanning: Bool

    public let codeTypes: [VNBarcodeSymbology]
    // public let scanInterval: Double
    public var isTorchOn: Bool
    public var videoCaptureDevice: AVCaptureDevice?
    public var action: (Result<ScanResult, ScanError>) -> Void
    
    public init(
        isScanning: Binding<Bool>,
        codeTypes: [VNBarcodeSymbology],
        isTorchOn: Bool = false,
        videoCaptureDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video),
        action: @escaping (Result<ScanResult, ScanError>) -> Void
    ) {
        self._isScanning = isScanning
        self.codeTypes = codeTypes
        self.isTorchOn = isTorchOn
        self.videoCaptureDevice = videoCaptureDevice
        self.action = action
    }
    
    public func makeCoordinator() -> ScannerCoordinator {
        ScannerCoordinator(parent: self)
    }
    
    public func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        uiViewController.updateViewController(
            isTorchOn: isTorchOn,
            isGalleryPresented: false
        )
    }
}
