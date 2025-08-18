//
//  Experiment.swift
//  CustomMacros2025
//
//  Created by Anand Kumar on 8/18/25.
//

protocol ExperimentProtocol {
    static func getVariation(variationName: String, variables: [String: String]) -> ConsumableExperimentProtocol?
}
protocol ConsumableExperimentProtocol {}

enum FeatureXExperiment {
    case on
    case off
    case variationA(headerMessage: String)
    case variationB(headerMessage: String)
    
    enum ConsumableExperiment: ConsumableExperimentProtocol {
        case variationA(headerMessage: String)
        case variationB(headerMessage: String)
    }
    
    static func getVariation(variationName: String, variables: [String: String]) -> ConsumableExperimentProtocol? {
        return ConsumableExperiment.variationA(headerMessage: variables["headerMessage"]!)
    }
}

extension FeatureXExperiment : ExperimentProtocol {}

struct FeatureFlag {
    let key = "FeatureX.Flag1"
    private let variation = "variationA"
    private let variables = ["headerMessage" : "Welcome"]
    
    func getVariation(expressedBasedOn experimentType: ExperimentProtocol.Type) -> ConsumableExperimentProtocol? {
        return experimentType.getVariation(variationName: variation, variables: variables)
    }
}
