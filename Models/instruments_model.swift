//
//  instruments_model.swift
//  InstrumentPresets
//
//  Created by Ajmal Hussain on 6/26/20.
//  Copyright © 2020 nishant. All rights reserved.
//

import Foundation

struct Instruments:Identifiable {
    var id = UUID()
    var instrumentName:String
    let instrumentFamily:String
    var programChange : UInt8?
    var description: String?
    var imageURL: String  // for user explaination
}
extension Instruments {
    
    static func all() -> [Instruments] {
        
        return [
            Instruments(instrumentName:"nylon sring guitar", instrumentFamily:  "guitar",programChange: UInt8(24),description:  "this will give a classical guitar feel to your song",imageURL: "guitar_nylon_string"),
            Instruments(instrumentName:"steel string guitar", instrumentFamily:  "guitar",programChange: UInt8(25),description:  "this will give a mettalic beats to your song",imageURL: "guitar_steel_string"),
            Instruments(instrumentName:"violin", instrumentFamily:  "strings",programChange: UInt8(40),description:  "Ah the sound of violin",imageURL: "image_violin"),
            Instruments(instrumentName:"Acoustic Grand", instrumentFamily:  "Piano",programChange: UInt8(0),description:  "CLassical piano",imageURL: "image_piano"),
            Instruments(instrumentName:"Glistening Pad", instrumentFamily:  "Synth Pad",programChange: UInt8(89),description:  "Synthesizer tunes",imageURL: "image_synth_pad")
        ]
        
    }
    
}
