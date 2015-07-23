package khage.util.macro;

import haxe.macro.Expr;
import haxe.macro.Context;

class Util{

	public static function append(expr : Expr, exprToAdd : Expr) : Expr{
		return
		switch(expr.expr){
			case EBlock(exprs):
				exprs.push(exprToAdd);
				expr;
			default :
				expr.expr = EBlock([{pos:expr.pos,expr:expr.expr}, exprToAdd]);
				expr;
		}
	}

}
