import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

struct MacroLog: DiagnosticMessage {
    var diagnosticID: SwiftDiagnostics.MessageID
    
    let message: String
    let severity: DiagnosticSeverity
    let id = MessageID(domain: "AutoCodableMacros", id: "log")
}

extension MacroLog {
    static func note(_ text: String) -> MacroLog {
        .init(diagnosticID: MessageID(domain: "X", id: "Y"), message: text, severity: .note)
    }
    static func warning(_ text: String) -> MacroLog {
        .init(diagnosticID: MessageID(domain: "X", id: "Y"), message: text, severity: .warning)
    }
    static func error(_ text: String) -> MacroLog {
        .init(diagnosticID: MessageID(domain: "X", id: "Y"), message: text, severity: .error)
    }
}

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct SuperStringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        print("Hi there")
        context.diagnose(Diagnostic(node: node, message: MacroLog.note("Expanding it")))
        
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description.uppercased()))"
    }
}

public struct AutoCodableMacro: MemberMacro, ExtensionMacro {

  // Inject the CodingKeys enum as a member
  public static func expansion(of node: AttributeSyntax,
                               providingMembersOf decl: some DeclGroupSyntax,
                               in context: some MacroExpansionContext) throws -> [DeclSyntax] {

    let storedNames: [String] = decl.memberBlock.members.compactMap { member in
        
      guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { return nil }
        
      if varDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) == true {
        return nil
      }
        
      guard let binding = varDecl.bindings.first,
            binding.accessorBlock == nil,
            let ident = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
      else { return nil }
      
        return ident
    }

    let cases = storedNames.map { "case \($0)" }.joined(separator: "\n    ")
      
    let codingKeysEnum: DeclSyntax = """
    enum CodingKeys: String, CodingKey {
        \(raw: cases)
    }
    """
    return [codingKeysEnum]
  }

  // Provide the `: Codable` via an extension macro
  public static func expansion(of node: AttributeSyntax,
                               attachedTo declaration: some DeclGroupSyntax,
                               providingExtensionsOf type: some TypeSyntaxProtocol,
                               conformingTo protocols: [TypeSyntax],
                               in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {

    // Empty extension that adds conformance
    let declSyntax: DeclSyntax = """
    extension \(type): Codable {}
    """
    guard let ext = declSyntax.as(ExtensionDeclSyntax.self) else { return [] }
    return [ext]
  }
}

public struct ConsumableExperimentMacro: MemberMacro {
    public static func expansion(of attribute: AttributeSyntax, providingMembersOf decl: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {

        // We only support enums.
        guard let enumDecl = decl.as(EnumDeclSyntax.self) else { return [] }

        // Collect retained cases: everything except `on` and `off`,
        // preserving associated value parameter lists as-is.
        var retainedCaseLines: [String] = []

        for member in enumDecl.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }

            for element in caseDecl.elements {
                let name = element.name.text
                if name == "on" || name == "off" {
                    continue
                }

                if let params = element.parameterClause {
                    // Reuse the original parameter clause text verbatim
                    retainedCaseLines.append("case \(name)\(params.description)")
                } else {
                    retainedCaseLines.append("case \(name)")
                }
            }
        }

        // If nothing to retain, still generate an empty enum conforming to the protocol.
        // (You can also choose to return [] if you prefer to inject nothing.)
        let casesBody = retainedCaseLines.joined(separator: "\n")

        // Build the nested enum:
        //   enum ConsumableExperiment: ConsumableExperimentProtocol { ... }
        let nestedEnumSource =
        """
        enum ConsumableExperiment: ConsumableExperimentProtocol {
            \(casesBody)
        }
        """

        let nestedEnum: DeclSyntax = DeclSyntax(stringLiteral: nestedEnumSource)
        return [nestedEnum]
    }
}

@main
struct CustomMacros2025Plugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        SuperStringifyMacro.self,
        AutoCodableMacro.self,
        ConsumableExperimentMacro.self
    ]
}
