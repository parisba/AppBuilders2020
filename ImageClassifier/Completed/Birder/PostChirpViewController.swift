/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller for selecting images and applying Vision + Core ML processing.
*/

import UIKit
import CoreML
import Vision
import ImageIO

class PostChirpViewController: UIViewController {
    // MARK: - IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var classificationLabel: UILabel!
    
    // MARK: - Image Classification
    
    /// - Tag: MLModelSetup
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            
            // Create the model
            let model = try VNCoreMLModel(for: YOLOv3Tiny().model)
            
            // Create the request that, when complete, calls processClassifications
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            
            // Indicate that the request should crop the image to the center to fit the resolution requirements of the model
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            // Throw an error if we failed to load the model
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    /// - Tag: PerformRequests
    
    // Called when the user has provided a photo.
    func updateClassifications(for image: UIImage) {
        
        // Show a label while we wait for classification to complete
        classificationLabel.text = "Classifying..."
        
        // Get the orientation from the image - models are generally only trained on images in which the subject is right-way-up
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        
        // Get a CIImage from the UIImage
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        // Do the rest of the work in the background, to avoid hanging the rest of the app
        DispatchQueue.global(qos: .userInitiated).async {
            
            // Get a handler for this request that uses this specific image with this specific orientation
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            
            do {
                // Attempt to perform a classification, using our classification request. processClassifications will be called when the work is complete.
                try handler.perform([self.classificationRequest])
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    /// Updates the UI with the results of the classification.
    /// - Tag: ProcessClassifications
    
    // Called by the request when classification work has completed.
    func processClassifications(for request: VNRequest, error: Error?) {
        
        // Do all of this work on the main thread
        DispatchQueue.main.async {
            
            // Get the results. If we can't, there was an error.
            guard let results = request.results else {
                self.classificationLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            
            // The `results` will always be `VNRecognizedObjectObservation`s, as specified by the Core ML model in this project.
            let observations = results as! [VNRecognizedObjectObservation]
        
            // For any observation that we found, we want the best label for it.
            let descriptions = observations.compactMap { classification in
                
                // Each observation contains multiple classifications, each with an identifier and a confidence.
                // We want the highest-confidence identifier that is above 80%. If there are none, we're not confident enough in our prediction, so we will return nothing
                
                classification.labels
                    .filter({$0.confidence > 0.8})
                    .sorted(by: {
                        $0.confidence > $1.confidence
                    }).first?
                    .identifier
            }
            
            if descriptions.isEmpty {
                self.classificationLabel.text = "Nothing recognized."
            } else {
                
                // We confidently recognised objects, and can now produce a caption!
                self.classificationLabel.text = "May contain: " + descriptions.joined(separator: ", ")
            }
        }
    }
    
    // MARK: - Photo Actions
    
    @IBAction func takePicture() {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
}

extension PostChirpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Handling Image Picker Selection

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        
        // We always expect `imagePickerController(:didFinishPickingMediaWithInfo:)` to supply the original image.
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.image = image
        updateClassifications(for: image)
    }
}
