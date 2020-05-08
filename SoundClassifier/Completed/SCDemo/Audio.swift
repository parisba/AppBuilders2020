//
//  Audio.swift
//  SCDemo
//
//  Created by Mars Geldard on 14/6/19.
//  Copyright © 2019 Mars Geldard. All rights reserved.
//

import CoreML
import AVFoundation
import SoundAnalysis

class ResultsObserver: NSObject, SNResultsObserving {
    
    // The method to call when the entire file has completed analysis. Receives the predicted label, or nil if there was an error.
    private var completion: (String?) -> ()
    
    // The collection of results that we're confident in
    private var results: [(String, Double)] = []
    
    // A dictionary that maps the label name to the total cumulative confidence we have for it
    private var cumulativeResults: [String: Double] {
        return results.reduce(into: [:]) { $0[$1.0, default: 0.0] += $1.1 }
    }
    
    init(completion: @escaping (String?) -> ()) {
        self.completion = completion
    }
    
    // The SNAudioFileAnalyzer produced a request.
    func request(_ request: SNRequest, didProduce result: SNResult) {
        
        // Get the first result.
        guard let results = result as? SNClassificationResult,
            let result = results.classifications.first else { return }
       
        // Is this result reasonably confident?
        if result.confidence > 0.7 {
            // If so, keep it. We'll use these results when the analysis completes.
            self.results.append((result.identifier, result.confidence))
        }
    }
    
    // The SNAudioFileAnalzyer failed.
    func request(_ request: SNRequest, didFailWithError error: Error) {
        // Let the application know that we failed to produce a result.
        completion(nil)
    }
    
    // The SNAudioFileAnalyzer completed. We can now compute our most confident classification for the entire audio file.
    func requestDidComplete(_ request: SNRequest) {
        
        for result in cumulativeResults {
            print("\(result.key): \(result.value)")
        }
        
        // Get the most confident cumulative result, if any.
        // This is an optional value, because the analyzer may have never produced a confident result.
        let highestResult = cumulativeResults.max { $0.value < $1.value }
        
        // Return it to the application (or nil, if we don't have any results.)
        completion(highestResult?.key)
    }
}

class AudioClassifier {
    
    private let model: MLModel
    private let request: SNClassifySoundRequest
    
    init(model: MLModel) {
        
        do {
            self.model = model
            self.request = try SNClassifySoundRequest(mlModel: model)
        } catch let error {
            fatalError("Failed to create the audio classifier: \(error.localizedDescription)")
        }
        
    }
    
    func classify(audioFile: URL, completion: @escaping (String?) -> ()) {
        let observer = ResultsObserver(completion: completion)
        
        do {
            let analyzer = try SNAudioFileAnalyzer(url: audioFile)
            
            try analyzer.add(request, withObserver: observer)
            
            analyzer.analyze()
        } catch let error {
            fatalError("Error analyzing audio: \(error.localizedDescription)")
        }
    }
}
