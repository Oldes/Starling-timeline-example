package display
{
    import flash.errors.IllegalOperationError;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;
	import starling.animation.DelayedCall;
	import starling.display.DisplayObject;
	import starling.core.Starling;
	import starling.display.Quad;
    
    import starling.animation.IAnimatable;
    import starling.events.Event;
	
	import apparat.memory.Memory;
	import apparat.memory.MemoryPool;
    
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
		
		public var onFrameLabel:Function;
        
        /** Creates a TimelineMovie object **/  
        public function TimelineMovie(memoryBlock:TimelineMemoryBlock, fps:Number=25)
        {
			mPointerHead = memoryBlock.head;
			mPointerTail = memoryBlock.tail;

			mPointer = mPointerHead;
			mTotalFrames = Memory.readUnsignedShort(mPointer);
			mPointer += 2;
			
            if (fps <= 0) throw new ArgumentError("Invalid fps: " + fps);
			mFPS = fps;
			init();
        }
        
		override public function init():void {
			removeChildren();
			mPointer = mPointerHead + 2;
			mCurrentTime = 0.0;
			mCurrentFrame = 1;
			mFrameDuration = 1.0 / fps;
			play();
			updateFrame();
		}
		
		override public function dispose():void {
			log("Dispose TimelineMovie " + this, this.name);
			release();
		}
		
        // playback methods

		
		public function gotoAndPlay(frame:Object):void
        {
			var frameNum:uint = uint(frame) //getFrameNumber(frame);
			if (frameNum == 0) return;
			mCurrentFrame = frameNum;
			mCurrentTime = mCurrentFrame * mFrameDuration;
			mPointer = mPointerHead + 2;
			updateFrame();
			if(!mPlaying){
				mPlaying = true;
				Starling.juggler.add(this);
			}
        }
		public function gotoAndStop(frame:uint):void
        {
			var frameNum:uint = uint(frame) //getFrameNumber(frame);
			if (frameNum == 0) return;
			mCurrentFrame = frame;
			mCurrentTime = (mCurrentFrame-1) * mFrameDuration;
			mPointer = mPointerHead + 2;
			updateFrame();
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
				onFrameLabel(this, mCurrentLabel);
			}
			mCurrentLabel = null;
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
			var a:Number, b:Number, c:Number, d:Number, tx:Number, ty:Number;
			var multR:Number, multG:Number, multB:Number;
			//trace("updateFrame "+name)
			
			var p:int = mPointer; //actuall memory pointer position

			do {
				opcode = Memory.readUnsignedByte(p);
				p++;
				
				switch(opcode) {
					case cmdMoveDepth:
						depth = Memory.readUnsignedShort(p);
						flags = Memory.readUnsignedByte(p + 2);
						p += 3;

						obj = getChildAt(depth);
						if (obj) {
							tmpMatrix.tx = Memory.readFloat(p);
							tmpMatrix.ty = Memory.readFloat(p + 4);
							p += 8;
							if(8 == (flags & 8)){//scale
								tmpMatrix.a = Memory.readFloat(p);
								tmpMatrix.d = Memory.readFloat(p + 4);
								p += 8;
							} else {
								tmpMatrix.a = 
								tmpMatrix.d = 1;
							}
							if(16 == (flags & 16)){//skew
								tmpMatrix.b = Memory.readFloat(p);
								tmpMatrix.c = Memory.readFloat(p + 4);
								p += 8;
							} else {
								tmpMatrix.c = 
								tmpMatrix.b = 0;
							}
							if (32 == (flags & 32)) {//alpha
								obj.alpha = Memory.readUnsignedByte(p) / 255;
								p++;
							}
							if (64 == (flags & 64)) {//color multiply
								multR = Memory.readUnsignedByte(p)   / 255;
								multG = Memory.readUnsignedByte(p + 1) / 255;
								multB = Memory.readUnsignedByte(p + 2) / 255;
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
							obj.transformationMatrix = tmpMatrix;
						}
						break;
						
					case cmdShowFrame:
						//trace("showFrame " + mCurrentFrame);
						mCurrentFrame++;
						notBreak = false;
						break;
						
					case cmdPlaceObject:
					case cmdReplaceObject:
						id    = Memory.readUnsignedShort(p);
						depth = Memory.readUnsignedShort(p+2);
						flags = Memory.readUnsignedByte(p + 4);
						p += 5;
						switch(flags & 7) { //first 3 bits
							case 0: //placing image
								obj = Assets.getTimelineObjectByID(id);
								break;
							case 1: //placing object
								obj = Assets.getTimelineObjectByID(id);
								break;
							case 2: //placing shape
								obj = Assets.getTimelineShapeByID(id);
								break;
						}
						if (obj) {
							tmpMatrix.tx = Memory.readFloat(p);
							tmpMatrix.ty = Memory.readFloat(p + 4);
							p += 8;
							if(8 == (flags & 8)){//scale
								tmpMatrix.a = Memory.readFloat(p);
								tmpMatrix.d = Memory.readFloat(p + 4);
								p += 8;
							} else {
								tmpMatrix.a = 
								tmpMatrix.d = 1;
							}
							if(16 == (flags & 16)){//skew
								tmpMatrix.b = Memory.readFloat(p);
								tmpMatrix.c = Memory.readFloat(p + 4);
								p += 8;
							} else {
								tmpMatrix.c = 
								tmpMatrix.b = 0;
							}
							if (32 == (flags & 32)) {//alpha
								obj.alpha = Memory.readUnsignedByte(p) / 255;
								p++;
							} else {
								obj.alpha = 1;
							}
							if (64 == (flags & 64)) {//color multiply
								multR = Memory.readUnsignedByte(p)     / 255;
								multG = Memory.readUnsignedByte(p + 1) / 255;
								multB = Memory.readUnsignedByte(p + 2) / 255;
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
							obj.transformationMatrix = tmpMatrix;
							if (opcode == cmdPlaceObject) {
								addChildAt(obj, depth);
							} else {
								removeChildAt(depth);
								addChildAt(obj, depth);
								//replaceChildAt(obj, depth); //<-this is not in official Starling framework
							}
						}
						break;
						
					case cmdRemoveDepth:
						depth = Memory.readUnsignedShort(p);
						p += 2;
						removeChildAt(depth);
						break;
					case cmdLabel:
						MemoryPool.buffer.position = p;
						mCurrentLabel = MemoryPool.buffer.readUTF();
						p = MemoryPool.buffer.position;
						//log("LABEL: " + mCurrentLabel);
						
						break;
					case cmdStartSound:
						id = Memory.readUnsignedShort(p);
						p += 2;
						//log("SOUND: " + id);
						break;
					case cmdEnd: //end
						//log("MovieEnd "+name);
						var wasTime:Number = mCurrentTime; //To test if the timeline was changed by the complete event call
						if (hasEventListener(Event.COMPLETE))
						{
							dispatchEventWith(Event.COMPLETE);
							
						}
						if(mLoop && (wasTime == mCurrentTime)){
							removeChildren();
							mPointer = p = mPointerHead + 2; //first 2 bytes are used for frame count
							//mCurrentFrame = 0;
						} else {
							stop();
							notBreak = false;
						}
						break;
						
					default:
						log("UNKNOWN opcode: " + opcode);
				}
			} while (notBreak);
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
			mCurrentTime = (mCurrentFrame-1) * mFrameDuration;
			mFrameDuration = 1.0 / value;
        }
        
        /** The default number of frames per second. Individual frames can have different 
         *  durations. If you change the fps, the durations of all frames will be scaled 
         *  relatively to the previous value. */
        /*public function get fps():Number { return 1.0 / mDefaultFrameDuration; }
        public function set fps(value:Number):void
        {
            if (value <= 0) throw new ArgumentError("Invalid fps: " + value);
            
            var newFrameDuration:Number = 1.0 / value;
            var acceleration:Number = newFrameDuration / mDefaultFrameDuration;
            mCurrentTime *= acceleration;
            mDefaultFrameDuration = newFrameDuration;
            
            for (var i:int=0; i<numFrames; ++i)
                setFrameDuration(i, getFrameDuration(i) * acceleration);
        }
        */
        /** Indicates if the clip is still playing. Returns <code>false</code> when the end 
         *  is reached. */
        /*public function get isPlaying():Boolean 
        {
            if (mPlaying)
                return mLoop || mCurrentTime < mTotalTime;
            else
                return false;
        }
		*/
    }
}