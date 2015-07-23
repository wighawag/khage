package khage.g4;

// import haxe.macro.Expr;

abstract Mat4(Int){}
abstract Sampler2D(Int){}
abstract SamplerCube(Int){}

@:genericBuild(khage.g4.macro.ProgramMacro.apply())
class Program<Const>{

  // macro public static function usingG4Program(g4 : ExprOf<kha.graphics4.Graphics>, program : ExprOf<khage.g4.ProgramBase>, expr : Expr){
  //   return macro {};
  // }
}
