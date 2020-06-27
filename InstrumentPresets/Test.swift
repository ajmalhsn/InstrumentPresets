import Foundation
import AVFoundation
import CoreMIDI
import AudioUnit
import MidiParser

class Preset_Instruments: ObservableObject{
    
    @Published var preset_value:    Preset_model  = Preset_model(name: "guitar", preset: "nylon-string-guitar")
    @Published var selected_instrument: Instruments!
    
    
    var audioSession = AVAudioSession.sharedInstance()
    var all_instruments = Instruments.all()
    
    // setting up midiSynth with AVAudioUnit
    var midiSynth: AVAudioUnitMIDISynth!
    var patches = [UInt32]()
    
    
    
    
    
    // Track 0 Setup
    var engine: AVAudioEngine!
    private var mixer: AVAudioMixerNode!
    var sampler: AVAudioUnitSampler!
    var sequencer: AVAudioSequencer!
    var file_details: Midi_model = Midi_model()
    var tracks:[Track_model] =  [Track_model()]
    //    vocal track setup
    var vocalEngine: AVAudioEngine!
    var vocalPlayer: AVAudioPlayerNode!
    var sequencerVocal: AVAudioSequencer!  // AVPLayer
    var audioFileBuffer: AVAudioPCMBuffer!
    var midiPlayer: AVMIDIPlayer!
    init(){
        // adding midi synth
        
        
        //        tracl 0 init
        
        midiPlayer = AVMIDIPlayer()
        engine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        mixer = AVAudioMixerNode()
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        
        
       //MIDI Parser
        guard let fileNewURL = Bundle.main.url(forResource: "fmi", withExtension: "mid") else {
            print("could not load aupreset")
            return
        }
        let midi = MidiData()
        var data: Data!
        
        do {
        // load .mid file as `Data` type
        data = try Data(contentsOf: fileNewURL)
        }
        catch {
            print("error noticed")
        }
            
        midi.load(data: data)
        print(midi.tempoTrack)
        print(midi.noteTracks.count)
        print(midi.infoDictionary)
        print(midi.noteTracks[0].patch)
        print(midi.noteTracks[1].patch)
        print(midi.noteTracks[2].patch)
       // tracks.reserveCapacity(midi.noteTracks.count)
        for i in 0..<midi.noteTracks.count {
                if(midi.noteTracks[i].patch?.channel != 9 ){
                    if let foo = all_instruments.first(where: {$0.programChange == midi.noteTracks[i].patch?.patch.rawValue})  {
                        tracks.insert(Track_model(instrument: foo,channel: midi.noteTracks[i].patch?.channel,Gain: 0,pitch_bend: 0),at:i)
                    }
                }
        }
        file_details.tracks = tracks
        file_details.Tempo = midi.tempoTrack.extendedTempos[0].bpm
        file_details.masterGain = 0
        
        
        
        //        common setup
        loadPreset(preset: preset_value.preset)
        setupSequencerFile()
               //setupVocalFile() // added for vocal
        startEngine()
        setSessionPlayback()
        
    }
    func setup_Preset() {
        //init()
        engine.detach(sampler)
        engine.attach(sampler)
        sequencer.stop()
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        
        loadPreset(preset: preset_value.preset)
        startEngine()
        setSessionPlayback()
        
    }
    func setupVocalFile(){
        guard let filePath: String = Bundle.main.path(forResource: "twinle", ofType: "m4a") else{ return }
        print("\(filePath)", "vocal file")
        let fileURL: URL = URL(fileURLWithPath: filePath)
        guard let audioFile = try? AVAudioFile(forReading: fileURL) else{ return }
        
        let audioFormat = audioFile.processingFormat
        let audioFrameCount = UInt32(audioFile.length)
        guard let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)  else{ return }
        do{
            try audioFile.read(into: audioFileBuffer)
        } catch{
            print("over")
        }
        vocalEngine = AVAudioEngine()
        vocalPlayer = AVAudioPlayerNode()
        let mainMixer = vocalEngine.mainMixerNode
        vocalEngine.attach(vocalPlayer)
        vocalEngine.connect(vocalPlayer, to:mainMixer, format: audioFileBuffer.format)
        try? vocalEngine.stop()
        try? vocalEngine.start()
        vocalPlayer.play()
        vocalPlayer.scheduleBuffer(audioFileBuffer, at: nil, options:AVAudioPlayerNodeBufferOptions.loops)
        
        
        
        
    }
    func copyFilesFromBundleToDocumentsFolderWith(fileExtension: String) {
        if let resPath = Bundle.main.resourcePath {
            do {
                let dirContents = try FileManager.default.contentsOfDirectory(atPath: resPath)
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                let filteredFiles = dirContents.filter{ $0.contains(fileExtension)}
                for fileName in filteredFiles {
                    if let documentsURL = documentsURL {
                        let sourceURL = Bundle.main.bundleURL.appendingPathComponent(fileName)
                        let destURL = documentsURL.appendingPathComponent(fileName)
                        do { try FileManager.default.copyItem(at: sourceURL, to: destURL) } catch { }
                    }
                }
            } catch { }
        }
    }
    func playVocal(){
        print("playvocal func")
        setupVocalFile()
    }
    func setupSoundFont(){
        let fileManager = FileManager.default
        let documentDirectory = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:true)
        let soundFont = "Touhou.sf2"
        let soundFontURL = documentDirectory.appendingPathComponent(soundFont)
        midiSynth = try! AVAudioUnitMIDISynth(soundBankURL: soundFontURL)
    }
    func setupMidiSynth(){
        // setting up midi synth with distortion AUdioUnit
        let distortion = AVAudioUnitDistortion()
        //without distortion
        engine.attach(midiSynth)
        //with distortion
        engine.connect(distortion, to: engine.mainMixerNode, format: nil)
    }
    func setupSequencerFile() {
        // MARK: Either we will send 4 midi files for each track from backend or strip into 4 midi files on front end
        //NEXT: We found a solution to change program instruments so no need to strip and send tracks from backend
        guard let fileNewURL = Bundle.main.url(forResource: "midi_test", withExtension: "mid") else {
            print("could not load aupreset")
            return
        }
        
        
        // Attaching engine to sequencer
        self.sequencer = AVAudioSequencer(audioEngine: self.engine)
        
        
        let options = AVMusicSequenceLoadOptions()
        
        // adding for midiSynth
    
        
        // MARK : This file is what we are playing
        if let fileURL = Bundle.main.url(forResource: "fmi1", withExtension: "mid") {
            do {
                try sequencer.load(from: fileURL, options: options)
                print("loaded \(fileURL)")
                
            } catch {
                print("something screwed up \(error)")
                return
            }
        }
       // var tracks:[AVMusicTrack] = sequencer.tracks
        
        
//        MusicSequenceGetIndTrack(sequencer, i, &tracks);
//        MusicTrackGetProperty(tracks, kSequenceTrackProperty_TrackLength,
//                                    &trackLength, &propsize);
        sequencer.prepareToPlay()
      }
    func play(){
        if sequencer.isPlaying {
            stop()
        }
        
        sequencer.currentPositionInBeats = TimeInterval(0)
        
        do {
            try sequencer.start()
        } catch {
            print("cannot start \(error)")
        }
        print("Sound is playing0")
    }
    
    func stop() {
        //        sequencer for track 0
        sequencer.stop()
        print("Sound is stopped")
        //        sequencer1 for track 1
     //   sequencer1.stop()
        
        // stopping vocal
        vocalEngine.stop()
        vocalPlayer.stop()
        
    }
    func setPreload(enabled: Bool) throws {
        guard let engine = self.engine else { return print("Synth must be connected to an engine.") }
        if !engine.isRunning { print("Engine must be running.") }
        
        var enabledBit = enabled ? UInt32(1) : UInt32(0)
        
        let status = AudioUnitSetProperty(
            self.sampler.audioUnit,
            AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &enabledBit,
            UInt32(MemoryLayout<UInt32>.size))
        if status != noErr {
            print("\(status)")
        }
    }
    func playUsingMidiPlayer(fileURL: URL){
        do {
            try midiPlayer = AVMIDIPlayer(contentsOf: fileURL, soundBankURL: nil)
            midiPlayer?.prepareToPlay()
        } catch {
            print(error.localizedDescription,"could not create MIDI player")
        }
        
        midiPlayer?.play {
            print("finished playing")
        }
        
        var stillGoing = true
        while stillGoing {
            midiPlayer?.play {
                print("finished playing")
                stillGoing = false
            }
            usleep(100000)
        }
    }
    
    func saveFile(){
        self.engine.stop()
        self.sequencer.stop()
        
        print("save file")
        // setting up AVAudioSession
        
        try! audioSession.setCategory(AVAudioSession.Category.playback, options: .allowBluetooth)
        
        
//        let audioSession: AVAudioSession
        
        try! audioSession.setActive(true)
        print("after session")
        // setting up urls
        let fileManager = FileManager.default
        let fileToLoadName = "fmi1.mid"
        let destFile = "myra.wav"
        
        // use do try to catch any errors upfront and play using midi player
        do{
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:true)
            print(documentDirectory)
            let readingFileURL = documentDirectory.appendingPathComponent(fileToLoadName)
            var midiFile1 = sequencer.data(withSMPTEResolution: 0, error: nil)
            let midiFile = try Data(contentsOf: readingFileURL)
            print(midiFile.description, "descrip")
            midiFile.base64EncodedData()
            print(midiFile, "descrip")
            print(midiFile1, "descrip1")
            let destFileURL = documentDirectory.appendingPathComponent(destFile)
           
            // play using midi player. just gives sine wave sound
//                self.playUsingMidiPlayer(fileURL: readingFileURL)
            
            print("after play")
            errno = 0
            // setting up soundfont
            let soundFont = "Touhou.sf2"
            let soundFontURL = documentDirectory.appendingPathComponent(soundFont)
            print(soundFontURL, "soundFontURL")
            // logic to write the file
//            try AVAudioUnitMIDISynth(soundBankURL: soundFontURL).setPreload(enabled: true)
            AVAudioUnitMIDISynth.load()
            try AVAudioUnitMIDISynth.init(soundBankURL: soundFontURL)
            let processingFile = try MIDIFileBouncer(midiFileData: midiFile1, soundBankURL: soundFontURL, audioSession: audioSession)
            print(processingFile, "processing file")
            print("adfter processing")
            try processingFile.bounce(toFileURL: destFileURL)
            
        }
        catch{
            print(error.localizedDescription, "error in file urls")
        }
        
        
        
        
        
        
    }
    func loadPreset(preset: String) {
        
        guard let preset = Bundle.main.url(forResource: preset, withExtension: "aupreset") else {
            print("could not load aupreset")
            return
        }
        print("loaded preset \(preset)")
        //        setup for sampler for track 0
        do {
            try sampler.loadInstrument(at: preset)
        } catch {
            print("error loading preset \(error)")
        }
    }
    func setSessionPlayback() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try
//                audioSession.setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
                audioSession.setCategory(.playback, mode: .default)
        } catch {
            print("couldn't set category \(error)")
            return
        }
        
        do {
            try audioSession.setActive(true)
        } catch {
            print("couldn't set category active \(error)")
            return
        }
    }
    func startEngine() {
        
        if engine.isRunning {
            print("audio engine already started")
            engine.stop()
            //return
        }
        
        do {
            try engine.start()
            print("audio engine started")
        } catch {
            print("oops \(error)")
            print("could not start audio engine")
        }
        
        
    }
}


extension String {
    func appendingPathComponent(_ string: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(string).path
    }
}

extension String {
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}



