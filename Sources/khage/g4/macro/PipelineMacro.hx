package khage.g4.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using khage.util.macro.Util;
using StringTools;

import khage.g4.KhaAssetFiles;

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
      vertexShaderPath = vertexShaderPath.replace(".","_");
      fragmentShaderPath = fragmentShaderPath.replace(".","_");
      
      var json : KhaAssetFiles = KhaAssetFilesUtil.get();
      var vdesc : ShaderDescription = null;
      var fdesc : ShaderDescription = null;
      for(file in json.files){
        if(file.name == vertexShaderPath){
          vdesc = cast file;
          if(fdesc != null)break;
        }
        if(file.name == fragmentShaderPath){
          fdesc = cast file;
          if(vdesc != null)break;
        }
      }

      if(vdesc == null ){
        Context.error("no shader file found for " + vertexShaderPath, Context.currentPos());
      }
      if(vdesc == null ){
        Context.error("no shader file found for " + vertexShaderPath, Context.currentPos());
      }

      if(vdesc == null || fdesc == null){
        return null;
      }

      var desc = KhaAssetFilesUtil.assembleShaderDescriptions([vdesc,fdesc]);
      pipelineTypes[key] = generatePipelineType(desc,vertexShaderPath,fragmentShaderPath,pipelineClassPath);
    }
    
    return pipelineClassPath;
  }

  // static private function getShaderGroup(vertexShaderPath : String,fragmentShaderPath : String) : khage.g4.glsl.GLSLShaderGroup{

  //   var pos = Context.currentPos();

  //   var classPaths = Context.getClassPath();
  //   var vertexShaderFound = false;
  //   var fragmentShaderFound = false;
  //   for (classPath in classPaths){
  //     var prefix = classPath + "/Shaders/";
  //     if(!vertexShaderFound){
  //       var actualShaderPath = classPath + "/Shaders/" + vertexShaderPath + ".glsl";
  //       if(sys.FileSystem.exists(actualShaderPath)){
  //         vertexShaderPath = actualShaderPath;
  //         vertexShaderFound = true;
  //         if(fragmentShaderFound){
  //           break;
  //         }
  //       }
  //     }
  //     if(!fragmentShaderFound){
  //       var actualShaderPath = classPath + "/Shaders/" + fragmentShaderPath + ".glsl";
  //       if(sys.FileSystem.exists(actualShaderPath)){
  //         fragmentShaderPath = actualShaderPath;
  //         fragmentShaderFound = true;
  //         if(vertexShaderFound){
  //           break;
  //         }
  //       }
  //     }
  //   }

  //   var error = false;
  //   if(!vertexShaderFound){
  //       Context.error("cannot find vertex shader : " + vertexShaderPath,pos);
  //       error = true;
  //   }
  //   if(!fragmentShaderFound){
  //       Context.error("cannot find fragment shader : " + fragmentShaderPath,pos);
  //       error = true;
  //   }
  //   if(error){
  //     return null;
  //   }

  //   return khage.g4.glsl.GLSLShaderGroup.get(vertexShaderPath, fragmentShaderPath);
  // }

  // static function generatePipelineType(shaderGroup : khage.g4.glsl.GLSLShaderGroup,vertexShaderPath : String,fragmentShaderPath : String, pipelineClassPath : TypePath) : ComplexType{

  //   var pos = Context.currentPos();
  //   var fields : Array<Field> = [];

  //   var constructorBody = macro {
  //       pipeline = new kha.graphics4.PipelineState();
  //       pipeline.vertexShader = $p{["kha","Shaders",vertexShaderPath.replace(".","_")]};
  //       pipeline.fragmentShader = $p{["kha","Shaders",fragmentShaderPath.replace(".","_")]};
        
  //       if(conf.cull != null){
  //           pipeline.cullMode = conf.cull.mode;    
  //       }
        
  //       if(conf.depth != null){
  //           pipeline.depthWrite = conf.depth.write;
  //           pipeline.depthMode = conf.depth.mode;    
  //       }
        
  //       if(conf.stencil != null){
  //           pipeline.stencilMode = conf.stencil.mode;
  //           pipeline.stencilBothPass = conf.stencil.bothPass;
  //           pipeline.stencilDepthFail = conf.stencil.depthFail;
  //           pipeline.stencilFail = conf.stencil.fail;
  //           pipeline.stencilReferenceValue = conf.stencil.referenceValue;
  //           pipeline.stencilReadMask = conf.stencil.readMask;
  //           pipeline.stencilWriteMask = conf.stencil.writeMask;    
  //       }            
        
  //       if(conf.blend != null){
  //           pipeline.blendSource = conf.blend.source;
  //           pipeline.blendDestination = conf.blend.destination;    
  //       }    
         
  //       var structure = new kha.graphics4.VertexStructure(); //recompute it
  //   };

  //   var attributes = shaderGroup.attributes;
  //   for (attribute in attributes){
  //     var attributeName = attribute.name;
  //     var attrTPath = switch(cast attribute.type){
  //         case TPath(att): att;
  //         default: Context.error("should be a TPath", pos); null;
  //     };
  //     if(attrTPath.name == "Vec4"){
  //       constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float4));
  //     }else if(attrTPath.name == "Vec3"){
  //       constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float3));
  //     }else if(attrTPath.name == "Vec2"){
  //       constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float2));
  //     }else{
  //       constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float1));
  //     }
  //   }

  //   constructorBody.append(macro pipeline.inputLayout = [structure]);
  //   constructorBody.append(macro pipeline.compile());
   
  //   for (uniform in shaderGroup.uniforms){
  //     var uniformName = uniform.name;
  //     var uniformLocationVariableName = "_" + uniformName + "_shaderLocation";

  //     var locationType = macro : kha.graphics4.ConstantLocation;
  //     var valueType = macro : Int; //TODO
  //     var attrTPath = switch(cast uniform.type){
  //         case TPath(att): att;
  //         default: Context.error("should be a TPath", pos); null;
  //     };
  //     if(attrTPath.name == "Sampler2D"){ //TODO ?} || attrPath.name == "SamplerCube"){
  //       locationType = macro : kha.graphics4.TextureUnit;
  //       valueType = macro : kha.Image;
  //       constructorBody.append(macro $i{uniformLocationVariableName} = pipeline.getTextureUnit($v{uniformName}));
  //     }else{
  //       constructorBody.append(macro $i{uniformLocationVariableName} = pipeline.getConstantLocation($v{uniformName}));
  //     }
  //     fields.push({
  //       name: uniformLocationVariableName,
  //       pos: pos,
  //       access: [APrivate],
  //       kind: FVar(locationType,null),
  //     });

  //     var arguments = [];
  //     var body : Expr;
  //     switch(attrTPath.name){
  //       case "Vec2":
  //           arguments.push({name:"x", type: macro : Float});
  //           arguments.push({name:"y", type: macro : Float});
  //           body = macro g.setFloat2($i{uniformLocationVariableName},x,y);
  //       case "Vec3":
  //         arguments.push({name:"x", type: macro : Float});
  //         arguments.push({name:"y", type: macro : Float});
  //         arguments.push({name:"z", type: macro : Float});
  //         body = macro g.setFloat3($i{uniformLocationVariableName},x,y,z);
  //       case "Vec4":
  //         arguments.push({name:"x", type: macro : Float});
  //         arguments.push({name:"y", type: macro : Float});
  //         arguments.push({name:"z", type: macro : Float});
  //         arguments.push({name:"w", type: macro : Float});
  //         body = macro g.setFloat4($i{uniformLocationVariableName},x,y,z,w);
  //       case "Int":
  //         arguments.push({name:"x", type: macro : Int});
  //         body = macro g.setInt($i{uniformLocationVariableName},x);
  //       case "Float":
  //         arguments.push({name:"x", type: macro : Float});
  //         body = macro g.setFloat($i{uniformLocationVariableName},x);
  //       case "Mat4":
  //         arguments.push({name:"mat", type: macro : kha.math.FastMatrix4});
  //         body = macro g.setMatrix($i{uniformLocationVariableName},mat);
  //       case "Sampler2D":
  //         arguments.push({name:"texture", type: macro : kha.Image});
  //         body = macro g.setTexture($i{uniformLocationVariableName},texture);

  //         fields.push({
  //         name: "set_" + uniform.name + "_asVideo",
  //         pos: pos,
  //         access: [APublic],
  //         kind: FFun({
  //           args: [{name:"texture", type: macro : kha.Video}],
  //           expr: macro g.setVideoTexture($i{uniformLocationVariableName},texture),
  //           ret: null
  //         }),
  //       });

  //       case "SamplerCube":
  //         //TODO
  //         // arguments.push({name:"mat", type: macro : kha.math.FastMatrix4});
  //         // body = macro g.setMatrix(mat);
  //       //default :
  //       //    throw "" + uniform.type + " not supported yet";
  //     }

  //     fields.push({
  //       name: "set_" + uniform.name,
  //       pos: pos,
  //       access: [APublic],
  //       kind: FFun({
  //         args: arguments,
  //         expr: body,
  //         ret: null
  //       }),
  //     });

  //   }

  //   fields.push({
  //         name: "new",
  //         pos: pos,
  //         access: [APublic],
  //         kind: FFun({
  //           args:[{name:"conf", type: macro : khage.g4.PipelineConf}],
  //           expr: constructorBody,
  //           ret: null
  //         }),
  //       });

  //   var bufferClassPath = BufferMacro.getBufferClassPathFromAttributes(attributes);

  //   fields.push({
  //     name:"draw",
  //     pos:pos,
  //     access: [APublic],
  //     kind:FFun({
  //       args : [{
  //         name:"buffer",
  //         type : TPath(bufferClassPath)
  //       }],
  //       expr: macro {
  //         if(!buffer.uploaded){
  //           buffer.upload();
  //         }
  //         g.setVertexBuffer(@:privateAccess buffer.vertexBuffer);
  //         g.setIndexBuffer(@:privateAccess buffer.indexBuffer);
  //         g.drawIndexedVertices(0,buffer.numIndicesWritten);
  //       },
  //       ret : null
  //     })
  //   });


  //   var typeDefinition : TypeDefinition = {
  //       pos : pos,
  //       pack : pipelineClassPath.pack,
  //       name : pipelineClassPath.name,
  //       kind :TDClass({pack :["khage","g4"], name: "PipelineBase"},[], false),
  //       fields:fields
  //   }
  //   Context.defineType(typeDefinition);


  //   var pipelineType = TPath(pipelineClassPath);
  //   pipelineTypes[pipelineClassPath.name] = pipelineType;
  //   return pipelineType;
  // }

  static function generatePipelineType(desc : ShaderDescription, vertexShaderPath : String,fragmentShaderPath : String, pipelineClassPath : TypePath) : ComplexType{

    var pos = Context.currentPos();
    var fields : Array<Field> = [];

    var constructorBody = macro {
        pipeline = new kha.graphics4.PipelineState();
        pipeline.vertexShader = $p{["kha","Shaders",vertexShaderPath.replace(".","_")]};
        pipeline.fragmentShader = $p{["kha","Shaders",fragmentShaderPath.replace(".","_")]};
        
        if(conf.cull != null){
            pipeline.cullMode = conf.cull.mode;    
        }
        
        if(conf.depth != null){
            pipeline.depthWrite = conf.depth.write;
            pipeline.depthMode = conf.depth.mode;    
        }
        
        if(conf.stencil != null){
            pipeline.stencilMode = conf.stencil.mode;
            pipeline.stencilBothPass = conf.stencil.bothPass;
            pipeline.stencilDepthFail = conf.stencil.depthFail;
            pipeline.stencilFail = conf.stencil.fail;
            pipeline.stencilReferenceValue = conf.stencil.referenceValue;
            pipeline.stencilReadMask = conf.stencil.readMask;
            pipeline.stencilWriteMask = conf.stencil.writeMask;    
        }            
        
        if(conf.blend != null){
            pipeline.blendSource = conf.blend.source;
            pipeline.blendDestination = conf.blend.destination;    
        }    
         
         //TODO get rid of structure computation if strucutr is passed in
         //TODO check at runtime if conf.inputLayout matches
        var structure = new kha.graphics4.VertexStructure(); //recompute it
    };

    
    for (input in desc.inputs){
      var attributeName = input.name;
      switch (input.type) {
        case "vec4":constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float4));
        case "vec3":constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float3));
        case "vec2":constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float2));
        case "float":constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float1));
      }
    }

    constructorBody.append(macro if(conf.inputLayout != null){pipeline.inputLayout = conf.inputLayout;}else{pipeline.inputLayout = [structure];});
    constructorBody.append(macro pipeline.compile());
   
    for (uniform in desc.uniforms){
      var uniformName = uniform.name;
      var uniformLocationVariableName = "_" + uniformName + "_shaderLocation";

      var locationType = macro : kha.graphics4.ConstantLocation;
      var valueType = macro : Int; //TODO
      
      switch(uniform.type){
        case "sampler2D":
          locationType = macro : kha.graphics4.TextureUnit;
          valueType = macro : kha.Image;
          constructorBody.append(macro $i{uniformLocationVariableName} = pipeline.getTextureUnit($v{uniformName}));
          
          //TODO remove default
        default:
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
      switch(uniform.type){
        case "vec2":
            arguments.push({name:"x", type: macro : Float});
            arguments.push({name:"y", type: macro : Float});
            body = macro g.setFloat2($i{uniformLocationVariableName},x,y);
        case "vec3":
          arguments.push({name:"x", type: macro : Float});
          arguments.push({name:"y", type: macro : Float});
          arguments.push({name:"z", type: macro : Float});
          body = macro g.setFloat3($i{uniformLocationVariableName},x,y,z);
        case "vec4":
          arguments.push({name:"x", type: macro : Float});
          arguments.push({name:"y", type: macro : Float});
          arguments.push({name:"z", type: macro : Float});
          arguments.push({name:"w", type: macro : Float});
          body = macro g.setFloat4($i{uniformLocationVariableName},x,y,z,w);
        case "int":
          arguments.push({name:"x", type: macro : Int});
          body = macro g.setInt($i{uniformLocationVariableName},x);
        case "float":
          arguments.push({name:"x", type: macro : Float});
          body = macro g.setFloat($i{uniformLocationVariableName},x);
        case "mat4":
          arguments.push({name:"mat", type: macro : kha.math.FastMatrix4});
          body = macro g.setMatrix($i{uniformLocationVariableName},mat);
        case "mat3":
          //TODO
          // arguments.push({name:"mat", type: macro : kha.math.FastMatrix3});
          // body = macro g.setMatrix3($i{uniformLocationVariableName},mat);
        case "sampler2D":
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

        case "samplerCube":
          //TODO
          // arguments.push({name:"mat", type: macro : kha.math.FastMatrix4});
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
            args:[{name:"conf", type: macro : khage.g4.PipelineConf}],
            expr: constructorBody,
            ret: null
          }),
        });

    var bufferClassPath = BufferMacro.getBufferClassPathFromShaderInputs(desc.inputs);

    var typePathStr = bufferClassPath.pack.join(".") + "." + bufferClassPath.name;
    var type = macro : Dynamic;
    try{
        if(Context.getType(typePathStr) != null){
          type = TPath(bufferClassPath);
        }
    }catch(e : Dynamic){

    }

    fields.push({
      name:"draw",
      pos:pos,
      access: [APublic],
      kind:FFun({
        args : [{
          name:"buffer",
          type : type
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
