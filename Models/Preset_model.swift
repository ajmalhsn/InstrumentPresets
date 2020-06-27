//
//  Preset_model.swift
//  InstrumentPresets
//
//  Created by Ajmal Hussain on 6/26/20.
//  Copyright © 2020 nishant. All rights reserved.
//

import Foundation

struct Preset_model: Identifiable {
    
    let id = UUID()
    let name: String
    let preset: String
    
}

extension Preset_model {
    
    static func all() -> [Preset_model] {
        
        return [
            Preset_model(name:"guitar", preset:  "nylon-string-guitar"),
            Preset_model(name:"nylon-string-guitar", preset: "Sound_Nylon_Guitar"),
            Preset_model(name:"drums with bass", preset: "bass-drum"),
            Preset_model(name:"Normal drums", preset: "Drums")
        ]
        
    }
    
}
