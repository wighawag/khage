package khage.g4;

import haxe.macro.Expr;
import haxe.macro.Context;

using khage.util.macro.Util;
using haxe.macro.ExprTools;

class ProgramExtension{
  macro public static function usingProgram(g4 :ExprOf<khage.G4>, vs :String, fs : String, expr : Expr) : Expr{
    var pos = Context.currentPos();
    var programTypePath = khage.g4.macro.ProgramMacro.getTypePathOrGenerateProgram(vs,fs);
    var creationExpr = {
      pos: pos,
      expr:  ENew(programTypePath,[])
    };
    var varExpr = {
      pos: pos,
      expr: EVars([{
        type: TPath(programTypePath),
        name: "program",
        expr: null
      }])
    };

    var key = vs + "," + fs;
    var newExpr = macro {
      $e{varExpr};
      if(!@:privateAccess khage.g4.ProgramBase.programs.exists($v{key})){
        program = $e{creationExpr};
        @:privateAccess khage.g4.ProgramBase.programs.set($v{key},program);
      }else{
        program = cast(@:privateAccess khage.g4.ProgramBase.programs[$v{key}]);
      }
      program.use(@:this this);
    };

    newExpr = newExpr.append(expr);

    return newExpr;
  }
}
