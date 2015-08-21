package khage.g4;

typedef Option = {
	?type : ViewportType,
	?position : ViewportPosition,
//	?maxHDPI : Int  //TODO
	//?window : Window
}

enum ViewportType{
	Fixed(width : Int, height :Int);
	Fill;
	FillUpToRatios(minRatio : Float, maxRatio : Float);
	KeepRatioUsingBorder(width : Int, height :Int);
	KeepRatioUsingCropping(width : Int, height :Int);
	KeepRatioUsingBorderWithoutScalingUp(width : Int, height :Int);
	KeepRatioUsingCroppingWithoutScalingUp(width : Int, height :Int);
}

enum ViewportPosition{
	TopLeft;
	Top;
	TopRight;
	Right;
	BottomRight;
	Bottom;
	BottomLeft;
	Left;
	Center;
}

class Viewport{

	var _option : Option;

	public var x(default,null) : Int = 0;
	public var y(default,null) : Int = 0;
	public var width(default,null) : Int = 0;
	public var height(default,null) : Int = 0;

	// public var scaleX(default,null) : Float = 1;
	// public var scaleY(default,null) : Float = 1;

	var lastFrameWidth : Int = 0;
	var lastFrameHeight : Int = 0;

	var _needApply : Bool = false;

	public function new(option : Option){
		var defaultOption : Option = {
			type:Fill,
			position:Center,
			//maxHDPI:1
		};
		if(option != null){
			option.type = option.type == null ? defaultOption.type : option.type;
			option.position = option.position == null ? defaultOption.position : option.position;
			//option.maxHDPI = option.maxHDPI == null ? defaultOption.maxHDPI : option.maxHDPI;
		}else{
			option = defaultOption;
		}
		_option =option;
	}

	public function ensureSize(frameWidth : Int, frameHeight : Int){

		if(lastFrameWidth != frameWidth || lastFrameHeight != frameHeight){
			lastFrameWidth = frameWidth;
			lastFrameHeight = frameHeight;
			setViewportAutomatically(lastFrameWidth,lastFrameHeight);
			// scaleX = width / frameWidth;
			// scaleY = height / frameHeight;
			_needApply = true;
		}else{
			//TODO remove when Kha allow to disable the viewport reset with g4.begin()
			_needApply = true;
		}
	}

	public function apply(g4 : kha.graphics4.Graphics){
		if(_needApply){
			//TODO  when kha support viewport
			//g4.viewport(x, y, width, height);
			//for now:
			kha.Sys.gl.viewport(x, y, width, height);
		}
	}

	inline function setViewportAutomatically(frameBufferWidth,frameBufferHeight){
		var availableWidth : Float = frameBufferWidth;
		var availableHeight : Float = frameBufferHeight;
		switch(_option.type){
			case Fill :
				availableWidth = frameBufferWidth;
				availableHeight = frameBufferHeight;
			case FillUpToRatios(minRatio, maxRatio):
				if (frameBufferWidth / frameBufferHeight > maxRatio){
					availableWidth = frameBufferHeight * maxRatio;
					availableHeight = frameBufferHeight;
				}else if(frameBufferWidth / frameBufferHeight < minRatio){
					availableWidth = frameBufferHeight; //??
					availableHeight = frameBufferHeight * minRatio;
				}else{
					availableWidth = frameBufferWidth;
					availableHeight = frameBufferHeight;
				}

			case Fixed(w,h) :
				availableWidth = w;
				availableHeight = h;
			case KeepRatioUsingBorder(w,h):
				var widthRatio = availableWidth/w;
				var heightRatio = availableHeight/h;
				if(widthRatio > heightRatio){
					availableWidth = w * heightRatio;
				}else{
					availableHeight = h * widthRatio;
				}
			case KeepRatioUsingBorderWithoutScalingUp(w,h):
				var widthRatio = availableWidth/w;
				var heightRatio = availableHeight/h;
				if(widthRatio > 1 || heightRatio > 1){
					availableWidth = w;
					availableHeight = h;
				}else if(widthRatio > heightRatio){
					availableWidth = w * heightRatio;
				}else{
					availableHeight = h * widthRatio;
				}
			case KeepRatioUsingCropping(w,h):
				var widthRatio = availableWidth/w;
				var heightRatio = availableHeight/h;
				if(widthRatio < heightRatio){
					availableWidth = w * heightRatio;
				}else{
					availableHeight = h * widthRatio;
				}
			case KeepRatioUsingCroppingWithoutScalingUp(w,h):
				var widthRatio = availableWidth/w;
				var heightRatio = availableHeight/h;
				if(widthRatio > 1 || heightRatio > 1){
					availableWidth = w;
					availableHeight = h;
				}else if(widthRatio < heightRatio){
					availableWidth = w * heightRatio;
				}else{
					availableHeight = h * widthRatio;
				}
		}
		//TODO add option to not scale up?

		//TODO support drawingBufferWidth < windowWidth and drawingBufferHeight < windowHeight

		var tentativeX : Float = 0;
		var tentativeY : Float = 0;
		switch(_option.position){
			case Center :
				tentativeX = (frameBufferWidth - availableWidth) / 2;
				tentativeY = (frameBufferHeight - availableHeight) / 2;
			case TopLeft :
				tentativeY = (frameBufferHeight - availableHeight);
			case Top :
				tentativeX = (frameBufferWidth - availableWidth) / 2;
				tentativeY = (frameBufferHeight - availableHeight);
			case TopRight:
				tentativeX = (frameBufferWidth - availableWidth);
				tentativeY = (frameBufferHeight - availableHeight);
			case Right:
				tentativeX = (frameBufferWidth - availableWidth);
				tentativeY = (frameBufferHeight - availableHeight) / 2;
			case BottomRight:
				tentativeX = (frameBufferWidth - availableWidth);
			case Bottom:
				tentativeX = (frameBufferWidth - availableWidth) / 2;
			case BottomLeft:
			case Left:
				tentativeY = (frameBufferHeight - availableHeight) / 2;

		}


		if(availableWidth != width || availableHeight != height || tentativeX != x || tentativeY != y){
			x = Std.int(tentativeX);
			y = Std.int(tentativeY);
			width = Std.int(availableWidth);
			height = Std.int(availableHeight);
		}

	}



}
