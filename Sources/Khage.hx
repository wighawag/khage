import haxe.macro.Expr;
import haxe.macro.Context;

using khage.util.macro.Util;

class Khage{


  macro public static function usingG4(frame :ExprOf<kha.Framebuffer>, expr : Expr) : Expr{

    var newExpr = macro {

      var g4 : khage.G4 = cast(@:this this,kha.Framebuffer).g4;
      @:this this.g4.begin(false); //TODO pass viewport
    };

    newExpr = newExpr.append(expr);
    newExpr = newExpr.append(macro {
      @:this this.g4.end();
    });

    return newExpr;
  }

  //TODO allow to pass argument to begin
  macro public static function usingG2(frame :ExprOf<kha.Framebuffer>, expr : Expr) : Expr{

    var newExpr = macro {
      var g2 : kha.graphics2.Graphics = @:this this.g2;
      @:this this.g2.begin();
    };

    newExpr = newExpr.append(expr);
    newExpr = newExpr.append(macro {
      @:this this.g2.end();
    });

    return newExpr;
  }

  macro public static function usingG1(frame :ExprOf<kha.Framebuffer>, expr : Expr) : Expr{

    var newExpr = macro {
      var g1 : kha.graphics1.Graphics = @:this this.g1;
      @:this this.g1.begin();
    };

    newExpr = newExpr.append(expr);
    newExpr = newExpr.append(macro {
      @:this this.g1.end();
    });

    return newExpr;
  }

  macro public static function usingKhaProgram(g4 :ExprOf<khage.G4>, program : ExprOf<kha.graphics4.Program>,  expr : Expr) : Expr{

    var newExpr = macro {
      var prog : khage.Program = cast(@:this this);
      @:this this.use($v{program});
    };

    newExpr = newExpr.append(expr);
    return newExpr;
  }

}

typedef ProgExtension = khage.g4.ProgramExtension;
