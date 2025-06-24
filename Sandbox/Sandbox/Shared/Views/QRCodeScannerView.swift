//
//  QRCodeScannerView.swift
//  Sandbox
//
//  Created by Bidon Team on 01.03.2023.
//

import Foundation
import UIKit
import SwiftUI
import AVFoundation


struct QRCodeScannerView: UIViewControllerRepresentable {
    enum ScanError: Error {
        case badInput, badOutput
    }

    class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView
        var codeFound = false

        init(parent: QRCodeScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                guard codeFound == false else { return }

                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                found(code: stringValue)

                // make sure we only trigger scans once per use
                codeFound = true
            }
        }

        func found(code: String) {
            parent.completion(.success(code))
        }

        func didFail(reason: ScanError) {
            parent.completion(.failure(reason))
        }
    }

#if targetEnvironment(simulator)
    class ScannerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var delegate: ScannerCoordinator?

        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = true
            view.backgroundColor = .tertiarySystemBackground

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            label.text = "You're running in the simulator, which means the camera isn't available. Tap anywhere to send back some simulated data."
            label.textAlignment = .center
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("Or tap here to select a custom image", for: .normal)
            button.setTitleColor(UIColor.systemBlue, for: .normal)
            button.setTitleColor(UIColor.gray, for: .highlighted)
            button.addTarget(self, action: #selector(self.openGallery), for: .touchUpInside)

            let stackView = UIStackView()
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.spacing = 50
            stackView.addArrangedSubview(label)
            stackView.addArrangedSubview(button)

            view.addSubview(stackView)

            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 50),
                stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let simulatedData = delegate?.parent.simulatedData else {
                print("Simulated Data Not Provided!")
                return
            }

            delegate?.found(code: simulatedData)
        }

        @objc func openGallery(_ sender: UIButton) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let qrcodeImg = info[.originalImage] as? UIImage {
                let detector: CIDetector=CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
                let ciImage: CIImage=CIImage(image: qrcodeImg)!
                var qrCodeLink=""

                let features=detector.features(in: ciImage)
                for feature in features as! [CIQRCodeFeature] {
                    qrCodeLink += feature.messageString!
                }

                if qrCodeLink=="" {
                    delegate?.didFail(reason: .badOutput)
                }else {
                    delegate?.found(code: qrCodeLink)
                }
            }
            else {
                print("Something went wrong")
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
#else
    class ScannerViewController: UIViewController {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var delegate: ScannerCoordinator?

        let queue = DispatchQueue(label: "capture.queue")

        override func viewDidLoad() {
            super.viewDidLoad()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updateOrientation),
                name: Notification.Name("UIDeviceOrientationDidChangeNotification"),
                object: nil
            )

            view.backgroundColor = UIColor.black
            captureSession = AVCaptureSession()

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                return
            }

            if (captureSession.canAddInput(videoInput)) {
                captureSession.addInput(videoInput)
            } else {
                delegate?.didFail(reason: .badInput)
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if (captureSession.canAddOutput(metadataOutput)) {
                captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = delegate?.parent.codeTypes
            } else {
                delegate?.didFail(reason: .badOutput)
                return
            }
        }

        override func viewWillLayoutSubviews() {
            previewLayer?.frame = view.layer.bounds
        }

        @objc func updateOrientation() {
            guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else { return }
            guard let connection = captureSession.connections.last, connection.isVideoOrientationSupported else { return }
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) ?? .portrait
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.anchorPoint = view.layer.bounds.origin

            view.layer.addSublayer(previewLayer)
            view.layer.masksToBounds = true

            updateOrientation()
            queue.async {
                self.captureSession.startRunning()
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            if let session = captureSession, !session.isRunning {
                queue.async {
                    self.captureSession.startRunning()
                }
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            if let session = captureSession, session.isRunning {
                captureSession.stopRunning()
            }

            NotificationCenter.default.removeObserver(self)
        }

        override var prefersStatusBarHidden: Bool {
            return true
        }

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .all
        }
    }
#endif

    let codeTypes: [AVMetadataObject.ObjectType]
    var simulatedData = ""
    var completion: (Result<String, ScanError>) -> Void

    init(
        codeTypes: [AVMetadataObject.ObjectType],
        simulatedData: String = "",
        completion: @escaping (Result<String, ScanError>) -> Void
    ) {
        self.codeTypes = codeTypes
        self.simulatedData = simulatedData
        self.completion = completion
    }

    func makeCoordinator() -> ScannerCoordinator {
        return ScannerCoordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}
