package khage.g4;

import kha.graphics4.Program;
import kha.graphics4.Graphics;

class ProgramBase{
  private static var programs : Map<String,ProgramBase> = new Map();

  public var program(default,null) : Program;
  private var g : Graphics;

  public function use(g : Graphics){
    this.g = g;
    this.g.setProgram(program);
  }


}
