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
      var g2 : kha.graphics2.Graphics = cast(@:this this,kha.Framebuffer).g2;
      g2.begin(false);
    };

    newExpr = newExpr.append(expr);
    newExpr = newExpr.append(macro {
      g2.end();
    });

    return newExpr;
  }

  macro public static function usingG1(frame :ExprOf<kha.Framebuffer>, expr : Expr) : Expr{

    var newExpr = macro {
      var g1 : kha.graphics1.Graphics = cast(@:this this,kha.Framebuffer).g1;
      g1.begin();
    };

    newExpr = newExpr.append(expr);
    newExpr = newExpr.append(macro {
      g1.end();
    });

    return newExpr;
  }

  macro public static function usingKhaPipelineState(g4 :ExprOf<khage.G4>, pipelineState : ExprOf<kha.graphics4.PipelineState>,  expr : Expr) : Expr{

    var newExpr = macro {
      var pipelinse : khage.PipelineState = cast(@:this this);
      @:this this.use($v{pipelineState});
    };

    newExpr = newExpr.append(expr);
    return newExpr;
  }

}

typedef PipelineExtension = khage.g4.PipelineExtension;

typedef CompareMode = kha.graphics4.CompareMode;
typedef BlendingOperation = kha.graphics4.BlendingOperation;
typedef CullMode = kha.graphics4.CullMode;
typedef StencilAction = kha.graphics4.StencilAction;