package display
{
	import core.Assets;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import memory.Memory;
	import starling.display.DisplayObjectContainer;
	import flash.errors.IllegalOperationError;
	import flash.geom.Matrix;
	import starling.animation.DelayedCall;
	import starling.display.DisplayObject;
	import starling.core.Starling;
	import starling.filters.ColorMatrixFilter;

	import starling.animation.IAnimatable;
	import starling.events.Event;
	
	import avm2.intrinsics.memory.*;
	import flash.utils.getTimer;
	
//	import apparat.memory.Memory;
//	import apparat.memory.MemoryPool;
    
    /** Dispatched whenever the movie has displayed its last frame. */
    [Event(name="complete", type="starling.events.Event")]
    
    public class TimelineMovie extends TimelineObject implements IAnimatable
    {
		private var mPlaying:Boolean;
		private var mLoop:Boolean=true;
		private var mCurrentFrame:int;
		private var mCurrentLabel:String;
		private var mCurrentTime:Number;
		private var mTotalTime:Number;
		private var mTotalFrames:Number;
		private var mFrameDuration:Number;
		private var mFPS:Number;
		
		private var dcResume:DelayedCall;
		
		private var tmpMatrix:Matrix = new Matrix();
		
		private var mControlTags:TimelineMemoryBlock;
		private var mPointerHead:int;
		private var mPointerTail:int;
		private var mPointer:int;
		
		private var mReuseChildren:Boolean;
		
		public var onFrameLabel:Function;
        
        /** Creates a TimelineMovie object **/  
        public function TimelineMovie(memoryBlock:TimelineMemoryBlock, fps:Number=25)
        {
			mPointerHead = memoryBlock.head;
			mPointerTail = memoryBlock.tail;

			mPointer = mPointerHead;
			mTotalFrames = li16(mPointer);
			mPointer += 2;
			
            if (fps <= 0) throw new ArgumentError("Invalid fps: " + fps);
			mFPS = fps;
			init();
        }
        
		override public function init():void {
			//log("INIT TimelineMovie " + this, this.name, mTotalFrames, mPlaying);
			removeChildren();
			mPointer = mPointerHead + 2;
			mCurrentTime = 0.0;
			mCurrentFrame = 1;
			mFrameDuration = 1.0 / fps;
			mTotalTime = mTotalFrames * mFrameDuration;
			mReuseChildren = false;
			play();
			updateFrame();
		}
		
		public function unload():void {
			stop();
			super.dispose();
		}
		override public function dispose():void {
			//log("Dispose TimelineMovie " + this, this.name);
			release();
			//stop();
			//super.dispose();
		}
		
		
		override public function release():void {
			if (dcResume) {
				Starling.juggler.remove(dcResume);
				dcResume = null;
			}
			stop();
			super.release();
		}

        // playback methods

		
		public function gotoAndPlay(frame:Object):void
        {
			seekToFrame(frame);
			
			if(!mPlaying){
				mPlaying = true;
				Starling.juggler.add(this);
			}
        }
		public function gotoAndStop(frame:uint):void
        {
			var frameNum:uint = uint(frame) //getFrameNumber(frame);
			if (frameNum == 0) return;
			
			seekToFrame(frameNum);
			
			if(mPlaying){
				mPlaying = false;
				Starling.juggler.remove(this);
			}
        }
		
		public function forwardToLabel(label:String):void {
			do {
				updateFrame()
			} while (label != mCurrentLabel);
			mCurrentTime = (mCurrentFrame-1) * mFrameDuration;
		}
		
        /** Starts playback. Beware that the clip has to be added to a juggler, too! */
        public function play():void
        {
            if (!mPlaying) {
				mPlaying = true;
				mCurrentTime = (mCurrentFrame-1) * mFrameDuration;
				Starling.juggler.add(this);
			}
        }
        public function playAll():void
        {
            mPlaying = true;
			Starling.juggler.add(this);
			var n:int = numChildren;
			var child:DisplayObject;
			while (n > 0) {
				n--;
				child = getChildAt(n);
				if (child is TimelineMovie) {
					TimelineMovie(child).playAll();
				}
			}
        }
        /** Pauses playback. */
        public function pause(delay:Number=0):void
        {
            mPlaying = false;
			Starling.juggler.remove(this);
			if (delay > 0) {
				if (dcResume) {
					Starling.juggler.remove(dcResume);
					dcResume.reset(play, delay);
					Starling.juggler.add(dcResume);
				} else {
					dcResume = Starling.juggler.delayCall(play, delay);
				}
			}
        }
        
        /** Stops playback, resetting "currentFrame" to zero. */
        public function stop():void
        {
            mPlaying = false;
			Starling.juggler.remove(this);
        }
		public function stopAll():void
        {
			//log("stopAll "+this.name);
            mPlaying = false;
			Starling.juggler.remove(this);
			var n:int = numChildren;
			var child:DisplayObject;
			while (n > 0) {
				n--;
				child = getChildAt(n);
				if (child is TimelineMovie) {
					//log("stoping.. " + child, child.name);
					TimelineMovie(child).stopAll();
				}
			}
			
			//log("stop finished");
        }
		
		private function onExitFrame():void {
			if (mCurrentLabel && onFrameLabel != null ) {
				//null current label before actual event call as it may be changed there
				var tmp:String = mCurrentLabel;
				mCurrentLabel = null;
				onFrameLabel(this, tmp);
			}
		}
		/* seekToFrame is made by brute force, so it should be used carefully! */
		private function seekToFrame(frame:Object):void {
			removeChildren();
			mPointer = mPointerHead + 2;
			mCurrentTime = 0.0;
			mCurrentFrame = 0;
			
			var opcode:uint;
			var notBreak:Boolean = true;
			var id:uint;
			var depth:uint, flags:uint;
			var obj:DisplayObject;

			var multR:Number, multG:Number, multB:Number;
			var matrix:Matrix
			var clrFilter:ColorMatrixFilter
			//trace("updateFrame "+name)
			
			var p:int = mPointer; //actuall memory pointer position

			do {
				opcode = li8(p);
				//trace("MovOp[" + p + "]: " + opcode);
				p++;
				switch(opcode) {
					case cmdMoveDepth:
						depth = li16(p);
						flags = li8(p + 2);
						p += 3;

						obj = getChildAt(depth);

						if (obj) {
							matrix = obj.transformationMatrix;
							if (8 == (flags & 8)) {//xy
								matrix.tx = lf32(p);
								matrix.ty = lf32(p + 4);
								p += 8;
							}
							if(16 == (flags & 16)){//scale
								matrix.a = lf32(p);
								matrix.d = lf32(p + 4);
								p += 8;
							} else {
								matrix.a = matrix.d = 1;
							}
							if(32 == (flags & 32)){//skew
								matrix.b = lf32(p);
								matrix.c = lf32(p + 4);
								p += 8;
							} else {
								matrix.b = matrix.c = 0;
							}
							if (64 == (flags & 64)) {//colorMatrix
								clrFilter = obj.filter as ColorMatrixFilter;
								if (clrFilter == null) {
									clrFilter = Assets.getColorMatrixFilter();
									obj.filter = clrFilter;
								}
								clrFilter.setShaderColorMatrix(
									lf32(p),
									lf32(p+4),
									lf32(p+8),
									lf32(p+12),
									lf32(p+16),
									lf32(p+20),
									lf32(p+24),
									lf32(p+28)
								);
								p += 32;
								
							} else if (128 == (flags & 128)) {
								obj.alpha = li8(p) / 255;
								p++;
							}
						}
						break;
						
					case cmdShowFrame:
						mCurrentFrame++;
						notBreak = !(mCurrentFrame == frame || mCurrentLabel == frame);
						//trace("showFrame " + mCurrentFrame, mCurrentLabel, frame, notBreak);
						break;
					
					case cmdPlaceNamed:
						var nameID:String = Memory.readUTF(p);
						p = Memory.buffer.position;
					case cmdPlaceObject:
					case cmdReplaceObject:
						id    = li16(p);
						depth = li16(p+2);
						flags = li8(p + 4);
						p += 5;
						switch(flags & 7) { //first 3 bits
							case 0: //placing image
								obj = Assets.getTimelineImageByID(id, touchable);
								break;
							case 1: //placing object
								obj = Assets.getTimelineObjectByID(id, touchable);
								break;
							case 2: //placing shape
								obj = Assets.getTimelineShapeByID(id);
								break;
						}
						
						if (obj) {
							obj.numId = id;
							if (8 == (flags & 8)) {//xy
								tmpMatrix.tx = lf32(p);
								tmpMatrix.ty = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.tx = 0;
								tmpMatrix.ty = 0;
							}
							if(16 == (flags & 16)){//scale
								tmpMatrix.a = lf32(p);
								tmpMatrix.d = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.a = 
								tmpMatrix.d = 1;
							}
							if(32 == (flags & 32)){//skew
								tmpMatrix.b = lf32(p);
								tmpMatrix.c = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.c = 
								tmpMatrix.b = 0;
							}
							obj.transformationMatrix = tmpMatrix;

							if (64 == (flags & 64)) {//colorMatrix
								clrFilter = Assets.getColorMatrixFilter();
								clrFilter.setShaderColorMatrix(
									lf32(p),
									lf32(p+4),
									lf32(p+8),
									lf32(p+12),
									lf32(p+16),
									lf32(p+20),
									lf32(p+24),
									lf32(p+28)
								);
								obj.filter = clrFilter;
								p += 32;
								
							} else if (128 == (flags & 128)) {
								obj.alpha = li8(p) / 255;
								p++;
							} else {
								obj.alpha = 1;
							}
							switch (opcode) {
								case cmdPlaceObject:
									addChildAt(obj, depth);
									break;
								case cmdPlaceNamed:
									Assets.addNamedObject(obj as TimelineObject, nameID);
									addChildAt(obj, depth);
									break;
								default:
									//TODO: form-timeline script is not producing replace command at this moment!
									//removeChildAt(depth);
									//addChildAt(obj, depth);
									replaceChildAt(obj, depth); //<-this is not in official Starling framework
							}
							if (dispatching && obj is DisplayObjectContainer) {
								DisplayObjectContainer(obj).setDispatching(true);
							}
						} else {
							throw new Error("UNKNOWN OBJ");
						}
						break;
					case cmdRemoveDepth:
						depth = li16(p);
						p += 2;
						removeChildAt(depth);
						break;
					case cmdLabel:
						mCurrentLabel = Memory.readUTF(p);
						p = Memory.buffer.position;
						//log("LABEL: " + mCurrentLabel);
						break;
					case cmdStartSound:
						//if (mCurrentFrame == frameNum - 1) { //the mCurrentFrame value is updated by showFrame command, which comes later
							id = li16(p);
							var loops:int = li16(p + 2);
							var snd:Sound = Assets.getSound(id);
							var sndTrans:SoundTransform = new SoundTransform();
							sndTrans.leftToLeft   = li16(p + 4) / 32768;
							sndTrans.rightToRight = li16(p + 6) / 32768;
							snd.play(0, loops, sndTrans);
						//}
						p += 8;
						break;
					case cmdEnd: //end
						//log("MovieEnd "+name);
						stop();
						notBreak = false;
						break;
						
					default:
						log("[movie] UNKNOWN opcode: " + opcode);
				}
			} while (notBreak);
			mPointer = p;
			mCurrentTime = (mCurrentFrame-1) * mFrameDuration;
		}
		
		private function updateFrame():void {
			onExitFrame(); //call events when exiting previous frame
			//above may stop this movie
			if (!mPlaying) return; 
			
			var opcode:uint;
			var notBreak:Boolean = true;
			var id:uint;
			var depth:uint, flags:uint;
			var obj:DisplayObject;

			var multR:Number, multG:Number, multB:Number;
			var matrix:Matrix
			var clrFilter:ColorMatrixFilter
			//trace("updateFrame "+name)
			
			var p:int = mPointer; //actuall memory pointer position

			do {
				opcode = li8(p);
				//trace("MovOp[" + p + "]: " + opcode);
				p++;
				switch(opcode) {
					case cmdMoveDepth:
						depth = li16(p);
						flags = li8(p + 2);
						p += 3;

						obj = getChildAt(depth);

						if (obj) {
							matrix = obj.transformationMatrix;
							if (8 == (flags & 8)) {//xy
								matrix.tx = lf32(p);
								matrix.ty = lf32(p + 4);
								p += 8;
							}
							if(16 == (flags & 16)){//scale
								matrix.a = lf32(p);
								matrix.d = lf32(p + 4);
								p += 8;
							} else {
								matrix.a = matrix.d = 1;
							}
							if(32 == (flags & 32)){//skew
								matrix.b = lf32(p);
								matrix.c = lf32(p + 4);
								p += 8;
							} else {
								matrix.b = matrix.c = 0;
							}
							/*
							if (64 == (flags & 64)) {//alpha
								obj.alpha = li8(p) / 255;
								p++;
							}
							if (128 == (flags & 128)) {//color multiply
								multR = li8(p)   / 255;
								multG = li8(p + 1) / 255;
								multB = li8(p + 2) / 255;
								p += 3;
								//log("Tint (Movie): ", multR, multG, multB);
								if (obj is TimelineObject) {
									TimelineObject(obj).setColorTransform(multR, multG, multB);
								} else if (obj is Quad) {
									Quad(obj).color = (
										int((255 * tintRealR * multR)) << 16)
										+ (int(255 * tintRealG * multG) << 8)
										+ (int(255 * tintRealB * multB));
								}
							}
							*/
							if (64 == (flags & 64)) {//colorMatrix
								clrFilter = obj.filter as ColorMatrixFilter;
								if (clrFilter == null) {
									clrFilter = Assets.getColorMatrixFilter();
									obj.filter = clrFilter;
								}
								clrFilter.setShaderColorMatrix(
									lf32(p),
									lf32(p+4),
									lf32(p+8),
									lf32(p+12),
									lf32(p+16),
									lf32(p+20),
									lf32(p+24),
									lf32(p+28)
								);
								p += 32;
								
							} else if (128 == (flags & 128)) {
								obj.alpha = li8(p) / 255;
								p++;
							}
						}
						break;
						
					case cmdShowFrame:
						//trace("showFrame " + name+" "+mCurrentFrame);
						mReuseChildren = false;
						mCurrentFrame++;
						mPointer = p;
						return;
						//notBreak = false;
						//break;
					
					case cmdPlaceNamed:
						var nameID:String = Memory.readUTF(p);
						p = Memory.buffer.position;
						log("%%%%%%% " + nameID);
					case cmdPlaceObject:
					case cmdReplaceObject:
						id    = li16(p);
						depth = li16(p+2);
						flags = li8(p + 4);
						p += 5;
						var newObj:Boolean = false;
						if (mReuseChildren) {
							//log("LOOP> " + depth, numChildren, name);
							if (depth >= numChildren) {
								//log("!!!!!!!!!!!!! " + depth, numChildren);
								mReuseChildren = false;
								obj = null;
							} else {
								obj = getChildAt(depth);
							}
							//
							if (obj && id != obj.numId) {
								obj.removeFromParent();
								obj = null;
								if(depth == numChildren) mReuseChildren = false;
							}
							if (obj == null) {
								newObj = true;
								switch(flags & 7) { //first 3 bits
									case 0: //placing image
										obj = Assets.getTimelineImageByID(id, touchable);
										break;
									case 1: //placing object
										obj = Assets.getTimelineObjectByID(id, touchable);
										break;
									case 2: //placing shape
										obj = Assets.getTimelineShapeByID(id);
										break;
								}
							}
							
							
						} else {
							newObj = true;
							switch(flags & 7) { //first 3 bits
								case 0: //placing image
									obj = Assets.getTimelineImageByID(id, touchable);
									break;
								case 1: //placing object
									obj = Assets.getTimelineObjectByID(id, touchable);
									break;
								case 2: //placing shape
									obj = Assets.getTimelineShapeByID(id);
									break;
							}
						}
						if (obj) {
							obj.numId = id;
							if (8 == (flags & 8)) {//xy
								tmpMatrix.tx = lf32(p);
								tmpMatrix.ty = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.tx = 0;
								tmpMatrix.ty = 0;
							}
							if(16 == (flags & 16)){//scale
								tmpMatrix.a = lf32(p);
								tmpMatrix.d = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.a = 
								tmpMatrix.d = 1;
							}
							if(32 == (flags & 32)){//skew
								tmpMatrix.b = lf32(p);
								tmpMatrix.c = lf32(p + 4);
								p += 8;
							} else {
								tmpMatrix.c = 
								tmpMatrix.b = 0;
							}
							obj.transformationMatrix = tmpMatrix;

							if (64 == (flags & 64)) {//colorMatrix
								clrFilter = Assets.getColorMatrixFilter();
								clrFilter.setShaderColorMatrix(
									lf32(p),
									lf32(p+4),
									lf32(p+8),
									lf32(p+12),
									lf32(p+16),
									lf32(p+20),
									lf32(p+24),
									lf32(p+28)
								);
								obj.filter = clrFilter;
								p += 32;
								
							} else if (128 == (flags & 128)) {
								obj.alpha = li8(p) / 255;
								p++;
							} else {
								obj.alpha = 1;
							}
							/*if (128 == (flags & 128)) {//color multiply
								multR = li8(p)     / 255;
								multG = li8(p + 1) / 255;
								multB = li8(p + 2) / 255;
								p += 3;
								//log("Tint (Movie): ", multR, multG, multB);
								if (obj is TimelineObject) {
									TimelineObject(obj).setColorTransform(multR, multG, multB);
								} else if (obj is Quad) {
									Quad(obj).color = (
										int((255 * tintRealR * multR)) << 16)
										+ (int(255 * tintRealG * multG) << 8)
										+ (int(255 * tintRealB * multB));
								}
							}*/
							if(newObj){
								switch (opcode) {
									case cmdPlaceObject:
										addChildAt(obj, depth);
										break;
									case cmdPlaceNamed:
										Assets.addNamedObject(obj as TimelineObject, nameID);
										addChildAt(obj, depth);
										break;
									default:
										//TODO: form-timeline script is not producing replace command at this moment!
										//removeChildAt(depth);
										//addChildAt(obj, depth);
										replaceChildAt(obj, depth); //<-this is not in official Starling framework
								}
							}
							if (dispatching && obj is DisplayObjectContainer) {
								DisplayObjectContainer(obj).setDispatching(true);
							}
						} else {
							throw new Error("UNKNOWN OBJ");
						}
						break;
					case cmdRemoveDepth:
						depth = li16(p);
						p += 2;
						removeChildAt(depth);
						break;
					case cmdLabel:
						mCurrentLabel = Memory.readUTF(p);
						p = Memory.buffer.position;
						//log("LABEL: " + mCurrentLabel);
						
						break;
					case cmdStartSound:
						id = li16(p);
						var snd:Sound = Assets.getSound(id);
						var sndTrans:SoundTransform = new SoundTransform();
						var loops:int = li16(p + 2);
						sndTrans.leftToLeft   = li16(p + 4) / 32768;
						sndTrans.rightToRight = li16(p + 6) / 32768;
						p += 8;

						snd.play(0, loops, sndTrans);
						//log("SOUND: " + id +" "+snd.length);
						break;
					case cmdEnd: //end
						//log("MovieEnd "+name);
						var wasTime:Number = mCurrentTime; //To test if the timeline was changed by the complete event call
						if (hasEventListener(Event.COMPLETE))
						{
							dispatchEventWith(Event.COMPLETE);
							
						}
						if(mLoop && (wasTime == mCurrentTime)){
							//removeChildren();
							mReuseChildren = true;
							mPointer = p = mPointerHead + 2; //first 2 bytes are used for frame count
							mCurrentFrame = 0;
							mCurrentTime -= mTotalTime;
						} else {
							stop();
							notBreak = false;
						}
						break;
						
					default:
						log("[movie] UNKNOWN opcode: " + opcode);
				}
			} while (notBreak);
			trace(mCurrentFrame);
			mPointer = p;
		}
        
        // IAnimatable
        
        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            var previousFrame:int = mCurrentFrame;
            
            //if (mLoop && mCurrentTime == mTotalTime) { mCurrentTime = 0.0; mCurrentFrame = 0; }
            if (!mPlaying || passedTime == 0.0) return;
            
            mCurrentTime += passedTime;
			while (mPlaying && mCurrentTime > (mCurrentFrame * mFrameDuration)) {
				//trace("========= "+mCurrentFrame+" "+mCurrentTime+ " "+(mCurrentFrame * mFrameDuration))
				updateFrame();
			}
			
        }
        
        // properties  
       
        /** The total duration of the clip in seconds. */
        //public function get totalTime():Number { return mTotalTime; }
        
        /** The total number of frames. */
        //public function get numFrames():int { return mTextures.length; }
        
        /** Indicates if the clip should loop. */
        public function get loop():Boolean { return mLoop; }
        public function set loop(value:Boolean):void { mLoop = value; }
        
        /** The index of the frame that is currently displayed. */
        public function get currentFrame():int { return mCurrentFrame; }
        public function set currentFrame(value:int):void {
            /*mCurrentFrame = value;
            mCurrentTime = 0.0;
            
            for (var i:int=0; i<value; ++i)
                mCurrentTime += getFrameDuration(i);
            
            mImage.texture = mTextures[mCurrentFrame];
            if (mSounds[mCurrentFrame]) mSounds[mCurrentFrame].play();
			*/
        }
		
		/** The animation speed in frames per second */
        public function get fps():int { return mFPS; }
        public function set fps(value:int):void {
			mFPS = value;
			mFrameDuration = 1.0 / value;
			mCurrentTime = (mCurrentFrame-1) * mFrameDuration;
        }
    }
}