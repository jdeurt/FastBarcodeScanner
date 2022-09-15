import Foundation
import Vision
import AVFoundation
import SwiftUI

extension FastCodeScannerView {
    public class ScannerCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: FastCodeScannerView
        var didFinishScanning = false
        var lastTime = Date(timeIntervalSince1970: 0)
        
        init(parent: FastCodeScannerView) {
            self.parent = parent
        }
        
        public func reset() {
            didFinishScanning = false
            lastTime = Date(timeIntervalSince1970: 0)
        }
        
        private lazy var captureSession: AVCaptureSession = {
            let s = AVCaptureSession()
            s.sessionPreset = .hd1920x1080
            return s
        }()
        
        lazy var detectBarcodeRequest: VNDetectBarcodesRequest = {
            let request =  VNDetectBarcodesRequest(completionHandler: { (request, error) in
                guard error == nil else { return }
                
                self.processClassification(for: request)
            })
            
            request.symbologies = parent.codeTypes
            
            return request
        }()
        
        private func processClassification(for request: VNRequest) {
            DispatchQueue.main.async {
                if let bestResult = request.results?.first as? VNBarcodeObservation,
                   let payload = bestResult.payloadStringValue {
                    if (bestResult.confidence >= self.parent.minimumConfidence) {
                        guard let data = payload.data(using: .utf8) else { return }
                        
                        self.found(
                            ScanResult(
                                string: String(data: data, encoding: .utf8)!,
                                type: bestResult.symbology,
                                confidence: bestResult.confidence,
                                boundingBox: bestResult.boundingBox
                            )
                        )
                        
                        if self.captureSession.isRunning {
                            self.captureSession.stopRunning()
                        }
                    }
                }
            }
        }
        
        func found(_ result: ScanResult) {
            lastTime = Date()
            
            parent.action(.success(result))
        }
        
        public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            var requestOptions: [VNImageOption : Any] = [:]
            
            if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
                requestOptions = [.cameraIntrinsics : camData]
            }
            
            if (parent.isScanning) {
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .left, options: requestOptions)
                try? imageRequestHandler.perform([self.detectBarcodeRequest])
            }
        }
        
        func didFail(reason: ScanError) {
            parent.action(.failure(reason))
        }
    }
}
