// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package display
{
    import flash.errors.IllegalOperationError;
    import flash.media.Sound;
	import starling.display.Image;
    
    import starling.animation.IAnimatable;
    import starling.events.Event;
    import starling.textures.Texture;
	import starling.core.Starling;
    
    /** Dispatched whenever the movie has displayed its last frame. */
    [Event(name="complete", type="starling.events.Event")]
    
    /** A MovieClip is a simple way to display an animation depicted by a list of textures.
     *  
     *  <p>Pass the frames of the movie in a vector of textures to the constructor. The movie clip 
     *  will have the width and height of the first frame. If you group your frames with the help 
     *  of a texture atlas (which is recommended), use the <code>getTextures</code>-method of the 
     *  atlas to receive the textures in the correct (alphabetic) order.</p> 
     *  
     *  <p>You can specify the desired framerate via the constructor. You can, however, manually 
     *  give each frame a custom duration. You can also play a sound whenever a certain frame 
     *  appears.</p>
     *  
     *  <p>The methods <code>play</code> and <code>pause</code> control playback of the movie. You
     *  will receive an event of type <code>Event.MovieCompleted</code> when the movie finished
     *  playback. If the movie is looping, the event is dispatched once per loop.</p>
     *  
     *  <p>As any animated object, a movie clip has to be added to a juggler (or have its 
     *  <code>advanceTime</code> method called regularly) to run. The movie will dispatch 
     *  an event of type "Event.COMPLETE" whenever it has displayed its last frame.</p>
     *  
     *  @see starling.textures.TextureAtlas
     */    
    public class TextureAnim extends Image implements IAnimatable
    {
        private var mTextures:Vector.<Texture>;
        private var mSounds:Vector.<Sound>;
        private var mDurations:Vector.<Number>;
        private var mStartTimes:Vector.<Number>;
        
		private var mFps:uint;
        private var mFrameDuration:Number;
        private var mTotalTime:Number;
        private var mCurrentTime:Number;
        private var mCurrentFrame:int;
		private var mPreviousFrame:int;
        private var mLoop:Boolean;
        private var mPlaying:Boolean;
        
		private var mLabelNames:Array = new Array();
		private var mLabelNumbers:Object = new Object();
		
		public var onFrameLabel:Function;
		public var onFrameLabelLeave:Function;
		
		private var mId:String;
		
        /** Creates a movie clip from the provided textures and with the specified default framerate.
         *  The movie will have the size of the first frame. */  
        public function TextureAnim(id:String, textures:Vector.<Texture>, fps:Number=12)
        {
            if (textures.length > 0)
            {
				mId = id;
                super(textures[0]);
                init(textures, fps);
            }
            else
            {
                throw new ArgumentError("Empty texture array");
            }
        }
        
        private function init(textures:Vector.<Texture>, fps:Number):void
        {
            if (fps <= 0) throw new ArgumentError("Invalid fps: " + fps);
			mFps = fps;
			
            var numFrames:int = textures.length;
            
            mFrameDuration = 1.0 / fps;
            mLoop = true;
            mPlaying = false;
            mCurrentTime = 0.0;
            mCurrentFrame = 0;
            mTotalTime = mFrameDuration * numFrames;
            mTextures = textures.concat();
            //mSounds = new Vector.<Sound>(numFrames);
            /*mDurations = new Vector.<Number>(numFrames);
            mStartTimes = new Vector.<Number>(numFrames);
            
            for (var i:int=0; i<numFrames; ++i)
            {
                mDurations[i] = mFrameDuration;
                mStartTimes[i] = i * mFrameDuration;
            }
			*/
		
        }
        
        // frame manipulation
        
        /** Adds an additional frame, optionally with a sound and a custom duration. If the 
         *  duration is omitted, the default framerate is used (as specified in the constructor). */   
        /*public function addFrame(texture:Texture, sound:Sound=null, duration:Number=-1):void
        {
            addFrameAt(numFrames, texture, sound, duration);
        }
        */
        /** Adds a frame at a certain index, optionally with a sound and a custom duration. */
        /*public function addFrameAt(frameID:int, texture:Texture, sound:Sound=null, 
                                   duration:Number=-1):void
        {
            if (frameID < 0 || frameID > numFrames) throw new ArgumentError("Invalid frame id");
            if (duration < 0) duration = mFrameDuration;
            
            mTextures.splice(frameID, 0, texture);
            mSounds.splice(frameID, 0, sound);
            mDurations.splice(frameID, 0, duration);
            mTotalTime += duration;
            
            if (frameID > 0 && frameID == numFrames) 
                mStartTimes[frameID] = mStartTimes[frameID-1] + mDurations[frameID-1];
            else
                updateStartTimes();
        }
        */
        /** Removes the frame at a certain ID. The successors will move down. */
        /*public function removeFrameAt(frameID:int):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            if (numFrames == 1) throw new IllegalOperationError("Movie clip must not be empty");
            
            mTotalTime -= getFrameDuration(frameID);
            mTextures.splice(frameID, 1);
            mSounds.splice(frameID, 1);
            mDurations.splice(frameID, 1);
            
            //updateStartTimes();
        }
        */
		
		public function addLabel(number:int, name:String):void {
			mLabelNames[number] = name;
			mLabelNumbers[name] = number;
		}
		
		/** Returns all subTextures */	
		public function get textures():Vector.<Texture> {
			return mTextures;
		}
		
		public function get id():String {
			return mId;
		}
		
        /** Returns the texture of a certain frame. */		
        public function getFrameTexture(frameID:int):Texture
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mTextures[frameID];
        }
        
        /** Sets the texture of a certain frame. */
        public function setFrameTexture(frameID:int, texture:Texture):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mTextures[frameID] = texture;
        }
        
        /** Returns the sound of a certain frame. */
        public function getFrameSound(frameID:int):Sound
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mSounds[frameID];
        }
        
        /** Sets the sound of a certain frame. The sound will be played whenever the frame 
         *  is displayed. */
        public function setFrameSound(frameID:int, sound:Sound):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mSounds[frameID] = sound;
        }
        
        /** Returns the duration of a certain frame (in seconds). */
        /*public function getFrameDuration(frameID:int):Number
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mDurations[frameID];
        }
        */
        /** Sets the duration of a certain frame (in seconds). */
        /*public function setFrameDuration(frameID:int, duration:Number):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mTotalTime -= getFrameDuration(frameID);
            mTotalTime += duration;
            mDurations[frameID] = duration;
            updateStartTimes();
        }
        */
		
        // playback methods
        private function getFrameNumber(frame:Object):uint {
			var frameNum:uint;
			switch(typeof(frame)) {
				case "string":
					return uint(mLabelNumbers[frame]);
				case "number":
					return uint(frame);
				default:
					return 0;
			}
		}
        
		public function gotoAndPlay(frame:Object):void
        {
			//log("GOTOANDPLAY " + frame, name);
			var frameNum:uint = getFrameNumber(frame);
			if (frameNum == 0) return;
			if(mCurrentFrame != frameNum){
				mCurrentFrame = frameNum;
				mCurrentTime = mCurrentFrame * mFrameDuration;
				updateFrame();
			}
			if(!mPlaying){
				mPlaying = true;
				Starling.juggler.add(this);
			}
        }
		public function gotoAndStop(frame:uint):void
        {
			var frameNum:uint = getFrameNumber(frame);
			if (frameNum == 0) return;
			mCurrentFrame = frame;
			mCurrentTime = (mCurrentFrame-1) * mFrameDuration;
			updateFrame();
			if(mPlaying){
				mPlaying = false;
				Starling.juggler.remove(this);
			}
        }
        /** Starts playback. Beware that the clip has to be added to a juggler, too! */
        public function play():void
        {
            if(!mPlaying){
				mPlaying = true;
				Starling.juggler.add(this);
			}
        }
        
        /** Pauses playback. */
        public function pause():void
        {
            mPlaying = false;
        }
        
        /** Stops playback, resetting "currentFrame" to zero. */
        public function stop():void
        {
			if(mPlaying){
				mPlaying = false;
				//currentFrame = 0;
				Starling.juggler.remove(this);
			}
        }
        
        // helpers
        
        /*private function updateStartTimes():void
        {
            var numFrames:int = this.numFrames;
            
            mStartTimes.length = 0;
            mStartTimes[0] = 0;
            
            for (var i:int=1; i<numFrames; ++i)
                mStartTimes[i] = mStartTimes[i-1] + mDurations[i-1];
        }*/
        
		public function updateFrame():void {
			if (mCurrentFrame != mPreviousFrame && mPlaying) {
				//trace("upadate "+name+" "+mCurrentFrame)
				mPreviousFrame = mCurrentFrame;
				texture = mTextures[mCurrentFrame-1];
			}
		}
		private function processFrameEvents():Boolean {
			// var sound:Sound = mSounds[mCurrentFrame];
			// if (sound) sound.play();
			if (onFrameLabel != null) {
				var label:String = mLabelNames[mCurrentFrame];
				if (label) {
					//log("LABEL: " + label);
					onFrameLabel(this,label);
					return true;
				}
			}
			return false;
		}
		
	
        // IAnimatable
        
        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            var finalFrame:int = mTextures.length;
			//var mCurrentFrame:int = sourceMovie.currentFrame;
            var previousFrame:int = mCurrentFrame;
            
			
			
			//log(mCurrentFrame, finalFrame,passedTime);
            if (mLoop && mCurrentFrame == finalFrame) {
				mCurrentTime = 0.0;
				mCurrentFrame = 0;
			}
			if (!mPlaying || passedTime == 0.0 || mCurrentFrame > finalFrame) return;
            
            mCurrentTime += passedTime;
			
            while (mCurrentTime >= (mCurrentFrame * mFrameDuration) && mPlaying)
            {
				
                if (mCurrentFrame == finalFrame)
                {
					//log("COMPLETE");
                    if (hasEventListener(Event.COMPLETE))
                    {
                        var restTime:Number = mCurrentTime - mTotalTime;
                        mCurrentTime = mTotalTime;
						//stop();
                        dispatchEventWith(Event.COMPLETE);
                        // user might have changed movie clip settings, so we restart the method
                        //advanceTime(restTime);
                        //return;
                    }
                    
                    if (mLoop)
                    {
                        mCurrentTime -= mTotalTime;
                        mCurrentFrame = 1;
						//sourceMovie.gotoAndStop(1);
                    }
                    else
                    {
                        mCurrentTime = mTotalTime;
						stop();
                        break;
                    }
                }
                else
                {
                    mCurrentFrame++;
					if (processFrameEvents()) {
						advanceTime(mCurrentTime - ((mCurrentFrame-1) * mFrameDuration));
                        return;
					}
                }
            }
            //if(mCurrentFrame != previousFrame) trace("FRAMES: " + (mCurrentFrame - previousFrame));
            updateFrame();
        }
        
        /** Indicates if a (non-looping) movie has come to its end. */
        public function get isComplete():Boolean 
        {
            return !mLoop && mCurrentTime >= mTotalTime;
        }
        
        // properties  
        
        /** The total duration of the clip in seconds. */
        public function get totalTime():Number { return mTotalTime; }
        
        /** The total number of frames. */
        public function get numFrames():int { return mTextures.length; }
        
        /** Indicates if the clip should loop. */
        public function get loop():Boolean { return mLoop; }
        public function set loop(value:Boolean):void { mLoop = value; }
        
        /** The index of the frame that is currently displayed. */
        public function get currentFrame():int { return mCurrentFrame; }
        public function set currentFrame(value:int):void
        {
            mCurrentFrame = value;
            mCurrentTime = value * mFrameDuration;

            updateFrame();
            //if (mSounds[mCurrentFrame]) mSounds[mCurrentFrame].play();
        }
        
        /** The default number of frames per second. Individual frames can have different 
         *  durations. If you change the fps, the durations of all frames will be scaled 
         *  relatively to the previous value. */
        public function get fps():Number { return 1.0 / mFrameDuration; }
        public function set fps(value:Number):void
        {
            if (value <= 0) throw new ArgumentError("Invalid fps: " + value);
   			if(mFps != value) {
				mFps = value;
				mFrameDuration = 1.0 / value;
				mCurrentTime = mCurrentFrame * mFrameDuration;
			}
        }
        
        /** Indicates if the clip is still playing. Returns <code>false</code> when the end 
         *  is reached. */
        public function get isPlaying():Boolean 
        {
            if (mPlaying)
                return mLoop || mCurrentTime < mTotalTime;
            else
                return false;
        }
    }
}