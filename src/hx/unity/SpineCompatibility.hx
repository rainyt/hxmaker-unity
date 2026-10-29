package hx.unity;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

/** 修复 Spine JSON 动态偏移作为 C# 数组索引时缺少整数转换的问题。 */
class SpineCompatibility {
	public static function build():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		for (field in fields) {
			switch field.kind {
				case FFun(method):
					if (method.expr != null) method.expr = fixExpression(method.expr);
				default:
			}
		}
		return fields;
	}

	private static function fixExpression(expression:Expr):Expr {
		var mapped:Expr = ExprTools.map(expression, fixExpression);
		switch mapped.expr {
			case EArray(array, index):
				switch [array.expr, index.expr] {
					case [EConst(CIdent("drawOrder")), EBinop(OpAdd, originalIndex, offset)]:
						switch offset.expr {
							case ECall({expr: EField({expr: EConst(CIdent("Reflect"))}, "getProperty")},
								[_, {expr: EConst(CString("offset"))}]):
								// 保留原赋值与自增顺序，只让偏移量参与整数运算。
								var integerOffset:Expr = macro Std.int($e{offset});
								mapped.expr = EArray(array, {
									expr: EBinop(OpAdd, originalIndex, integerOffset),
									pos: index.pos
								});
							default:
						}
					default:
				}
			default:
		}
		return mapped;
	}
}
#end
