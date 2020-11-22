//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by Glenn Posadas on 11/21/20.
//

import Speech
import UIKit

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    let speechRecognizer = SFSpeechRecognizer()
    var audioPlayer: AVAudioPlayer?
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    @IBOutlet weak var tryAgainBottomConstraint: NSLayoutConstraint!
    var confettiView: SAConfettiView!
    
    // MARK: - Overrides
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.speechRecognizer?.delegate = self
        
        self.requestSpeechRecognitionPermission()
    }
    
    private func playFile(_ fileName: String) {
        let soundFilePath = "\(Bundle.main.resourcePath ?? "")/\(fileName).wav"
        let soundFileURL = URL(fileURLWithPath: soundFilePath)
        
        self.audioPlayer = try? AVAudioPlayer(contentsOf: soundFileURL)
        self.audioPlayer?.play()
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil

        if success {
            self.recognizeSpeech()
        } else {
            self.showAlert("Failed to record your voice.")
        }
    }
    
    private func recognizeSpeech() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        guard self.speechRecognizer?.isAvailable == true else {
            self.showAlert("Speech Recognition not available.")
            return
        }
        
        self.speechRecognizer?.defaultTaskHint = .dictation
        
        let request = SFSpeechURLRecognitionRequest(url: audioFilename)
        self.speechRecognizer?.recognitionTask(with: request, resultHandler: { (result, error) in
            if let error = error {
                self.showAlert(error.localizedDescription)
                return
            }
            
            // if we got the final transcription back, print it
            if result?.isFinal == true {
                // pull out the best transcription...
                print((result?.bestTranscription.formattedString)! + "🔥")
                self.handleFinalRecognizedSpeechResult(result!.bestTranscription.formattedString)
            }
        })
    }
    
    private func handleFinalRecognizedSpeechResult(_ speechResult: String) {
        if speechResult.contains("a") || speechResult.contains("A") {
            // Create confetti view
            self.confettiView = SAConfettiView(frame: self.view.bounds)
            
            // Set colors (default colors are red, green and blue)
            self.confettiView.colors = [UIColor(red:0.95, green:0.40, blue:0.27, alpha:1.0),
                                   UIColor(red:1.00, green:0.78, blue:0.36, alpha:1.0),
                                   UIColor(red:0.48, green:0.78, blue:0.64, alpha:1.0),
                                   UIColor(red:0.30, green:0.76, blue:0.85, alpha:1.0),
                                   UIColor(red:0.58, green:0.39, blue:0.55, alpha:1.0)]
            self.confettiView.intensity = 0.5
            
            // Set type
            self.confettiView.type = .diamond
            self.view.addSubview(self.confettiView)
            
            self.confettiView.startConfetti()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                self.confettiView.stopConfetti()
            }
            
            self.playFile("welldone")
            
        } else {
            UIView.animate(withDuration: 0.3) {
                self.tryAgainBottomConstraint.constant = 10000.0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Permissions
    
    private func requestAudioRecordingPermission() {
        self.recordingSession = AVAudioSession.sharedInstance()

        do {
            try self.recordingSession.setCategory(.record, mode: .default)
            try self.recordingSession.setActive(true)
            self.recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Allowed audio recording")
                    } else {
                        self.showAlert("Your permission is required to record an audio.")
                    }
                }
            }
        } catch {
            self.showAlert(error.localizedDescription)
        }
    }
    
    private func requestSpeechRecognitionPermission() {
        // Make the authorization request
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            // The authorization status results in changes to the
            // app’s interface, so process the results on the app’s
            // main queue.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("Authorized")
                    self.playFile("question")
                    self.requestAudioRecordingPermission()
                    
                case .notDetermined:
                    break
                    
                default:
                    self.showAlert("Please allow speech recognition")
                    self.requestAudioRecordingPermission()
                }
            }
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func sayYourAnswer(_ sender: Any) {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                self.finishRecording(success: true)
            }
        } catch {
            finishRecording(success: false)
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension ViewController: SFSpeechRecognizerDelegate {

}

// MARK: - AVAudioRecorderDelegate

extension ViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}
