package khage.g4;

import kha.graphics4.PipelineState;
import kha.graphics4.Graphics;

class PipelineBase{
  private static var pipelines : Map<String,PipelineBase> = new Map();

  public var pipeline(default,null) : PipelineState; //TODO private?
  private var g : Graphics;
  private var g2ong4 : kha.graphics4.Graphics2;
  

  public function use(g4 : Graphics){
    g = g4;
    g.setPipeline(pipeline);
  }

   public function useInG2(g2 : kha.graphics2.Graphics){
   	g2ong4 = cast g2;
   	if(g2ong4 != null){
   		g = @:privateAccess g2ong4.g;
    	g2ong4.pipeline = pipeline;
   	}//TODO else error
  }

  public function detach(){
    g = null;
    if(g2ong4 != null){
    	g2ong4.pipeline = null;
    }
    g2ong4 = null;
  }

}
