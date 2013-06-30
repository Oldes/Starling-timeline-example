package core
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
	import flash.errors.EOFError;
	import memory.Memory;
	import memory.MemoryBlock;
	import starling.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.geom.Rectangle;
    import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
    import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.Endian;
	import flash.system.ImageDecodingPolicy;
	import flash.system.System;
	import starling.display.Image;
	import starling.display.materials.StandardMaterial;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.filters.ColorMatrixFilter;
	import starling.textures.SubTexture;
    
	import starling.core.Starling;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
	import starling.events.Event;

	//import apparat.memory.MemoryPool;
	//import apparat.memory.MemoryBlock;
	//import apparat.memory.Memory;

	import avm2.intrinsics.memory.*;

	public final class Assets 
	{
		private static var mBaseTextures:Array = new Array();
		private static var mSubTextures:Vector.<Texture> = new Vector.<Texture>(5000, true);
		//private static var atlases:Array = new Array();
		private static var mTextureAnims:Array = new Array();
		private static var mFlashMovies:Array = new Array();
		private static var mImageNameIDs:Array = new Array();
		private static var mSoundNameIDs:Array = new Array();
		private static var mPoolTextureAnims:Vector.<TextureAnim> = new Vector.<TextureAnim>();
		private static var mPoolTimelineShapes:Vector.<Vector.<DisplayObject>> = new Vector.<Vector.<DisplayObject>>(5000, true); 
		private static var mPoolTimelineObjects:Vector.<Vector.<DisplayObject>> = new Vector.<Vector.<DisplayObject>>(5000, true); //WARNING: now there can be max 5000 timeline items!
		private static var mPoolImages:Vector.<Vector.<Image>> = new Vector.<Vector.<Image>>(5000, true); //WARNING: now there can be max 5000 timeline items!
		private static var mPoolCMFilters:Vector.<ColorMatrixFilter> = new Vector.<ColorMatrixFilter>;
		private static var mSWFLoaders:Array = new Array();
		private static var mSounds:Array = new Array();
		private static var mDataBlocks:Array = new Array();
		private static var mDataBlocksToFree:Array = new Array();
		
		public  static var namedObjects:Array = new Array();
		
		private static var mNamesByIDs:Array = new Array();
		private static var mIDsByNames:Array = new Array();
		
		private var mStrings:Vector.<String> = new Vector.<String>;
		
		private static var mTextureDefinitions:Array = new Array();
		private static var spriteDefinitions:Vector.<TimelineMemoryBlock> = new Vector.<TimelineMemoryBlock>(2000, true); //USE NUMBER WHICH IS LARGE ENOUGH FOR YOUR PURPOSE
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
		
		private static const cmdImageNames:int               = 30;
		
		
		private static const DOMAIN_MEMORY_LENGTH:int = 5000000;
		public  static const mMemory:ByteArray = new ByteArray();

		public function Assets() 
		{
			log("Assets");
			// Initialize the MemoryPool with default settings.
			//IT'S NOT POSSIBLE TO CHANGE THE MEMORY POOL SIZE!
			//So you should choose such a size, which will be enough for all app's life-time!
			//MemoryPool.initialize(DOMAIN_MEMORY_LENGTH);

			mMemory.length = DOMAIN_MEMORY_LENGTH;
			mMemory.endian = Endian.LITTLE_ENDIAN;
			Memory.select(mMemory);
			
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
				log("ALL PRELOADED " + (getTimer() - started) + "ms", "pixelsProcessed: " + pixelsProcessed);
				disposeUnusedDataBlocks();
				if (fOnPreloaded!=null) fOnPreloaded();
			}
		}
		private function disposeUnusedDataBlocks():void {
			/*var n:int = mDataBlocksToFree.length;
			while (n-- > 0) {
				var dataBlock:MemoryBlock = mDataBlocksToFree[n] as MemoryBlock;
				trace("#####FREE: " + dataBlock);
				MemoryPool.free(dataBlock);
			}*/
			mDataBlocksToFree.length = 0;
		}
		private function onProgress(e:flash.events.Event = null):void {
			trace(">" + fs.bytesAvailable);
		}
		private function onProcessCommands(e:flash.events.Event=null):void {
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
			try {
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
								mBaseTextures[activeTextureName] = activeAtlasTexture;
								inBuffer.clear();
							}
							
							numBytes = fs.readUnsignedInt(); //specification's data block size
							
							trace("NUMBYTES"+ numBytes);
							
							//todo: !!!! temp hardcoded value
							dataBlock = Memory.allocate( numBytes );
							mMemory.position = dataBlock.position;
							fs.readBytes(mMemory, dataBlock.position, numBytes);
							
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
						case cmdImageNames:
							i = fs.readShort();
							while (i-- > 0) {
								id = fs.readUTF();
								numId = fs.readShort();
								//log("NAMED IMAGE: " + numId + " " + id);
								mImageNameIDs[id] = numId;
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
							mSWFLoaders[activeLevel] = ldr;
							loadersCounter++;
							inBuffer.clear();
							break;
						case cmdDefineSound:
							id = mStrings[fs.readShort()];
							numId = fs.readShort();
							numBytes = fs.readUnsignedInt();
							mSoundNameIDs[id] = numId;
							var sound:Sound = new Sound();
							fs.readBytes(inBuffer, 0, numBytes);
							sound.loadCompressedDataFromByteArray(inBuffer, numBytes);
							mSounds[numId] = sound;
							log("DEFINE SOUND: " + numId +" "+ id);
							inBuffer.clear();
							break;
						case cmdTimelineData:
							numBytes = fs.readUnsignedInt();
							trace("TimelineData bytes " +  numBytes);
							//fs.readBytes(inBuffer, 0, numBytes);
							dataBlock = Memory.allocate( numBytes );
							dataBlock.level = activeLevel;
							mDataBlocks.push(dataBlock);
							Memory.buffer.position = dataBlock.position;
							while ((command = fs.readUnsignedByte()) > 0) {
								switch(command){
									case cmdTimelineObject:
										numId = fs.readUnsignedShort();
										numBytes = fs.readUnsignedInt();
										fs.readBytes(inBuffer, 0, numBytes);
										spriteDefinitions[numId] = new TimelineMemoryBlock(Memory.buffer.position, numBytes);
										Memory.buffer.writeBytes(inBuffer);
										inBuffer.clear();
										trace("Definition " + numId+" > "+ numBytes);
										break;
									case cmdTimelineShape:
										numId = fs.readUnsignedShort();
										numBytes = fs.readUnsignedInt();
										fs.readBytes(inBuffer, 0, numBytes);
										shapeDefinitions[numId] = new TimelineMemoryBlock(Memory.buffer.position, numBytes);
										Memory.buffer.writeBytes(inBuffer);
										inBuffer.clear();
										//trace("Shape " + numId+" > "+ numBytes);
										break;
									default:
										throw new Error("Invalid Timeline command");
								}
							}
							var n:int = fs.readUnsignedInt();
							while (n-- > 0) {
								numId = fs.readUnsignedShort();
								id    = fs.readUTF();
								trace("NameDefinition: " + numId+" > "+ id);
								mNamesByIDs[numId] = id;
								mIDsByNames[id] = numId;
							}
							break;
						default:
							log("Invalid command " + command);
							return;
					}
				}
			} catch (e:EOFError) {
				log(e);
				throw e;
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
			var numId:int;
			var region:Rectangle;
			var frame:Rectangle;
			
			var p:int = data.position; //pointer
			while ((command = li8(p++)) > 0) {
				//trace(command);
				switch(command){
					case cmdDefineImage:
						numId         = li16(p);
						region  = new Rectangle();
						region.x      = li16(p+2);
						region.y      = li16(p+4);
						region.width  = li16(p+6);
						region.height = li16(p+8);
						p += 10;
						//trace("defineImage: "+numId+" "+region)
						mSubTextures[numId] = Texture.fromTexture(activeAtlasTexture, region);
						break;
					case cmdStartMovie:
						trace("start-movie");
						activeMovieTextures = new Vector.<Texture>;
						activeMovieName = mStrings[li16(p)];
						p += 2;
						break;
					case cmdEndMovie:
						trace("end-movie " + activeMovieName);
						var ta:TextureAnim = new TextureAnim(activeMovieName, activeMovieTextures, 25);
						var count:int = li16(p); //number of labels
						p += 2;
						while (count-- > 0) {
							ta.addLabel(li16(p), mStrings[li16(p + 2)]);
							p += 4;
						}
						ta.name = activeMovieName;
						
						mPoolTextureAnims.push(ta);
						//mTextureAnims[activeMovieName] = ta;
						activeMovieTextures.length = 0;
						activeMovieTextures = null;
						break;
					case cmdAddMovieTexture:
						region = new Rectangle();
						region.x      = li16(p);
						region.y      = li16(p+2);
						region.width  = li16(p+4);
						region.height = li16(p+6);
						p += 8;
						activeMovieTextures.push(Texture.fromTexture(activeAtlasTexture, region));
						break;
					case cmdAddMovieTextureWithFrame:
						region = new Rectangle();
						frame  = new Rectangle();
						region.x      = li16(p);
						region.y      = li16(p+2);
						region.width  = li16(p+4);
						region.height = li16(p+6);
						frame.x       = li32(p + 8);
						frame.y       = li32(p + 12);
						frame.width   = li16(p + 16);
						frame.height  = li16(p + 18);
						p += 20;
						//trace("add-texture:" + region + " " + frame);
						activeMovieTextures.push(Texture.fromTexture(activeAtlasTexture, region, frame));
						break;
					

					default:
						throw new Error("Invalid texture data definition command");
				}
			}
			
			// Mark the dataBlock as free as it's not needed anymore.
			Memory.free(data);
		}
		private function onLoaderComplete(e:flash.events.Event):void {
			e.target.removeEventListener(flash.events.Event.COMPLETE, onLoaderComplete);
			var content:Object = e.target.content;
			var name:String = LoaderInfo(e.target).parameters.id;
			if(content is Bitmap){
				trace("LOADED BMP " + name);
				var bitmapData:BitmapData = Bitmap(content).bitmapData;
				var texture:Texture = Texture.fromBitmapData(bitmapData, false);
				mBaseTextures[name] = texture;
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
							mFlashMovies[m.name] = m;	
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
			trace("GetImage: " + name+" = "+ mImageNameIDs[name]);
			
            return getTimelineImageByID(mImageNameIDs[name]) as Image;
        }
		public static function getImageById(id:int):Image
        {
            return getTimelineImageByID(id) as Image;
        }
		public static function getFlashMovie(name:String):MovieClip {
			var movie:MovieClip = mFlashMovies[name];
			if (movie == null) {
				throw new Error ("Unknown FlashMovie with name: " + name);
			}
			return movie;
		}
		public static function getTexture(name:String):Texture {
			return mBaseTextures[name];
		}
		public static function getSubTexture(name:String):SubTexture {
			return mSubTextures[mImageNameIDs[name]] as SubTexture;
		}
		
		public static function getStarlingMovie(name:String):TextureAnim {
			//log("GetMovie: " + name);
			var anim:TextureAnim;
			var animUsed:TextureAnim;
			var pool:Vector.<TextureAnim> = mPoolTextureAnims;
			var n:int = pool.length;
			while (n-- > 0) {
				anim = pool[n];
				trace("ANIM? " + anim.id);
				if (anim.id == name) {
					if (anim.parent == null) {
						anim.alpha = 1;
						return anim;
					} else {
						animUsed = anim;
					}
				}
			}
			if (animUsed == null) {
				throw new Error("Unknown movie with name: " + name);
			} else {
				log("CLONING TextureAnim " + name);
				anim = new TextureAnim(name, animUsed.textures, animUsed.fps);
				pool.push(anim);
			}
			return anim;
		}
		
		public static function overrideTimelineObject(name:String, object:DisplayObject):Boolean {
			var id:int = mIDsByNames[name];
			log("OverrideTLO: " + name + " " + id);
			if (!id) return false;
			var pool:Vector.<DisplayObject> = mPoolTimelineObjects[id];
			if (pool == null) {
				mPoolTimelineObjects[id] = pool = new Vector.<DisplayObject>();
			} else {
				//TODO: dispose mPoolTimelineObjects in the pool if there are any!!!
				pool.length = 1;
			}
			pool.push(object);
			return true;
		}
		public static function getTimelineObject(name:String, touchable:Boolean=false):DisplayObject {
			//log("getTimelineObject " + name+" "+mIDsByNames[name]);
			return getTimelineObjectByID(mIDsByNames[name], touchable);
		}
		public static function getTimelineObjectByID(id:uint, touchable:Boolean=false):DisplayObject {
			//log("getTimelineObject: " + id );
			
			var object:DisplayObject;
			var pool:Vector.<DisplayObject> = mPoolTimelineObjects[id];
			if (pool == null) {
				mPoolTimelineObjects[id] = pool = new Vector.<DisplayObject>();
			}
			var found:Boolean;
			var n:int = pool.length;
			while (n-- > 0){
				object = pool[n];
				if (object.parent == null) {
					//log("Reusing TimelineObject " + object.name);
					if (object is TimelineObject) {
						TimelineObject(object).init(); //resets object state
					}
					found = true;
					break;
				}
			}
			if (!found) {
				var name:String = mNamesByIDs[id];
				var spec:TimelineMemoryBlock = spriteDefinitions[id];
				if (spec) {
					var numFrames:uint = li16(spec.head);
					//log("Creating new TimelineObject", id, spec.length, numFrames);
					
					if (numFrames == 1) {
						object = new TimelineSprite(spec) as DisplayObject;
					} else {
						object = new TimelineMovie(spec) as DisplayObject;
					}
					TimelineObject(object).removeTint();
					object.name = name?name:String(id);
				} else {
					//throw new Error("Unknown TimelineObject: " + id);
					object = new Quad(10, 10, 0xff0000);
				}
				pool.push(object);
			}
			object.touchable = touchable;
			return object;
		}
		public static function getTimelineObjectInSprite(name:String, touchable:Boolean = false):Sprite {
			var object:DisplayObject = getTimelineObjectByID(mIDsByNames[name], touchable);
			var spr:Sprite = new Sprite();
			spr.name = object.name;
			spr.addChild(object);
			return spr;
		}
		public static function getTimelineImageByID(id:uint, touchable:Boolean=false):DisplayObject {
			//log("getTimelineImage: " + id);
			
			var image:Image;
			var pool:Vector.<Image> = mPoolImages[id];
			if (pool == null) {
				mPoolImages[id] = pool = new Vector.<Image>();
			}
			var found:Boolean;
			var n:int = pool.length;
			while (n-- > 0){
				image = pool[n];
				if (image.parent == null) {
					//log("Reusing Image " + id);
					found = true;
					break;
				}
			}
			if (!found) {
				//var name:String = mNamesByIDs[id];
				var texture:Texture = mSubTextures[id];
				if (texture) {
					image = new Image(texture);
					image.name = String(id);
					image.touchable = touchable;
				} else {
					//throw new Error("Unknown TimelineImage: " + id);
					image = new Quad(10, 10, 0x00ff00) as Image;
				}
				pool.push(image);
			}
			return image as DisplayObject;
		}
		public static function getSoundByName(name:String):Sound {
			//log("getSound " + name);
			return mSounds[mSoundNameIDs[name]] as Sound;
		}
		public static function getSound(id:int):Sound {
			//log("getSound " + id);
			return mSounds[id] as Sound;
		}
		public static function getTimelineShape(name:String):DisplayObject {
			//log("getTimelineShape " + name);
			return getTimelineShapeByID(mIDsByNames[name]);
		}
		public static function getTimelineShapeByID(id:uint):DisplayObject {
			//log("getTimelineShape: " + id + " "+mNamesByIDs[id]);
			
			var object:DisplayObject;
			var pool:Vector.<DisplayObject> = mPoolTimelineShapes[id];
			
			if (pool == null) {
				mPoolTimelineShapes[id] = pool = new Vector.<DisplayObject>();
			}
			//trace("mPoolTimelineObjects: "+mPoolTimelineObjects.length+" pool " + pool.length);
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
				var spec:TimelineMemoryBlock = shapeDefinitions[id];
				if(spec){
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
		public static function getColorMatrixFilter():ColorMatrixFilter {
			return (mPoolCMFilters.length > 0) ? mPoolCMFilters.pop() : new ColorMatrixFilter();
		}
		public static function addColorMatrixFilter(filter:ColorMatrixFilter):void {
			mPoolCMFilters.push(filter);
		}
		
		public static function addNamedObject(object:TimelineObject, nameID:String):void {
			object.id = nameID;
			namedObjects[nameID] = object;
			Global.instance.currentScene.onAddNamedObject(object);
		}
		public static function removeNamedObject(object:TimelineObject):void {
			namedObjects[object.id] = null;
		}
		
		public static function unloadLevel(levelName:String):void {
			trace("ASSETS = UnloadLevel = " + levelName);
			var key:String;
			var n:int, m:int;
			
			trace("-- Disposing mPoolImages");
			n = mPoolImages.length;
			while (n-- > 100) {
				var poolImages:Vector.<Image> = mPoolImages[n];
				if (poolImages) {
					m = poolImages.length;
					while (m-- > 0) {
						var img:Image = poolImages[m];
						if (img.parent) {
							img.removeFromParent(true);
						} else {
							img.dispose();
						}
					}
					mPoolImages[n].length = 0;
					mPoolImages[n] = null;
				}

			}
			
			trace("-- Disposing mPoolTimelineObjects");
			n = mPoolTimelineObjects.length;
			while (n-- > 100) {
				var objects:Vector.<DisplayObject> = mPoolTimelineObjects[n];
				if (objects) {
					m = objects.length;
					while (m-- > 0) {
						objects[m].dispose();
					}
					mPoolTimelineObjects[n].length = 0;
					mPoolTimelineObjects[n] = null;
				}
			}
			
			trace("\n-- SubTextures");
			n = mSubTextures.length;
			while (n-- > 100) {
				mSubTextures[n] = null;
			}
			
			
			trace("\n-- FlashMovies");
			for (key in mFlashMovies) {
				trace(key + " " + mFlashMovies[key]);
				var movie:MovieClip = MovieClip(mFlashMovies[key]);
				//stopAllInSWF(movie as DisplayObjectContainer);
				if (movie) {
					movie.stop();
					if (movie.parent) movie.parent.removeChild(movie);
				}
				
				mFlashMovies[key] = null;
			}
			mFlashMovies.length = 0;
			namedObjects.length = 0;
			
			trace("\n-- SWFLoader");
			if (mSWFLoaders[levelName]) {
				trace(mSWFLoaders[levelName]);
				Loader(mSWFLoaders[levelName]).unloadAndStop(true);
				mSWFLoaders[levelName] = null;
			}
			
			trace("\n-- DataBlocks");
			n = mDataBlocks.length;
			while(n-- > 0) {
				var block:MemoryBlock = mDataBlocks[n];
				if (block && block.level == levelName) {
					trace("..block: " + block);
					Memory.free(block);
					mDataBlocks[n] = null;
				}
			}
			
			trace("\n-- spriteDefinitions");
			for (key in spriteDefinitions) {
				//trace(key + " " + spriteDefinitions[key]);
				var memoryBlock:TimelineMemoryBlock = spriteDefinitions[key];
				//if(memoryBlock){
					spriteDefinitions[key] = null;
				//}
			}
			//spriteDefinitions.length = 0;
			
			
			trace("\n-- Sounds");
			for (key in mSounds) {
				//if (key.indexOf(levelName) == 0) {
					trace(key + " " + mSounds[key]);
					//Sound(mSounds[key])
					mSounds[key] = null;
				//}
			}
			mSounds.length = 0;
			
			trace("\nTextureAnims");
			for (key in mTextureAnims) {
				if (key.indexOf(levelName) == 0) {
					trace(key + " " + mTextureAnims[key]);
					TextureAnim(mTextureAnims[key]).dispose();
					mTextureAnims[key] = null;
				}
			}
			mTextureAnims.length = 0;
			
			trace("\nAtlasTextures");
			for (key in mBaseTextures) {
				if (key.indexOf(levelName) == 0) {
					trace("Disposing: "+ key + " " + mBaseTextures[key]);
					Texture(mBaseTextures[key]).dispose();
					mBaseTextures[key] = null;
					delete mBaseTextures[key];
				}
			}
			mNamesByIDs.length = 0;
			mIDsByNames.length = 0;
			
			System.pauseForGCIfCollectionImminent(0.25);
		}
		
		public static function info():void {
			var m:int, n:int;
			var key:String;
			var numSubTextures:int, numBaseTextures:int;
			
			for (key in mBaseTextures) {
				numBaseTextures++;
			}
			for (key in numSubTextures) {
				numSubTextures++;
			}
			
			log("BaseTextures: " + numBaseTextures);
			log("SubTextures: " + mSubTextures.length);
			log("TextureAnims: " + mTextureAnims.length);
			log("FlashMovies: " + mFlashMovies.length);
			log("ImageNameIDs: " + mImageNameIDs.length);
			log("SWFLoaders: " + mSWFLoaders.length);
			log("Sounds: " + mSounds.length);
			log("DataBlocks: " + mDataBlocks.length);
			log("NamesByIDs: " + mNamesByIDs.length);
			log("IDsByNames: " + mIDsByNames.length);
			
		}
		
		private static function stopAllInSWF(swf:DisplayObjectContainer):void {
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