//
//  ViewController.swift
//  CoreML
//
//  Created by Firoz Khursheed on 12/11/17.
//  Copyright © 2017 Firoz Khursheed. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {

  @IBOutlet weak var captionLabel: UILabel!
  @IBOutlet weak var predicitonLabel: UILabel!
  
  var captureSession: AVCaptureSession!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    prepareInput()
    appPreviewLayer()
    addOutput()
  }

  private func prepareInput() {
    captureSession = AVCaptureSession()
    guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
    
    guard let input = try? AVCaptureDeviceInput(device: captureDevice) else{return}
    captureSession.addInput(input)
    captureSession.startRunning()
  }

  private func appPreviewLayer() {
    let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    view.layer.addSublayer(previewLayer)
    previewLayer.frame = view.frame
    view.bringSubview(toFront: captionLabel)
    view.bringSubview(toFront: predicitonLabel)
  }

  private func addOutput() {
    let dataOutput = AVCaptureVideoDataOutput()
    dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video"))
    captureSession.addOutput(dataOutput)
  }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
    guard let model = try? VNCoreMLModel(for: Resnet50().model) else {return}
    let request = VNCoreMLRequest(model: model) { (vnRequest, error) in
      guard let result = vnRequest.results as? [VNClassificationObservation] else {return}
      
      guard let firstObservation = result.first else {return}
      
      DispatchQueue.main.async {
        self.captionLabel.text = "\(firstObservation.identifier)"
        self.predicitonLabel.text = "\(firstObservation.confidence * 100)%"
      }
    }

    try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
  }
}
