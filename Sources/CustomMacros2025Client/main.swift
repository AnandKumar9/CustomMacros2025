import CustomMacros2025

let a = 34
let b = 50

let (result1, code1) = #stringify(a + b)
let (result2, code2) : (Int, String) = #superStringify(a + b)

print("The value \(result2) was produced by the code \"\(code2)\"")

@AutoCodable
struct User {
    let id: Int
    var name: String
    var nickname: String?
    // computed property: won’t appear in CodingKeys
    var uppercasedName: String { name.uppercased() }
}

let userA = User(id: 1, name: "Mark", nickname: "Junior")
print(User.CodingKeys.id)

let variation = FeatureFlag().getVariation(expressedBasedOn: FeatureXExperiment.self) as! FeatureXExperiment.ConsumableExperiment
print(variation)

/*
The attached macro should
 1. Create a nested enum skipping the cases `on` and `off`, but retaining every other case. Declare a conformance to ConsumableExperimentProtocol.
 2. Add the static function getVariation(), along with the implementation
 */

enum SampleExperiment {
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

extension SampleExperiment : ExperimentProtocol {}

@ConsumableExperiment
enum MusicBand {
    case on
    case off
    case theRollingStones(preferredMember: String, song: String)
    case ledZeppelin(preferredMember: String, song: String)
}

