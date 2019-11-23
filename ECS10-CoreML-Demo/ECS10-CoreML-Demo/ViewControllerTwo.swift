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
    var inputFormat: AVAudioFormat!
    
    var audioStreamAnalyzer: SNAudioStreamAnalyzer!
    var model: MLModel!
    let analysisQueue = DispatchQueue(label: "com.custom.AnalysisQueue")
    let soundClassifier = ESC_10_Sound_Classifier()
    var resultsObserver = ResultsObserver()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        audioStreamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)

    }

    override func viewDidAppear(_ animated: Bool) {
        model = soundClassifier.model
        self.startAudioEngine()
    }

    func startAudioEngine() {
        do {
            let request = try SNClassifySoundRequest(mlModel: soundClassifier.model)
            try audioStreamAnalyzer.add(request, withObserver: resultsObserver)
        } catch {
            print("Unable to prepare request: \(error.localizedDescription)")
            return
        }
       
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8000, format: inputFormat) { buffer, time in
                self.analysisQueue.async {
                    self.audioStreamAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
                }
        }
        
        do{
        try audioEngine.start()
        }catch( _){
            print("error in starting the Audio Engin")
        }
        
        //Update the UI
        DispatchQueue.main.async {
            print(self.resultsObserver.classificationResult)
        }
    }

}
