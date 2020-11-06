//
//  ViewController.swift
//  ECS10-CoreML-Demo
//
//  Created by Nick Arner on 10/20/19.
//  Copyright © 2019 Nick Arner. All rights reserved.
//

import UIKit
import SoundAnalysis
import CoreML
import AudioKit

//from https://developer.apple.com/documentation/soundanalysis/analyzing_audio_to_classify_sounds
//https://developer.apple.com/documentation/createml/mlsoundclassifier

class ViewController: UIViewController {
    // Create a new audio engine.

    @IBOutlet weak var selectedClip: UILabel!
    @IBOutlet weak var prediction: UILabel!
    @IBOutlet weak var analyzeAudioButton: UIButton!
    @IBOutlet weak var plotView: UIView!
    var plot: NodeOutputPlot!

    var audioEngine = AudioEngine()
    var player = AudioPlayer()
    var audioFileAnalyzer: SNAudioFileAnalyzer!
    var model: MLModel!
    var soundFiles: [URL]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupAudioPlayer()
        loadAudioFiles()

    }
    
    func setupAudioPlayer(){
        audioEngine.output = player
        do {
            try audioEngine.start()
            setupOutputPlot()
        } catch  {
            print(error)
        }
    }
    
    func setupOutputPlot(){
        plot = NodeOutputPlot(player)
        plot.plotType = .rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = .red
        plotView.addSubview(plot)
        plot.start()
    }
    
    func loadAudioFiles(){
        
        let helicopterFileURLPath = Bundle.main.path(forResource: "helicopter", ofType: "wav")
        let helicopterFileURL = NSURL.fileURL(withPath: helicopterFileURLPath!)

        let chainsawFileURLPath = Bundle.main.path(forResource: "chainsaw-cutting", ofType: "wav")
        let chainsawFileURL = NSURL.fileURL(withPath: chainsawFileURLPath!)

        let rainFileURLPath = Bundle.main.path(forResource: "rain", ofType: "wav")
        let rainFileURL = NSURL.fileURL(withPath: rainFileURLPath!)

        let dogFileURLPath = Bundle.main.path(forResource: "dogs", ofType: "wav")
        let dogFileURL = NSURL.fileURL(withPath: dogFileURLPath!)

        let sneezeFileURLPath = Bundle.main.path(forResource:
            "man-sneezing", ofType: "wav")
        let sneezeFileURL = NSURL.fileURL(withPath: sneezeFileURLPath!)

        let wavesFileURLPath = Bundle.main.path(forResource: "waves", ofType: "wav")
        let wavesFileURL = NSURL.fileURL(withPath: wavesFileURLPath!)

        let fireFileURLPath = Bundle.main.path(forResource: "crackling-fire", ofType: "wav")
        let fireFileURL = NSURL.fileURL(withPath: fireFileURLPath!)

        let roosterFileURLPath = Bundle.main.path(forResource:
            "rooster-crow", ofType: "wav")
        let roosterFileURL = NSURL.fileURL(withPath: roosterFileURLPath!)

        let clockFileURLPath = Bundle.main.path(forResource: "clock-ticking", ofType: "wav")
        let clockFileURL = NSURL.fileURL(withPath: clockFileURLPath!)

        let babyFileURLPath = Bundle.main.path(forResource:"baby-crying", ofType: "wav")
        let babyFileURL = NSURL.fileURL(withPath: babyFileURLPath!)

        soundFiles = [
            helicopterFileURL,
            chainsawFileURL,
            rainFileURL,
            dogFileURL,
            sneezeFileURL,
            wavesFileURL,
            fireFileURL,
            roosterFileURL,
            clockFileURL,
            babyFileURL
        ]
    }

    override func viewDidAppear(_ animated: Bool) {
        let soundClassifier = ESC_10_Sound_Classifier()
        model = soundClassifier.model
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        audioEngine.stop()
    }
    
    @IBAction func analyizeRandomAudioClip(_ sender: Any) {
        //Disable the button so that we an audio clip has to finish playing / being analyized before another one can be triggered
        analyzeAudioButton.isEnabled = false
        
        //Randomly select the audio clip to analyizes
        let selectedAudioClipURL: URL = soundFiles.randomElement()!
        selectedClip.text = "Selected Clip: " + selectedAudioClipURL.lastPathComponent
        prediction.text = "Prediction: "
        
        //Start analysis on the audio file on the background thread
        DispatchQueue.global(qos: .background).async {
            self.startAudioAnalysis(audioFileURL: selectedAudioClipURL)
        }

        //Create a player so we can hear the audio file being analyized
        player.scheduleFile(selectedAudioClipURL, at: .now()) {
            DispatchQueue.main.async {
                self.analyzeAudioButton.isEnabled = true
            }
        }
        
        player.play()

    }
    
    
    func startAudioAnalysis(audioFileURL: URL) {
            
        // Create a new audio file analyzer.
        do {
            audioFileAnalyzer = try SNAudioFileAnalyzer(url: audioFileURL)
        } catch {
            print(error)
        }

        // Create a new observer that will be notified of analysis results.
        let resultsObserver = ResultsObserver()
        
        // Prepare a new request for the trained model.
        do {
            let request = try SNClassifySoundRequest(mlModel: model)
            try audioFileAnalyzer.add(request, withObserver: resultsObserver)

        } catch {
            print(error)
        }
        
        // Analyze the audio data.
        audioFileAnalyzer.analyze()
        
        //Update the UI
        DispatchQueue.main.async {
            self.prediction.text = "Prediction: " + resultsObserver.classificationResult
        }
            
    }
    
    //Create a waveform plot
    func setupAudioPlot(player: AudioPlayer){
    }
   

}

