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

	public var viewportX(default,null) : Int = 0;
	public var viewportY(default,null) : Int = 0;
	public var viewportWidth(default,null) : Int = 0;
	public var viewportHeight(default,null) : Int = 0;

	var lastFrameWidth : Int;
	var lastFrameHeight : Int;

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

	public function ensureSize(g4 : kha.graphics4.Graphics, frameWidth : Int, frameHeight : Int){
		//TODO enable check when Kha allow to disable the viewport reset with g4.begin()
		//if(lastFrameWidth != frameWidth || lastFrameHeight != frameHeight){
			lastFrameWidth = frameWidth;
			lastFrameHeight = frameHeight;
			setViewportAutomatically(lastFrameWidth,lastFrameHeight,g4);
		//}
	}

	inline function setViewportAutomatically(frameBufferWidth,frameBufferHeight,g4 : kha.graphics4.Graphics){
		var width : Float = frameBufferWidth;
		var height : Float = frameBufferHeight;
		switch(_option.type){
			case Fill :
				width = frameBufferWidth;
				height = frameBufferHeight;
			case FillUpToRatios(minRatio, maxRatio):
				if (frameBufferWidth / frameBufferHeight > maxRatio){
					width = frameBufferHeight * maxRatio;
					height = frameBufferHeight;
				}else if(frameBufferWidth / frameBufferHeight < minRatio){
					width = frameBufferHeight; //??
					height = frameBufferHeight * minRatio;
				}else{
					width = frameBufferWidth;
					height = frameBufferHeight;
				}

			case Fixed(w,h) :
				width = w;
				height = h;
			case KeepRatioUsingBorder(w,h):
				var widthRatio = width/w;
				var heightRatio = height/h;
				if(widthRatio > heightRatio){
					width = w * heightRatio;
				}else{
					height = h * widthRatio;
				}
			case KeepRatioUsingBorderWithoutScalingUp(w,h):
				var widthRatio = width/w;
				var heightRatio = height/h;
				if(widthRatio > 1 || heightRatio > 1){
					width = w;
					height = h;
				}else if(widthRatio > heightRatio){
					width = w * heightRatio;
				}else{
					height = h * widthRatio;
				}
			case KeepRatioUsingCropping(w,h):
				var widthRatio = width/w;
				var heightRatio = height/h;
				if(widthRatio < heightRatio){
					width = w * heightRatio;
				}else{
					height = h * widthRatio;
				}
			case KeepRatioUsingCroppingWithoutScalingUp(w,h):
				var widthRatio = width/w;
				var heightRatio = height/h;
				if(widthRatio > 1 || heightRatio > 1){
					width = w;
					height = h;
				}else if(widthRatio < heightRatio){
					width = w * heightRatio;
				}else{
					height = h * widthRatio;
				}
		}
		//TODO add option to not scale up?

		//TODO support drawingBufferWidth < windowWidth and drawingBufferHeight < windowHeight

		var x : Float = 0;
		var y : Float = 0;
		switch(_option.position){
			case Center :
				x = (frameBufferWidth - width) / 2;
				y = (frameBufferHeight - height) / 2;
			case TopLeft :
				y = (frameBufferHeight - height);
			case Top :
				x = (frameBufferWidth - width) / 2;
				y = (frameBufferHeight - height);
			case TopRight:
				x = (frameBufferWidth - width);
				y = (frameBufferHeight - height);
			case Right:
				x = (frameBufferWidth - width);
				y = (frameBufferHeight - height) / 2;
			case BottomRight:
				x = (frameBufferWidth - width);
			case Bottom:
				x = (frameBufferWidth - width) / 2;
			case BottomLeft:
			case Left:
				y = (frameBufferHeight - height) / 2;

		}


		if(width != viewportWidth || height != viewportHeight || x != viewportX || y != viewportY){
			viewportX = Std.int(x);
			viewportY = Std.int(y);
			viewportWidth = Std.int(width);
			viewportHeight = Std.int(height);

			//TODO  when kha support viewport
			//g4.viewport(viewportX, viewportY, viewportWidth, viewportHeight);
			//for now:
			kha.Sys.gl.viewport(viewportX, viewportY, viewportWidth, viewportHeight);
		}

	}



}
