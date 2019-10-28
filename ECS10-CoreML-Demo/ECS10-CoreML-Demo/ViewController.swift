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
import AudioKitUI

//from https://developer.apple.com/documentation/soundanalysis/analyzing_audio_to_classify_sounds

//https://developer.apple.com/documentation/createml/mlsoundclassifier
class ViewController: UIViewController {
    // Create a new audio engine.

    @IBOutlet weak var selectedClip: UILabel!
    @IBOutlet weak var prediction: UILabel!
    @IBOutlet weak var analyzeAudioButton: UIButton!
    
    var audioEngine = AVAudioEngine()
    var audioFileAnalyzer: SNAudioFileAnalyzer!
    var model: MLModel!
    var soundFiles: [URL]!
    @IBOutlet weak var plotView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        loadAudioFiles()
    }
    
    func loadAudioFiles(){
        
        let helicopterFileURLPath = Bundle.main.path(forResource: "helicopter", ofType: "wav")
        let helicopterFileURL = NSURL.fileURL(withPath: helicopterFileURLPath!)

        let chainsawFileURLPath = Bundle.main.path(forResource: "chainsaw-cutting", ofType: "wav")
        let chainsawFileURL = NSURL.fileURL(withPath: chainsawFileURLPath!)

        let rainFileURLPath = Bundle.main.path(forResource: "rain", ofType: "wav")
        let rainFileURL = NSURL.fileURL(withPath: rainFileURLPath!)

        let dogFileURLPath = Bundle.main.path(forResource: "dog", ofType: "wav")
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
    
    override func viewDidDisappear(_ animated: Bool) {
        do {
            try AudioKit.stop()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func analyizeRandomAudioClip(_ sender: Any) {
        //Disable the button so that we an audio clip has to finish playing / being analyized before another one can be triggered
        analyzeAudioButton.isEnabled = false
        
        //Randomly select the audio clip to analyizes
        let selectedAudioClip: URL = soundFiles.randomElement()!
        selectedClip.text = "Selected Clip: " + selectedAudioClip.lastPathComponent
        prediction.text = "Prediction: "
        
        //Start analysis on the audio file on the background thread
        DispatchQueue.global(qos: .background).async {
            self.startAudioEngine(audioFileURL: selectedAudioClip)
        }

        //Create a player so we can hear the audio file being analyized
        var player: AKPlayer!
        if let audioFile = try? AKAudioFile(readFileName: selectedAudioClip.lastPathComponent) {
            player = AKPlayer(audioFile: audioFile)
            player.completionHandler = {
                self.analyzeAudioButton.isEnabled = true
            }
            player.isLooping = false
            player.buffering = .always
            AudioKit.output = player
            do {
                try AudioKit.start()
            } catch {
                print(error.localizedDescription)
            }
        }
        
        player.play()
        self.setupAudioPlot(player: player)
    }
    
    func startAudioEngine(audioFileURL: URL) {
            
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
    func setupAudioPlot(player: AKPlayer){
        let plot = AKNodeOutputPlot(player, frame: CGRect(x: 0, y: 0, width: plotView.frame.width, height: plotView.frame.height))
        plot.plotType = .rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = AKColor.blue
        plotView.addSubview(plot)
    }
   

}

