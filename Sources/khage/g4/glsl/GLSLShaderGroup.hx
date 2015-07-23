package khage.g4.glsl;

import haxe.macro.Context;
import haxe.macro.Expr;

typedef Uniform = {
	name : String,
	type : ComplexType
}

typedef Attribute = {
	name : String,
	type : ComplexType
}


class GLSLShaderGroup{

	static var shaderGroups : Map<String, GLSLShaderGroup> = new Map();

	public var uniforms(default,null) : Array<Uniform>;
	public var attributes(default,null) : Array<Attribute>;
	public var vertexShaderSrc(default, null) : String;
	public var fragmentShaderSrc(default, null) : String;

	public function new(vertexShaderSrc : String, fragmentShaderSrc : String, newUniforms : Array<Uniform>, newAttributes : Array<Attribute>){
		uniforms = newUniforms;
		attributes = newAttributes;
		this.vertexShaderSrc = vertexShaderSrc;
		this.fragmentShaderSrc = fragmentShaderSrc;
	}

	static private function link(vertex_glsl : GLSL, fragment_glsl : GLSL) : GLSLShaderGroup{

        var newUniforms = new Array<Uniform>();
        var newAttributes = new Array<Attribute>();

        for (uniformName in vertex_glsl.uniforms.keys()){
        	newUniforms.push({name : uniformName, type : vertex_glsl.uniforms[uniformName]});
        }

        for (uniformName in fragment_glsl.uniforms.keys()){
        	if (!vertex_glsl.uniforms.exists(uniformName)){
        		newUniforms.push({name : uniformName, type : fragment_glsl.uniforms[uniformName]});
        	}
        }

        for (attributeName in vertex_glsl.attributes.keys()){
        	newAttributes.push({name : attributeName, type : vertex_glsl.attributes[attributeName]});
        }

        return new GLSLShaderGroup(vertex_glsl.source, fragment_glsl.source, newUniforms, newAttributes);
	}

	public static function get(vertexShaderFilePath : String, fragmentShaderFilePath : String) : GLSLShaderGroup{

		var id = vertexShaderFilePath + "::_::" + fragmentShaderFilePath;
		if (shaderGroups.exists(id)){
			return shaderGroups[id];
		}

        var vertex_glsl = khage.g4.glsl.GLSL.get(vertexShaderFilePath);
        var fragment_glsl = khage.g4.glsl.GLSL.get(fragmentShaderFilePath);

        var shaderGroup = link(vertex_glsl, fragment_glsl);

        shaderGroups[id] = shaderGroup;

        return shaderGroup;
	}



}
