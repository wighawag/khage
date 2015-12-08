package khage.g4.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using khage.util.macro.Util;

class PipelineMacro{

  static var pipelineTypes : Map<String,ComplexType> = new Map();
  static var pipelineTypePaths : Map<String,TypePath> = new Map();
  static var pipelineTypeNames : Map<String,String> = new Map();
  static var numPipelineTypes : Int =0;

	macro static public function apply() : ComplexType{
    var pos = Context.currentPos();
    var localType = Context.getLocalType();

    switch (localType) {
      case TInst(_,[TInst(_.get() => { kind: KExpr(macro $v{(s:String)}) },_)]):
        var shaderPaths = s.split(",");
        if(shaderPaths.length == 2){
          getTypePathOrGeneratePipeline(shaderPaths[0], shaderPaths[1]);
          return pipelineTypes[s];
        }else{
          Context.error("2 shader path need to be provided separated by comma, no space",pos);
        }
      default:
        Context.error("expect a string constant",pos);
    }


    return null;
  }

  static public function getTypePathOrGeneratePipeline(vertexShaderPath : String,fragmentShaderPath : String){
    var key = vertexShaderPath+","+fragmentShaderPath;
    if(!pipelineTypePaths.exists(key)){
      var pipelineClassPath = getPipelineClassPathFromShaderPaths(vertexShaderPath, fragmentShaderPath);
      pipelineTypePaths[key] = pipelineClassPath;
    }
    var pipelineClassPath = pipelineTypePaths[key];
    var typePathStr = pipelineClassPath.pack.join(".") + "." + pipelineClassPath.name;
    var toGenerate = true;
    
    try{
        Context.getType(typePathStr);
        if (pipelineTypes.exists(key)){
            toGenerate = false;
        }
    }catch(e : Dynamic){
        
    }
    if(toGenerate){
      var shaderGroup = getShaderGroup(vertexShaderPath, fragmentShaderPath);
      pipelineTypes[key] = generatePipelineType(shaderGroup,vertexShaderPath,fragmentShaderPath,pipelineClassPath);  
    }
    
    return pipelineClassPath;
  }

  static private function getShaderGroup(vertexShaderPath : String,fragmentShaderPath : String) : khage.g4.glsl.GLSLShaderGroup{

    var pos = Context.currentPos();

    var classPaths = Context.getClassPath();
    var vertexShaderFound = false;
    var fragmentShaderFound = false;
    for (classPath in classPaths){
      var prefix = classPath + "/Shaders/";
      if(!vertexShaderFound){
        var actualShaderPath = classPath + "/Shaders/" + vertexShaderPath + ".glsl";
        if(sys.FileSystem.exists(actualShaderPath)){
          vertexShaderPath = actualShaderPath;
          vertexShaderFound = true;
          if(fragmentShaderFound){
            break;
          }
        }
      }
      if(!fragmentShaderFound){
        var actualShaderPath = classPath + "/Shaders/" + fragmentShaderPath + ".glsl";
        if(sys.FileSystem.exists(actualShaderPath)){
          fragmentShaderPath = actualShaderPath;
          fragmentShaderFound = true;
          if(vertexShaderFound){
            break;
          }
        }
      }
    }

    var error = false;
    if(!vertexShaderFound){
        Context.error("cannot find vertex shader : " + vertexShaderPath,pos);
        error = true;
    }
    if(!fragmentShaderFound){
        Context.error("cannot find fragment shader : " + fragmentShaderPath,pos);
        error = true;
    }
    if(error){
      return null;
    }

    return khage.g4.glsl.GLSLShaderGroup.get(vertexShaderPath, fragmentShaderPath);
  }

  static function generatePipelineType(shaderGroup : khage.g4.glsl.GLSLShaderGroup,vertexShaderPath : String,fragmentShaderPath : String, pipelineClassPath : TypePath) : ComplexType{

    var pos = Context.currentPos();
    var fields : Array<Field> = [];

    trace(vertexShaderPath);
    trace(fragmentShaderPath);
    var constructorBody = macro {
        pipeline = new kha.graphics4.PipelineState();
        pipeline.vertexShader = kha.Shaders.simple_vert; //TODO //$v{vertexShaderPath};
        pipeline.fragmentShader = kha.Shaders.simple_frag; //TODO $v{fragmentShaderPath};
        var structure = new kha.graphics4.VertexStructure(); //recompute it
    };

    var attributes = shaderGroup.attributes;
    for (attribute in attributes){
      var attributeName = attribute.name;
      var attrTPath = switch(cast attribute.type){
          case TPath(att): att;
          default: Context.error("should be a TPath", pos); null;
      };
      if(attrTPath.name == "Vec4"){
        constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float4));
      }else if(attrTPath.name == "Vec3"){
        constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float3));
      }else if(attrTPath.name == "Vec2"){
        constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float2));
      }else{
        constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float1));
      }
    }

    constructorBody.append(macro pipeline.inputLayout = [structure]);
    constructorBody.append(macro pipeline.compile());

    for (uniform in shaderGroup.uniforms){
      var uniformName = uniform.name;
      var uniformLocationVariableName = "_" + uniformName + "_shaderLocation";

      var locationType = macro : kha.graphics4.ConstantLocation;
      var valueType = macro : Int; //TODO
      var attrTPath = switch(cast uniform.type){
          case TPath(att): att;
          default: Context.error("should be a TPath", pos); null;
      };
      if(attrTPath.name == "Sampler2D"){ //TODO ?} || attrPath.name == "SamplerCube"){
        locationType = macro : kha.graphics4.TextureUnit;
        valueType = macro : kha.Image;
        constructorBody.append(macro $i{uniformLocationVariableName} = pipeline.getTextureUnit($v{uniformName}));
      }else{
        constructorBody.append(macro $i{uniformLocationVariableName} = pipeline.getConstantLocation($v{uniformName}));
      }
      fields.push({
        name: uniformLocationVariableName,
        pos: pos,
        access: [APrivate],
        kind: FVar(locationType,null),
      });

      var arguments = [];
      var body : Expr;
      switch(attrTPath.name){
        case "Vec2":
            arguments.push({name:"x", type: macro : Float});
            arguments.push({name:"y", type: macro : Float});
            body = macro g.setFloat2($i{uniformLocationVariableName},x,y);
        case "Vec3":
          arguments.push({name:"x", type: macro : Float});
          arguments.push({name:"y", type: macro : Float});
          arguments.push({name:"z", type: macro : Float});
          body = macro g.setFloat3($i{uniformLocationVariableName},x,y,z);
        case "Vec4":
          arguments.push({name:"x", type: macro : Float});
          arguments.push({name:"y", type: macro : Float});
          arguments.push({name:"z", type: macro : Float});
          arguments.push({name:"w", type: macro : Float});
          body = macro g.setFloat4($i{uniformLocationVariableName},x,y,z,w);
        case "Int":
          arguments.push({name:"x", type: macro : Int});
          body = macro g.setInt($i{uniformLocationVariableName},x);
        case "Float":
          arguments.push({name:"x", type: macro : Float});
          body = macro g.setFloat($i{uniformLocationVariableName},x);
        case "Mat4":
          arguments.push({name:"mat", type: macro : kha.math.Matrix4});
          body = macro g.setMatrix($i{uniformLocationVariableName},mat);
        case "Sampler2D":
          arguments.push({name:"texture", type: macro : kha.Image});
          body = macro g.setTexture($i{uniformLocationVariableName},texture);

          fields.push({
          name: "set_" + uniform.name + "_asVideo",
          pos: pos,
          access: [APublic],
          kind: FFun({
            args: [{name:"texture", type: macro : kha.Video}],
            expr: macro g.setVideoTexture($i{uniformLocationVariableName},texture),
            ret: null
          }),
        });

        case "SamplerCube":
          //TODO
          // arguments.push({name:"mat", type: macro : kha.math.Matrix4});
          // body = macro g.setMatrix(mat);
        //default :
        //    throw "" + uniform.type + " not supported yet";
      }

      fields.push({
        name: "set_" + uniform.name,
        pos: pos,
        access: [APublic],
        kind: FFun({
          args: arguments,
          expr: body,
          ret: null
        }),
      });

    }


    fields.push({
          name: "new",
          pos: pos,
          access: [APublic],
          kind: FFun({
            args:[],
            expr: constructorBody,
            ret: null
          }),
        });

    var bufferClassPath = BufferMacro.getBufferClassPathFromAttributes(attributes);

    fields.push({
      name:"draw",
      pos:pos,
      access: [APublic],
      kind:FFun({
        args : [{
          name:"buffer",
          type : TPath(bufferClassPath)
        }],
        expr: macro {
          if(!buffer.uploaded){
            buffer.upload();
          }
          g.setVertexBuffer(@:privateAccess buffer.vertexBuffer);
          g.setIndexBuffer(@:privateAccess buffer.indexBuffer);
          g.drawIndexedVertices(0,buffer.numIndicesWritten);
        },
        ret : null
      })
    });


    var typeDefinition : TypeDefinition = {
        pos : pos,
        pack : pipelineClassPath.pack,
        name : pipelineClassPath.name,
        kind :TDClass({pack :["khage","g4"], name: "PipelineBase"},[], false),
        fields:fields
    }
    Context.defineType(typeDefinition);


    var pipelineType = TPath(pipelineClassPath);
    pipelineTypes[pipelineClassPath.name] = pipelineType;
    return pipelineType;
  }


  static private function getPipelineClassPathFromShaderPaths(vertexShaderPath : String, fragmentShaderPath : String): TypePath{

      var pipelineClassName =  "Pipeline_" + vertexShaderPath + "_" + fragmentShaderPath;

      if (pipelineTypeNames.exists(pipelineClassName)){
          pipelineClassName = pipelineTypeNames[pipelineClassName];
      }else{
          //TODO use different naming
          numPipelineTypes++;
          var newPipelineClassName = "Pipeline_" + numPipelineTypes;
          pipelineTypeNames[pipelineClassName] = newPipelineClassName;
          pipelineClassName = newPipelineClassName;
      }

      var pipelineClassPath = {pack:["khage","g4", "pipeline"],name:pipelineClassName};

      return pipelineClassPath;
  }

}
