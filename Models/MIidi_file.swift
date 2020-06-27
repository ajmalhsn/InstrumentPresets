//
//  MIidi_file.swift
//  InstrumentPresets
//
//  Created by Ajmal Hussain on 6/26/20.
//  Copyright © 2020 nishant. All rights reserved.
//

import Foundation
struct Midi_model: Identifiable {
    
    let id = UUID()
    var tracks: [Track_model]?
    var masterGain: Int?
    var Tempo: Double?
    var time_signature: Int?
}

