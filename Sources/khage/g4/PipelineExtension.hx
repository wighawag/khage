package khage.g4;

import haxe.macro.Expr;
import haxe.macro.Context;

using khage.util.macro.Util;
using haxe.macro.ExprTools;



class PipelineExtension{
  macro public static function usingPipeline(g4 :ExprOf<khage.G4>, vs :String, fs : String, conf : Expr/*ExprOf<PipelineConf>*/, ?expr : Expr = null) : Expr{
    if(expr.toString() == "null"){
        expr = conf;
        conf = macro $v{{}};
    }
    var pos = Context.currentPos();
    var pipelineTypePath = khage.g4.macro.PipelineMacro.getTypePathOrGeneratePipeline(vs,fs);
    var creationExpr = {
      pos: pos,
      expr:  ENew(pipelineTypePath,[conf]) 
    };
    var varExpr = {
      pos: pos,
      expr: EVars([{
        type: TPath(pipelineTypePath),
        name: "pipeline",
        expr: null
      }])
    };

    var cullMode = macro $v{kha.graphics4.CullMode.None};
    
	var depthWrite = macro $v{false};
	var depthMode = macro $v{kha.graphics4.CompareMode.Always};
		
	var stencilMode = macro $v{kha.graphics4.CompareMode.Always};
	var stencilBothPass = macro $v{kha.graphics4.StencilAction.Keep};
	var stencilDepthFail = macro $v{kha.graphics4.StencilAction.Keep};
	var stencilFail = macro $v{kha.graphics4.StencilAction.Keep};
	var stencilReferenceValue = macro $v{0};
	var stencilReadMask = macro $v{0xff};
	var stencilWriteMask = macro $v{0xff};
		
	var blendSource = macro $v{kha.graphics4.BlendingFactor.BlendOne};
	var blendDestination = macro $v{kha.graphics4.BlendingFactor.BlendZero};
    
    if(conf != null){
        switch(conf.expr){
            case EObjectDecl(fields):
                for(field in fields){
                    switch(field.field){
                        case "stencil":
                            switch(field.expr.expr){
                                case EObjectDecl(fields):
                                    for(field in fields){                                    
                                        switch(field.field){
                                            case "mode": stencilMode = field.expr;
                                            case "bothPass": stencilBothPass = field.expr;
                                            case "depthFail": stencilDepthFail = field.expr;
                                            case "fail": stencilFail = field.expr;
                                            case "referenceValue": stencilReferenceValue = field.expr;
                                            case "readMask": stencilReadMask = field.expr;
                                            case "writeMask": stencilWriteMask = field.expr;
                                            default: //Context.error("param not recognized in stencyl : " + field.field, pos);
                                        }
                                    }
                                default: //Context.error("stencyl conf need to be specified as an anonymous object", pos);
                            }
                        case "depth":
                            switch(field.expr.expr){
                                case EObjectDecl(fields):
                                    for(field in fields){
                                        switch(field.field){
                                            case "write": depthWrite = field.expr;
                                            case "mode": depthMode = field.expr;
                                            default: //Context.error("param not recognized in depth : " + field.field, pos);
                                        }
                                    }
                                default:// Context.error("depth conf need to be specified as an anonymous object", pos);
                            }
                        case "cull":
                            switch(field.expr.expr){
                                case EObjectDecl(fields):
                                    for(field in fields){
                                        switch(field.field){
                                            case "mode": cullMode = field.expr;
                                            default:// Context.error("param not recognized in cull : " + field.field, pos);
                                        }
                                    }
                                default:// Context.error("cull conf need to be specified as an anonymous object", pos);
                            }
                        case "blend":
                            switch(field.expr.expr){
                                case EObjectDecl(fields):
                                    for(field in fields){
                                        switch(field.field){
                                            case "source": blendSource = field.expr;
                                            case "destination": blendDestination = field.expr;
                                            default: //Context.error("param not recognized in blend : " + field.field, pos);
                                        }
                                    }
                                default: //Context.error("blend conf need to be specified as an anonymous object", pos);
                            }
                            
                        default: //Context.error("param not recognized : " + field.field, pos);
                    }
                }
            default: //Context.error("need to specify an anonymous object of type khage.g4.PipelineExtension.PipelineConf", pos);
        }
    }
    
    
    var key = vs + "," + fs;
    key += cullMode.toString();
    key += depthWrite.toString();
    key += depthMode.toString();
    key += stencilMode.toString();
    key += stencilBothPass.toString();
    key += stencilDepthFail.toString();
    key += stencilFail.toString();
    key += stencilReferenceValue.toString();
    key += stencilReadMask.toString();
    key += stencilWriteMask.toString();
    key += blendSource.toString();
    key += blendDestination.toString();
    
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
