//
//  Experiment.swift
//  CustomMacros2025
//
//  Created by Anand Kumar on 8/18/25.
//

import CustomMacros2025

protocol ExperimentProtocol {
    static func getVariation(variationName: String, variables: [String: String]) -> ConsumableExperimentProtocol?
}
protocol ConsumableExperimentProtocol {}

@ConsumableExperiment
enum FeatureXExperiment: ExperimentProtocol {
    case on
    case off
    case variationA(headerMessage: String)
    case variationB(headerMessage: String)
}

@ConsumableExperiment
enum FTUXMusicBandGreeting: ExperimentProtocol {
    case on
    case off
    case theRollingStones(preferredMember: String, song: String)
    case ledZeppelin(preferredMember: String, song: String)    
}

struct FeatureFlag {
    let key = "FeatureX.Flag1"
    
    private let variation = "theRollingStones"
    private let variables = ["preferredMember" : "Mick Jagger", "song" : "Sweet Virginia"]
    
    func getVariation(expressedBasedOn experimentType: ExperimentProtocol.Type) -> ConsumableExperimentProtocol? {
        return experimentType.getVariation(variationName: variation, variables: variables)
    }
}
