package khage.g4;

import kha.graphics4.PipelineState;
import kha.graphics4.Graphics;

class PipelineBase{
  private static var pipelines : Map<String,PipelineBase> = new Map();

  public var pipeline(default,null) : PipelineState; //TODO private?
  private var g : Graphics;
  

  public function use(g : Graphics){
    this.g = g;
    this.g.setPipeline(pipeline);
  }

}
