package khage.g4;

import haxe.macro.Expr;
import haxe.macro.Context;

using khage.util.macro.Util;
using haxe.macro.ExprTools;

class PipelineExtension{
  macro public static function usingPipeline(g4 :ExprOf<khage.G4>, vs :String, fs : String, expr : Expr) : Expr{
    var pos = Context.currentPos();
    var pipelineTypePath = khage.g4.macro.PipelineMacro.getTypePathOrGeneratePipeline(vs,fs); //TODO add blend,depthtest params...
    var creationExpr = {
      pos: pos,
      expr:  ENew(pipelineTypePath,[])
    };
    var varExpr = {
      pos: pos,
      expr: EVars([{
        type: TPath(pipelineTypePath),
        name: "pipeline",
        expr: null
      }])
    };

    var key = vs + "," + fs;
    var newExpr = macro {
      $e{varExpr};
      if(!@:privateAccess khage.g4.PipelineBase.pipelines.exists($v{key})){
        pipeline = $e{creationExpr};
        @:privateAccess khage.g4.PipelineBase.pipelines.set($v{key},pipeline);
      }else{
        pipeline = cast(@:privateAccess khage.g4.PipelineBase.pipelines[$v{key}]);
      }
      pipeline.use(@:this this);
    };

    newExpr = newExpr.append(expr);

    return newExpr;
  }
}
