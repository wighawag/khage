package khage.g4.macro;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using khage.util.macro.Util;

//vertexBuffer = new VertexBuffer();
//indexBuffer = new IndexBuffer();

class BufferMacro{

  static var bufferTypes : Map<String,ComplexType> = new Map();
  static var bufferTypeNames : Map<String,String> = new Map();
  static var numBufferTypes : Int =0;

	macro static public function apply() : ComplexType{

        var pos = Context.currentPos();

        var localType = Context.getLocalType();

        return BufferMacro.getBufferTypeFromLocalType(localType,pos);
    }

    static public function getBufferTypeFromLocalType(localType : Null<Type>, pos : Position) : ComplexType{
        var typeParam = switch (localType) {
            case TInst(_,[tp]):
                switch(tp){
                    case TType(t,param): t.get().type;
                    case TAnonymous(t) : tp;
                    default : null;
                }
            default:null;
        }
        if(typeParam == null){
            //Still alow specifying buffer via their porgram //TODO use shader paths separated by commas
//             switch (localType) {
//             case TInst(_,[t]):
//                 switch(t){
//                     case TInst(ref,_):
//                         var programType = ref.get();
//                         var metadata = programType.meta.get();
//                         var shaderGroup = glee.macro.GPUProgramMacro.getShaderGroupFromMetadata(metadata);
// -                       return getBufferClassFromAttributes(shaderGroup.attributes);
//                     case TMono(_): Context.error("need to specify the program type explicitly, no type inference supported", pos);
//                     default: Context.error("unsuported type : " +  localType, pos);
//                 }
//                 default: Context.error("unsuported type : " +  localType, pos);
//             }
        }

        if(typeParam == null){
            Context.error("type param not found",pos);
        }

        var fields = switch(typeParam){
            case TInst(ref,_):
                 ref.get().fields.get();
            case TMono(mono):  Context.error("need to specify the program type explicitely, no type inference : " + typeParam + " (" + mono.get() + ")",pos); null;
            case TAnonymous(ref):
                ref.get().fields;
            default: null;
        }

        if(fields == null){
            Context.error("type param not supported " + typeParam, pos);
            return null;
        }

        var attributes = new Array<khage.g4.glsl.GLSLShaderGroup.Attribute>();
        for (field in fields){
            switch(field.type){
                case TAbstract(t,_):
                    var abstractType = t.get();
                    if(abstractType.pack.length == 2 && abstractType.pack[0] == "khage" && abstractType.pack[1] == "g4"){
                        attributes.push({name:field.name, type:TPath({name :abstractType.name, pack :abstractType.pack})});
                    }else if(abstractType.pack.length == 0 && abstractType.name == "Float"){
                      attributes.push({name:field.name, type:TPath({name :abstractType.name, pack :abstractType.pack})});
                    }else{
                        Context.error("attribute type not supported " + abstractType, pos);
                        return null;
                    }
                default :
                    Context.error("attribute type not supported " + field.type, pos);
                    return null;
            }
        }

        attributes.sort(function(a,b){
					if (a.name < b.name) return -1;
    			if (a.name > b.name) return 1;
    			return 0;
				});


        //TODO sort

        var bufferType = getBufferClassFromAttributes(attributes);

        return bufferType;
    }

    static public function getBufferClassFromAttributes(attributes : Array<khage.g4.glsl.GLSLShaderGroup.Attribute>) : ComplexType{
        var pos = Context.currentPos();
        var bufferClassPath = getBufferClassPathFromAttributes(attributes);

        if (bufferTypes.exists(bufferClassPath.name)){
            //trace("already generated " + bufferClassPath.name);
            return bufferTypes[bufferClassPath.name];
        }


        var fields : Array<Field> = [];

        var constructorBody = macro {
          var structure = new kha.graphics4.VertexStructure();
        };


        var getNumVerticesWrittenBody = macro {var max : Float = 0;};

        var rewindBody = macro {
            lock();
            numIndicesWritten = 0;
        };


        var totalStride : Int = 0;

        for (attribute in attributes){
            var numValues = 1;
            var attrTPath = switch(cast attribute.type){
                case TPath(att): att;
                default: Context.error("should be a TPath", pos); null;
            };
            if(attrTPath.name == "Vec4"){
                numValues = 4;
            }else if(attrTPath.name == "Vec3"){
                numValues = 3;
            }else if(attrTPath.name == "Vec2"){
                numValues = 2;
            }
            totalStride+= numValues; //work for samme types attributes //TODO make it work for mixed types Int/Float...
        }

        var stride = 0;
        for (attribute in attributes){
            var attributeName = attribute.name;
            var attributeMetadataName = "_" + attributeName + "_bufferPosition";

            getNumVerticesWrittenBody.append(macro max = Math.max(max,$i{attributeMetadataName}));

            rewindBody.append(macro  $i{attributeMetadataName} = 0);

            var numValues = 1;
            var attrTPath = switch(cast attribute.type){
                case TPath(att): att;
                default: Context.error("should be a TPath", pos); null;
            };
            if(attrTPath.name == "Vec4"){
              constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float4));
              numValues = 4;
            }else if(attrTPath.name == "Vec3"){
              constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float3));
              numValues = 3;
            }else if(attrTPath.name == "Vec2"){
              constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float2));
              numValues = 2;
            }else{
              constructorBody.append(macro structure.add($v{attributeName}, kha.graphics4.VertexData.Float1));
            }

            //////////////////////initialization //////////////////////////////////////////


            fields.push({
                name: attributeMetadataName,
                pos: pos,
                access: [APrivate],
                kind: FVar(macro : Int,macro 0), //TODO -1 or 0 ?
                });


            /////////////////////// write function ////////////////////////////////////////////
            var body = macro {
                uploaded = false;
                var pos : Int = $i{attributeMetadataName} * $v{totalStride} + $v{stride};
                $i{attributeMetadataName} ++;
            }

            for (i in 0...numValues){
                var arg = "v" + i;
                body.append(macro  vertexData[pos+$v{i}] = $i{arg});
            }

            //trace(body.toString());

            var arguments = [];
            var attrTPath = switch(cast attribute.type){
                case TPath(att): att;
                default: Context.error("should be a TPath", pos); null;
            };

            if(attrTPath.name.substr(0,3) == "Vec"){
                for (i in 0...numValues){
                  arguments.push({
                    name:"v" + i,
                    type : macro : Float
                  });
                }
            }else if(attrTPath.name == "Float"){
                arguments.push({
                  name:"v0",
                  type : macro : Float
                });
            }

            fields.push({
                  name: "write_" + attribute.name,
                  pos: pos,
                  access: [APublic, AInline],
                  kind: FFun({
                    args:arguments,
                    expr: body,
                    ret: macro :Void
                  }),
                  meta:[{
                    pos:pos,
                    name:":extern"
                  }]
                });
            stride+= numValues; //work for samme types attributes //TODO make it work for mixed types Int/Float...
        }

        getNumVerticesWrittenBody.append(macro return Std.int(max));
        fields.push({
              name: "getNumVerticesWritten",
              pos: pos,
              access: [APublic, AInline],
              kind: FFun({
                args:[],
                expr: getNumVerticesWrittenBody,
                ret: macro :Int
              }),
            });

        fields.push({
              name: "rewind",
              pos: pos,
              access: [APublic, AInline],
              kind: FFun({
                args:[],
                expr: rewindBody,
                ret: macro :Void
              }),
            });


        constructorBody.append(macro {
          vertexBuffer = new kha.graphics4.VertexBuffer(numVertices * $v{totalStride},structure,usage);
          indexBuffer = new kha.graphics4.IndexBuffer(numIndices,usage);
        });
        fields.push({
              name: "new",
              pos: pos,
              access: [APublic,AInline],
              kind: FFun({
                args:[{
                    name:"numVertices",
                    type: macro :Int
                },
                {
                    name:"numIndices",
                    type: macro :Int
                },
                {
                  name:"usage",
                  type: macro : kha.graphics4.Usage
                }],
                expr: constructorBody,
                ret: null
              }),
            });


        var typeDefinition : TypeDefinition = {
            pos : pos,
            pack : bufferClassPath.pack,
            name : bufferClassPath.name,
            kind :TDClass({pack :["khage","g4"], name: "BufferBase"},[], false),
            fields:fields
        }
        Context.defineType(typeDefinition);


        var bufferType = TPath(bufferClassPath);
        bufferTypes[bufferClassPath.name] = bufferType;
        return bufferType;
    }

    static public function getBufferClassPathFromAttributes(attributes : Array<khage.g4.glsl.GLSLShaderGroup.Attribute>): TypePath{
        var bufferClassName =  "Buffer_";
        attributes = attributes.copy();
        attributes.sort(function(x,y){
            if(x.name == y.name){
                return 0;
            }
            return x.name < y.name ? -1 : 1;
            });
        for (attribute in attributes){
          bufferClassName += attribute.name + attribute.type;
        }
        bufferClassName = StringTools.urlEncode(bufferClassName);
        bufferClassName = StringTools.replace(bufferClassName,"%","_");

        if (bufferTypeNames.exists(bufferClassName)){
            //trace("already generated " + bufferClassPath.name);
            bufferClassName = bufferTypeNames[bufferClassName];
        }else{
            //TODO use different naming
            numBufferTypes++;
            var newBufferClassName = "Buffer_" + numBufferTypes;
            bufferTypeNames[bufferClassName] = newBufferClassName;
            bufferClassName = newBufferClassName;
        }

        var bufferClassPath = {pack:["khage","g4", "buffer"],name:bufferClassName};

        return bufferClassPath;
    }


}
