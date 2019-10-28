//
//  ViewController.swift
//  ECS10-CoreML-Demo
//
//  Created by Nick Arner on 10/20/19.
//  Copyright © 2019 Nick Arner. All rights reserved.
//

import UIKit
import AVFoundation
import SoundAnalysis
import CoreML

//from https://developer.apple.com/documentation/soundanalysis/analyzing_audio_to_classify_sounds

//https://developer.apple.com/documentation/createml/mlsoundclassifier
class ViewControllerTwo: UIViewController {
    // Create a new audio engine.

    var audioEngine = AVAudioEngine()
    var audioFileAnalyzer: SNAudioFileAnalyzer!
    var model: MLModel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }

    override func viewDidAppear(_ animated: Bool) {
            
        let soundClassifier = ESC_10_Sound_Classifier()
        model = soundClassifier.model

        self.startAudioEngine()
    }

    
    func startAudioEngine() {
        
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(
                AVAudioSession.Category.record)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }

        // Create a new audio engine.
        audioEngine = AVAudioEngine()
                
        //https://forums.developer.apple.com/thread/44833
        audioEngine.mainMixerNode

        do {
            // Start the stream of audio data.
            try audioEngine.start()
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
        
        // Get the native audio format of the engine's input bus.
        let inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)

        // Create a new stream analyzer.
        print(inputFormat)
        let streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)

        
        // Create a new observer that will be notified of analysis results.
        // Keep a strong reference to this object.
        let resultsObserver = ResultsObserver()

        do {
            // Prepare a new request for the trained model.
            let request = try SNClassifySoundRequest(mlModel: model)
            try streamAnalyzer.add(request, withObserver: resultsObserver)
        } catch {
            print("Unable to prepare request: \(error.localizedDescription)")
            return
        }

        // Serial dispatch queue used to analyze incoming audio buffers.
        let analysisQueue = DispatchQueue(label: "com.apple.AnalysisQueue")

        // Install an audio tap on the audio engine's input node.
        audioEngine.inputNode.installTap(onBus: 0,
                                         bufferSize: 8192, // 8k buffer
                                         format: inputFormat) { buffer, time in
            
            // Analyze the current audio buffer.
            analysisQueue.async {
                streamAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }

    }
    
    

}
