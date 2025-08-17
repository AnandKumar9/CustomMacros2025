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

@main
struct CustomMacros2025Plugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        SuperStringifyMacro.self,
//        AutoCodableMacro.self
    ]
}
