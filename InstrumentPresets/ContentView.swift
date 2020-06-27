    //
    //  ContentView.swift
    //  InstrumentPresets
    //
    //  Created by nishant gurung on 6/11/20.
    //  Copyright © 2020 nishant. All rights reserved.
    //
    
    import SwiftUI
    //import MidiParser
    import Foundation
    // let presets = Preset_Instruments()
    
    
    struct ContentView: View {
        @State var start_preset:Bool = false
        @State var start_preset1:Bool = false
        @State var selected_preset:String = ""
        @State var selected_preset1:String = ""
        @ObservedObject var Preset_class = Preset_Instruments()
        @State var presets = Preset_model.all()
      //  @State var presets1 = Preset_model1.all()
        @State var instruments = Instruments.all()
       // @State var audio_file = 
        // let Preset_VC:PresetController
        var body: some View {
            //Text("Hello, World!")
            VStack{
                ZStack{
                    VStack{
                        HStack{
                            Text("Track Information")
                            Text(instruments[0].instrumentName)
                            Text(instruments[0].instrumentFamily)
                        }
                        Spacer()
                        HStack{
                            Button(action:{self.start_preset = true
                                self.Preset_class.play()
                            }) {
                                Text("Play")
                            }.padding(20)
                            Spacer()
                            Button(action: {self.start_preset = false
                                self.Preset_class.stop()
                            }) {
                                Text("Stop")
                            }.padding(20)
                        }
                    }
                    
                }
                List{
                    ForEach(0..<presets.count){ index in
                        Button(action: {self.selected_preset = self.presets[index].preset
                            //self.Preset_class.setup_Preset(preset: self.presets[index])
                            print(self.presets[index].name, "play preset")
                            self.Preset_class.preset_value = self.presets[index]
                            self.Preset_class.setup_Preset()
                        }) {
                            Text(self.presets[index].name)
                        }
                        
                        
                    }
                }
                Button(action: {
                    self.Preset_class.saveFile()
                    
                }){
                    Text("Save")
                }
                PresetControllerRespresentable(start_preset: self.$start_preset, start_preset1: self.$start_preset1)
                
            }
            
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
    
    class PresetController:UIViewController{
        //print(Example.str1)
        
        
        //var preset = Preset_Instruments()
        
        override func viewDidLoad(){
            super.viewDidLoad()
        }
    }
    
    struct PresetControllerRespresentable:UIViewControllerRepresentable {
        
        @Binding var start_preset:Bool
        @Binding var start_preset1:Bool
        //  @Binding var selected_preset:String
        //  let preset = Preset_Instruments()
        
        func makeUIViewController(context: Context) -> PresetController {
            
            print(" --- 1")
            let controller = PresetController()
            var data:Data!
            //***********Running MIDIParser
//            let midi = MidiData()
//            let data_URL = Bundle.main.url(forResource: "fmi", withExtension: "mid")
//            //            let data_URL2 = Bundle.main.url(forResource: "midi_test", withExtension: "mid")
//            
//            
//            
//            do {//loading fmi and writing to miditest
//                data = try Data(contentsOf: data_URL!) // load .mid file as `Data` type
//            }
//            catch
//            {
//                print("File did not work")
//            }
//            midi.load(data: data)
//            
//            print(midi.noteTracks[0].patch?.family)
//            print("this is channel 0 ", midi.noteTracks[0].patch?.channel)
//            print(midi.noteTracks[0].patch?.patch)
//            
//            
//            let track = midi.noteTracks[0]
//            let track1 = midi.noteTracks[1]
//            
//            
//            //            track.patch = MidiParser.MidiPatch.init(channel: 5, patch: GMPatch(rawValue: 75)!)
//            track.patch = MidiPatch(channel: 4, patch: .distortionGuitar)
//            track1.patch = MidiPatch(channel: 4, patch: .bagpipe)
//            //            track.trackName = "track1"
//            //            track.add(notes: track.notes)
//            do{
//                try midi.writeData(to: data_URL!)
//            }
//            catch{
//                print(error.localizedDescription, "error local")
//            }
//            
//            let output = midi.createData()
            return controller
        }
        
        func updateUIViewController(_ PresetVC: PresetController, context: Context){
            /*if start_preset  {
             //preset.startEngine()
             preset.play()
             // PresetVC.dummy()
             }
             else   {
             preset.stop()
             }*/
            /*  if selected_preset != "" {
             if !start_preset {
             preset.setup_Preset(preset: selected_preset)
             
             }
             else{
             preset.stop()
             }
             }*/
            
        }
        
        
        typealias UIViewControllerType = PresetController
        
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UINavigationControllerDelegate {
            
            
            let parent: PresetControllerRespresentable
            
            init(_ parent: PresetControllerRespresentable) {
                self.parent = parent
            }
        }
    }
    
    
    
    

