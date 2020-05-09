
 

/// - Tag: MLModelSetup
lazy var observationRequest: VNCoreMLRequest = {
    do {
        
        // Create the model
        let model = try VNCoreMLModel(for: YOLOv3Tiny().model)
        
        // Create the request that, when complete, calls
        // processObservations
        let request = VNCoreMLRequest(model: model, completionHandler: { 
            [weak self] request, error in

            self?.processObservations(for: request, error: error)
        })
        
        // Indicate that the request should crop the image to the center to
        // fit the resolution requirements of the model
        request.imageCropAndScaleOption = .centerCrop
        return request
    } catch {
        // Throw an error if we failed to load the model
        fatalError("Failed to load Vision ML model: \(error)")
    }
}()

// 2. run request with handler

// Show a label while we wait for observation to complete
imageCaptionTextView.text = "Classifying..."       
        
// Get the orientation from the image - models are generally only trained
// on images in which the subject is right-way-up
let orientation = CGImagePropertyOrientation(image.imageOrientation)

// Get a CIImage from the UIImage
guard let ciImage = CIImage(image: image) else { 
    fatalError("Unable to create \(CIImage.self) from \(image).") 
}

// Do the rest of the work in the background, to avoid hanging the rest of
// the app
DispatchQueue.global(qos: .userInitiated).async {
    
    // Get a handler for this request that uses this specific image with
    // this specific orientation
    let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
    
    do {
        // Attempt to perform a classification, using our classification
        // request. processObservations will be called when the work is
        // complete.
        try handler.perform([self.observationRequest])
    } catch {
        /*
            This handler catches general image processing errors. The
            `observationRequest`'s completion handler
            `processObservations(_:error:)` catches errors specific to
            processing that request.
            */
        print("Failed to perform classification.\n\(error.localizedDescription)")
    }
}

// 3. process observations

// Do all of this work on the main thread
DispatchQueue.main.async {
    
    // Get the results. If we can't, there was an error.
    guard let results = request.results else {
        self.imageCaptionTextView.text = "Unable to classify image.\n\(error!.localizedDescription)"
        return
    }
    
    // The `results` will always be `VNRecognizedObjectObservation`s, as
    // specified by the Core ML model in this project.
    let observations = results as! [VNRecognizedObjectObservation]

    // For any observation that we found, we want the best label for it.
    let descriptions = observations.compactMap { classification in
        
        // Each observation contains multiple classifications, each with an
        // identifier and a confidence. We want the highest-confidence
        // identifier that is above 80%. If there are none, we're not
        // confident enough in our prediction, so we will return nothing
        
        // 4. get labels for observations
    }
    
    if descriptions.isEmpty {
        self.imageCaptionTextView.text = "Nothing recognized."
    } else {
        
        // We confidently recognised objects, and can now produce a
        // caption!
        self.imageCaptionTextView.text = "May contain: " + descriptions.joined(separator: ", ")
    }
}

// 4. get labels for observations

classification.labels
    .filter({$0.confidence > 0.8})
    .sorted(by: {
        $0.confidence > $1.confidence
    }).first?
    .identifier