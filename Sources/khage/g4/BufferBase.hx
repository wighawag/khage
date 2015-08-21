package khage.g4;

import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;

class BufferBase{

	public var vertexBuffer(default,null) : VertexBuffer;
	public var indexBuffer(default,null) : IndexBuffer;

	public var numIndicesWritten(default,null) : Int;
	public var uploaded(default,null) : Bool;

	private var vertexData : kha.arrays.Float32Array;
	private var indexData : Array<Int>; //should be Int16Array for webgl?

	inline private function lock(){
		vertexData = vertexBuffer.lock();
		indexData = indexBuffer.lock();
	}

	inline private function unlock(){
		vertexBuffer.unlock();
		indexBuffer.unlock();
		vertexData = null;
		indexData = null;
	}

	@:extern inline public function writeIndex(i : Int){
		indexData[numIndicesWritten] = i;
		numIndicesWritten++;
	}

	inline public function upload() :Void{
	      uploaded = true;
				//TODO
				unlock();
	}

}
