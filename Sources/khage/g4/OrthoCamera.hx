package khage.g4;

import kha.math.Matrix4;
import kha.math.Vector3;
import kha.math.Vector4;
import kha.math.FastMatrix3;

typedef OrthoCameraOption = {
	?scale : Bool
}

class OrthoCamera{

	public var viewproj(default,null) : Matrix4; //TODO return a Const<Mat4>
	public var g2Transformation(default,null) : FastMatrix3;
	public function new(width : Float, height : Float, ?option : OrthoCameraOption){
		_focusWidth = width;
		_focusHeight = height;
		_proj = Matrix4.identity();
		_view = Matrix4.identity();
		viewproj = Matrix4.identity();
		g2Transformation = FastMatrix3.identity();
		var defaultOption : OrthoCameraOption = {
			scale:true
		};
		if(option != null){
			option.scale = option.scale == null ? defaultOption.scale : option.scale;
		}else{
			option = defaultOption;
		}
		_option =option;
	}

  public function handleViewport(viewport : Viewport){
		_viewport = viewport;
		if(_lastViewPortWidth != _viewport.width || _lastViewPortHeight != _viewport.height){
			_lastViewPortWidth = _viewport.width;
			_lastViewPortHeight = _viewport.height;
			onViewportChanged(_viewport.x, _viewport.y, _viewport.width, _viewport.height);
		}
  }

  public function centerOn(x : Float, y : Float){
    //TODO keep in memory (state)
    _view = Matrix4.identity();
    _view = _view.multmat(Matrix4.scale(_scale,_scale,1));
    _view = _view.multmat(Matrix4.translation(_visibleWidth/2 - x,_visibleHeight/2 - y, 0));
    viewproj = _proj.multmat(_view);

		g2Transformation = FastMatrix3.identity();
		if(_viewport != null && (_viewport.x != 0 || _viewport.y != 0)){
			g2Transformation = g2Transformation.multmat(FastMatrix3.translation(_viewport.x,_viewport.y));
		}
		g2Transformation = g2Transformation.multmat(FastMatrix3.scale(_scale,_scale));
		g2Transformation = g2Transformation.multmat(FastMatrix3.translation(_visibleWidth/2 -x, _visibleHeight/2 - y));
		// if(_viewport.scaleX != 1 || _viewport.scaleY != 1){
		//  	g2Transformation = g2Transformation.multmat(FastMatrix3.scale(_viewport.scaleX,_viewport.scaleY));
		//

    //TODO limit the side

    //TODO support zooming
  }

  public function toBufferCoordinates(vec3 : Vector3) : Vector3{
		var vec4 = new Vector4(vec3.x,vec3.y,vec3.z,0);
		var out = _view.multvec(vec4);
    out.x + _viewport.x;
    out.y + _viewport.y;
    return new Vector3(out.x,out.y,out.z);
  }

	var _viewport : Viewport;
  var _option : OrthoCameraOption;
	var _scale : Float = 1;

	var _proj : Matrix4;
	var _view: Matrix4;

  var _visibleWidth : Float = 0;
	var _visibleHeight : Float = 0;

	var _focusWidth : Float;
	var _focusHeight : Float;

  var _lastViewPortWidth : Int = 0;
  var _lastViewPortHeight : Int = 0;

	function onViewportChanged(x : Int, y : Int, width : Int, height : Int){
		//TODO set viewproj to dirty
		_proj = Matrix4.orthogonalProjection(0, width, height,0,-1,1);

		var widthRatio = width/_focusWidth;
		var heightRatio = height/_focusHeight;
		if(_option.scale){
			if(widthRatio > heightRatio){
				_scale = heightRatio;
			}else{
				_scale = widthRatio;
			}
		 }else{
		 	_scale = 1;
		 }
		//_proj.scale(_proj,_scale, _scale, 1);
		_visibleWidth = width / _scale;
		_visibleHeight = height / _scale;
		//TODO support light when _scale =1 (while the drawingbuffer has a different scale)
	}



}
