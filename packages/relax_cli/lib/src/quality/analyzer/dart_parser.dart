import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import '../models/quality_models.dart';

/// A method or top-level function extracted from the AST.
class ParsedMethod {
  ParsedMethod({
    required this.name,
    required this.isAsync,
    required this.returnType,
    required this.params,
    required this.calls,
    required this.startLine,
    required this.endLine,
    required this.bodySource,
    required this.cyclomaticComplexity,
  });

  final String name;
  final bool isAsync;
  final String returnType;
  final List<ParamInfo> params;
  final List<FunctionCallRef> calls;
  final int startLine;
  final int endLine;

  /// Source text of the body (for duplication hashing); empty for abstract.
  final String bodySource;
  final int cyclomaticComplexity;

  int get lineCount => endLine - startLine + 1;

  FunctionSignature get signature => FunctionSignature(
    name: name,
    isAsync: isAsync,
    returnType: returnType,
    params: params,
  );
}

/// A field or constructor-injected dependency of a class.
class ParsedField {
  const ParsedField({required this.name, required this.type});

  final String name;
  final String type;
}

/// A class extracted from the AST with its inheritance and members.
class ParsedClass {
  ParsedClass({
    required this.name,
    required this.superclass,
    required this.interfaces,
    required this.mixins,
    required this.annotations,
    required this.methods,
    required this.fields,
    required this.isAbstract,
  });

  final String name;
  final String? superclass;
  final List<String> interfaces;
  final List<String> mixins;
  final List<String> annotations;
  final List<ParsedMethod> methods;

  /// Instance fields and constructor-injected dependencies (name → type).
  final List<ParsedField> fields;
  final bool isAbstract;

  /// All named types this class extends/implements/mixes-in.
  List<String> get supertypes => [?superclass, ...interfaces, ...mixins];
}

/// An import directive with the details needed by the unused-import rule.
class ParsedImport {
  ParsedImport({
    required this.uri,
    required this.line,
    required this.shownNames,
    required this.hasPrefix,
  });

  final String uri;
  final int line;

  /// Names in a `show` combinator, if any.
  final List<String> shownNames;
  final bool hasPrefix;
}

/// The structural result of parsing a single Dart file. All `package:analyzer`
/// dependencies are confined to this file.
class ParsedFile {
  ParsedFile({
    required this.imports,
    required this.importDirectives,
    required this.classes,
    required this.topLevelFunctions,
    required this.lineCount,
    required this.hasParseErrors,
    required this.referencedNames,
  });

  final List<String> imports;
  final List<ParsedImport> importDirectives;
  final List<ParsedClass> classes;
  final List<ParsedMethod> topLevelFunctions;
  final int lineCount;
  final bool hasParseErrors;

  /// Every simple identifier referenced anywhere in the file (invocations,
  /// tear-offs, type references). Used by the dead-code rule to reliably tell
  /// whether a declaration is actually used — including as a callback.
  final Set<String> referencedNames;
}

/// Parses Dart source into a [ParsedFile] using the unresolved syntactic AST
/// (`parseString`). Unresolved parsing is fast and sufficient for the
/// heuristics used by the quality subsystem — it does not require a configured
/// analysis context or resolved type information.
class DartParser {
  ParsedFile parse(String content) {
    final result = parseString(content: content, throwIfDiagnostics: false);
    final unit = result.unit;
    final lineInfo = result.lineInfo;

    final imports = <String>[];
    final importDirectives = <ParsedImport>[];
    for (final directive in unit.directives) {
      if (directive is ImportDirective) {
        final uri = directive.uri.stringValue;
        if (uri == null) continue;
        imports.add(uri);
        final shown = <String>[];
        for (final combinator in directive.combinators) {
          if (combinator is ShowCombinator) {
            shown.addAll(combinator.shownNames.map((n) => n.name));
          }
        }
        importDirectives.add(
          ParsedImport(
            uri: uri,
            line: lineInfo.getLocation(directive.offset).lineNumber,
            shownNames: shown,
            hasPrefix: directive.prefix != null,
          ),
        );
      }
    }

    final referencedNames = <String>{};
    unit.accept(_ReferencedNameVisitor(referencedNames));

    final classes = <ParsedClass>[];
    final topLevel = <ParsedMethod>[];
    for (final decl in unit.declarations) {
      if (decl is ClassDeclaration) {
        classes.add(_parseClass(decl, lineInfo));
      } else if (decl is FunctionDeclaration) {
        topLevel.add(
          _parseExecutable(
            name: decl.name.lexeme,
            returnType: decl.returnType?.toSource() ?? 'dynamic',
            params: decl.functionExpression.parameters,
            body: decl.functionExpression.body,
            lineInfo: lineInfo,
          ),
        );
      }
    }

    return ParsedFile(
      imports: imports,
      importDirectives: importDirectives,
      classes: classes,
      topLevelFunctions: topLevel,
      lineCount: lineInfo.lineCount,
      hasParseErrors: result.errors.any(
        (e) => e.diagnosticCode.severity.name == 'ERROR',
      ),
      referencedNames: referencedNames,
    );
  }

  ParsedClass _parseClass(ClassDeclaration decl, LineInfo lineInfo) {
    final methods = <ParsedMethod>[];
    final fields = <ParsedField>[];
    // `ClassBody.members` is only exposed on the sealed `BlockClassBody`
    // subtype in analyzer 10.x; the deprecated getter is the stable path.
    // ignore: deprecated_member_use
    final members = decl.members;
    for (final member in members) {
      if (member is MethodDeclaration && !member.isGetter && !member.isSetter) {
        methods.add(
          _parseExecutable(
            name: member.name.lexeme,
            returnType: member.returnType?.toSource() ?? 'dynamic',
            params: member.parameters,
            body: member.body,
            lineInfo: lineInfo,
          ),
        );
      } else if (member is FieldDeclaration) {
        final type = member.fields.type?.toSource() ?? 'dynamic';
        for (final v in member.fields.variables) {
          fields.add(ParsedField(name: v.name.lexeme, type: type));
        }
      } else if (member is ConstructorDeclaration) {
        // Constructor field-initializing params (`this.repository`) declare
        // dependency fields whose type lives on the field, but capture any
        // typed ones directly too.
        for (final param in member.parameters.parameters) {
          final node = param is DefaultFormalParameter
              ? param.parameter
              : param;
          if (node is FieldFormalParameter) {
            final t = node.type?.toSource();
            if (t != null) {
              fields.add(ParsedField(name: node.name.lexeme, type: t));
            }
          }
        }
      }
    }
    return ParsedClass(
      name: decl.namePart.typeName.lexeme,
      superclass: decl.extendsClause?.superclass.toSource(),
      interfaces:
          decl.implementsClause?.interfaces.map((t) => t.toSource()).toList() ??
          const [],
      mixins:
          decl.withClause?.mixinTypes.map((t) => t.toSource()).toList() ??
          const [],
      annotations: decl.metadata.map((a) => a.name.name).toList(),
      methods: methods,
      fields: fields,
      isAbstract: decl.abstractKeyword != null,
    );
  }

  ParsedMethod _parseExecutable({
    required String name,
    required String returnType,
    required FormalParameterList? params,
    required FunctionBody body,
    required LineInfo lineInfo,
  }) {
    final start = lineInfo.getLocation(body.offset).lineNumber;
    final end = lineInfo.getLocation(body.end).lineNumber;

    final paramInfos = <ParamInfo>[];
    if (params != null) {
      for (final param in params.parameters) {
        paramInfos.add(
          ParamInfo(name: param.name?.lexeme ?? '_', type: _paramType(param)),
        );
      }
    }

    final callVisitor = _CallAndComplexityVisitor();
    body.accept(callVisitor);

    return ParsedMethod(
      name: name,
      isAsync: body.isAsynchronous,
      returnType: returnType,
      params: paramInfos,
      calls: callVisitor.calls,
      startLine: start,
      endLine: end,
      bodySource: body is EmptyFunctionBody ? '' : body.toSource(),
      // +1 baseline for the single straight-line path through the body.
      cyclomaticComplexity: callVisitor.branches + 1,
    );
  }

  String _paramType(FormalParameter param) {
    final node = param is DefaultFormalParameter ? param.parameter : param;
    if (node is SimpleFormalParameter) {
      return node.type?.toSource() ?? 'dynamic';
    }
    if (node is FieldFormalParameter) {
      return node.type?.toSource() ?? 'dynamic';
    }
    if (node is FunctionTypedFormalParameter) {
      return 'Function';
    }
    return 'dynamic';
  }
}

/// Collects outgoing method calls and counts branch points for cyclomatic
/// complexity in a single traversal of a function body.
class _CallAndComplexityVisitor extends RecursiveAstVisitor<void> {
  final List<FunctionCallRef> calls = [];
  int branches = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final receiver = node.target;
    calls.add(
      FunctionCallRef(
        target: node.methodName.name,
        receiver: receiver?.toSource(),
      ),
    );
    super.visitMethodInvocation(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    branches++;
    super.visitIfStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    branches++;
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    branches++;
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    branches++;
    super.visitDoStatement(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    branches++;
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    branches++;
    super.visitSwitchPatternCase(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    branches++;
    super.visitCatchClause(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    branches++;
    super.visitConditionalExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final op = node.operator.lexeme;
    if (op == '&&' || op == '||' || op == '??') branches++;
    super.visitBinaryExpression(node);
  }
}

/// Collects every simple identifier name referenced in the file. Declaration
/// name tokens are not `SimpleIdentifier`s, so a name that appears here is a
/// genuine use site (call, tear-off, or type reference).
class _ReferencedNameVisitor extends RecursiveAstVisitor<void> {
  _ReferencedNameVisitor(this.names);

  final Set<String> names;

  @override
  void visitImportDirective(ImportDirective node) {
    // Skip: names in `show`/`hide` combinators are not use sites and would
    // otherwise make an unused import look used.
  }

  @override
  void visitExportDirective(ExportDirective node) {}

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
