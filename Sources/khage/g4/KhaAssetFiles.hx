package khage.g4;

//TODO abstract enum
typedef AttributeType = String;
typedef UniformType = String;

typedef ShaderAttribute = {
  name : String,
  type : AttributeType
};

typedef ShaderUniform = {
  name : String,
  type : UniformType
};

typedef ShaderDescription = {
  inputs : Array<ShaderAttribute>,
  outputs : Array<ShaderAttribute>,
  uniforms : Array<ShaderUniform>
};

typedef KhaAssetFile = {
  name : String,
  files : Array<String>,
  type : String //TODO abstract enum
};

typedef KhaAssetFiles = {
  files : Array<KhaAssetFile>
};


class KhaAssetFilesUtil{
	public static function get() : KhaAssetFiles{
		var resourcesPath = kha.internal.AssetsBuilder.findResources();
		var path = resourcesPath + "/files.json";
		return haxe.Json.parse(sys.io.File.getContent(path));
	}

	public static function assembleShaderDescriptions(shaders : Array<ShaderDescription>) : ShaderDescription{
		var outputShader : ShaderDescription = {inputs : [], outputs :[], uniforms:[]};
		if(shaders.length == 0){
			return outputShader;
		}

		for(input in shaders[0].inputs){
			outputShader.inputs.push(input);
		}

        outputShader.inputs.sort(function(x,y){
	        if(x.name == y.name){
	            return 0;
	        }
	        return x.name < y.name ? -1 : 1;
        });

		var uniformSet = new Map<String,Bool>();
		for(shader in shaders){
			for(uniform in shader.uniforms){
				if(!uniformSet.exists(uniform.name)){
					uniformSet.set(uniform.name,true);
					outputShader.uniforms.push(uniform);
				}else{
					//TODO error
				}
			}
		}
		for(output in shaders[shaders.length-1].outputs){
			outputShader.outputs.push(output);
		}

		return outputShader;
	}
}