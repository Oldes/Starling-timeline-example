package  
{
	/**
	 * ...
	 * @author Oldes
	 */
	import display.TextureAnim;
	import display.TimelineMemoryBlock;
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
	import starling.utils.getNextPowerOfTwo;
    
	import starling.core.Starling;
    import starling.text.BitmapFont;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
	import starling.events.Event;

	import apparat.memory.MemoryPool;
	import apparat.memory.MemoryBlock;
	import apparat.memory.Memory;
	
	public final class Assets 
	{
		private static var images:Array = new Array();
		private static var atlasTextures:Array = new Array();
		private static var atlases:Array = new Array();
		private static var movies:Array = new Array();
		private static var flashMovies:Array = new Array();
		private static var objects:Array = new Array();
		private static var swfLoaders:Array = new Array();
		private static var sounds:Array = new Array();

		private static var namesByIDs:Array = new Array();
		private static var IDsByNames:Array = new Array();
		
		private var mStrings:Vector.<String> = new Vector.<String>;
		
		private static var mTextureDefinitions:Array = new Array();
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
		private var loadersCounter:int = 0;
		
		private static const context:LoaderContext = new LoaderContext;
		
		private static const cmdUseLevel:int                 = 1;
		private static const cmdTextureData:int              = 2;
		private static const cmdDefineImage:int              = 3;
		private static const cmdStartMovie:int               = 4;
		private static const cmdEndMovie:int                 = 5;
		private static const cmdAddMovieTexture:int          = 6;
		private static const cmdAddMovieTextureWithFrame:int = 7;
		private static const cmdLoadSWF:int                  = 8;
		
		private static const cmdTimelineData:int             = 10;
		private static const cmdTimelineObject:int           = 11;
		private static const cmdTimelineShape:int            = 12;
		
		private static const cmdDefineSound:int              = 15;
		
		private static const cmdWalkData:int                 = 20;
		
		private static const mMemory:ByteArray = new ByteArray();
		private static const DOMAIN_MEMORY_LENGTH:int = 50000;
		
		public function Assets() 
		{
			log("Assets");

			// Initialize the MemoryPool with default settings.
			//IT'S NOT POSSIBLE TO CHANGE THE MEMORY POOL SIZE!
			//So you should choose such a size, which will be enough for all app's life-time!
			MemoryPool.initialize(DOMAIN_MEMORY_LENGTH);
			
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
				//trace("opening FS " + currentFile);
				fs = new FileStream();
				fs.endian = Endian.LITTLE_ENDIAN;
				//fs.addEventListener(ProgressEvent.PROGRESS, onProgress);
				//fs.addEventListener(flash.events.Event.COMPLETE, onProcessCommands);
				//fs.openAsync(sourceFile, FileMode.READ);
				fs.open(sourceFile, FileMode.READ); onProcessCommands();
			} else if(loadersCounter==0) {				
				log();
				log("ALL PRELOADED " + (getTimer() - started) + "ms", "pixelsProcessed: "+pixelsProcessed);
				if (fOnPreloaded!=null) fOnPreloaded();
			}
		}
		
		private function onProgress(e:flash.events.Event = null):void {
			trace(">" + fs.bytesAvailable);
		}
		private function onProcessCommands(e:flash.events.Event = null):void {
			trace("preloaded Texture... " + currentFile +" "+(getTimer()-time));
			var textureAtlas:TextureAtlas;
			var texture:Texture;
			var command:int, numBytes:int;
			var id:String, numId:uint;
			var bitmap:Bitmap;
			var region:Rectangle;
			var frame:Rectangle;
			var bytes:ByteArray
			var i:int, count:int;
			var dataBlock:MemoryBlock;
			var ldr:Loader;
			var ctx:LoaderContext;

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
						numId = fs.readUnsignedShort();
						mStrings.length = 0;
						for (i = 0; i < numId; i++) {
							mStrings[i] = fs.readUTF();
						}
						trace("String Pool length: " + numId);
						break;
					case cmdTextureData:
						activeTextureName = mStrings[fs.readUnsignedShort()];
						var isATF:Boolean = (fs.readUnsignedByte() == 1)
						if (isATF) {
							//atf stream
							numBytes = fs.readUnsignedInt();
							fs.readBytes(inBuffer, 0, numBytes);
							log("ATF textureAtlas "+activeTextureName+" "+numBytes)
							activeAtlasTexture = Texture.fromAtfData(inBuffer);
							atlasTextures[activeTextureName] = activeAtlasTexture;
							inBuffer.clear();
						}
						
						numBytes = fs.readUnsignedInt(); //specification's data block size
						
						//trace("NUMBYTES"+ numBytes);
						
						dataBlock = MemoryPool.allocate( numBytes );
						MemoryPool.buffer.position = dataBlock.position;
						fs.readBytes(MemoryPool.buffer, dataBlock.position, numBytes);
						
						if (isATF) {
							processTextureAssets(activeAtlasTexture, activeTextureName, dataBlock);
						} else {
							mTextureDefinitions[activeTextureName] = dataBlock;
							numBytes = fs.readUnsignedInt(); //size of the not compressed image
							log("BMP textureAtlas "+activeTextureName+" "+numBytes)
							fs.readBytes(inBuffer, 0, numBytes);
							ldr = new Loader();
							ctx = new LoaderContext();
							ctx.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
							ctx.parameters = {"id": activeTextureName};
							ldr.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, onLoaderComplete);
							ldr.loadBytes(inBuffer, ctx);
							loadersCounter++;
							inBuffer.clear();
						}
						break;
					case cmdLoadSWF:
						id = fs.readUTF();
						numBytes = fs.readUnsignedInt();
						//trace("load-swf: " + id + " " + numBytes);
						fs.readBytes(inBuffer, 0, numBytes);
						ldr = new Loader();
						ctx = new LoaderContext();
						ctx.allowCodeImport = true;
						ctx.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
						ctx.parameters = {"id": id};
						ldr.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, onLoaderComplete);
						ldr.loadBytes(inBuffer, ctx);
						swfLoaders[activeLevel] = ldr;
						loadersCounter++;
						inBuffer.clear();
						break;
					case cmdDefineSound:
						id = mStrings[fs.readShort()];
						numBytes = fs.readUnsignedInt();
						var sound:Sound = new Sound();
						fs.readBytes(inBuffer, 0, numBytes);
						sound.loadCompressedDataFromByteArray(inBuffer, numBytes);
						sounds[id] = sound;
						log("DEFINE SOUND: " + id);
						inBuffer.clear();
						break;
					case cmdTimelineData:
						numBytes = fs.readUnsignedInt();
						trace("TimelineData bytes " +  numBytes);
						//fs.readBytes(inBuffer, 0, numBytes);
						dataBlock = MemoryPool.allocate( numBytes );
						MemoryPool.buffer.position = dataBlock.position;
						while ((command = fs.readUnsignedByte()) > 0) {
							switch(command){
								case cmdTimelineObject:
									numId = fs.readUnsignedShort();
									numBytes = fs.readUnsignedInt();
									fs.readBytes(inBuffer, 0, numBytes);
									spriteDefinitions[numId] = new TimelineMemoryBlock(dataBlock, MemoryPool.buffer.position, numBytes);
									MemoryPool.buffer.writeBytes(inBuffer);
									inBuffer.clear();
									//trace("Definition " + numId+" > "+ numBytes);
									break;
								case cmdTimelineShape:
									numId = fs.readUnsignedShort();
									numBytes = fs.readUnsignedInt();
									fs.readBytes(inBuffer, 0, numBytes);
									shapeDefinitions[numId] = new TimelineMemoryBlock(dataBlock, MemoryPool.buffer.position, numBytes);
									MemoryPool.buffer.writeBytes(inBuffer);
									inBuffer.clear();
									trace("Shape " + numId+" > "+ numBytes);
									break;
								default:
									throw new Error("Invalid Timeline command");
							}
						}
						var n:int = fs.readUnsignedInt();
						while (n-- > 0) {
							numId = fs.readUnsignedShort();
							id    = fs.readUTF();
							//trace("NameDefinition: " + numId+" > "+ id);
							namesByIDs[numId] = id;
							IDsByNames[id] = numId;
						}
						break;
					default:
						trace("Invalid command " + command);
						return;
				}
			}
			log("time: "+(getTimer() - started));
			fs.close();
			fs = null;
			preloadFile();
		}
		
		private function processTextureAssets(activeAtlasTexture:Texture, activeTextureName:String, data:MemoryBlock):void {
			log("Making texture assets " + activeTextureName);
			trace("DATA " + data.length);
			
			var command:int;
			var id:String;
			var region:Rectangle;
			var frame:Rectangle;
			
			var p:int = data.position; //pointer
			while ((command = Memory.readUnsignedByte(p++)) > 0) {
				switch(command){
					case cmdDefineImage:
						id = mStrings[Memory.readUnsignedShort(p)];
						region = new Rectangle();
						region.x      = Memory.readUnsignedShort(p+2);
						region.y      = Memory.readUnsignedShort(p+4);
						region.width  = Memory.readUnsignedShort(p+6);
						region.height = Memory.readUnsignedShort(p+8);
						p += 10;
						images[activeLevel + "/" + activeTextureName + "/" + id] = new Image(Texture.fromTexture(activeAtlasTexture, region));
						
						break;
					case cmdStartMovie:
						trace("start-movie2");
						activeMovieTextures = new Vector.<Texture>;
						activeMovieName = mStrings[Memory.readUnsignedShort(p)];
						p += 2;
						break;
					case cmdEndMovie:
						trace("end-movie " + activeMovieName);
						var ta:TextureAnim = new TextureAnim(activeMovieTextures, 25);
						var count:int = Memory.readUnsignedShort(p); //number of labels
						p += 2;
						while (count-- > 0) {
							ta.addLabel(Memory.readUnsignedShort(p), mStrings[Memory.readUnsignedShort(p + 2)]);
							p += 4;
						}
						ta.name = activeMovieName;
						movies[activeMovieName] = ta;
						activeMovieTextures.length = 0;
						activeMovieTextures = null;
						break;
					case cmdAddMovieTexture:
						region = new Rectangle();
						region.x      = Memory.readUnsignedShort(p);
						region.y      = Memory.readUnsignedShort(p+2);
						region.width  = Memory.readUnsignedShort(p+4);
						region.height = Memory.readUnsignedShort(p+6);
						p += 8;
						activeMovieTextures.push(Texture.fromTexture(activeAtlasTexture, region));
						break;
					case cmdAddMovieTextureWithFrame:
						region = new Rectangle();
						frame  = new Rectangle();
						region.x      = Memory.readUnsignedShort(p);
						region.y      = Memory.readUnsignedShort(p+2);
						region.width  = Memory.readUnsignedShort(p+4);
						region.height = Memory.readUnsignedShort(p+6);
						frame.x       = Memory.readInt(p + 8);
						frame.y       = Memory.readInt(p + 12);
						frame.width   = Memory.readUnsignedShort(p + 16);
						frame.height  = Memory.readUnsignedShort(p + 18);
						p += 20;
						//trace("add-texture:" + region + " " + frame);
						activeMovieTextures.push(Texture.fromTexture(activeAtlasTexture, region, frame));
						break;
					

					default:
						throw new Error("Invalid texture data definition command");
				}
			}
			
			// Free the space used by the data as we do not need it any longer
			MemoryPool.free( data );
		}
		private function onLoaderComplete(e:flash.events.Event):void {
			e.target.removeEventListener(flash.events.Event.COMPLETE, onLoaderComplete);
			var content:Object = e.target.content;
			var name:String = LoaderInfo(e.target).parameters.id;
			if(content is Bitmap){
				trace("LOADED BMP " + name);
				var bitmapData:BitmapData = Bitmap(content).bitmapData;
				var texture:Texture = Texture.fromBitmapData(bitmapData, false);
				atlasTextures[name] = texture;
				var data:MemoryBlock = mTextureDefinitions[name];
				
				processTextureAssets(texture, name, data);
				
				bitmapData.dispose();
				LoaderInfo(e.target).loader.unload();
			} else {
				trace("LOADED SWF" + name);
				var mov:DisplayObjectContainer = DisplayObjectContainer(content);
				var n:int = mov.numChildren;
				var m:DisplayObjectContainer;
				while (n-- > 0) {
					m = mov.getChildAt(n) as DisplayObjectContainer;
					if (m) {
						stopAllInSWF(m);
						if (m is MovieClip && m.name) {
							var mc:MovieClip = MovieClip(m);
							log("SWF: " + m.name);
							mc.stop();
							flashMovies[m.name] = m;	
						}
					}
				}
				//TODO: I should store the loader so I could unload it correctly when it's not needed anymore!
			}
			
			if (--loadersCounter == 0) {
				log();
				log("ALL PRELOADED " + (getTimer() - started) + "ms", "pixelsProcessed: "+pixelsProcessed);
				if (fOnPreloaded!=null) fOnPreloaded();
			}
			
		}
		
		
		private function onContextCreated(e:starling.events.Event):void {
			log("ASSETS: ON CONTEXT CREATED");
			//TODO: the textures must be reuploaded!
		}
		
		public static function getImage(name:String):Image
        {
			var img:Image = images[name] as Image;
			img.touchable = false;
            return img;
        }
		public static function getFlashMovie(name:String):MovieClip {
			var movie:MovieClip = flashMovies[name];
			if (movie == null) {
				throw new Error ("Unknown FlashMovie with name: " + name);
			}
			return movie;
		}
		public static function getTextureAtlas(name:String):TextureAtlas {
			return atlases[name];
		}
		public static function getStarlingMovie(name:String):TextureAnim {
			//log("GetMovie: " + name);
			var anim:TextureAnim = movies[name];
			if (anim == null) {
				throw new Error("Unknown movie with name: " + name);
			}
			if (anim.parent) {
				anim = new TextureAnim(anim.textures, anim.fps);
			}
			return anim;
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
		public static function getTimelineObject(name:String, asSprite:Boolean=false, touchable:Boolean=false):DisplayObject {
			//log("getTimelineObject " + name);
			return getTimelineObjectByID(IDsByNames[name], asSprite, touchable);
		}
		public static function getTimelineObjectByID(id:uint, asSprite:Boolean=false, touchable:Boolean=false):DisplayObject {
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
			var name:String = namesByIDs[id];
			if (!object) {
				var spec:TimelineMemoryBlock = spriteDefinitions[id];
				if (spec) {
					var numFrames:uint = Memory.readUnsignedShort(spec.head);
					//log("Creating new TimelineObject", id, spec.length, numFrames);
					
					if (numFrames == 1) {
						object = new TimelineSprite(spec) as DisplayObject;
					} else {
						object = new TimelineMovie(spec) as DisplayObject;
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
						object.touchable = touchable;
						Quad(object).color = 0xFFFFFF;
					}
				}
				if (!object) {
					//throw new Error("Unknown TimelineObject: " + id);
					object = new Quad(10, 10, 0xff0000);
				}
				pool.push(object);
			}
			object.touchable = touchable;
			if (asSprite) {
				var spr:Sprite = new Sprite();
				spr.name = name?name:String(id);
				spr.addChild(object);
				return spr;
			}
			return object as DisplayObject;
		}
		public static function getSound(name:String):Sound {
			log("getSound " + name);
			return sounds[name] as Sound;
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
			//trace("objects: "+objects.length+" pool " + pool.length);
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
			while (n-- > 0) {
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