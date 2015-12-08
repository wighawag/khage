package khage.g4;

// import haxe.macro.Expr;

abstract Mat4(Int){}
abstract Sampler2D(Int){}
abstract SamplerCube(Int){}

@:genericBuild(khage.g4.macro.PipelineMacro.apply())
class Pipeline<Const>{

  // macro public static function usingPipeline(g4 : ExprOf<kha.graphics4.Graphics>, pipeline : ExprOf<khage.g4.PipelineBase>, expr : Expr){
  //   return macro {};
  // }
}
