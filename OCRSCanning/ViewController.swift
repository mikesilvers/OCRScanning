//
//  ViewController.swift
//  OCRSCanning
//
//  Created by Mike Silvers on 6/21/19.
//  Copyright © 2019 Mike Silvers. All rights reserved.
//

import UIKit
import Vision
import VisionKit

class ViewController: UIViewController, VNDocumentCameraViewControllerDelegate {

    @IBOutlet var processExample: UIButton!
    @IBOutlet var processPicture: UIButton!
    @IBOutlet var processUPCScan: UIButton!

    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var upcLabel: UILabel!

    private var scanResults = [String]()
    
    //MARK: View functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "ScanResults":
            if let dest = segue.destination as? ResultsTableViewController {
                dest.scanResults = self.scanResults
                if let img = UIImage(named: "Sample") {
                    dest.sampleImage = img
                }
            }
        default:
            // do nothing
            print("Nothing to see here")
        }
    }
    //MARK: Button actionsa
    @IBAction func processExample(_ sender: UIButton) {
        
        // reset the results array
        scanResults.removeAll()
        
        // setup the procesing handler
        let request = VNRecognizeTextRequest { request, error in

            // make sure the observations were correctly obtained
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                fatalError("Invalid observations")
            }

            for observation in observations {

                guard let bestCandidate = observation.topCandidates(1).first else {
                    print("No candidate")
                    continue
                }

                // add the result to the array
                let bc = bestCandidate.string
                self.scanResults.append(bc)
                print("Result string:  \(bc)")

            }

        }
        
        let requests = [request]
        
        // process the image
        DispatchQueue.global(qos: .userInitiated).async {
            guard let img = UIImage(named: "Sample")?.cgImage else {
                fatalError("Missing image to scan")
            }
            let handler = VNImageRequestHandler(cgImage: img, options: [:])
            try? handler.perform(requests)
            
            print("\(self.scanResults)")
            
            // do this in the main thread
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "ScanResults", sender: nil)
            }
        }
    }

    @IBAction func processPicture(_ sender: UIButton) {
        
        let vc = VNDocumentCameraViewController()
        vc.delegate = self
        present(vc, animated: true)
        
    }
    
    @IBAction func processUPCScanning(_ sender: UIButton) {
        
        
        
    }
    
    //MARK: VNDocumentCameraViewControllerDelegate functions
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {

        // reset the results array
        scanResults.removeAll()

        for i in 0 ..< scan.pageCount {
            
            let imgRaw = scan.imageOfPage(at: i)
            
            // setup the procesing handler
            let request = VNRecognizeTextRequest { request, error in
                
                // make sure the observations were correctly obtained
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    fatalError("Invalid observations")
                }
                
                for observation in observations {
                    
                    guard let bestCandidate = observation.topCandidates(1).first else {
                        print("No candidate")
                        continue
                    }
                    
                    // add the result to the array
                    let bc = bestCandidate.string
                    self.scanResults.append(bc)
                    print("Result string:  \(bc)")
                    
                }
            }
            
            let requests = [request]
            
            // process the image
            DispatchQueue.global(qos: .userInitiated).async {
                guard let img = imgRaw.cgImage else {
                    fatalError("Missing image to scan")
                }
                let handler = VNImageRequestHandler(cgImage: img, options: [:])
                try? handler.perform(requests)
                
                print("\(self.scanResults)")
                
            }
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        
        print("The scanning camera VC was canceled.")
        
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print("There was an error with the document scanning: \(error.localizedDescription)")
    }
}

