module Ast::Normalise

import lang::java::m3::AST;
import lang::java::m3::Core;

Type defaultType = Type::\void();
Modifier defaultModifier = Modifier::\public();
str defaultString = "";
str defaultNumber = "0";
str defaultBoolean = "false";

list[Declaration] normaliseAst(list[Declaration] asts) = [normaliseAst(ast) | ast <- asts];

Declaration normaliseAst(Declaration ast) {
    return visit(ast) {
        case \characterLiteral(_) => \characterLiteral(defaultString)
        case \number(_) => \number(defaultNumber)
        case \booleanLiteral(_) => \booleanLiteral(defaultBoolean)
        case \stringLiteral(_) => \stringLiteral(defaultString)
        case \textBlock(_) => \textBlock(defaultString)
        case \id(_) => \id(defaultString)

        case Type _ => defaultType
        case Modifier _ => defaultModifier
    }
}