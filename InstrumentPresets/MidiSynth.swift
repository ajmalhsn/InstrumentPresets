//
//  MidiSynth.swift
//  InstrumentPresets
//
//  Created by Mayank Thakur on 6/21/20.
//  Copyright © 2020 nishant. All rights reserved.
//

import Foundation
import CoreMIDI
import AVFoundation
import MidiParser


class AVAudioUnitMIDISynth: AVAudioUnitMIDIInstrument,ObservableObject {
    init(soundBankURL: URL) throws {
        let description = AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice,
            componentSubType: kAudioUnitSubType_MIDISynth,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        super.init(audioComponentDescription: description)
        
        var bankURL = soundBankURL
        
        let status = AudioUnitSetProperty(
            self.audioUnit,
            AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &bankURL,
            UInt32(MemoryLayout<URL>.size))
        
        
        if status != OSStatus(noErr) {
            print("\(status)")
        }
    }
    
     func setPreload(enabled: Bool) throws {
           guard let engine = self.engine else {
            print("Synth must be connected to an engine.")
            return
            
        }
           if !engine.isRunning {
             print("Engine must be running.")
            return
        }
           
           var enabledBit = enabled ? UInt32(1) : UInt32(0)
           
           let status = AudioUnitSetProperty(
               self.audioUnit,
               AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
               AudioUnitScope(kAudioUnitScope_Global),
               0,
               nil,
               UInt32(MemoryLayout<UInt32>.size))
           if status != noErr {
               print("\(status)", "status")
           }
       }
}

class MIDIFileBouncer {
    fileprivate let audioSession: AVAudioSession
    
    fileprivate var engine: AVAudioEngine!
    fileprivate var sampler: AVAudioUnitMIDISynth!
    fileprivate var sequencer: AVAudioSequencer!
    

    deinit {
        self.engine.disconnectNodeInput(self.sampler, bus: 0)
        self.engine.detach(self.sampler)
        self.sequencer = nil
        self.sampler = nil
        self.engine = nil
    }
    
   
    
    init(midiFileData: Data, soundBankURL: URL, audioSession: AVAudioSession) throws {
        self.audioSession = audioSession
                
        self.engine = AVAudioEngine()
        self.sampler = try AVAudioUnitMIDISynth(soundBankURL: soundBankURL)
        
        // probably instance variables
        let melodicBank:UInt8 = UInt8(kAUSampler_DefaultMelodicBankMSB)
        let gmMarimba:UInt8 = 12
        //let gmHarpsichord:UInt8 = 6
        self.sampler.sendProgramChange(gmMarimba, bankMSB: melodicBank, bankLSB: 0, onChannel: 0)
        self.sampler.sendMIDIEvent(1, data1: 8, data2: 9)
//        sampler.loadPreset(preset: "nylon-string-guitar")
        
        self.engine.attach(self.sampler)
        
        // We'll tap the sampler output directly for recording
        // and mute the mixer output so that bouncing is silent to the user.
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        let mixer = self.engine.mainMixerNode
        mixer.outputVolume = 100.0
        self.engine.connect(self.sampler, to: mixer, format: audioFormat)
        
        self.sequencer = AVAudioSequencer(audioEngine: self.engine)
        try self.sequencer.load(from: midiFileData, options: [])
        print(self.sequencer.tracks, "seq tracks")
        
       // print(sequencer.tracks[0].observationInfo)
        self.sequencer.prepareToPlay()
        
    }
}

extension MIDIFileBouncer {
    
//    let preset_value = "nylon"
    func bounce(toFileURL fileURL: URL) throws {
        
        print("inside bounce")
        let outputNode = self.sampler!
        print("after outputnode")
        let sequenceLength = self.sequencer.tracks.map({ $0.lengthInSeconds }).max() ?? 0
        print("after sequenceLength")
        var writeError: NSError? = nil
        print("after var write erro")
        print(outputNode.outputFormat(forBus: 0).settings, "output file settings")
        
        let outputFile = try AVAudioFile(forWriting: fileURL, settings: outputNode.outputFormat(forBus: 0).settings)
        
        // added
         print("format")
//        let SAMPLE_RATE =  Float64(16000.0)
//        let outputFormatSettings = [
//        AVFormatIDKey:kAudioFormatLinearPCM,
//        AVLinearPCMBitDepthKey:32,
//        AVLinearPCMIsFloatKey: true,
//        //  AVLinearPCMIsBigEndianKey: false,
//        AVSampleRateKey: SAMPLE_RATE,
//        AVNumberOfChannelsKey: 1
//        ] as [String : Any]
//
//        let outputFile = try? AVAudioFile(forWriting: fileURL, settings: outputFormatSettings, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: true)
//        let bufferFormat = AVAudioFormat(settings: outputFormatSettings)
//        let dataInput = self.sequencer.data(withSMPTEResolution: 0, error: nil)
//        print(type(of: dataInput), "dataInput")
//        let outputBuffer = AVAudioPCMBuffer(pcmFormat: bufferFormat!, frameCapacity: AVAudioFrameCount(dataInput.count))
//        outputBuffer!.frameLength = AVAudioFrameCount( dataInput.count )

            
//        let outputFile = try! AVAudioFile(forWriting: fileURL, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC], commonFormat: .pcmFormatFloat32, interleaved: true)

        print("before try audiosession")
//        let sz : UInt32 = 4096
//        do{try self.engine.enableManualRenderingMode(.offline, format: outputFile.processingFormat, maximumFrameCount: sz)}catch{print(error.localizedDescription, "error in saving")}
        
        try self.audioSession.setActive(true)
        self.engine.prepare()
        try self.engine.start()
        
        // Load the patches by playing the sequence through in preload mode.
        
        self.sequencer.rate = 100.0
        self.sequencer.currentPositionInSeconds = 0
        self.sequencer.prepareToPlay()
        // modify properties for below
        try self.sampler.setPreload(enabled: true)
//        self.sampler.sendProgramChange(56, bankMSB: 3, bankLSB: 8, onChannel: 1)
        try self.sequencer.start()
        while (self.sequencer.isPlaying
            && self.sequencer.currentPositionInSeconds < sequenceLength) {
                usleep(100000)
        }
        self.sequencer.stop()
        usleep(500000) // ensure all notes have rung out
        // modify properties for below
        try self.sampler.setPreload(enabled: false)
        self.sequencer.rate = 1.0
        
        
        
        

//        try! self.sampler.loadPreset(at: presetFileURL)
        
//        do{
//        try self.sampler.sendProgramChange(UInt8(50), onChannel: 1)
//        }
//        catch{
//            print(error.localizedDescription)
//        }
       
//        self.sampler.sendProgramChange(56, bankMSB: 8, bankLSB: 7, onChannel: 1)
        
        //added vol
//        self.sampler.engine?.mainMixerNode.outputVolume = 1.0
        // Get sequencer ready again.
        self.sequencer.currentPositionInSeconds = 0
        self.sequencer.prepareToPlay()
//        try self.sequencer.start()
        
        
                
        // Start recording.
        
        // i had my samples in doubles, so convert then write

//        for i in 0..<dataInput.count {
//            outputBuffer?.floatChannelData!.pointee[i] = Float( dataInput[i] )
//        }
        
        
//        do {
//
//                       print("started writing")
//            try outputFile!.write(from: outputBuffer!)
//                   } catch {
//                       writeError = error as NSError
//                   }
        
        // original below commented for testing
        
        
        
        
        
        
        
        
        
        //
        outputNode.installTap(onBus: 0, bufferSize: 4096, format: outputNode.outputFormat(forBus: 0)) { (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            do {
                // MARK: MAGIC HAPPENED HERE
                let melodicBank:UInt8 = UInt8(kAUSampler_DefaultMelodicBankMSB)
                
                let gmMarimba:UInt8 = 12
                //let gmHarpsichord:UInt8 = 2
                outputNode.sendProgramChange(gmMarimba, onChannel: 0)
                // code for applying preset and saving
//                guard let preset = Bundle.main.url(forResource: "nylon-string-guitar", withExtension: "aupreset") else {
//                                  print("could not load aupreset")
//                                  return
//                              }
//                try outputNode.loadPreset(at: preset)
                print("started writing")
                try outputFile.write(from: buffer)
                print(buffer.floatChannelData?.pointee.hashValue.description)
            } catch {
                writeError = error as NSError
            }
        }
        print("finished writing")
        // Add silence to beginning.
        usleep(200000)

        // Start playback.
        try self.sequencer.start()
        // Continuously check for track finished or error while looping.
        while (self.sequencer.isPlaying
            && writeError == nil
            && self.sequencer.currentPositionInSeconds < sequenceLength) {
            usleep(100000)
        }
        
        // Ensure playback is stopped.
        self.sequencer.stop()
        
        // Add silence to end.
        usleep(1000000)

        // Stop recording.
        outputNode.removeTap(onBus: 0)
        // Midi Parser
            
//        midi2.load(data: data2)
//        print(midi2.tempoTrack)
//        print(midi2.noteTracks.count)
//        print(midi2.infoDictionary)
//        print(midi2.noteTracks[0].patch)
//        print(midi2.noteTracks[1].patch)
//        print(midi2.noteTracks[2].patch)
        self.engine.stop()
        try self.audioSession.setActive(false)
        
        // Return error if there was any issue during recording.
        if let writeError = writeError {
            throw writeError
        }
    }
}

