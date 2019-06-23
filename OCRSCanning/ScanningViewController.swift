//
//  ScanningViewController.swift
//  OCRSCanning
//
//  Created by Mike Silvers on 6/22/19.
//  Copyright © 2019 Mike Silvers. All rights reserved.
//

import UIKit
import AVFoundation

class ScanningViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet var captureView  : UIView!
    @IBOutlet var captureLabel : UILabel!
    @IBOutlet var captureButton: UIButton!

    var captureSession: AVCaptureSession!
    var previewLayer  : AVCaptureVideoPreviewLayer!

    var soundEffect: AVAudioPlayer?
    
    private var urlCode: String = ""
    private var apiEndpoint = "https://api.upcdatabase.org/product/{code}/7A71D2BF3AC7CA2361F1D3AE3423855D"
    
    //MARK: - View functions
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        // setup the capture camera
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            failed("The video input failed to create correctly.")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed("The video input failed to set correctly.")
            return
        }
        
        // setup the types of barcodes to read
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.upce, .code93, .interleaved2of5, .ean13]
        } else {
            failed("The capture session metadata failed to set correctly.")
            return
        }
        
        // setup the preview
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        // start the capture running
        captureSession.startRunning()

        // setup the sound
        let path = Bundle.main.path(forResource: "ringing-bell.mp3", ofType:nil)!
        let soundUrl = URL(fileURLWithPath: path)
        do {
            soundEffect = try AVAudioPlayer(contentsOf: soundUrl)
        } catch {
            // just an error
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        captureLabel.text = ""
        urlCode = ""
        
        previewLayer.frame = captureView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        previewLayer.connection?.videoOrientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        captureView.layer.addSublayer(previewLayer)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // remove the preview
        previewLayer.removeFromSuperlayer()
        
        // stop capturing
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    //MARK: - Supporting functions
    func failed(_ message: String) {
        
        let alert = UIAlertController(title: "Scanner Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        captureSession = nil
    }
    
    func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }

    //MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
//        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // play the dings
            if let se = soundEffect {
                se.play()
            }
            
            // set the label
            captureLabel.text = stringValue
            urlCode = stringValue
        }
        
    }
    
    //MARK: - Button functions
    @IBAction func cancelButton(_ sender: UIButton) {
    
        urlCode = ""
        captureLabel.text = ""
        captureSession.stopRunning()
        captureView.removeFromSuperview()
        
        dismiss(animated: true, completion: nil)
        
    }

    @IBAction func captureButton(_ sender: UIButton) {
        
        let urlString = apiEndpoint.replacingOccurrences(of: "{code}", with: urlCode)
        
        // make the request
        guard let urlRequest = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                // Handle Error
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let response = response else {
                // Handle Empty Response
                print("Response is nil")
                
                DispatchQueue.main.async {
                    self.captureLabel.text = "\(self.urlCode): Not Found"
                }

                return
            }
            
            guard let data = data else {
                print("Data is nil")
                return
            }
            
            if let dataString = String(data: data, encoding: .utf8) {
                print("Data returned: \(dataString)")
            }

            // Handle Decode Data into Model
            do {
                let _ = try JSONDecoder().decode(UPCModel.self, from: data)
            } catch {
                print("Decode error: \(error.localizedDescription)")
            }
            
            guard let theUPC = try? JSONDecoder().decode(UPCModel.self, from: data) else { return }

            DispatchQueue.main.async {
                self.captureLabel.text = "\(theUPC.upcnumber ?? " " ): \(theUPC.description ?? " ")"
            }
            
        }.resume()
        
    }

}
