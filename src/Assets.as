package  
{
	/**
	 * ...
	 * @author Oldes
	 */
	import display.TextureAnim;
	import display.TimelineMovie;
	import display.TimelineObject;
	import display.TimelineShape;
	import display.TimelineSprite;
    import flash.display.Bitmap;
	import flash.display.BitmapData;
	import starling.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.geom.Rectangle;
    import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.Endian;
	import flash.system.ImageDecodingPolicy;
	import starling.display.Image;
	import starling.display.materials.StandardMaterial;
	import starling.display.Quad;
	import starling.display.Sprite;
    
	import starling.core.Starling;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
	import starling.events.Event;

	
	public final class Assets 
	{
		private static var images:Array = new Array();
		private static var atlasTextures:Array = new Array();
		private static var atlases:Array = new Array();
		private static var movies:Array = new Array();
		private static var objects:Array = new Array();
		
		private static var namesByIDs:Array = new Array();
		private static var IDsByNames:Array = new Array();
		
		private static var spriteDefinitions:Array = new Array();
		private static var shapeDefinitions:Array = new Array();
		private static var shapeMaterials:Vector.<StandardMaterial> = new Vector.<StandardMaterial>;
		private static const loader:Loader = new Loader();
		
		private var fs:FileStream;
		private static var currentFile:String;
		private static var _instance:Assets;
		private var assetPacksToPreload:Array;
		private var fOnPreloaded:Function;
		
		private var bitmapData:BitmapData;
		private var atfBytes:ByteArray;
		private var useATF:Boolean = false;
		
		private var time:Number;
		private var started:Number;
		private var pixelsProcessed:uint;
		private var inBuffer:ByteArray;
		private const inRectangle:Rectangle = new Rectangle();
		private const inRectangle2:Rectangle = new Rectangle();
		private var bValidateStream:Boolean;
		private var activeLevel:String;
		private var activeTextureName:String;
		private var activeMovieName:String;
		private var activeMovieTextures:Vector.<Texture>;
		private var activeAtlasTexture:Texture;
		private static const context:LoaderContext = new LoaderContext;
		
		private static const cmdUseLevel:int                 = 1;
		private static const cmdLoadTexture:int              = 2;
		private static const cmdInitTexture:int              = 3;
		private static const cmdDefineImage:int              = 4;
		private static const cmdStartMovie:int               = 5;
		private static const cmdAddMovieTexture:int          = 6;
		private static const cmdAddMovieTextureWithFrame:int = 7;
		private static const cmdEndMovie:int                 = 8;
		private static const cmdLoadSWF:int                  = 9;
		private static const cmdInitSWF:int                  = 10;
		private static const cmdATFTexture:int               = 11;
		private static const cmdATFTextureMovie:int          = 12;
		private static const cmdTimelineObject:int           = 13;
		private static const cmdTimelineName:int             = 14;
		private static const cmdTimelineShape:int            = 15;
		private static const cmdStartMovie2:int              = 16;
		private static const cmdWalkData:int                 = 17;
		
		public function Assets() 
		{
			log("Assets");
			context.allowCodeImport = true;
			context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;;
			inBuffer = new ByteArray();
			loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, onProcessCommands);
			Starling.current.addEventListener(starling.events.Event.CONTEXT3D_CREATE, onContextCreated);
		}
		
		public static function get instance():Assets{
			if(!_instance) _instance = new Assets();
			return _instance;
		}
		
		public function preloadFiles(files:Array, onPreloaded:Function = null):void {
			started = getTimer();
			log("Preload assets: " + files);
			assetPacksToPreload = files;
			fOnPreloaded = onPreloaded;
			preloadFile();
		}
		
		private function preloadFile():void {
			log("AssetPacksToPreload " + assetPacksToPreload.length);
			if (assetPacksToPreload.length > 0) {
				time = getTimer();
				currentFile = assetPacksToPreload.shift();
				var file:URLRequest;
				
				var sourceFile:File = File.applicationDirectory.resolvePath("Data/" + currentFile + ".lvl");
				bValidateStream = true;
				trace("opening FS " + currentFile);
				fs = new FileStream();
				fs.endian = Endian.LITTLE_ENDIAN;
				fs.addEventListener(flash.events.Event.COMPLETE, onProcessCommands);
				fs.open(sourceFile, FileMode.READ);	onProcessCommands();
			} else {				
				log();
				log("ALL PRELOADED " + (getTimer() - started) + "ms", "pixelsProcessed: "+pixelsProcessed);
				if (fOnPreloaded!=null) fOnPreloaded();
			}
		}
		
		private function onProcessCommands(e:flash.events.Event=null):void{
			trace("preloaded Texture... " + currentFile +" "+(getTimer()-time));
			var textureAtlas:TextureAtlas;
			var texture:Texture;
			var command:int, numBytes:int;
			var id:String, numId:uint;
			var bitmap:Bitmap;
			var region:Rectangle;
			var frame:Rectangle;
			var bytes:ByteArray
			
			if ( bValidateStream ) {
				if (
					   fs.readByte() != 76 //"L"
					|| fs.readByte() != 86 //"V"
					|| fs.readByte() != 76 //"L"
				) {
					throw new Error("Invalid LVL file!");
				}
				bValidateStream = false;
			}
			
			while ((command = fs.readUnsignedByte()) > 0) {
				//trace("COMMAND: " + command)
				switch(command) {
					case cmdUseLevel:
						activeLevel = fs.readUTF();
						trace("use-level: " + activeLevel);
						break;
					case cmdLoadTexture:
						numBytes = fs.readUnsignedInt();
						log("textureAtlas "+" "+numBytes)
						fs.readBytes(inBuffer, 0, numBytes);
						loader.loadBytes(inBuffer, context);
						return;
					case cmdInitTexture:
						bitmapData = Bitmap(LoaderInfo(e.target).content).bitmapData;
						activeTextureName = fs.readUTF();
						log("loaded file " + activeTextureName);
						//pixelsProcessed += (bitmapData.width * bitmapData.height);
						activeAtlasTexture = Texture.fromBitmapData(bitmapData, false);
						atlasTextures[activeTextureName] = activeAtlasTexture;
						bitmapData.dispose();
						inBuffer.clear();
						break;
					case cmdDefineImage:
						id = fs.readUTF();
						region = new Rectangle();
						region.x = fs.readUnsignedShort();
						region.y = fs.readUnsignedShort();
						region.width = fs.readUnsignedShort();
						region.height = fs.readUnsignedShort();
						//trace("addregion:" + id+" "+region);
						//activeTextureAtlas.addRegion(id, inRectangle);
						//trace("image: " + activeLevel + "/" + activeTextureName + "/" + id);
						images[activeLevel+"/"+activeTextureName+"/"+id] = new Image(Texture.fromTexture(activeAtlasTexture, region));
						break;
					case cmdStartMovie:
						//trace("start-movie");
						activeMovieName = fs.readUTF();
						activeMovieTextures = new Vector.<Texture>;
						
						bitmapData = Bitmap(LoaderInfo(e.target).content).bitmapData;
						activeAtlasTexture = Texture.fromBitmapData(bitmapData, false);
						atlasTextures[activeMovieName] = activeAtlasTexture;
						bitmapData.dispose();
						break;
					case cmdAddMovieTexture:
						region = new Rectangle();
						region.x = fs.readUnsignedShort();
						region.y = fs.readUnsignedShort();
						region.width = fs.readUnsignedShort();
						region.height = fs.readUnsignedShort();
						activeMovieTextures.push(Texture.fromTexture(activeAtlasTexture, region));
						break;
					case cmdAddMovieTextureWithFrame:
						region = new Rectangle();
						frame = new Rectangle();
						region.x = fs.readUnsignedShort();
						region.y = fs.readUnsignedShort();
						region.width = fs.readUnsignedShort();
						region.height = fs.readUnsignedShort();
						frame.x = fs.readShort();
						frame.y = fs.readShort();
						frame.width = fs.readUnsignedShort();
						frame.height = fs.readUnsignedShort();
						//trace("add-texture:" + region + " " + frame);
						activeMovieTextures.push(Texture.fromTexture(activeAtlasTexture, region, frame));
						break;
					case cmdEndMovie:
						movies[activeMovieName] = new TextureAnim(activeMovieTextures, 25);
						activeMovieTextures.length = 0;
						activeMovieTextures = null;
						break;
					case cmdLoadSWF:
						id = fs.readUTF();
						numBytes = fs.readUnsignedInt();
						//trace("load-swf: " + id + " " + numBytes);
						fs.readBytes(inBuffer, 0, numBytes);
						loader.loadBytes(inBuffer, context);
						return;
					case cmdInitSWF:
						log("SWF loaded:" + LoaderInfo(e.target).content);
						var mov:DisplayObjectContainer = DisplayObjectContainer(LoaderInfo(e.target).content);
						var n:int = mov.numChildren;
						var m:DisplayObjectContainer;
						while (n > 0) {
							n--;
							m = mov.getChildAt(n) as DisplayObjectContainer;
							if (m) {
								stopAllInSWF(m);
								if (m is MovieClip && m.name) {
									var mc:MovieClip = MovieClip(m);
									log("SWF: " + m.name);
									mc.stop();
									movies[m.name] = m;	
								}
							}
						}
						inBuffer.clear();
						break;
					case cmdATFTexture:
						numBytes = fs.readUnsignedInt();
						time = getTimer();
						fs.readBytes(inBuffer, 0, numBytes);
						log("ATF textureAtlas "+" "+numBytes+" "+(getTimer()-time))
						activeTextureName = fs.readUTF();
						activeAtlasTexture = Texture.fromAtfData(inBuffer);
						atlasTextures[activeTextureName] = activeAtlasTexture;
						inBuffer.clear();
						break;
					case cmdATFTextureMovie:
						numBytes = fs.readUnsignedInt();
						time = getTimer();
						fs.readBytes(inBuffer, 0, numBytes);
						log("ATF textureAtlas "+" "+numBytes+" "+(getTimer()-time))
						activeMovieName = fs.readUTF();
						activeMovieTextures = new Vector.<Texture>;
						
						activeAtlasTexture = Texture.fromAtfData(inBuffer);
						atlasTextures[activeMovieName] = activeAtlasTexture;
						inBuffer.clear();
						break;
					case cmdTimelineObject:
						numId = fs.readUnsignedShort();
						numBytes = fs.readUnsignedInt();
						bytes = new ByteArray();
						fs.readBytes(bytes, 0, numBytes);
						bytes.endian = Endian.LITTLE_ENDIAN;
						spriteDefinitions[numId] = bytes;
						log("Definition " + numId, numBytes);
						break;
					case cmdTimelineName:
						numId = fs.readUnsignedShort();
						id    = fs.readUTF();
						log("NameDefinition: " + numId, id);
						namesByIDs[numId] = id;
						IDsByNames[id] = numId;
						break;
					case cmdTimelineShape:
						numId = fs.readUnsignedShort();
						numBytes = fs.readUnsignedInt();
						bytes = new ByteArray();
						fs.readBytes(bytes, 0, numBytes);
						bytes.endian = Endian.LITTLE_ENDIAN;
						shapeDefinitions[numId] = bytes;
						log("Shape " + numId, numBytes);
						break;
					case cmdStartMovie2:
						trace("start-movie2");
						activeMovieName = fs.readUTF();
						activeMovieTextures = new Vector.<Texture>;
						break;
					default:
						log("Invalid command " + command);
						return;
				}
			}
			fs.close();
			fs = null;
			preloadFile();
		}

		
		
		private function onContextCreated(e:starling.events.Event):void {
			log("ASSETS: ON CONTEXT CREATED");
			//TODO: the textures must be reuploaded!
		}
		
		public static function getImage(name:String):Image
        {
            return images[name];
        }
		public static function getFlashMovie(name:String):MovieClip {
			return movies[name];
		}
		public static function getTextureAtlas(name:String):TextureAtlas {
			return atlases[name];
		}
		public static function getStarlingMovie(name:String):TextureAnim {
			//log("GetMovie: " + name);
			return movies[name];
		}
		
		public static function overrideTimelineObject(name:String, object:DisplayObject):Boolean {
			var id:int = IDsByNames[name];
			log("OverrideTLO: " + name + " " + id);
			if (!id) return false;
			var pool:Array = objects[id];
			if (pool == null) {
				objects[id] = pool = new Array();
			} else {
				//TODO: dispose objects in the pool if there are any!!!
				pool.length = 1;
			}
			pool.push(object);
			return true;
		}
		public static function getTimelineObject(name:String, asSprite:Boolean=false):DisplayObject {
			log("getTimelineObject " + name);
			return getTimelineObjectByID(IDsByNames[name], asSprite);
		}
		public static function getTimelineObjectByID(id:uint, asSprite:Boolean=false):DisplayObject {
			//log("getTimelineObject: " + id + " "+namesByIDs[id]);
			
			var object:DisplayObject;
			var pool:Array = objects[id];
			if (pool == null) {
				objects[id] = pool = new Array();
			}
			for (var n:int = 0; n < pool.length; n++) {
				object = DisplayObject(pool[n]);
				if (object.parent == null) {
					//log("Reusing TimelineObject " + object.name);
					if (object is TimelineObject) {
						TimelineObject(object).init(); //resets object state
					}
					break;
				} else {
					object = null;
				}
			}
			if (!object) {
				var name:String = namesByIDs[id];
				var spec:ByteArray = spriteDefinitions[id];
			
				if (spec) {
					spec.position = 0;
					var newSpec:ByteArray = new ByteArray();
					spec.readBytes(newSpec);
					newSpec.endian = Endian.LITTLE_ENDIAN;
					newSpec.position = 0;
					var numFrames:uint = newSpec.readUnsignedShort();
					//log("Creating new TimelineObject", id, spec.length, numFrames);
					
					if (numFrames == 1) {
						object = new TimelineSprite(newSpec) as DisplayObject;
					} else {
						object = new TimelineMovie(newSpec) as DisplayObject;
					}
					TimelineObject(object).removeTint();
					object.name = name?name:String(id);
				} else {
					var tmp:Image = images[name];
					if (tmp) {
						if (tmp.parent == null) {
							//log("reusing image");
							object = tmp;
						} else {
							//log("cloning image: "+name);
							object = new Image(tmp.texture) as DisplayObject;
							object.name = name?name:String(id);
						}
						object.touchable = false;
						Quad(object).color = 0xFFFFFF;
					}
				}
				if (!object) {
					//throw new Error("Unknown TimelineObject: " + id);
					object = new Quad(10, 10, 0xff0000);
				}
				pool.push(object);
			}
			if (asSprite) {
				var spr:Sprite = new Sprite();
				spr.addChild(object);
				return spr;
			}
			return object as DisplayObject;
		}
		public static function getTimelineShape(name:String):DisplayObject {
			log("getTimelineShape " + name);
			return getTimelineShapeByID(IDsByNames[name]);
		}
		public static function getTimelineShapeByID(id:uint):DisplayObject {
			//log("getTimelineShape: " + id + " "+namesByIDs[id]);
			
			var object:DisplayObject;
			var pool:Array = objects[id];
			
			if (pool == null) {
				objects[id] = pool = new Array();
			}
			trace("objects: "+objects.length+" pool " + pool.length);
			for (var n:int = 0; n < pool.length; n++) {
				object = DisplayObject(pool[n]);
				if (object.parent == null) {
					//log("resusing shape " + id);
					//TimelineShape(object).init();
					break;
				} else {
					object = null;
				}
			}
			if (!object) {
				var spec:ByteArray = shapeDefinitions[id];
				if(spec){
					spec.position = 0;
					object = new TimelineShape(spec) as DisplayObject;
					pool.push(object);
				} else {
					object = new Quad(10, 10, 0x00ff00);
					pool.push(object);
					//throw new Error("Unknown shape definition! " + id);
				}
			}
			return object as DisplayObject;
		}
		public static function getLineMaterial(color:int, alpha:Number):StandardMaterial {
			var sharedLineMaterial:StandardMaterial;
			for each (sharedLineMaterial in shapeMaterials) {
				if (sharedLineMaterial.color == color && sharedLineMaterial.alpha == alpha) return sharedLineMaterial;
			}
			sharedLineMaterial = new StandardMaterial();
			sharedLineMaterial.color = color;
			sharedLineMaterial.alpha = alpha;
			shapeMaterials.push(sharedLineMaterial);
			trace(shapeMaterials.length);
			return sharedLineMaterial;
		}

		
		public static function getTimelineSprite(name:String):Sprite {
			return new Sprite;
		}
		
		
		
		
		private function stopAllInSWF(swf:DisplayObjectContainer):void {
			var n:int = swf.numChildren;
			var child:flash.display.DisplayObject;
			while (n > 0) {
				n--;
				child = swf.getChildAt(n);
				if (child is DisplayObjectContainer) {
					//log("stoping.. " + child, child.name);
					if (child is MovieClip) MovieClip(child).stop();
					stopAllInSWF(DisplayObjectContainer(child));
				}
			}
		}
	}	
		
}