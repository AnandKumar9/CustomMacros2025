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

enum Experiment {
    case on
    case off
    case variationA
    case variationB
    
    enum ExperimentToUse {
        case variationA
        case variationB
    }
}
