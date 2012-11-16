REBOL [
    Title: "Pack-assets" 
    Date: 16-Nov-2012/19:00:37+1:00 
    Name: none 
    Version: 0.1.0 
    File: none 
    Home: none 
    Author: "Oldes" 
    Owner: none 
    Rights: none 
    Needs: none 
    Tabs: none 
    Usage: none 
    Purpose: none 
    Comment: none 
    History: none 
    Language: none 
    Type: none 
    Content: none 
    Email: oldes.huhuman@gmail.com 
    require: none
] 
comment {
#### RS include: %stream-io.r
#### Title:   "stream-io"
#### Author:  "Oldes"
----} 
stream-io: context [
    inBuffer: none 
    availableBits: 0 
    bitBuffer: none 
    setStreamBuffer: func [buff] [
        inBuffer: either port? buff [copy buff] [buff] 
        availableBits: 0 
        bitBuffer: none
    ] 
    initBitBuffer: does [
        bitBuffer: first inBuffer 
        availableBits: 8 
        inBuffer: next inBuffer
    ] 
    clearBuffers: does [
        if series? inBuffer [clear head inBuffer] 
        if series? outBuffer [clear head outBuffer] 
        availableBits: 0 
        bitBuffer: none 
        outBitMask: 0 
        outBitBuffer: none
    ] 
    readSB: func [nbits [integer!] /local result] [
        if nbits = 0 [return 0] 
        result: copy "" 
        loop nbits [append result readBit] 
        insert/dup result result/1 (32 - nbits) 
        to integer! debase/base result 2
    ] 
    byteAlign: does [
        if availableBits > 0 [
            availableBits: 0 
            bitBuffer: none
        ] 
        inBuffer
    ] 
    readBit: has [bit] [
        unless bitBuffer [
            bitBuffer: first inBuffer 
            availableBits: 8 
            inBuffer: next inBuffer
        ] 
        if 0 < bit: 128 and bitBuffer [bit: 1] 
        either 0 = availableBits: availableBits - 1 [
            bitBuffer: none
        ] [
            bitBuffer: bitBuffer * 2
        ] 
        bit
    ] 
    readBitLogic: has [bit] [
        unless bitBuffer [
            bitBuffer: first inBuffer 
            availableBits: 8 
            inBuffer: next inBuffer
        ] 
        bit: (128 and bitBuffer) > 0 
        either 0 = availableBits: availableBits - 1 [
            bitBuffer: none
        ] [
            bitBuffer: bitBuffer * 2
        ] 
        bit
    ] 
    readUB: func [nbits [integer!] /local result nb x] [
        if nbits = 0 [return 0] 
        result: 0 nb: nbits 
        while [nbits > 0] [
            unless bitBuffer [
                bitBuffer: first inBuffer 
                inBuffer: next inBuffer 
                availableBits: 8
            ] 
            either availableBits > nbits [
                availableBits: availableBits - nbits 
                result: (256 - to integer! x: (2 ** (8 - nbits))) and bitBuffer / x + result 
                bitBuffer: either availableBits = 0 [none] [to integer! (bitBuffer * (2 ** nbits))] 
                return to integer! result 
                break
            ] [
                result: ((255 and bitBuffer) / (2 ** (8 - availableBits))) * (2 ** (nb - availableBits)) + result 
                nbits: nbits - availableBits 
                bitBuffer: none 
                availableBits: 0
            ]
        ] 
        to integer! result
    ] 
    readByte: func [/local byte] [
        byte: copy/part inBuffer 1 
        inBuffer: next inBuffer 
        byte
    ] 
    readBytes: func [nbytes /local bytes] [
        bytes: copy/part inBuffer 
        inBuffer: skip inBuffer nbytes 
        bytes
    ] 
    readPair: has [nbits] [
        nbits: readUB 5 
        reduce [readFB nbits readFB nbits]
    ] 
    readSBPair: has [nbits] [
        nbits: readUB 5 
        reduce [readSB nbits readSB nbits]
    ] 
    readFB: func [nbits /local] [
        (readSB nBits) / 65536.0
    ] 
    readRect: has [nbits result] [
        byteAlign 
        nbits: readUB 5 
        result: reduce [
            readSB nbits 
            readSB nbits 
            readSB nbits 
            readSB nbits
        ] 
        byteAlign 
        result
    ] 
    readBytesRev: func [nbytes] [
        reverse 
        copy/part inBuffer 
        inBuffer: skip inBuffer nbytes
    ] 
    readBytesArray: func [
        {Slices the binary data to parts which length is specified in the bytes block} 
        bytes [block!] 
        /local result b
    ] [
        result: copy [] 
        while [not tail? bytes] [
            insert tail result readBytes bytes/1 
            bytes: next bytes
        ] 
        result
    ] 
    readUI8: has [i] [i: first inBuffer inBuffer: next inBuffer i] 
    readUI16: func [] [to integer! readBytesRev 2] 
    readUI32: func [] [to integer! readBytesRev 4] 
    readSI8: has [i] [
        i: first inBuffer inBuffer: next inBuffer 
        if i > 127 [
            i: (i and 127) - 128
        ] 
        i
    ] 
    readSI16: has [i] [
        i: to integer! readBytesRev 2 
        if i > 32767 [
            i: (i and 32767) - 32768
        ] 
        i
    ] 
    readS24: has [i] [
        i: to integer! readBytesRev 3 
        if i > 8388607 [
            i: (i and 8388607) - 8388608
        ] 
        i
    ] 
    readUI16le: :readUI16 
    readUI32le: :readUI32 
    readSI8le: :readSI8 
    readSI16le: :readSI16 
    readUI16be: func [] [to integer! readBytes 2] 
    readUI32be: func [] [to integer! readBytes 4] 
    readSI8be: has [i] [
        i: first inBuffer inBuffer: next inBuffer 
        if i > 127 [
            i: (i and 127) - 128
        ] 
        i
    ] 
    readSI16be: has [i] [
        i: to integer! readBytes 2 
        if i > 32767 [
            i: (i and 32767) - 32768
        ] 
        i
    ] 
    readSI32: :readUI32 
    readRest: has [bytes] [
        bytes: copy inBuffer 
        inBuffer: tail inBuffer 
        bytes
    ] 
    readFloat: does [
        change third float-struct readBytes 4 
        float-struct/value
    ] 
    readUI30: has [r b s] [
        b: first inBuffer inBuffer: next inBuffer 
        if b < 128 [return to integer! b] 
        r: b and 127 
        s: 128 
        while [b: first inBuffer inBuffer: next inBuffer] [
            r: r + (b * s) 
            if 128 > b [return r] 
            s: s + 128
        ]
    ] 
    readU32: has [r b s] [
        r: b: first inBuffer inBuffer: next inBuffer 
        if r < 128 [return r] 
        ask "x" 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 127) or (shift/left b 7) 
        if r < 16384 [probe r ask "2" return r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 16383) or (shift/left b 14) 
        if r < 2097152 [return r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 2097151) or (shift/left b 21) 
        if r < 268435456 [return r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 268435455) or (shift/left b 28) 
        r
    ] 
    readS32: has [r b] [
        r: b: first inBuffer inBuffer: next inBuffer 
        if r < 128 [return r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 127) or (shift/left b 7) 
        if r < 16384 [return 2 * r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 16383) or (shift/left b 14) 
        if r < 2097152 [return 2 * r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 2097151) or (shift/left b 21) 
        if r < 268435456 [return 2 * r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 268435455) or (shift/left b 28) 
        2 * r
    ] 
    readD64: does [
        from-ieee64 readBytes 8
    ] 
    readShort: :readUI16 
    readLongFloat: func ["reads 4 bytes and converts them to decimal!" /local tmp] [
        readBytesRev 4
    ] 
    readULongFixed: has [l r] [
        r: readUI16 
        l: readUI16 
        load ajoin [l #"." r]
    ] 
    readSLongFixed: has [l r] [
        r: readUI16 
        l: readSI16 
        load ajoin [l #"." r]
    ] 
    readSShortFixed: has [l r] [
        r: readUI8 
        l: readSI8 
        load ajoin [l #"." r]
    ] 
    readRGB: does [to tuple! readBytes 3] 
    readRGBA: does [to tuple! readBytes 4] 
    readStringP: has [str] [
        parse/all inBuffer [copy str to "^@" 1 skip inBuffer:] 
        inBuffer: as-binary inBuffer 
        str
    ] 
    readStringNum: func [bytes] [
        as-string readBytes bytes
    ] 
    readString: does [
        head remove back tail copy/part inBuffer inBuffer: find/tail inBuffer #{00}
    ] 
    readUTF: does [
        as-string readBytes readUI16
    ] 
    readStringInfo: does [
        as-string readBytes readUI30
    ] 
    skipString: does [inBuffer: find/tail inBuffer #{00}] 
    readCount: has [c] [
        either 255 = c: readUI8 [readUI16] [c]
    ] 
    readRGBAArray: func [count /local result] [
        result: copy [] 
        loop count [append result readRGBA] 
        result
    ] 
    readUI8Array: func [count /local result] [
        result: copy [] 
        loop count [append result readUI8] 
        result
    ] 
    readUI32array: readSI32array: func [/local count result] [
        count: readUI30 - 1 
        either count >= 0 [
            result: make block! count 
            loop count [append result readUI32] 
            result
        ] [none]
    ] 
    readU32array: func [/local count result] [
        count: readUI30 - 1 
        either count >= 0 [
            result: make block! count 
            loop count [append result readU32] 
            result
        ] [none]
    ] 
    readS32array: func [/local count result] [
        count: readUI30 - 1 
        either count >= 0 [
            result: make block! count 
            loop count [append result readS32] 
            result
        ] [none]
    ] 
    readD64array: func [/local count result] [
        count: readUI30 - 1 
        either count >= 0 [
            result: make block! count 
            loop count [append result readD64] 
            result
        ] [none]
    ] 
    readLongFloatArray: func [count /local result] [
        result: copy [] 
        loop count [append result readLongFloat] 
        result
    ] 
    readCharCode: func [{Reads sequence of 1-6 octets into 32-bit unsigned integer.} /local us] [
        us: utf-8/decode-integer inBuffer 
        inBuffer: skip inBuffer second us 
        first us
    ] 
    comment {
^-readUCS2Code: func[/local us][
    ^-us: utf-8/decode-integer inBuffer
        vs: make block! 2
        z: to integer! ((first us) / 256)
        insert vs z
        z: (first us) - (z * 256)
        insert tail vs z
        ;probe vs
        insert tail result to binary! vs
       ; probe us
        xs: skip xs second us
    ^-inBuffer: skip inBuffer second us
    ^-first us
^-]
^-} 
    isSetBit?: func [flags [integer!] bit [integer!] /local b] [
        (b: to integer! (2 ** (bit - 1))) = (b and flags)
    ] 
    comment "SKIP FUNCTIONS" 
    skipRect: does [
        byteAlign 
        skipBits (4 * readUB 5) 
        byteAlign
    ] 
    skipPair: does [skipBits (2 * readUB 5)] 
    skipBits: func [nbits] [
        if availableBits > 0 [
            inBuffer: back inBuffer 
            nbits: 8 - availableBits + nbits
        ] 
        inBuffer: skip inBuffer (to integer! (nbits / 8)) 
        either 0 = availableBits: nbits // 8 [
            bitBuffer: none
        ] [
            bitBuffer: to integer! (2 ** availableBits) * first inBuffer 
            availableBits: 8 - availableBits 
            inBuffer: next inBuffer
        ] 
        none
    ] 
    skipBytes: func [nbytes] [inBuffer: skip inBuffer nbytes] 
    skipByte: does [inBuffer: next inBuffer] 
    skipUI16: does [inBuffer: skip inBuffer 2] 
    skipUI32: does [inBuffer: skip inBuffer 4] 
    skipRGB: does [inBuffer: skip inBuffer 3] 
    skipSBPair: does [skipBits (2 * readUB 5)] 
    skipRGBA: :skipUI32 
    skipSI16: :skipUI16 
    skipUI8: :skipByte 
    comment "WRITE FUNCTIONS" 
    outBuffer: make binary! 1000 
    outBitMask: 0 
    outBitBuffer: none 
    alignBuffers: does [
        if availableBits > 0 [
            availableBits: 0 
            bitBuffer: none
        ] 
        unless none? outBitBuffer [
            outBuffer: insert outBuffer to char! outBitBuffer 
            outBitMask: 0 
            outBitBuffer: none
        ]
    ] 
    clearOutBuffer: does [
        outBuffer: copy #{} 
        outBitMask: 0 
        outBitBuffer: none
    ] 
    outSetStreamBuffer: func [buff] [
        outBuffer: buff 
        outBitMask: 0 
        outBitBuffer: none
    ] 
    outByteAlign: does [
        unless none? outBitBuffer [
            outBuffer: insert outBuffer to char! outBitBuffer 
            outBitMask: 0 
            outBitBuffer: none
        ] 
        outBuffer
    ] 
    getUBitsLength: func [
        {Returns number of bits needed to store unsigned integer value} 
        value [integer!] "Unsigned integer"
    ] [
        either value <= 0 [0] [1 + to integer! log-2 value]
    ] 
    getSBitsLength: func [
        {Returns number of bits needed to store signed integer value} 
        value [integer!] "Signed integer"
    ] [
        either value = 0 [0] [2 + to integer! log-2 abs value]
    ] 
    getUBitsLength: func [
        {Returns number of bits needed to store unsigned integer value} 
        value [integer!] "unsigned integer"
    ] [
        either value = 0 [0] [1 + to integer! log-2 abs value]
    ] 
    getSBnBits: func [values] [
        2 + to integer! log-2 max (first maximum-of values) (abs first minimum-of values)
    ] 
    getUBnBits: func [values] [1 + to integer! log-2 (first maximum-of values)
    ] 
    ui32-struct: make struct! [value [integer!]] none 
    ui16-struct: make struct! [value [short]] none 
    float-struct: make struct! [value [float]] none 
    writeFloat: func [v [number!]] [
        float-struct/value: v 
        outBuffer: insert outBuffer third float-struct
    ] 
    writeUI32: writeUnsignedInt: func [i] [
        ui32-struct/value: to integer! i 
        outBuffer: insert outBuffer copy third ui32-struct
    ] 
    writeUI16: func [i] [
        ui16-struct/value: to integer! i 
        outBuffer: insert outBuffer copy third ui16-struct
    ] 
    writeUI8: func [i] [
        outBuffer: insert outBuffer to char! 255 and to integer! i
    ] 
    writeUI30: func [i] [
        case [
            i < 128 [writeUI8 i] 
            true [make error! "Unsuported value for writeUI30"]
        ]
    ] 
    comment {^-^-^-
^-def writeLen(self, l):
        if l < 0x80:
            self.writeStr(chr(l))
        elif l < 0x4000:
            l |= 0x8000
            self.writeStr(chr((l >> 8) & 0xFF))
            self.writeStr(chr(l & 0xFF))
        elif l < 0x200000:
            l |= 0xC00000
            self.writeStr(chr((l >> 16) & 0xFF))
            self.writeStr(chr((l >> 8) & 0xFF))
            self.writeStr(chr(l & 0xFF))
        elif l < 0x10000000:        
            l |= 0xE0000000         
            self.writeStr(chr((l >> 24) & 0xFF))
            self.writeStr(chr((l >> 16) & 0xFF))
            self.writeStr(chr((l >> 8) & 0xFF))
            self.writeStr(chr(l & 0xFF))
        else:                       
            self.writeStr(chr(0xF0))
            self.writeStr(chr((l >> 24) & 0xFF))
            self.writeStr(chr((l >> 16) & 0xFF))
            self.writeStr(chr((l >> 8) & 0xFF))
            self.writeStr(chr(l & 0xFF))
} 
    writeByte: func [byte] [outBuffer: insert outBuffer byte] 
    writeBytes: func [bytes] [outBuffer: insert outBuffer as-binary bytes] 
    writeBit: func [bit [integer! logic!]] [
        unless outBitBuffer [
            outBitBuffer: 0 
            outBitMask: 128
        ] 
        either logic? bit [
            if bit [outBitBuffer: outBitBuffer or outBitMask]
        ] [
            outBitBuffer: outBitBuffer or (outBitMask and bit)
        ] 
        if 1 > outBitMask: outBitMask / 2 [
            outBuffer: insert outBuffer to char! outBitBuffer 
            outBitBuffer: none
        ] 
        outBitBuffer
    ] 
    writeBits: func [value [integer!] nBits [integer!]] [
        loop nBits [
            writeBit value
        ]
    ] 
    writeFPBits: func [value nBits] [
        writeSignedBits (value * 65536.0) nBits
    ] 
    writeInteger: func [value nBits /local nbitCursor val] [
        if nBits = 32 [
            unless outBitBuffer [
                outBitBuffer: 0 
                outBitMask: 128
            ] 
            if -2147483648 = (-2147483648 and value) [
                outBitBuffer: outBitBuffer or outBitMask
            ] 
            if 1 > outBitMask: outBitMask / 2 [
                outBuffer: insert outBuffer to char! outBitBuffer 
                outBitBuffer: none
            ] 
            nBits: 31
        ] 
        nbitCursor: to integer! power 2 (nBits - 1) 
        while [nbitCursor >= 1] [
            unless outBitBuffer [
                outBitBuffer: 0 
                outBitMask: 128
            ] 
            if 0 < (nbitCursor and value) [
                outBitBuffer: outBitBuffer or outBitMask
            ] 
            if 1 > outBitMask: outBitMask / 2 [
                outBuffer: insert outBuffer to char! outBitBuffer 
                outBitBuffer: none
            ] 
            nbitCursor: nbitCursor / 2
        ]
    ] 
    writeUB: :writeInteger 
    writeSB: func [value [integer!] nBits /local] [
        if nBits < bitsNeeded: getSBitsLength value [
            throw make error! reform ["IO: At least" bitsNeeded "bits needed for representation of" value "(writeSB)"]
        ] 
        writeInteger value nBits
    ] 
    writeFB: func [value [number!] nBits /local x y fb] [
        writeSB to integer! (value * 65536.0) nBits
    ] 
    writeSBs: func [values [block!] nbits /local bitsNeeded] [
        bitsNeeded: 1 + to integer! log-2 max (first maximum-of values) (abs first minimum-of values) 
        if nBits < bitsNeeded [
            throw make error! reform ["IO: At least" bitsNeeded "bits needed for representation of" value "(writeSBs)"]
        ] 
        forall values [
            writeInteger values/1 nBits
        ]
    ] 
    writeUBs: func [values [block!] nBits] [
        forall values [
            writeInteger max 0 values/1 nBits
        ]
    ] 
    writeRect: func [corners /local nBits] [
        outByteAlign 
        nBits: 2 + to integer! log-2 max (first maximum-of corners) (abs first minimum-of corners) 
        writeInteger nBits 5 
        forall corners [
            writeInteger corners/1 nBits
        ] 
        outByteAlign
    ] 
    writeString: func [value] [writeBytes join as-binary value #{00}] 
    writeUTF: func [value] [
        writeUI16 length? value 
        writeBytes value
    ] 
    writePair: func [value [pair! block!] /local nBits] [
        v1: value/1 
        v2: value/2 
        nBits: 16 + getSBitsLength to integer! (round max abs v1 abs v2) 
        writeUB nBits 5 
        writeFB v1 nbits 
        writeFB v2 nbits
    ] 
    writeSBPair: func [value [pair! block!] /local v1 v2 nBits x y] [
        v1: value/1 
        v2: value/2 
        nBits: getSBitsLength to integer! max abs v1 abs v2 
        writeUB nBits 5 
        writeSB v1 nbits 
        writeSB v2 nbits
    ] 
    readLongFloat: func ["reads 4 bytes and converts them to decimal!" /local tmp] [
        readBytesRev 4
    ] 
    writeCount: func [c] [
        either c < 255 [writeUI8 c] [writeByte #{FF} writeUI16 c]
    ] 
    carryCount: has [c] [
        either 255 > c: readUI8 [writeUI8 c] [writeByte #{FF} writeUI16 c: readUI16] c
    ] 
    carryBytes: func [num] [writeBytes readBytes num] 
    carryBitLogic: has [b] [writeBit b: readBitLogic b] 
    carrySBPair: carryPair: has [nBits] [
        nBits: readUB 5 
        writeUB nBits 5 
        loop (2 * nBits) [
            writeBit readBitLogic
        ]
    ] 
    carryBits: func [num] [loop num [writeBit readBitLogic]] 
    carryUI8: has [v] [writeUI8 v: readUI8 v] 
    carryUI16: has [v] [writeUI16 v: readUI16 v] 
    carryUB: func [nBits /local v] [writeUB v: readUB nBits nBits v] 
    carrySB: func [nBits /local v] [writeSB v: readSB nBits nBits v] 
    carryString: does [writeString readString]
] 
comment {
system/options/binary-base: 2

s: make stream-io []
s/outSetStreamBuffer x: copy #{}
with s [
^-writeBit true
^-writePair [14.1421203613281 14.1421203613281]
^-writeBit true
^-writePair [14.1421203613281 -14.1421203613281]
^-outByteAlign
^-probe enbase/base x 16
]


s: make stream-io []
s/outSetStreamBuffer x: copy #{}
with s [
^-writeUI8 2
^-b: index? outBuffer
^-writeUI8 3
^-probe outBuffer: at head outBuffer b
^-writeUI8 4
^-
^-setStreamBuffer copy head outBuffer
^-probe readUI8
^-probe readUI8
^-probe readUI8
]


system/options/binary-base: 2

s: make stream-io []
s/outSetStreamBuffer x: copy #{}
with s [
^-writeBit true
^-writePair [14.1421203613281 14.1421203613281]
^-writeBit true
^-writePair [14.1421203613281 -14.1421203613281]
^-outByteAlign
^-probe enbase/base x 16
]


with s [
^-setStreamBuffer copy head outBuffer
^-;setStreamBuffer copy #{D5C48C4E2462D5C48C52DB9E0000100BD8FA0E97}
^-probe reduce [
^-^-either readBitLogic [ readPair ][none] ;scale
^-^-either readBitLogic [ readPair ][none] ;rotate
^-]
]
;halt
s/outSetStreamBuffer x: copy #{}
s/writePair [3.47296355333861 -3.472963553338612]
s/outByteAlign
probe x 

s/setStreamBuffer copy head s/outBuffer
clear head s/outBuffer
probe s/readPair


s/outByteAlign
probe head s/outBuffer


system/options/binary-base: 2
s: make stream-io []
s/outSetStreamBuffer x: copy #{}
s/writeFB 20 22
s/outByteAlign
probe x 

s/setStreamBuffer head s/outBuffer
probe s/readFB 22

s/writeBit 0
s/writeBit 0
s/writeBit 0
s/writeBit 1
s/writeSBPair [2799 940]
s/writeBit 0
s/writeBit 0
s/writeBit 0
s/writeBit 1
s/writeBit 1
s/writeUB 11 4


;s/writeUB 32 5
;s/writeInteger 1 6
;s/writeSB -22106 32
;s/writePair [0.707118333714809 0.707118333714809]
;s/writeRect [100 10 30 -210] 5
;s/writeFB 3.0 19
;s/writeFB 0.707118333714809 19
;s/writePair [10 2.2]
;s/writeSB -22 9
;s/writeSBPair [-80000 2460]
;s/outByteAlign
;s/writeString "test"
;s/writeRect [100 10 30 10]
;s/writeInteger 0 2
;s/writeSB -2 3
;s/writeInteger 10 6
;s/writeSBPair [ 0 0 ]
s/outByteAlign

probe x 

s/setStreamBuffer head s/outBuffer
probe s/readBit
probe s/readBit
probe s/readBit
probe s/readBit
probe s/readSBPair
probe s/readBit
probe s/readBit
probe s/readBit
probe s/readBit
probe s/readBit
probe s/readUB 4
;probe s/readUB 5
;probe s/readUB 1
;probe s/readUB 6
;probe s/readSB 32
;probe s/readPair
;probe s/readRect
;probe s/readFB 19
;probe s/readFB 19
;probe s/readPair
;probe s/readSB 9
;probe s/readSBPair
;probe s/readSBPair
;probe as-string s/readString

probe x ; head s/outBuffer
} 
comment "---- end of RS include %stream-io.r ----" 
comment {
#### RS include: %form-timeline.r
#### Title:   "form-timeline"
#### Author:  "Oldes"
----} 
comment {
#### RS include: %swf-parser.r
#### Title:   "Swf-parser"
#### Author:  "David Oliva (commercial)"
----} 
comment {
#### RS include: %r2-forward.r
#### Title:   "R2-forward"
#### Author:  "Oldes"
----} 
funct: func [
    "Defines a function with all set-words as locals." 
    [catch] 
    spec [block!] {Help string (opt) followed by arg words (and opt type and string)} 
    body [block!] "The body block of the function" 
    /with "Define or use a persistent object (self)" 
    object [object! block!] "The object or spec" 
    /extern words [block!] "These words are not local" 
    /local r ws wb a
] [
    spec: copy/deep spec 
    body: copy/deep body 
    ws: make block! length? spec 
    parse spec [any [
            set-word! | set a any-word! (insert tail ws to-word a) | skip
        ]] 
    if with [
        unless object? object [object: make object! object] 
        bind body object 
        insert tail ws first object
    ] 
    insert tail ws words 
    wb: make block! 12 
    parse body r: [any [
            set a set-word! (insert tail wb to-word a) | 
            hash! | into r | skip
        ]] 
    unless empty? wb: exclude wb ws [
        remove find wb 'local 
        unless find spec /local [insert tail spec /local] 
        insert tail spec wb
    ] 
    throw-on-error [make function! spec body]
] 
comment "---- end of RS include %r2-forward.r ----" 
comment {
#### RS include: %stream-io.r
#### Title:   "stream-io"
#### Author:  "Oldes"
----} 
stream-io: context [
    inBuffer: none 
    availableBits: 0 
    bitBuffer: none 
    setStreamBuffer: func [buff] [
        inBuffer: either port? buff [copy buff] [buff] 
        availableBits: 0 
        bitBuffer: none
    ] 
    initBitBuffer: does [
        bitBuffer: first inBuffer 
        availableBits: 8 
        inBuffer: next inBuffer
    ] 
    clearBuffers: does [
        if series? inBuffer [clear head inBuffer] 
        if series? outBuffer [clear head outBuffer] 
        availableBits: 0 
        bitBuffer: none 
        outBitMask: 0 
        outBitBuffer: none
    ] 
    readSB: func [nbits [integer!] /local result] [
        if nbits = 0 [return 0] 
        result: copy "" 
        loop nbits [append result readBit] 
        insert/dup result result/1 (32 - nbits) 
        to integer! debase/base result 2
    ] 
    byteAlign: does [
        if availableBits > 0 [
            availableBits: 0 
            bitBuffer: none
        ] 
        inBuffer
    ] 
    readBit: has [bit] [
        unless bitBuffer [
            bitBuffer: first inBuffer 
            availableBits: 8 
            inBuffer: next inBuffer
        ] 
        if 0 < bit: 128 and bitBuffer [bit: 1] 
        either 0 = availableBits: availableBits - 1 [
            bitBuffer: none
        ] [
            bitBuffer: bitBuffer * 2
        ] 
        bit
    ] 
    readBitLogic: has [bit] [
        unless bitBuffer [
            bitBuffer: first inBuffer 
            availableBits: 8 
            inBuffer: next inBuffer
        ] 
        bit: (128 and bitBuffer) > 0 
        either 0 = availableBits: availableBits - 1 [
            bitBuffer: none
        ] [
            bitBuffer: bitBuffer * 2
        ] 
        bit
    ] 
    readUB: func [nbits [integer!] /local result nb x] [
        if nbits = 0 [return 0] 
        result: 0 nb: nbits 
        while [nbits > 0] [
            unless bitBuffer [
                bitBuffer: first inBuffer 
                inBuffer: next inBuffer 
                availableBits: 8
            ] 
            either availableBits > nbits [
                availableBits: availableBits - nbits 
                result: (256 - to integer! x: (2 ** (8 - nbits))) and bitBuffer / x + result 
                bitBuffer: either availableBits = 0 [none] [to integer! (bitBuffer * (2 ** nbits))] 
                return to integer! result 
                break
            ] [
                result: ((255 and bitBuffer) / (2 ** (8 - availableBits))) * (2 ** (nb - availableBits)) + result 
                nbits: nbits - availableBits 
                bitBuffer: none 
                availableBits: 0
            ]
        ] 
        to integer! result
    ] 
    readByte: func [/local byte] [
        byte: copy/part inBuffer 1 
        inBuffer: next inBuffer 
        byte
    ] 
    readBytes: func [nbytes /local bytes] [
        bytes: copy/part inBuffer 
        inBuffer: skip inBuffer nbytes 
        bytes
    ] 
    readPair: has [nbits] [
        nbits: readUB 5 
        reduce [readFB nbits readFB nbits]
    ] 
    readSBPair: has [nbits] [
        nbits: readUB 5 
        reduce [readSB nbits readSB nbits]
    ] 
    readFB: func [nbits /local] [
        (readSB nBits) / 65536.0
    ] 
    readRect: has [nbits result] [
        byteAlign 
        nbits: readUB 5 
        result: reduce [
            readSB nbits 
            readSB nbits 
            readSB nbits 
            readSB nbits
        ] 
        byteAlign 
        result
    ] 
    readBytesRev: func [nbytes] [
        reverse 
        copy/part inBuffer 
        inBuffer: skip inBuffer nbytes
    ] 
    readBytesArray: func [
        {Slices the binary data to parts which length is specified in the bytes block} 
        bytes [block!] 
        /local result b
    ] [
        result: copy [] 
        while [not tail? bytes] [
            insert tail result readBytes bytes/1 
            bytes: next bytes
        ] 
        result
    ] 
    readUI8: has [i] [i: first inBuffer inBuffer: next inBuffer i] 
    readUI16: func [] [to integer! readBytesRev 2] 
    readUI32: func [] [to integer! readBytesRev 4] 
    readSI8: has [i] [
        i: first inBuffer inBuffer: next inBuffer 
        if i > 127 [
            i: (i and 127) - 128
        ] 
        i
    ] 
    readSI16: has [i] [
        i: to integer! readBytesRev 2 
        if i > 32767 [
            i: (i and 32767) - 32768
        ] 
        i
    ] 
    readS24: has [i] [
        i: to integer! readBytesRev 3 
        if i > 8388607 [
            i: (i and 8388607) - 8388608
        ] 
        i
    ] 
    readUI16le: :readUI16 
    readUI32le: :readUI32 
    readSI8le: :readSI8 
    readSI16le: :readSI16 
    readUI16be: func [] [to integer! readBytes 2] 
    readUI32be: func [] [to integer! readBytes 4] 
    readSI8be: has [i] [
        i: first inBuffer inBuffer: next inBuffer 
        if i > 127 [
            i: (i and 127) - 128
        ] 
        i
    ] 
    readSI16be: has [i] [
        i: to integer! readBytes 2 
        if i > 32767 [
            i: (i and 32767) - 32768
        ] 
        i
    ] 
    readSI32: :readUI32 
    readRest: has [bytes] [
        bytes: copy inBuffer 
        inBuffer: tail inBuffer 
        bytes
    ] 
    readFloat: does [
        change third float-struct readBytes 4 
        float-struct/value
    ] 
    readUI30: has [r b s] [
        b: first inBuffer inBuffer: next inBuffer 
        if b < 128 [return to integer! b] 
        r: b and 127 
        s: 128 
        while [b: first inBuffer inBuffer: next inBuffer] [
            r: r + (b * s) 
            if 128 > b [return r] 
            s: s + 128
        ]
    ] 
    readU32: has [r b s] [
        r: b: first inBuffer inBuffer: next inBuffer 
        if r < 128 [return r] 
        ask "x" 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 127) or (shift/left b 7) 
        if r < 16384 [probe r ask "2" return r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 16383) or (shift/left b 14) 
        if r < 2097152 [return r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 2097151) or (shift/left b 21) 
        if r < 268435456 [return r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 268435455) or (shift/left b 28) 
        r
    ] 
    readS32: has [r b] [
        r: b: first inBuffer inBuffer: next inBuffer 
        if r < 128 [return r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 127) or (shift/left b 7) 
        if r < 16384 [return 2 * r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 16383) or (shift/left b 14) 
        if r < 2097152 [return 2 * r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 2097151) or (shift/left b 21) 
        if r < 268435456 [return 2 * r] 
        b: first inBuffer inBuffer: next inBuffer 
        r: (r and 268435455) or (shift/left b 28) 
        2 * r
    ] 
    readD64: does [
        from-ieee64 readBytes 8
    ] 
    readShort: :readUI16 
    readLongFloat: func ["reads 4 bytes and converts them to decimal!" /local tmp] [
        readBytesRev 4
    ] 
    readULongFixed: has [l r] [
        r: readUI16 
        l: readUI16 
        load ajoin [l #"." r]
    ] 
    readSLongFixed: has [l r] [
        r: readUI16 
        l: readSI16 
        load ajoin [l #"." r]
    ] 
    readSShortFixed: has [l r] [
        r: readUI8 
        l: readSI8 
        load ajoin [l #"." r]
    ] 
    readRGB: does [to tuple! readBytes 3] 
    readRGBA: does [to tuple! readBytes 4] 
    readStringP: has [str] [
        parse/all inBuffer [copy str to "^@" 1 skip inBuffer:] 
        inBuffer: as-binary inBuffer 
        str
    ] 
    readStringNum: func [bytes] [
        as-string readBytes bytes
    ] 
    readString: does [
        head remove back tail copy/part inBuffer inBuffer: find/tail inBuffer #{00}
    ] 
    readUTF: does [
        as-string readBytes readUI16
    ] 
    readStringInfo: does [
        as-string readBytes readUI30
    ] 
    skipString: does [inBuffer: find/tail inBuffer #{00}] 
    readCount: has [c] [
        either 255 = c: readUI8 [readUI16] [c]
    ] 
    readRGBAArray: func [count /local result] [
        result: copy [] 
        loop count [append result readRGBA] 
        result
    ] 
    readUI8Array: func [count /local result] [
        result: copy [] 
        loop count [append result readUI8] 
        result
    ] 
    readUI32array: readSI32array: func [/local count result] [
        count: readUI30 - 1 
        either count >= 0 [
            result: make block! count 
            loop count [append result readUI32] 
            result
        ] [none]
    ] 
    readU32array: func [/local count result] [
        count: readUI30 - 1 
        either count >= 0 [
            result: make block! count 
            loop count [append result readU32] 
            result
        ] [none]
    ] 
    readS32array: func [/local count result] [
        count: readUI30 - 1 
        either count >= 0 [
            result: make block! count 
            loop count [append result readS32] 
            result
        ] [none]
    ] 
    readD64array: func [/local count result] [
        count: readUI30 - 1 
        either count >= 0 [
            result: make block! count 
            loop count [append result readD64] 
            result
        ] [none]
    ] 
    readLongFloatArray: func [count /local result] [
        result: copy [] 
        loop count [append result readLongFloat] 
        result
    ] 
    readCharCode: func [{Reads sequence of 1-6 octets into 32-bit unsigned integer.} /local us] [
        us: utf-8/decode-integer inBuffer 
        inBuffer: skip inBuffer second us 
        first us
    ] 
    comment {
^-readUCS2Code: func[/local us][
    ^-us: utf-8/decode-integer inBuffer
        vs: make block! 2
        z: to integer! ((first us) / 256)
        insert vs z
        z: (first us) - (z * 256)
        insert tail vs z
        ;probe vs
        insert tail result to binary! vs
       ; probe us
        xs: skip xs second us
    ^-inBuffer: skip inBuffer second us
    ^-first us
^-]
^-} 
    isSetBit?: func [flags [integer!] bit [integer!] /local b] [
        (b: to integer! (2 ** (bit - 1))) = (b and flags)
    ] 
    comment "SKIP FUNCTIONS" 
    skipRect: does [
        byteAlign 
        skipBits (4 * readUB 5) 
        byteAlign
    ] 
    skipPair: does [skipBits (2 * readUB 5)] 
    skipBits: func [nbits] [
        if availableBits > 0 [
            inBuffer: back inBuffer 
            nbits: 8 - availableBits + nbits
        ] 
        inBuffer: skip inBuffer (to integer! (nbits / 8)) 
        either 0 = availableBits: nbits // 8 [
            bitBuffer: none
        ] [
            bitBuffer: to integer! (2 ** availableBits) * first inBuffer 
            availableBits: 8 - availableBits 
            inBuffer: next inBuffer
        ] 
        none
    ] 
    skipBytes: func [nbytes] [inBuffer: skip inBuffer nbytes] 
    skipByte: does [inBuffer: next inBuffer] 
    skipUI16: does [inBuffer: skip inBuffer 2] 
    skipUI32: does [inBuffer: skip inBuffer 4] 
    skipRGB: does [inBuffer: skip inBuffer 3] 
    skipSBPair: does [skipBits (2 * readUB 5)] 
    skipRGBA: :skipUI32 
    skipSI16: :skipUI16 
    skipUI8: :skipByte 
    comment "WRITE FUNCTIONS" 
    outBuffer: make binary! 1000 
    outBitMask: 0 
    outBitBuffer: none 
    alignBuffers: does [
        if availableBits > 0 [
            availableBits: 0 
            bitBuffer: none
        ] 
        unless none? outBitBuffer [
            outBuffer: insert outBuffer to char! outBitBuffer 
            outBitMask: 0 
            outBitBuffer: none
        ]
    ] 
    clearOutBuffer: does [
        outBuffer: copy #{} 
        outBitMask: 0 
        outBitBuffer: none
    ] 
    outSetStreamBuffer: func [buff] [
        outBuffer: buff 
        outBitMask: 0 
        outBitBuffer: none
    ] 
    outByteAlign: does [
        unless none? outBitBuffer [
            outBuffer: insert outBuffer to char! outBitBuffer 
            outBitMask: 0 
            outBitBuffer: none
        ] 
        outBuffer
    ] 
    getUBitsLength: func [
        {Returns number of bits needed to store unsigned integer value} 
        value [integer!] "Unsigned integer"
    ] [
        either value <= 0 [0] [1 + to integer! log-2 value]
    ] 
    getSBitsLength: func [
        {Returns number of bits needed to store signed integer value} 
        value [integer!] "Signed integer"
    ] [
        either value = 0 [0] [2 + to integer! log-2 abs value]
    ] 
    getUBitsLength: func [
        {Returns number of bits needed to store unsigned integer value} 
        value [integer!] "unsigned integer"
    ] [
        either value = 0 [0] [1 + to integer! log-2 abs value]
    ] 
    getSBnBits: func [values] [
        2 + to integer! log-2 max (first maximum-of values) (abs first minimum-of values)
    ] 
    getUBnBits: func [values] [1 + to integer! log-2 (first maximum-of values)
    ] 
    ui32-struct: make struct! [value [integer!]] none 
    ui16-struct: make struct! [value [short]] none 
    float-struct: make struct! [value [float]] none 
    writeFloat: func [v [number!]] [
        float-struct/value: v 
        outBuffer: insert outBuffer third float-struct
    ] 
    writeUI32: writeUnsignedInt: func [i] [
        ui32-struct/value: to integer! i 
        outBuffer: insert outBuffer copy third ui32-struct
    ] 
    writeUI16: func [i] [
        ui16-struct/value: to integer! i 
        outBuffer: insert outBuffer copy third ui16-struct
    ] 
    writeUI8: func [i] [
        outBuffer: insert outBuffer to char! 255 and to integer! i
    ] 
    writeUI30: func [i] [
        case [
            i < 128 [writeUI8 i] 
            true [make error! "Unsuported value for writeUI30"]
        ]
    ] 
    comment {^-^-^-
^-def writeLen(self, l):
        if l < 0x80:
            self.writeStr(chr(l))
        elif l < 0x4000:
            l |= 0x8000
            self.writeStr(chr((l >> 8) & 0xFF))
            self.writeStr(chr(l & 0xFF))
        elif l < 0x200000:
            l |= 0xC00000
            self.writeStr(chr((l >> 16) & 0xFF))
            self.writeStr(chr((l >> 8) & 0xFF))
            self.writeStr(chr(l & 0xFF))
        elif l < 0x10000000:        
            l |= 0xE0000000         
            self.writeStr(chr((l >> 24) & 0xFF))
            self.writeStr(chr((l >> 16) & 0xFF))
            self.writeStr(chr((l >> 8) & 0xFF))
            self.writeStr(chr(l & 0xFF))
        else:                       
            self.writeStr(chr(0xF0))
            self.writeStr(chr((l >> 24) & 0xFF))
            self.writeStr(chr((l >> 16) & 0xFF))
            self.writeStr(chr((l >> 8) & 0xFF))
            self.writeStr(chr(l & 0xFF))
} 
    writeByte: func [byte] [outBuffer: insert outBuffer byte] 
    writeBytes: func [bytes] [outBuffer: insert outBuffer as-binary bytes] 
    writeBit: func [bit [integer! logic!]] [
        unless outBitBuffer [
            outBitBuffer: 0 
            outBitMask: 128
        ] 
        either logic? bit [
            if bit [outBitBuffer: outBitBuffer or outBitMask]
        ] [
            outBitBuffer: outBitBuffer or (outBitMask and bit)
        ] 
        if 1 > outBitMask: outBitMask / 2 [
            outBuffer: insert outBuffer to char! outBitBuffer 
            outBitBuffer: none
        ] 
        outBitBuffer
    ] 
    writeBits: func [value [integer!] nBits [integer!]] [
        loop nBits [
            writeBit value
        ]
    ] 
    writeFPBits: func [value nBits] [
        writeSignedBits (value * 65536.0) nBits
    ] 
    writeInteger: func [value nBits /local nbitCursor val] [
        if nBits = 32 [
            unless outBitBuffer [
                outBitBuffer: 0 
                outBitMask: 128
            ] 
            if -2147483648 = (-2147483648 and value) [
                outBitBuffer: outBitBuffer or outBitMask
            ] 
            if 1 > outBitMask: outBitMask / 2 [
                outBuffer: insert outBuffer to char! outBitBuffer 
                outBitBuffer: none
            ] 
            nBits: 31
        ] 
        nbitCursor: to integer! power 2 (nBits - 1) 
        while [nbitCursor >= 1] [
            unless outBitBuffer [
                outBitBuffer: 0 
                outBitMask: 128
            ] 
            if 0 < (nbitCursor and value) [
                outBitBuffer: outBitBuffer or outBitMask
            ] 
            if 1 > outBitMask: outBitMask / 2 [
                outBuffer: insert outBuffer to char! outBitBuffer 
                outBitBuffer: none
            ] 
            nbitCursor: nbitCursor / 2
        ]
    ] 
    writeUB: :writeInteger 
    writeSB: func [value [integer!] nBits /local] [
        if nBits < bitsNeeded: getSBitsLength value [
            throw make error! reform ["IO: At least" bitsNeeded "bits needed for representation of" value "(writeSB)"]
        ] 
        writeInteger value nBits
    ] 
    writeFB: func [value [number!] nBits /local x y fb] [
        writeSB to integer! (value * 65536.0) nBits
    ] 
    writeSBs: func [values [block!] nbits /local bitsNeeded] [
        bitsNeeded: 1 + to integer! log-2 max (first maximum-of values) (abs first minimum-of values) 
        if nBits < bitsNeeded [
            throw make error! reform ["IO: At least" bitsNeeded "bits needed for representation of" value "(writeSBs)"]
        ] 
        forall values [
            writeInteger values/1 nBits
        ]
    ] 
    writeUBs: func [values [block!] nBits] [
        forall values [
            writeInteger max 0 values/1 nBits
        ]
    ] 
    writeRect: func [corners /local nBits] [
        outByteAlign 
        nBits: 2 + to integer! log-2 max (first maximum-of corners) (abs first minimum-of corners) 
        writeInteger nBits 5 
        forall corners [
            writeInteger corners/1 nBits
        ] 
        outByteAlign
    ] 
    writeString: func [value] [writeBytes join as-binary value #{00}] 
    writeUTF: func [value] [
        writeUI16 length? value 
        writeBytes value
    ] 
    writePair: func [value [pair! block!] /local nBits] [
        v1: value/1 
        v2: value/2 
        nBits: 16 + getSBitsLength to integer! (round max abs v1 abs v2) 
        writeUB nBits 5 
        writeFB v1 nbits 
        writeFB v2 nbits
    ] 
    writeSBPair: func [value [pair! block!] /local v1 v2 nBits x y] [
        v1: value/1 
        v2: value/2 
        nBits: getSBitsLength to integer! max abs v1 abs v2 
        writeUB nBits 5 
        writeSB v1 nbits 
        writeSB v2 nbits
    ] 
    readLongFloat: func ["reads 4 bytes and converts them to decimal!" /local tmp] [
        readBytesRev 4
    ] 
    writeCount: func [c] [
        either c < 255 [writeUI8 c] [writeByte #{FF} writeUI16 c]
    ] 
    carryCount: has [c] [
        either 255 > c: readUI8 [writeUI8 c] [writeByte #{FF} writeUI16 c: readUI16] c
    ] 
    carryBytes: func [num] [writeBytes readBytes num] 
    carryBitLogic: has [b] [writeBit b: readBitLogic b] 
    carrySBPair: carryPair: has [nBits] [
        nBits: readUB 5 
        writeUB nBits 5 
        loop (2 * nBits) [
            writeBit readBitLogic
        ]
    ] 
    carryBits: func [num] [loop num [writeBit readBitLogic]] 
    carryUI8: has [v] [writeUI8 v: readUI8 v] 
    carryUI16: has [v] [writeUI16 v: readUI16 v] 
    carryUB: func [nBits /local v] [writeUB v: readUB nBits nBits v] 
    carrySB: func [nBits /local v] [writeSB v: readSB nBits nBits v] 
    carryString: does [writeString readString]
] 
comment {
system/options/binary-base: 2

s: make stream-io []
s/outSetStreamBuffer x: copy #{}
with s [
^-writeBit true
^-writePair [14.1421203613281 14.1421203613281]
^-writeBit true
^-writePair [14.1421203613281 -14.1421203613281]
^-outByteAlign
^-probe enbase/base x 16
]


s: make stream-io []
s/outSetStreamBuffer x: copy #{}
with s [
^-writeUI8 2
^-b: index? outBuffer
^-writeUI8 3
^-probe outBuffer: at head outBuffer b
^-writeUI8 4
^-
^-setStreamBuffer copy head outBuffer
^-probe readUI8
^-probe readUI8
^-probe readUI8
]


system/options/binary-base: 2

s: make stream-io []
s/outSetStreamBuffer x: copy #{}
with s [
^-writeBit true
^-writePair [14.1421203613281 14.1421203613281]
^-writeBit true
^-writePair [14.1421203613281 -14.1421203613281]
^-outByteAlign
^-probe enbase/base x 16
]


with s [
^-setStreamBuffer copy head outBuffer
^-;setStreamBuffer copy #{D5C48C4E2462D5C48C52DB9E0000100BD8FA0E97}
^-probe reduce [
^-^-either readBitLogic [ readPair ][none] ;scale
^-^-either readBitLogic [ readPair ][none] ;rotate
^-]
]
;halt
s/outSetStreamBuffer x: copy #{}
s/writePair [3.47296355333861 -3.472963553338612]
s/outByteAlign
probe x 

s/setStreamBuffer copy head s/outBuffer
clear head s/outBuffer
probe s/readPair


s/outByteAlign
probe head s/outBuffer


system/options/binary-base: 2
s: make stream-io []
s/outSetStreamBuffer x: copy #{}
s/writeFB 20 22
s/outByteAlign
probe x 

s/setStreamBuffer head s/outBuffer
probe s/readFB 22

s/writeBit 0
s/writeBit 0
s/writeBit 0
s/writeBit 1
s/writeSBPair [2799 940]
s/writeBit 0
s/writeBit 0
s/writeBit 0
s/writeBit 1
s/writeBit 1
s/writeUB 11 4


;s/writeUB 32 5
;s/writeInteger 1 6
;s/writeSB -22106 32
;s/writePair [0.707118333714809 0.707118333714809]
;s/writeRect [100 10 30 -210] 5
;s/writeFB 3.0 19
;s/writeFB 0.707118333714809 19
;s/writePair [10 2.2]
;s/writeSB -22 9
;s/writeSBPair [-80000 2460]
;s/outByteAlign
;s/writeString "test"
;s/writeRect [100 10 30 10]
;s/writeInteger 0 2
;s/writeSB -2 3
;s/writeInteger 10 6
;s/writeSBPair [ 0 0 ]
s/outByteAlign

probe x 

s/setStreamBuffer head s/outBuffer
probe s/readBit
probe s/readBit
probe s/readBit
probe s/readBit
probe s/readSBPair
probe s/readBit
probe s/readBit
probe s/readBit
probe s/readBit
probe s/readBit
probe s/readUB 4
;probe s/readUB 5
;probe s/readUB 1
;probe s/readUB 6
;probe s/readSB 32
;probe s/readPair
;probe s/readRect
;probe s/readFB 19
;probe s/readFB 19
;probe s/readPair
;probe s/readSB 9
;probe s/readSBPair
;probe s/readSBPair
;probe as-string s/readString

probe x ; head s/outBuffer
} 
comment "---- end of RS include %stream-io.r ----" 
comment {
#### RS include: %ajoin.r
#### Title:   "Ajoin"
#### Author:  "David Oliva (commercial)"
----} 
unless value? 'ajoin [
    ajoin: func [
        {Faster way how to create string from a block (in R3 it's native!)} 
        block [block!]
    ] [make string! reduce block]
] 
unless value? 'abin [
    abin: func [
        "faster binary creation of a block" 
        block
    ] [
        head insert copy #{} reduce block
    ]
] 
comment "---- end of RS include %ajoin.r ----" 
comment {
#### RS include: %binary-conversions.r
#### Title:   "Binary-conversions"
#### Author:  "David Oliva (commercial)"
----} 
either value? 'rebcode [
    int-to-ui8: rebcode [val [integer!] /local tmp result] [
        copy result #{00} -1 
        and val 255 
        poke result 1 val 
        return result
    ] 
    int-to-ui16: rebcode [val [integer!] /local tmp result] [
        copy result #{0000} -1 
        set tmp 0 
        set.i tmp val 
        and tmp 255 
        poke result 1 tmp 
        set.i tmp val 
        lsr tmp 8 
        and tmp 255 
        poke result 2 tmp 
        return result
    ] 
    int-to-ui32: rebcode [val [integer!] /local tmp result] [
        copy result #{00000000} -1 
        set tmp 0 
        set.i tmp val 
        and tmp 255 
        poke result 1 tmp 
        set.i tmp val 
        lsr tmp 8 
        and tmp 255 
        poke result 2 tmp 
        set.i tmp val 
        lsr tmp 16 
        and tmp 255 
        poke result 3 tmp 
        set.i tmp val 
        lsr tmp 24 
        and tmp 255 
        poke result 4 tmp 
        return result
    ] 
    int-to-bits: func [i [number!] bits] [skip enbase/base head reverse int-to-ui32 i 2 32 - bits]
] [
    if error? try [
        ui32-struct: make struct! [value [integer!]] none 
        ui16-struct: make struct! [value [short]] none 
        int-to-ui32: func [i] [ui32-struct/value: to integer! i copy third ui32-struct] 
        int-to-ui16: func [i] [ui16-struct/value: to integer! i copy third ui16-struct] 
        int-to-ui8: func [i] [ui16-struct/value: to integer! i copy/part third ui16-struct 1] 
        int-to-bits: func [i [number!] bits] [skip enbase/base head reverse int-to-ui32 i 2 32 - bits]
    ] [
        int-to-ui32: func [i [number!]] [head reverse load rejoin ["#{" to-hex to integer! i "}"]] 
        int-to-ui16: func [i [number!]] [head reverse load rejoin ["#{" skip mold to-hex to integer! i 5 "}"]] 
        int-to-ui8: func [i [number!]] [load rejoin ["#{" skip mold to-hex to integer! i 7 "}"]] 
        int-to-bits: func [i [number!] bits] [skip enbase/base load rejoin ["#{" to-hex to integer! i "}"] 2 32 - bits]
    ]
] 
issue-to-binary: func [clr] [debase/base clr 16] 
issue-to-decimal: func [i [issue!] /local e d] [
    i: head reverse issue-to-binary i 
    e: 0 d: 0 
    forall i [
        d: d + (i/1 * (2 ** e)) 
        e: e + 8
    ] 
    d
] 
tuple-to-decimal: func [t [tuple!] /local e d] [
    t: head reverse to-binary t 
    e: 0 d: 0 
    forall t [
        d: d + (t/1 * (2 ** e)) 
        e: e + 8
    ] 
    d
] 
to-ieee64f: func [
    "Conversion of number to IEEE (Flash byte order)" 
    value [number!] 
    /local tmp
] [
    insert tail tmp: third make struct! [f [double]] reduce [value] copy/part tmp 4 
    return remove/part tmp 4
] 
from-ieee64f: func [
    "Conversion of number from IEEE (Flash byte order)" 
    bin [binary!] 
    /local tmp
] [
    change third tmp: make struct! [f [double]] [0] remove/part head insert tail bin: copy bin copy/part bin 4 4 
    tmp/f
] 
from-ieee64: func [
    "Conversion of number from IEEE" 
    bin [binary!] 
    /local tmp
] [
    change third tmp: make struct! [f [double]] [0] bin 
    tmp/f
] 
comment "---- end of RS include %binary-conversions.r ----" 
swf-parser: make stream-io [
    tagId: tagLength: tagData: upd: none 
    store?: false 
    replaced-ids: make block! 200 
    imported-names: make block! 200 
    imported-labels: make block! 50 
    imported-frames: 0 
    wasDefineSceneAndFrameLabelDataTag: false 
    export-dir: none 
    write-tag: func [
        "Writes the SWF-TAG to outBuffer" 
        id [integer!] "Tag ID" 
        data [binary!] "Tag data block" 
        /local len
    ] [
        either any [
            62 < len: length? data 
            not none? find [2 20 34 36 37 48] id
        ] [
            writeUI16 (63 or (id * 64)) 
            writeUI32 len 
            writeBytes data
        ] [
            writeUI16 (len or (id * 64)) 
            writeBytes data
        ]
    ] 
    parse-swf-header: func [/local sig tmp] [
        sig: readBytes 3 
        case [
            sig = #{465753} [
                swf/header/version: readUI8 
                readUI32
            ] 
            sig = #{435753} [
                swf/header/version: readUI8 
                if error? set/any 'err try [inBuffer: as-binary decompress skip (join inBuffer (readBytes 4)) 4] [
                    clear tmp 
                    recycle 
                    print "Cannot decompress the data:(" 
                    probe disarm err 
                    halt
                ]
            ] 
            true [
                print "Illegal swf header!" 
                halt
            ]
        ] 
        swf/header/frame-size: readRect 
        byteAlign 
        swf/header/frame-rate: to integer! readBytes 2 
        swf/header/frame-count: readUI16
    ] 
    open-swf-stream: func [swf-file [file! url! string!] "the SWF source file" /local f] [
        if string? swf-file [swf-file: to-rebol-file swf-file] 
        unless swf-file [
            swf-file: either empty? swf-file: ask "SWF file:" [%new.swf] [
                either "http://" = copy/part swf-file 7 [to-url swf-file] [to-file swf-file]
            ]
        ] 
        unless exists? swf-file [
            f: join swf-file ".swf" 
            either exists? f [swf-file: f] [print ["Cannot found the file" swf-file "!"]]
        ] 
        swf: make object! [
            file: swf-file 
            header: make object! [version: frame-size: frame-rate: frame-count: none] 
            data: copy []
        ] 
        read/binary swf-file
    ] 
    foreach-swf-tag: func [action /local tagAndLength] [
        bind action 'tagAndLength 
        while [not tail? inBuffer] [
            tagAndLength: readUI16 
            tagId: to integer! ((65472 and tagAndLength) / (2 ** 6)) 
            tagLength: tagAndLength and 63 
            if tagLength = 63 [tagLength: readUI32] 
            tagData: either tagLength > 0 [readBytes tagLength] [make binary! 0] 
            do action
        ]
    ] 
    set 'extract-swf-tags func [
        "Returns block of specified SWF tags" 
        swf-file [file! url! string!] "the SWF source file" 
        tagids [block!] "Tag IDs to extract" 
        /local result
    ] [
        result: copy [] 
        setStreamBuffer swf-stream: open-swf-stream swf-file 
        if error? set/any 'err try [
            parse-swf-header 
            foreach-swf-tag [
                if find tagids tagId [
                    repend result [tagId tagData]
                ]
            ]
        ] [
            throw err
        ] 
        result
    ] 
    readSWFTags: func [swfTagsStream /local storeBuffer results onlyTagIds] [
        storeBuffer: reduce [inBuffer availableBits bitBuffer] 
        setStreamBuffer swfTagsStream 
        results: copy [] 
        onlyTagIds: swf-tag-parser/onlyTagIds 
        swf-tag-parser/spriteLevel: swf-tag-parser/spriteLevel + 1 
        foreach-swf-tag [
            tagId 
            if any [
                none? onlyTagIds 
                find onlyTagIds tagId
            ] [
                insert/only tail results reduce [
                    tagId 
                    parse-swf-tag tagId tagData
                ]
            ]
        ] 
        inBuffer: storeBuffer/1 
        availableBits: storeBuffer/2 
        bitBuffer: storeBuffer/3 
        clear storeBuffer 
        swf-tag-parser/spriteLevel: swf-tag-parser/spriteLevel - 1 
        results
    ] 
    importSWFTags: func [swfTagsStream /local storeBuffer results importedResult] [
        importedResult: make binary! 20000 
        storeBuffer: reduce [inBuffer availableBits bitBuffer] 
        setStreamBuffer swfTagsStream 
        swf-tag-parser/spriteLevel: swf-tag-parser/spriteLevel + 1 
        while [not tail? inBuffer] [
            tagStart: index? inBuffer 
            tagAndLength: readUI16 
            tagId: to integer! ((65472 and tagAndLength) / (2 ** 6)) 
            tagLength: tagAndLength and 63 
            if tagLength = 63 [tagLength: readUI32] 
            tagData: either tagLength > 0 [readBytes tagLength] [make binary! 0] 
            insert tail importedResult import-swf-tag tagId tagData
        ] 
        inBuffer: storeBuffer/1 
        availableBits: storeBuffer/2 
        bitBuffer: storeBuffer/3 
        clear storeBuffer 
        swf-tag-parser/spriteLevel: swf-tag-parser/spriteLevel - 1 
        importedResult
    ] 
    rescaleSWFTags: func [swfTagsStream /local storeBuffer results rescaledResult] [
        rescaledResult: make binary! 20000 
        storeBuffer: reduce [inBuffer availableBits bitBuffer head swf-tag-parser/outBuffer] 
        setStreamBuffer swfTagsStream 
        swf-tag-parser/outSetStreamBuffer copy #{} 
        swf-tag-parser/spriteLevel: swf-tag-parser/spriteLevel + 1 
        while [not tail? inBuffer] [
            tagStart: index? inBuffer 
            tagAndLength: readUI16 
            tagId: to integer! ((65472 and tagAndLength) / (2 ** 6)) 
            tagLength: tagAndLength and 63 
            if tagLength = 63 [tagLength: readUI32] 
            tagData: either tagLength > 0 [readBytes tagLength] [make binary! 0] 
            insert tail rescaledResult rescale-swf-tag tagId tagData
        ] 
        inBuffer: storeBuffer/1 
        availableBits: storeBuffer/2 
        bitBuffer: storeBuffer/3 
        swf-tag-parser/outBuffer: tail storeBuffer/4 
        clear storeBuffer 
        swf-tag-parser/spriteLevel: swf-tag-parser/spriteLevel - 1 
        rescaledResult
    ] 
    set 'exam-swf func [
        "Examines SWF file structure" [catch] 
        /file swf-file [file! url! string!] "the SWF source file" 
        /quiet "No visible output" 
        /into out-file [file!] 
        /store {If you want to store parsed tags in the swf/data block} 
        /only onlyTagIds [block!] 
        /parseActions pActions [block! hash!] 
        /local err sysprint sysprin action
    ] [
        if all [file string? swf-file] [swf-file: to-rebol-file swf-file] 
        store?: store 
        setStreamBuffer open-swf-stream swf-file 
        if error? set/any 'err try [
            prin "Searching the binary file... " 
            parse-swf-header 
            print "-------------------------" 
            probe swf/header 
            swf-tag-parser/verbal?: not quiet 
            swf-tag-parser/output-file: either into [out-file: open/new/write out-file] [none] 
            swf-tag-parser/parseActions: either parseActions [pActions] [swfTagParseActions] 
            swf-tag-parser/onlyTagIds: onlyTagIds 
            swf-tag-parser/swfVersion: swf/header/version 
            foreach-swf-tag [
                if any [
                    none? onlyTagIds 
                    find onlyTagIds tagId
                ] [
                    if store [repend/only swf/data [tagId tagData]] 
                    parse-swf-tag tagId tagData
                ]
            ]
        ] [
            clear head inBuffer 
            error? try [close swf-tag-parser/output-file] 
            recycle 
            throw err
        ] 
        clear head inBuffer inBuffer: none 
        recycle 
        error? try [close out-file] 
        swf
    ] 
    set 'import-swf func [
        {Reads SWF file, changes all IDs in the file not to conflict with given existing IDs and returns the new binary (without header)} 
        [catch] swf-file [file! url! string!] "the SWF source file" 
        used-tag-ids [block!] 
        init-depth [integer!] 
        /except except-tag-ids [block!] 
        /local importedSWF tagStart tagAndLength tagLength importedTags importedDict importedResult importedLabels importedFrames
    ] [
        clear replaced-ids 
        clear imported-names 
        clear imported-labels 
        importedFrames: 0 
        importedTags: make block! 2000 
        importedDict: make binary! 1000000 
        importedCtrl: make binary! 200000 
        importedResult: copy [] 
        tagsStartIndex: 0 
        if all [string? swf-file] [swf-file: to-rebol-file swf-file] 
        setStreamBuffer open-swf-stream swf-file 
        if error? set/any 'err try [
            parse-swf-header 
            swf-tag-parser/parseActions: swfTagImportActions 
            swf-tag-parser/swfVersion: swf/header/version 
            swf-tag-parser/used-ids: used-tag-ids 
            swf-tag-parser/init-depth: init-depth 
            tagsStartIndex: index? inBuffer 
            while [not tail? inBuffer] [
                tagStart: index? inBuffer 
                tagAndLength: readUI16 
                tagId: to integer! ((65472 and tagAndLength) / 64) 
                tagLength: tagAndLength and 63 
                if tagLength = 63 [tagLength: readUI32] 
                tagData: either tagLength > 0 [readBytes tagLength] [make binary! 0] 
                case [
                    find [65 69 77 9] tagId [] 
                    find [0 1 4 5 12 15 18 19 26 28 43 45 59 70 76 82 89] tagId [
                        insert tail importedCtrl import-swf-tag tagId tagData 
                        if tagId = 1 [
                            repend importedResult [copy importedDict copy importedCtrl] 
                            clear importedCtrl 
                            clear importedDict 
                            importedFrames: importedFrames + 1
                        ]
                    ] 
                    tagId = 86 [
                        unless wasDefineSceneAndFrameLabelDataTag [
                            insert tail importedDict import-swf-tag tagId tagData 
                            wasDefineSceneAndFrameLabelDataTag: true
                        ]
                    ] 
                    true [
                        insert tail importedDict import-swf-tag tagId tagData
                    ]
                ]
            ] 
            repend importedResult [copy importedDict copy importedCtrl] 
            clear importedCtrl 
            clear importedDict
        ] [
            clear importedCtrl 
            clear importedDict 
            clear importedResult 
            clear head inBuffer 
            recycle 
            throw err
        ] 
        imported-frames: importedFrames 
        recycle 
        print ["FRAMES:" imported-frames] 
        reduce [
            importedResult 
            swf-tag-parser/last-depth 
            imported-names 
            imported-labels 
            imported-frames
        ]
    ] 
    set 'remove-blurs-from-swf func [
        {Reads SWF file, removes all blur effects and returns the new binary (without header)} 
        [catch] swf-file [file! url! string!] "the SWF source file" 
        /into out-file [file! url!] 
        /local importedSWF tagStart tagAndLength tagLength importedDict importedResult importedLabels outBuffer
    ] [
        clear replaced-ids 
        clear imported-names 
        clear imported-labels 
        importedDict: make binary! 1000000 
        importedCtrl: make binary! 200000 
        importedResult: copy #{} 
        tagsStartIndex: 0 
        if all [string? swf-file] [swf-file: to-rebol-file swf-file] 
        setStreamBuffer open-swf-stream swf-file 
        if error? set/any 'err try [
            parse-swf-header 
            swf-tag-parser/parseActions: swfTagImportActions 
            swf-tag-parser/swfVersion: swf/header/version 
            swf-tag-parser/used-ids: copy [] 
            swf-tag-parser/init-depth: 0 
            tagsStartIndex: index? inBuffer 
            while [not tail? inBuffer] [
                tagStart: index? inBuffer 
                tagAndLength: readUI16 
                tagId: to integer! ((65472 and tagAndLength) / 64) 
                tagLength: tagAndLength and 63 
                if tagLength = 63 [tagLength: readUI32] 
                tagData: either tagLength > 0 [readBytes tagLength] [make binary! 0] 
                case [
                    find [0 1 4 5 12 15 18 19 26 28 43 45 59 70 76 82 89] tagId [
                        insert tail importedCtrl import-swf-tag tagId tagData 
                        if tagId = 1 [
                            insert tail importedResult importedDict 
                            insert tail importedResult importedCtrl 
                            clear importedCtrl 
                            clear importedDict
                        ]
                    ] 
                    tagId = 86 [
                        unless wasDefineSceneAndFrameLabelDataTag [
                            insert tail importedDict import-swf-tag tagId tagData 
                            wasDefineSceneAndFrameLabelDataTag: true
                        ]
                    ] 
                    true [
                        insert tail importedDict import-swf-tag tagId tagData
                    ]
                ]
            ] 
            insert tail importedResult importedDict 
            insert tail importedResult importedCtrl 
            clear importedCtrl 
            clear importedDict
        ] [
            clear importedCtrl 
            clear importedDict 
            clear importedResult 
            clear head inBuffer 
            recycle 
            throw err
        ] 
        outBuffer: create-swf/rate/version/compressed 
        as-pair (SWF/HEADER/FRAME-SIZE/2 / 20) (SWF/HEADER/FRAME-SIZE/4 / 20) 
        importedResult 
        swf/header/frame-rate 
        swf/header/version 
        true 
        if into [write/binary out-file outBuffer] 
        recycle 
        outBuffer
    ] 
    set 'swf-to-rswf func [
        "Converts SWF into RSWF" [catch] 
        swf-file [file! url! string!] "the SWF source file" 
        /into out-file [file!] 
        /local err sysprint sysprin action names-to-ids swfDir swfName
    ] [
        if string? swf-file [swf-file: to-rebol-file swf-file] 
        swfName: copy find/last/tail swf-file #"/" 
        unless swfDir: export-dir [
            swfDir: either url? swf-file [
                what-dir
            ] [first split-path swf-file]
        ] 
        swfDir: rejoin [swfDir swfName %_export/] 
        if not exists? swfDir [make-dir/deep swfDir] 
        setStreamBuffer open-swf-stream swf-file 
        if error? set/any 'err try [
            prin "Searching the binary file... " 
            parse-swf-header 
            print "-------------------------" 
            probe swf/header 
            print stats 
            swf-tag-parser/names-to-ids: copy [] 
            swf-tag-parser/JPEGTables: none 
            swf-tag-parser/swfDir: swfDir 
            swf-tag-parser/swfName: swfName 
            swf-tag-parser/output-file: either into [out-file: open/new/write out-file] [none] 
            swf-tag-parser/parseActions: swfTagToRSWFActions 
            swf-tag-parser/swfVersion: swf/header/version 
            foreach-swf-tag [
                swf-tag-to-rswf tagId tagData
            ]
        ] [
            clear head inBuffer 
            error? try [close swf-tag-parser/output-file] 
            recycle 
            throw err
        ] 
        clear head inBuffer inBuffer: none 
        recycle 
        error? try [close out-file] 
        swf
    ] 
    set 'swf-optimize func [
        "Optimize SWF file" 
        swf-file [file! url! string!] "the SWF source file" 
        /into out-file [file!] 
        /local origBytes noBBids err sysprint sysprin action names-to-ids swfDir swfName result swfTags ext bmp crops w h x y md5 noCrops bin1 bin2 shapeStyles
    ] [
        if string? swf-file [swf-file: to-rebol-file swf-file] 
        swfName: copy find/last/tail swf-file #"/" 
        unless swfDir: export-dir [
            swfDir: either url? swf-file [
                what-dir
            ] [first split-path swf-file]
        ] 
        swfDir: rejoin [swfDir swfName %_export/] 
        if not exists? swfDir [make-dir/deep swfDir] 
        setStreamBuffer open-swf-stream swf-file 
        clearOutBuffer 
        frames: 0 
        swfTags: copy [] 
        swfBitmaps: copy [] 
        swfBitmapFills: copy [] 
        noCrops: copy [] 
        shapeStyles: copy [] 
        noBBids: copy [] 
        origBytes: 0 
        if error? set/any 'err try [
            prin "Searching the binary file... " 
            parse-swf-header 
            origBytes: length? inBuffer 
            print "-------------------------" 
            probe swf/header 
            print stats 
            swf-tag-parser/names-to-ids: copy [] 
            swf-tag-parser/JPEGTables: none 
            swf-tag-parser/swfDir: swfDir 
            swf-tag-parser/swfName: swfName 
            swf-tag-parser/parseActions: swfTagOptimizeActions 
            swf-tag-parser/swfVersion: swf/header/version 
            foreach-swf-tag [
                repend swfTags [tagId tagData] 
                switch tagId [
                    6 20 21 36 [
                        probe md5: enbase/base checksum/method skip tagData 2 'md5 16 
                        result: swf-tag-optimize tagId tagData 
                        swf-tag-parser/export-image-tag tagId md5 result 
                        append result md5 
                        change/only back tail swfTags copy/deep result 
                        append swfBitmaps result/1 
                        repend/only swfBitmaps head change result tagId
                    ] 
                    35 [
                        probe md5: enbase/base checksum/method skip tagData 2 'md5 16 
                        result: swf-tag-optimize tagId tagData 
                        swf-tag-parser/export-image-tag tagId md5 result 
                        swf-tag-parser/export-image-tag/alpha tagId md5 result 
                        append result md5 
                        change/only back tail swfTags copy/deep result 
                        append swfBitmaps result/1 
                        repend/only swfBitmaps head change result tagId
                    ] 
                    2 22 32 67 83 [
                        if result: swf-tag-optimize tagId tagData [
                            append swfBitmapFills result/1 
                            append append shapeStyles result/2 result/3
                        ]
                    ] 1 [frames: frames + 1] 
                    56 [
                        print ["EXPORT"] 
                        foreach [id name] swf-tag-optimize tagId tagData [
                            if find/part name #{6E6F4242} 4 [
                                append noBBids id
                            ]
                        ]
                    ]
                ]
            ]
        ] [
            clear head inBuffer 
            clear head swfTags 
            error? try [close swf-tag-parser/output-file] 
            recycle 
            throw err
        ] 
        print ["BITMAPS:" (length? swfBitmaps) / 2] 
        print ["BITMAP FILLS" mold swfBitmapFills] 
        crops: copy [] 
        mat: func [x y a b c d tx ty /local nx ny] [
            nx: (x * a) + (y * c) + tx 
            ny: (x * b) + (y * d) + ty 
            reduce [nx ny]
        ] 
        xxx: copy [] 
        foreach [id minx miny maxx maxy sx sy rx ry tx ty] swfBitmapFills [
            unless find noCrops id [
                unless rx [rx: 0] 
                unless ry [ry: 0] 
                minx: minx / 20 
                miny: miny / 20 
                maxx: maxx / 20 
                maxy: maxy / 20 
                a: sx / 20 
                c: ry / 20 
                b: rx / 20 
                d: sy / 20 
                tx: tx / 20 
                ty: ty / 20 
                tmp: (a * d) - (b * c) 
                ai: d / tmp 
                bi: - b / tmp 
                ci: - c / tmp 
                di: a / tmp 
                txi: ((c * ty) - (d * tx)) / tmp 
                tyi: - ((a * ty) - (b * tx)) / tmp 
                xA: (minx * ai) + (miny * ci) + txi 
                yA: (minx * bi) + (miny * di) + tyi 
                xB: (maxx * ai) + (miny * ci) + txi 
                yB: (maxx * bi) + (miny * di) + tyi 
                xC: (maxx * ai) + (maxy * ci) + txi 
                yC: (maxx * bi) + (maxy * di) + tyi 
                xD: (minx * ai) + (maxy * ci) + txi 
                yD: (minx * bi) + (maxy * di) + tyi 
                nminx: to-integer min xD min xC min xA xB 
                nmaxx: to-integer max xD max xC max xA xB 
                nminy: to-integer min yD min yC min yA yB 
                nmaxy: to-integer max yD max yC max yA yB 
                x: xc: round/floor nminx 
                y: yc: round/floor nminy 
                w: round/ceiling (nmaxx - x) 
                h: round/ceiling (nmaxy - y) 
                if bmp: select swfBitmaps id [
                    imgsz: swf-tag-parser/get-image-size-from-tagData bmp 
                    if xc < 0 [xc: imgsz/1 + (xc // imgsz/1)] 
                    if yc < 0 [yc: imgsz/2 + (yc // imgsz/2)] 
                    if xc > imgsz/1 [xc: xc // imgsz/1] 
                    if yc > imgsz/2 [yc: yc // imgsz/2] 
                    if xc > 0 [x: x - 1 xc: xc - 1 w: w + 1] 
                    if yc > 0 [y: y - 1 yc: yc - 1 h: h + 1] 
                    if (xc + w) < imgsz/1 [w: w + 1] 
                    if (yc + h) < imgsz/2 [h: h + 1]
                ] 
                print ["crop:" x y w h tab "===" tab nminx nminy nmaxx nmaxy] 
                either tmp: select xxx id [
                    repend tmp [xc yc (xc + w) (yc + h) x y]
                ] [
                    append xxx id 
                    repend/only xxx [xc yc xc + w yc + h x y]
                ] 
                either none? tmp: select crops id [
                    append crops id 
                    repend/only crops [xc yc xc + w yc + h x y]
                ] [
                    change tmp reduce [
                        min tmp/1 xc 
                        min tmp/2 yc 
                        max tmp/3 (xc + w) 
                        max tmp/4 (yc + h) 
                        min tmp/5 x 
                        min tmp/6 y
                    ]
                ] 
                if error? try [md5: last select swfBitmaps id] [md5: none] 
                print ["BMP" id md5 w h as-pair x y as-pair x + w y + h]
            ]
        ] 
        print "============CROP==============" 
        probe xxx 
        save %crops.rb xxx 
        comment {^-^-
^-^-^-^-
^-^-foreach [id szs] xxx [
^-^-^-crops: copy []

^-^-^-foreach [xc1 yc1 xc2 yc2 x y] szs [
^-^-^-^-joined?: false
^-^-^-^-
^-^-^-^-while [not tail? crops] [
^-^-^-^-^-;probe crops
^-^-^-^-^-set [cx1 cy1 cx2 cy2 cx cy] crops
^-^-^-^-^-print ["?xc" xc1 yc1 xc2 yc2 x y]
^-^-^-^-^-print ["?cx" cx1 cy1 cx2 cy2 cx cy]
^-^-^-^-^-print ["cx1 <= xc1" cx1 <= xc1]
^-^-^-^-^-print ["cx2 <= xc2" cx2 <= xc2]
^-^-^-^-^-print ["cy1 <= yc1" cy1 <= yc1]
^-^-^-^-^-print ["cy2 <= yc2" cy2 <= yc2]
^-^-^-^-^-if any [
^-^-^-^-^-^-all [
^-^-^-^-^-^-^-cx1 <= xc1
^-^-^-^-^-^-^-cx2 >= xc1
^-^-^-^-^-^-^-cy1 <= yc1
^-^-^-^-^-^-^-cy2 >= yc1
^-^-^-^-^-^-]
^-^-^-^-^-^-all [
^-^-^-^-^-^-^-cx1 <= xc2
^-^-^-^-^-^-^-cx2 >= xc2
^-^-^-^-^-^-^-cy1 <= yc1
^-^-^-^-^-^-^-cy2 >= yc1
^-^-^-^-^-^-]
^-^-^-^-^-^-all [
^-^-^-^-^-^-^-cx1 <= xc1
^-^-^-^-^-^-^-cx2 >= xc1
^-^-^-^-^-^-^-cy1 <= yc2
^-^-^-^-^-^-^-cy2 >= yc2
^-^-^-^-^-^-]
^-^-^-^-^-^-all [
^-^-^-^-^-^-^-cx1 <= xc2
^-^-^-^-^-^-^-cx2 >= xc2
^-^-^-^-^-^-^-cy1 <= yc2
^-^-^-^-^-^-^-cy2 >= yc2
^-^-^-^-^-^-]
^-^-^-^-^-^-
^-^-^-^-^-^-all [
^-^-^-^-^-^-^-xc1 <= cx1
^-^-^-^-^-^-^-xc2 >= cx1
^-^-^-^-^-^-^-yc1 <= cy1
^-^-^-^-^-^-^-yc2 >= cy1
^-^-^-^-^-^-]
^-^-^-^-^-^-all [
^-^-^-^-^-^-^-xc1 <= cx1
^-^-^-^-^-^-^-xc2 >= cx1
^-^-^-^-^-^-^-yc1 <= cy2
^-^-^-^-^-^-^-yc2 >= cy2
^-^-^-^-^-^-]
^-^-^-^-^-^-all [
^-^-^-^-^-^-^-xc1 <= cx2
^-^-^-^-^-^-^-xc2 >= cx2
^-^-^-^-^-^-^-yc1 <= cy1
^-^-^-^-^-^-^-yc2 >= cy1
^-^-^-^-^-^-]
^-^-^-^-^-^-all [
^-^-^-^-^-^-^-xc1 <= cx2
^-^-^-^-^-^-^-xc2 >= cx2
^-^-^-^-^-^-^-yc1 <= cy2
^-^-^-^-^-^-^-yc2 >= cy2
^-^-^-^-^-^-]
^-^-^-^-^-] [
^-^-^-^-^-^-;ask ""
^-^-^-^-^-^-change/part crops reduce [
^-^-^-^-^-^-^-min cx1 xc1
^-^-^-^-^-^-^-min cy1 yc1
^-^-^-^-^-^-^-max cx2 xc2
^-^-^-^-^-^-^-max cy2 yc2
^-^-^-^-^-^-^-min cx  x
^-^-^-^-^-^-^-min cy  y
^-^-^-^-^-^-] 6
^-^-^-^-^-^-joined?: true
^-^-^-^-^-^-break
^-^-^-^-^-] 
^-^-^-^-^-crops: skip crops 6
^-^-^-^-]
^-^-^-^-crops: head crops
^-^-^-^-unless joined? [
^-^-^-^-^-repend crops [xc1 yc1 xc2 yc2 x y]
^-^-^-^-]
^-^-^-]
^-^-^-probe crops
^-^-^-clear szs
^-^-^-insert szs crops
^-^-]
^-^-probe xxx
^-^-^-^-
^-^-cache-bmp-sizes: copy []
^-^-foreach [id szs] xxx [
^-^-^-if bmp: select swfBitmaps id [
^-^-^-^-print ["crop bitmap type:" bmp/1 last bmp]
^-^-^-^-ext: either find [20 36] bmp/1 [%.png][%.jpg]
^-^-^-^-size: swf-tag-parser/get-image-size-from-tagData bmp ;get-image-size rejoin [swfDir %tag35  %_ last bmp %.jpg]
^-^-^-^-
^-^-^-^-;test range for all szs
^-^-^-^-in-range?: true
^-^-^-^-foreach [xc1 yc1 xc2 yc2 x y] szs [
^-^-^-^-^-if any [
^-^-^-^-^-^-xc1 < 0
^-^-^-^-^-^-yc1 < 0
^-^-^-^-^-^-xc2 > size/x
^-^-^-^-^-^-yc2 > size/y
^-^-^-^-^-][
^-^-^-^-^-^-in-range?: false
^-^-^-^-^-^-append noCrops id
^-^-^-^-^-^-print ["!! Crop out of bounds!" xc1 yc1 xc2 yc2 "with size:" size]
^-^-^-^-^-^-clear szs
^-^-^-^-^-^-break
^-^-^-^-^-]
^-^-^-^-]
^-^-^-^-if in-range? [
^-^-^-^-^-repend cache-bmp-sizes [id size] 
^-^-^-^-^-probe szs
^-^-^-^-^-foreach [xc1 yc1 xc2 yc2 x y] szs [
^-^-^-^-^-^-switch bmp/1 [
^-^-^-^-^-^-^-35 [
^-^-^-^-^-^-^-^-
^-^-^-^-^-^-^-^-unless crop-images
^-^-^-^-^-^-^-^-^-reduce [
^-^-^-^-^-^-^-^-^-^-rejoin [swfDir %tag35  %_ last bmp %.jpg]
^-^-^-^-^-^-^-^-^-^-rejoin [swfDir %tag35  %_ last bmp %.png]
^-^-^-^-^-^-^-^-^-]
^-^-^-^-^-^-^-^-^-xc1
^-^-^-^-^-^-^-^-^-yc1
^-^-^-^-^-^-^-^-^-xc2 - xc1
^-^-^-^-^-^-^-^-^-yc2 - yc1
^-^-^-^-^-^-^-^-[
^-^-^-^-^-^-^-^-^-print ["!!!" id]
^-^-^-^-^-^-^-^-^-append noCrops id
^-^-^-^-^-^-^-^-]
^-^-^-^-^-^-^-^-^-
^-^-^-^-^-^-^-]
^-^-^-^-^-^-^-6 20 21 36 [
^-^-^-^-^-^-^-^-unless crop-images
^-^-^-^-^-^-^-^-^-reduce [
^-^-^-^-^-^-^-^-^-^-rejoin [swfDir %tag bmp/1  %_ last bmp ext]
^-^-^-^-^-^-^-^-^-]
^-^-^-^-^-^-^-^-^-xc1
^-^-^-^-^-^-^-^-^-yc1
^-^-^-^-^-^-^-^-^-xc2 - xc1
^-^-^-^-^-^-^-^-^-yc2 - yc1
^-^-^-^-^-^-^-^-[
^-^-^-^-^-^-^-^-^-print ["!!!" id]
^-^-^-^-^-^-^-^-^-append noCrops id
^-^-^-^-^-^-^-^-]
^-^-^-^-^-^-^-]
^-^-^-^-^-^-]
^-^-^-^-^-]
^-^-^-^-]
^-^-^-^-
^-^-^-]
^-^-]^-
^-^-probe xxx
^-^-ask "croping done"
^-^-} 
        foreach [id sizes] crops [
            if bmp: select swfBitmaps id [
                print ["crop bitmap type:" bmp/1 last bmp] 
                probe sizes 
                ext: either find [20 36] bmp/1 [%.png] [%.jpg] 
                switch bmp/1 [
                    35 [
                        unless crop-images 
                        reduce [
                            rejoin [swfDir %tag35 %_ last bmp %.jpg] 
                            rejoin [swfDir %tag35 %_ last bmp %.png]
                        ] 
                        sizes/1 
                        sizes/2 
                        sizes/3 - sizes/1 
                        sizes/4 - sizes/2 
                        [
                            print ["!!!" id] 
                            append noCrops id
                        ]
                    ] 
                    6 20 21 36 [
                        unless crop-images 
                        reduce [
                            rejoin [swfDir %tag bmp/1 %_ last bmp ext]
                        ] 
                        sizes/1 
                        sizes/2 
                        sizes/3 - sizes/1 
                        sizes/4 - sizes/2 
                        [
                            print ["!!!" id] 
                            append noCrops id
                        ]
                    ]
                ]
            ]
        ] 
        print "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" 
        probe noCrops: unique noCrops 
        probe crops 
        foreach id sort/reverse noCrops [
            print ["noCrop:" id] 
            if tmp: find crops id [
                print ["noCrop:" mold tmp/2] 
                remove/part tmp 2
            ]
        ] 
        probe crops 
        clear head inBuffer inBuffer: none 
        swf-tag-parser/parseActions: swfTagOptimizeActions2 
        swf-tag-parser/use-BB-optimization?: true 
        swf-tag-parser/data: context compose/only [
            crops: (crops) 
            shapeStyles: (shapeStyles) 
            noBBids: (noBBids) 
            shapeReduction: 0
        ] 
        print ["noBBids:" mold noBBids] 
        rob-parts: [
            "4C1447FA88E3FF7948EE17E488504B15" ["hlava_zboku1" 613x52] 
            "833CDDDC6E0E92A4CEB86DE946CE6D9C" ["hlava_zboku1" 613x52] 
            "44A588C3DFAE46757ABB53484BBEF4CE" ["hlava_zepredu" 584x80] 
            "83CAA93D0452AA443BA2C49F3C985DE0" ["hlava_zepredu" 584x80] 
            "CA72BBAAA141E4E8FBADBC77BC9F5BAF" ["hlava_zezadu" 597x82] 
            "C9DD1E9CD54DDF0703C1F6C90172496E" ["hlava_zezadu" 597x82] 
            "C8A1BBD44C99562860B7F9B373AE4361" ["rob_clanek1" 412x446] 
            "96304CC31FFD00FC38CB79E329785585" ["rob_clanek1" 412x446] 
            "4E979CAAC3A1286F8863E3A731ECBCFE" ["rob_clanek2" 416x462] 
            "18E09D32E378101A68FA52B18E1B5078" ["rob_clanek2" 416x462] 
            "3F789582ED9EB4E0132F0B2A2B3218E2" ["rob_clanek3" 414x483] 
            "D347F7A1183289093C48AA56FFECE305" ["rob_clanek3" 414x483] 
            "5666B12A1AD994D53422AD7FBF6FD210" ["rob_clanek4" 414x520] 
            "779DE1ADBC02C33F135CFCA332E9B38A" ["rob_clanek4" 414x520] 
            "7C185BFEF392BBFEE91D8BA958D94E87" ["rob_nohy" 410x516] 
            "8568E78B9DF61D95096CD66DCBC0D5E8" ["rob_nohy" 410x516] 
            "559FF962C35C61AE3098544A6ACCBFB3" ["rob_ruka" 176x445] 
            "C869CF3DAE5FA462133B4D9A7F8DE032" ["rob_ruka" 176x445]
        ] 
        rob-parts: [] 
        foreach [Id tagData] swfTags [
            tagId: id 
            switch/default tagId [
                21 [
                    either tmp: select crops tagData/1 [
                        write-tag 21 abin [
                            int-to-ui16 tagData/1 
                            read/binary rejoin [swfDir %tag21_ tagData/3 %_crop_ tmp/1 %x tmp/2 %_ (tmp/3 - tmp/1) %x (tmp/4 - tmp/2) %.jpg]
                        ]
                    ] [
                        write-tag 21 abin [
                            int-to-ui16 tagData/1 
                            tagData/2
                        ]
                    ]
                ] 
                35 [
                    either tmp: select crops tagData/1 [
                        either tmp2: select rob-parts last tagData [
                            either find swf-file %rob-include [
                                print ["Adding ExportAssets for" tmp2 as-pair tmp/1 tmp/2 mold tmp] 
                                file: rejoin [swfDir %tag35_ last tagData %_crop_ tmp/1 %x tmp/2 %_ (tmp/3 - tmp/1) %x (tmp/4 - tmp/2)] 
                                bin1: read/binary join file %.jpg 
                                bin2: load join file %.png 
                                write-tag 35 abin [
                                    int-to-ui16 tagData/1 
                                    int-to-ui32 length? bin1 
                                    bin1 
                                    head head remove/part tail compress bin2/alpha -4
                                ] 
                                write-tag 56 abin [
                                    #{0100} 
                                    int-to-ui16 tagData/1 
                                    tmp2/1 
                                    #{00}
                                ]
                            ] [
                                print ["Adding ImportAssets for" tmp2 "as" tagData/1 as-pair tmp/1 tmp/2] 
                                change/part skip tmp 4 reduce [tmp2/2/x tmp2/2/y] 2 
                                write-tag 71 abin [
                                    as-binary "00/11111100.011" 
                                    #{0001000100} 
                                    int-to-ui16 tagData/1 
                                    tmp2/1 
                                    #{00}
                                ]
                            ]
                        ] [
                            file: rejoin [swfDir %tag35_ last tagData %_crop_ tmp/1 %x tmp/2 %_ (tmp/3 - tmp/1) %x (tmp/4 - tmp/2)] 
                            bin1: read/binary join file %.jpg 
                            bin2: load join file %.png 
                            write-tag 35 abin [
                                int-to-ui16 tagData/1 
                                int-to-ui32 length? bin1 
                                bin1 
                                head head remove/part tail compress bin2/alpha -4
                            ]
                        ]
                    ] [
                        write-tag 35 abin [
                            int-to-ui16 tagData/1 
                            int-to-ui32 length? tagData/2 
                            tagData/2 
                            tagData/3
                        ]
                    ]
                ] 
                36 [
                    either tmp: select crops tagData/1 [
                        write-tag 36 abin [
                            int-to-ui16 tagData/1 
                            ImageCore/ARGB2BLL ImageCore/load rejoin [swfDir %tag36_ last tagData %_crop_ tmp/1 %x tmp/2 %_ (tmp/3 - tmp/1) %x (tmp/4 - tmp/2) %.png]
                        ]
                    ] [
                        write-tag 36 abin [
                            int-to-ui16 tagData/1 
                            ImageCore/ARGB2BLL ImageCore/load rejoin [swfDir %tag36_ last tagData %.png]
                        ]
                    ]
                ] 
                20 [
                    either tmp: select crops tagData/1 [
                        write-tag 20 abin [
                            int-to-ui16 tagData/1 
                            ImageCore/ARGB2BLL ImageCore/load rejoin [swfDir %tag20_ last tagData %_crop_ tmp/1 %x tmp/2 %_ (tmp/3 - tmp/1) %x (tmp/4 - tmp/2) %.png]
                        ]
                    ] [
                        write-tag 20 abin [
                            int-to-ui16 tagData/1 
                            ImageCore/ARGB2BLL ImageCore/load rejoin [swfDir %tag20_ last tagData %.png]
                        ]
                    ]
                ] 
                6 [
                    either tmp: select crops tagData/1 [
                        write-tag 6 abin [
                            int-to-ui16 tagData/1 
                            read/binary rejoin [swfDir %tag6_ last tagData %_crop_ tmp/1 %x tmp/2 %_ (tmp/3 - tmp/1) %x (tmp/4 - tmp/2) %.jpg]
                        ]
                    ] [
                        write-tag 6 abin [
                            int-to-ui16 tagData/1 
                            read/binary rejoin [swfDir %tag6_ last tagData %.jpg]
                        ]
                    ]
                ] 
                2 22 32 67 83 [
                    if result: swf-tag-optimize tagId tagData [
                        write-tag tagId result
                    ]
                ]
            ] [
                write-tag tagId tagData
            ]
        ] 
        print length? outBuffer: head outBuffer 
        rswf/frames: frames 
        print ["TOTAL REDUCTION:" origBytes - (length? head outBuffer) "bytes"] 
        outBuffer: create-swf/rate/version/compressed 
        as-pair (SWF/HEADER/FRAME-SIZE/2 / 20) (SWF/HEADER/FRAME-SIZE/4 / 20) 
        outBuffer 
        swf/header/frame-rate 
        swf/header/version 
        true 
        if into [write/binary out-file outBuffer] 
        recycle 
        print ["SHAPE REDUCTION:" negate swf-tag-parser/data/shapeReduction "bytes"] 
        outBuffer
    ] 
    set 'rescale-swf func [
        "Rescale SWF file" [catch] 
        swf-file [file! url! string!] "the SWF source file" 
        /into out-file [file!] 
        /compact "Uses bitmap packing" 
        /local err sysprint sysprin action swfDir swfName rescaleResult frames px py swfTags tmp images-to-compact
    ] [
        frames: 0 
        rescaleResult: make binary! 20000 
        tagsStartIndex: 0 
        if all [string? swf-file] [swf-file: to-rebol-file swf-file] 
        swfName: copy find/last/tail swf-file #"/" 
        unless swfDir: export-dir [
            swfDir: either url? swf-file [
                what-dir
            ] [first split-path swf-file]
        ] 
        probe swfDir: rejoin [swfDir swfName %_export/] 
        px: to-integer (swf-tag-parser/rswf-rescale-index-x * 100) 
        py: to-integer (swf-tag-parser/rswf-rescale-index-y * 100) 
        unless exists? scDir: rejoin [swfDir %_sc either px = py [px] [rejoin [px "x" py]] #"/"] [
            make-dir/deep scDir
        ] 
        setStreamBuffer open-swf-stream probe swf-file 
        if error? set/any 'err try [
            parse-swf-header 
            swf-tag-parser/parseActions: swfTagRescaleActions 
            swf-tag-parser/swfVersion: swf/header/version 
            swf-tag-parser/swfDir: swfDir 
            swf-tag-parser/swfName: swfName 
            tagsStartIndex: index? inBuffer 
            either compact [
                swfTags: copy [] 
                images-to-compact: context [
                    jpeg3: copy [] 
                    jpeg2: copy []
                ] 
                swf-tag-parser/parseActions: swfTagParseImages 
                foreach-swf-tag [
                    repend swfTags [tagId tagData] 
                    switch tagId [
                        6 21 [
                            md5: enbase/base checksum/method skip tagData 2 'md5 16 
                            with swf-tag-parser [
                                setStreamBuffer tagData 
                                clearOutBuffer 
                                tmp: switch tagId [
                                    21 [parse-DefineBitsJPEG2] 
                                    6 [parse-DefineBits]
                                ] 
                                file: export-image-tag tagId md5 tmp 
                                repend images-to-compact/jpeg3 [
                                    get-image-size file 
                                    reduce [tmp/1 file]
                                ]
                            ]
                        ] 
                        6 20 21 36 [
                        ] 
                        35 [
                            md5: enbase/base checksum/method skip tagData 2 'md5 16 
                            with swf-tag-parser [
                                setStreamBuffer tagData 
                                clearOutBuffer 
                                tmp: parse-DefineBitsJPEG3 
                                file: export-image-tag tagId md5 tmp 
                                repend images-to-compact/jpeg3 [
                                    get-image-size file 
                                    reduce [tmp/1 file]
                                ]
                            ]
                        ] 
                        8 [with swf-tag-parser [JPEGTables: parse-JPEGTables]]
                    ]
                ] 
                unless empty? images-to-compact/jpeg3 [
                    maxpair: 0x0 
                    foreach [size id] images-to-compact/jpeg3 [
                        maxpair: max maxpair size
                    ] 
                    maxi: max maxpair/x maxpair/y 
                    size: case [
                        maxi < 64 [64x64] 
                        maxi < 128 [128x128] 
                        maxi < 256 [256x256] 
                        maxi < 512 [512x512] 
                        true [1024x1024]
                    ] 
                    while [not empty? second result: rectangle-pack images-to-compact/jpeg3 size] [
                        if size/x >= 1024 [
                            print "images too big to fit in one bmp" 
                            ask "" 
                            break
                        ] 
                        size: size * 2
                    ] 
                    ?? images-to-compact 
                    probe result 
                    combine-files result/1 size %/f/test.jpg 
                    combine-files result/1 size %/f/test.png 
                    ask ""
                ]
            ] [
                while [not tail? inBuffer] [
                    tagStart: index? inBuffer 
                    tagAndLength: readUI16 
                    tagId: to integer! ((65472 and tagAndLength) / (2 ** 6)) 
                    tagLength: tagAndLength and 63 
                    if tagLength = 63 [tagLength: readUI32] 
                    tagData: either tagLength > 0 [readBytes tagLength] [make binary! 0] 
                    insert tail rescaleResult rescale-swf-tag tagId tagData 
                    if tagId = 1 [
                        frames: frames + 1
                    ]
                ]
            ]
        ] [
            clear head inBuffer 
            recycle 
            throw err
        ] 
        rswf/frames: frames 
        rescaleResult: create-swf/rate/version/compressed 
        as-pair (swf-tag-parser/rsci-x SWF/HEADER/FRAME-SIZE/2 / 20) (swf-tag-parser/rsci-y SWF/HEADER/FRAME-SIZE/4 / 20) 
        rescaleResult 
        swf/header/frame-rate 
        swf/header/version 
        true 
        if into [write/binary out-file rescaleResult] 
        recycle 
        rescaleResult
    ] 
    set 'combine-swf-bmps func [
        {Tries to pack bitmaps into more compact texture map(s)} 
        swf-file [file! url! string!] "the SWF source file" 
        /into out-file [file!] 
        /compact "Uses bitmap packing" 
        /local err sysprint sysprin action swfDir swfName rescaleResult frames px py swfTags 
        tmp images-to-compact file md5 maxpair maxi round-to-pow2
    ] [
        frames: 0 
        tagsStartIndex: 0 
        if all [string? swf-file] [swf-file: to-rebol-file swf-file] 
        swfName: copy find/last/tail swf-file #"/" 
        unless swfDir: export-dir [
            swfDir: either url? swf-file [
                what-dir
            ] [first split-path swf-file]
        ] 
        round-to-pow2: func [v /local p] [repeat i 12 [if v <= (p: 2 ** i) [return p]] none] 
        remove-img-with-id: func [imgs id] [
            while [not tail? imgs] [
                if id = imgs/2/1 [
                    remove/part imgs 2 
                    break
                ] 
                imgs: skip imgs 2
            ] 
            imgs: head imgs
        ] 
        probe swfDir: rejoin [swfDir swfName %_export/] 
        if not exists? swfDir [make-dir/deep swfDir] 
        setStreamBuffer open-swf-stream probe swf-file 
        clearOutBuffer 
        if error? set/any 'err try [
            parse-swf-header 
            swf-tag-parser/parseActions: swfTagRescaleActions 
            swf-tag-parser/swfVersion: swf/header/version 
            swf-tag-parser/swfDir: swfDir 
            swf-tag-parser/swfName: swfName 
            tagsStartIndex: index? inBuffer 
            swfTags: copy [] 
            images-to-compact: context [
                jpeg3: copy [] 
                jpeg2: copy []
            ] 
            swf-tag-parser/parseActions: swfTagParseImages 
            foreach-swf-tag [
                repend swfTags [tagId tagData] 
                switch tagId [
                    76 [
                        with swf-tag-parser [
                            setStreamBuffer tagData 
                            clearOutBuffer 
                            foreach [id name] parse-SymbolClass [
                                remove-img-with-id images-to-compact/jpeg3 id 
                                remove-img-with-id images-to-compact/jpeg2 id
                            ]
                        ]
                    ] 
                    56 [
                        with swf-tag-parser [
                            setStreamBuffer tagData 
                            clearOutBuffer 
                            tmp: parse-ExportAssets
                        ]
                    ] 
                    6 21 [
                        md5: enbase/base checksum/method skip tagData 2 'md5 16 
                        with swf-tag-parser [
                            setStreamBuffer tagData 
                            clearOutBuffer 
                            tmp: switch tagId [
                                21 [parse-DefineBitsJPEG2] 
                                6 [parse-DefineBits]
                            ] 
                            file: export-image-tag tagId md5 tmp 
                            repend images-to-compact/jpeg2 [
                                get-image-size file 
                                reduce [tmp/1 file]
                            ]
                        ]
                    ] 
                    6 20 21 36 [
                    ] 
                    35 [
                        md5: enbase/base checksum/method skip tagData 2 'md5 16 
                        with swf-tag-parser [
                            setStreamBuffer tagData 
                            clearOutBuffer 
                            tmp: parse-DefineBitsJPEG3 
                            file: export-image-tag tagId md5 tmp 
                            export-image-tag/alpha tagId md5 tmp 
                            size: get-image-size file 
                            print ["??" size file] 
                            if all [size/x <= 2048 size/y <= 2048] [
                                repend images-to-compact/jpeg3 [
                                    size 
                                    reduce [tmp/1 file]
                                ]
                            ] 
                            change/only back tail swfTags copy/deep tmp
                        ]
                    ]
                ]
            ] 
            swf-tag-parser/data: context compose/only [
                combined-bitmaps: copy [] 
                combined-bmp-id: none
            ] 
            if 10 < length? images-to-compact/jpeg3 [
                get-comp-size: func [data /local maxpair maxi] [
                    maxpair: 0x0 
                    foreach [size id] data [
                        maxpair: max maxpair size
                    ] 
                    maxpair/x: to-integer round-to-pow2 maxpair/x 
                    maxpair/y: to-integer round-to-pow2 maxpair/y 
                    print ["MAXPAIR:" maxpair] 
                    comment {
^-^-^-^-^-^-case [
^-^-^-^-^-^-^-maxi < 64   [  64x64  ]
^-^-^-^-^-^-^-maxi < 128  [ 128x128 ]
^-^-^-^-^-^-^-maxi < 256  [ 256x256 ]
^-^-^-^-^-^-^-maxi < 512  [ 512x512 ]
^-^-^-^-^-^-^-maxi < 1024 [1024x1024]
^-^-^-^-^-^-^-true        [2048x2048]
^-^-^-^-^-^-]} 
                    maxpair
                ] 
                probe size: get-comp-size images-to-compact/jpeg3 
                data-to-process: images-to-compact/jpeg3 
                while [
                    10 < length? data-to-process 
                    not empty? probe second result: rectangle-pack data-to-process size
                ] [
                    probe data-to-process 
                    either size/x > size/y [
                        size/y: size/y * 2
                    ] [size/x: size/x * 2] 
                    if any [
                        size/x > 1024 
                        size/y > 1024
                    ] [
                        print [{Coumponed bitmap would be too large! Excluding bitmap..} copy/part data-to-process 2] 
                        remove/part data-to-process 2 
                        size: get-comp-size images-to-compact/jpeg3 
                        size/x: min 1024 size/x 
                        size/y: min 1024 size/y
                    ] 
                    print reform ["new size:" size "^/[ENTER to CONTRINUE]"]
                ] 
                maxi: 0 
                foreach [pos size data] result/1 [
                    maxi: max maxi (pos/y + size/y)
                ] 
                md5: enbase/base checksum/method mold result/1 'md5 16 
                probe combined-bmp-file: rejoin [swfDir %combined_ md5] 
                swf-tag-parser/combine-files result/1 size join combined-bmp-file %.jpg 
                swf-tag-parser/combine-files result/1 size join combined-bmp-file %.png 
                foreach [pos size data] result/1 [
                    repend swf-tag-parser/data/combined-bitmaps [data/1 pos]
                ] 
                new-line/skip swf-tag-parser/data/combined-bitmaps true 2
            ] 
            swf-tag-parser/parseActions: swfTagOptimizeActions2 
            swf-tag-parser/use-BB-optimization?: false 
            if empty? swf-tag-parser/data/combined-bitmaps [print "No compacting needed" return none] 
            foreach [Id tagData] swfTags [
                tagId: id 
                switch/default tagId [
                    35 [
                        either tmp: select swf-tag-parser/data/combined-bitmaps tagData/1 [
                            unless swf-tag-parser/data/combined-bmp-id [
                                swf-tag-parser/data/combined-bmp-id: tagData/1 
                                bin1: read/binary join combined-bmp-file %.jpg 
                                bin2: load join combined-bmp-file %.png 
                                write-tag 35 abin [
                                    int-to-ui16 tagData/1 
                                    int-to-ui32 length? bin1 
                                    bin1 
                                    head head remove/part tail compress bin2/alpha -4
                                ]
                            ]
                        ] [
                            write-tag 35 abin [
                                int-to-ui16 tagData/1 
                                int-to-ui32 length? tagData/2 
                                tagData/2 
                                tagData/3
                            ]
                        ]
                    ] 
                    2 22 32 67 83 [
                        with swf-tag-parser [
                            setStreamBuffer tagData 
                            clearOutBuffer 
                            result: combine-updateShape
                        ] 
                        write-tag tagId result
                    ] 
                    56 [
                        print ["EXPORT"] 
                        with swf-tag-parser [
                            setStreamBuffer probe tagData 
                            clearOutBuffer 
                            id: readUI16 
                            probe name: readSTRING
                        ]
                    ]
                ] [
                    write-tag tagId tagData
                ]
            ]
        ] [
            clear head inBuffer 
            recycle 
            throw err
        ] 
        rswf/frames: swf/header/frame-count 
        rescaleResult: create-swf/rate/version/compressed 
        as-pair (SWF/HEADER/FRAME-SIZE/2 / 20) (SWF/HEADER/FRAME-SIZE/4 / 20) 
        head outBuffer 
        swf/header/frame-rate 
        swf/header/version 
        true 
        if into [write/binary out-file rescaleResult] 
        recycle 
        rescaleResult
    ] 
    comment {
#### Include: %parsers/swf-tags.r
#### Title:   "swfTags"
#### Author:  ""
----} 
    swfTagNames: make hash! [0 "end" 1 "showFrame" 
        2 "DefineShape" 
        3 "FreeCharacter" 
        4 "PlaceObject" 
        5 "RemoveObject" 
        6 "DefineBits (JPEG)" 
        7 "DefineButton" 
        8 "JPEGTables" 
        9 "setBackgroundColor" 
        10 "DefineFont" 
        11 "DefineText" 
        12 "DoAction Tag" 
        13 "DefineFontInfo" 
        14 "DefineSound" 
        15 "StartSound" 
        18 "SoundStreamHead" 
        17 "DefineButtonSound" 
        19 "SoundStreamBlock" 
        20 "DefineBitsLossless" 
        21 "DefineBitsJPEG2" 
        22 "DefineShape2" 
        23 "DefineButtonCxform" 
        24 "Protect" 
        26 "PlaceObject2" 
        28 "RemoveObject2" 
        31 "?GeneratorCommand?" 
        32 "DefineShape3" 
        33 "DefineText2" 
        34 "DefineButton2" 
        35 "DefineBitsJPEG3" 
        36 "DefineBitsLossless2" 
        37 "DefineEditText" 
        38 "DefineVideo" 
        39 "DefineSprite" 
        40 "SWT-CharacterName" 
        41 "SerialNumber" 
        42 "DefineTextFormat" 
        43 "FrameLabel" 
        45 "SoundStreamHead2" 
        46 "DefineMorphShape" 
        48 "DefineFont2" 
        49 "?GenCommand?" 
        50 "?DefineCommandObj?" 
        51 "?Characterset?" 
        52 "?FontRef?" 
        56 "ExportAssets" 
        57 "ImportAssets" 
        58 "EnableDebugger" 
        59 "DoInitAction" 
        60 "DefineVideoStream" 
        61 "VideoFrame" 
        62 "DefineFontInfo2" 
        63 "DebugID" 
        64 "ProtectDebug2" 
        65 "ScriptLimits" 
        66 "SetTabIndex" 
        67 "DefineShape4" 
        69 "FileAttributes" 
        70 "PlaceObject3" 
        71 "Import2" 
        73 "DefineAlignZones" 
        74 "CSMTextSettings" 
        75 "DefineFont3" 
        77 "MetaData" 
        78 "DefineScalingGrid" 
        72 "DoAction3" 
        76 "DoAction3StartupClass" 
        82 "DoAction3" 
        83 "DefineShape5" 
        84 "DefineMorphShape2" 
        86 "DefineSceneAndFrameLabelData" 
        87 "DefineBinaryData" 
        88 "DefineFontName" 
        89 "StartSound2" 
        90 "DefineBitsJPEG4" 
        91 "DefineFont4" 
        93 "Telemetry" 
        1023 "DefineBitsPtr"
    ] 
    swfTagParseActions: make hash! [
        2 [parse-DefineShape] 
        4 [parse-PlaceObject] 
        5 [parse-RemoveObject] 
        6 [parse-DefineBits] 
        7 [parse-DefineButton] 
        8 [parse-JPEGTables] 
        9 [to-tuple tagData] 
        10 [parse-DefineFont] 
        11 [parse-DefineText] 
        12 [parse-DoAction] 
        13 [parse-DefineFontInfo] 
        14 [parse-DefineSound] 
        15 [parse-StartSound] 
        17 [parse-DefineButtonSound] 
        18 [parse-SoundStreamHead] 
        19 [parse-SoundStreamBlock] 
        20 [parse-DefineBitsLossless] 
        21 [parse-DefineBitsJPEG2] 
        22 [parse-DefineShape] 
        23 [parse-DefineButtonCxform] 
        26 [parse-PlaceObject2] 
        28 [parse-RemoveObject2] 
        32 [parse-DefineShape] 
        33 [parse-DefineText] 
        34 [parse-DefineButton2] 
        35 [parse-DefineBitsJPEG3] 
        36 [parse-DefineBitsLossless] 
        37 [parse-DefineEditText] 
        39 [parse-DefineSprite] 
        40 [parse-SWT-CharacterName] 
        41 [parse-SerialNumber] 
        42 [parse-DefineTextFormat] 
        43 [probe as-string readSTRING] 
        45 [parse-SoundStreamHead] 
        46 [parse-DefineMorphShape] 
        48 [parse-DefineFont2] 
        56 [parse-ExportAssets] 
        57 [parse-ImportAssets] 
        58 [parse-EnableDebugger] 
        59 [parse-DoInitAction] 
        60 [parse-DefineVideoStream] 
        61 [parse-VideoFrame] 
        62 [parse-DefineFontInfo2] 
        63 [readRest] 
        64 [parse-EnableDebugger2] 
        65 [parse-ScriptLimits] 
        66 [parse-SetTabIndex] 
        67 [parse-DefineShape] 
        69 [parse-FileAttributes] 
        70 [parse-PlaceObject3] 
        71 [parse-ImportAssets2] 
        73 [parse-DefineAlignZones] 
        74 [parse-CSMTextSettings] 
        75 [parse-DefineFont2] 
        77 [as-string tagData] 
        78 [parse-DefineScalingGrid] 
        72 [parse-DoABC] 
        76 [parse-SymbolClass] 
        82 [parse-DoABC2] 
        83 [parse-DefineShape] 
        84 [parse-DefineMorphShape2] 
        86 [parse-DefineSceneAndFrameLabelData] 
        87 [parse-DefineBinaryData] 
        88 [parse-DefineFontName] 
        89 [parse-StartSound2] 
        90 [parse-DefineBitsJPEG4] 
        93 [tagData] 
        91 [parse-DefineFont4]
    ] 
    swfTagImportActions: make hash! [
        2 [import-Shape] 
        4 [replacedID] 
        5 [replacedID] 
        6 [import-or-reuse] 
        7 [import-DefineButton] 
        10 [import-or-reuse] 
        11 [import-DefineText] 
        13 [replacedID] 
        14 [import-or-reuse] 
        15 [replacedID] 
        17 [import-DefineButtonSound] 
        20 [import-or-reuse] 
        21 [import-or-reuse] 
        22 [import-Shape] 
        23 [replacedID] 
        26 [import-PlaceObject2] 
        32 [import-Shape] 
        33 [import-DefineText] 
        34 [import-DefineButton2] 
        35 [import-or-reuse] 
        36 [import-or-reuse] 
        37 [import-DefineEditText] 
        38 [import-or-reuse] 
        39 [import-DefineSprite] 
        40 [import-or-reuse] 
        42 [print "!! Importing unknown TAG DefineTextFormat" replacedID] 
        43 [append imported-labels probe as-string readSTRING] 
        46 [import-DefineMorphShape] 
        48 [import-or-reuse] 
        56 [import-ExportAssets] 
        57 [import-ImportAssets] 
        59 [replacedID] 
        60 [import-or-reuse] 
        61 [replacedID] 
        62 [replacedID] 
        67 [import-Shape] 
        70 [import-PlaceObject2] 
        71 [import-ImportAssets] 
        73 [replacedID] 
        74 [replacedID] 
        75 [import-or-reuse] 
        78 [replacedID] 
        76 [import-SymbolClass] 
        83 [import-Shape] 
        84 [import-DefineMorphShape2] 
        87 [import-or-reuse] 
        88 [replacedID] 
        90 [import-or-reuse] 
        91 [import-or-reuse]
    ] 
    swfTagParseImages: make hash! [
        6 [parse-DefineBits] 
        8 [
            JPEGTables: parse-JPEGTables 
            none
        ] 
        20 [parse-DefineBitsLossless] 
        21 [parse-DefineBitsJPEG2] 
        35 [parse-DefineBitsJPEG3] 
        36 [parse-DefineBitsLossless2] 
        90 [parse-DefineBitsJPEG4]
    ] 
    swfTagRescaleActions: make hash! [
        2 [rescale-Shape] 
        6 [rescale-DefineBits] 
        8 [
            JPEGTables: parse-JPEGTables 
            none
        ] 
        20 [rescale-DefineBitsLossless] 
        21 [rescale-DefineBitsJPEG2] 
        22 [rescale-Shape] 
        26 [rescale-PlaceObject2] 
        32 [rescale-Shape] 
        35 [rescale-DefineBitsJPEG3] 
        36 [rescale-DefineBitsLossless2] 
        39 [rescale-DefineSprite] 
        46 [rescale-DefineMorphShape] 
        67 [rescale-Shape] 
        70 [rescale-PlaceObject3] 
        83 [rescale-Shape] 
        84 [rescale-DefineMorphShape]
    ] 
    comment "---- end of include %parsers/swf-tags.r ----" 
    comment {
#### Include: %parsers/swf-to-rswf-actions.r
#### Title:   "SWF-to-RSWF tag Actions"
#### Author:  ""
----} 
    swfTagToRSWFActions: make hash! [0 ["end"] 1 ["showFrame"] 
        2 [
            convert-DefineShape
        ] 
        4 [parse-PlaceObject] 
        5 [parse-RemoveObject] 
        6 [
            tmp: parse-DefineBits 
            file: export-file 6 tmp/1 %.jpg (join JPEGTables skip tmp/2 2) 
            ajoin ["DefineBits " tmp/1 " " mold file]
        ] 
        7 [parse-DefineButton] 
        8 [
            JPEGTables: parse-JPEGTables 
            head remove/part skip tail JPEGTables -2 2 
            none
        ] 
        9 [ajoin ["Background " form to-tuple tagData]] 
        10 [parse-DefineFont] 
        11 [parse-DefineText] 
        12 [parse-DoAction] 
        13 [parse-DefineFontInfo] 
        14 [parse-DefineSound] 
        15 [parse-StartSound] 
        17 [parse-DefineButtonSound] 
        18 [parse-SoundStreamHead] 
        19 [parse-SoundStreamBlock] 
        20 [parse-DefineBitsLossless] 
        21 [parse-DefineBitsJPEG2] 
        22 [convert-DefineShape] 
        23 [parse-DefineButtonCxform] 
        26 [convert-PlaceObject2] 
        28 [parse-RemoveObject2] 
        32 [convert-DefineShape] 
        33 [parse-DefineText] 
        34 [parse-DefineButton2] 
        35 [parse-DefineBitsJPEG3] 
        36 [parse-DefineBitsLossless] 
        37 [parse-DefineEditText] 
        39 [convert-DefineSprite] 
        40 [parse-SWT-CharacterName] 
        41 [parse-SerialNumber] 
        42 [parse-DefineTextFormat] 
        43 [probe readSTRING] 
        45 [parse-SoundStreamHead] 
        46 [parse-DefineMorphShape] 
        48 [parse-DefineFont2] 
        56 [convert-ExportAssets] 
        57 [parse-ImportAssets] 
        58 [parse-EnableDebugger] 
        59 [parse-DoInitAction] 
        60 [parse-DefineVideoStream] 
        61 [parse-VideoFrame] 
        62 [parse-DefineFontInfo2] 
        64 [parse-EnableDebugger2] 
        65 [parse-ScriptLimits] 
        66 [parse-SetTabIndex] 
        67 [parse-DefineShape] 
        69 [ajoin ["FileAttributes " mold parse-FileAttributes]] 
        70 [probe parse-PlaceObject3] 
        71 [parse-ImportAssets2] 
        73 [parse-DefineAlignZones] 
        74 [parse-CSMTextSettings] 
        75 [parse-DefineFont2] 
        77 [as-string tagData] 
        78 [parse-DefineScalingGrid] 
        72 [parse-DoABC] 
        76 [parse-SymbolClass] 
        82 [parse-DoABC2] 
        83 [parse-DefineShape] 
        84 [parse-DefineMorphShape2] 
        86 [parse-DefineSceneAndFrameLabelData] 
        87 [parse-DefineBinaryData] 
        88 [parse-DefineFontName]
    ] 
    comment {---- end of include %parsers/swf-to-rswf-actions.r ----} 
    comment {
#### Include: %parsers/swf-optimize-actions.r
#### Title:   "SWF-optimize tag Actions"
#### Author:  ""
----} 
    swfTagOptimizeActions: make hash! [
        2 [
            optimize-detectBmpFillBounds
        ] 
        6 [parse-DefineBits] 
        7 [parse-DefineButton] 
        8 [
            JPEGTables: parse-JPEGTables 
            head remove/part skip tail JPEGTables -2 2 
            none
        ] 
        10 [parse-DefineFont] 
        11 [parse-DefineText] 
        12 [parse-DoAction] 
        13 [parse-DefineFontInfo] 
        14 [parse-DefineSound] 
        15 [parse-StartSound] 
        17 [parse-DefineButtonSound] 
        18 [parse-SoundStreamHead] 
        19 [parse-SoundStreamBlock] 
        20 [parse-DefineBitsLossless] 
        21 [parse-DefineBitsJPEG2] 
        22 [optimize-detectBmpFillBounds] 
        23 [parse-DefineButtonCxform] 
        28 [parse-RemoveObject2] 
        32 [optimize-detectBmpFillBounds] 
        33 [parse-DefineText] 
        34 [parse-DefineButton2] 
        35 [
            parse-DefineBitsJPEG3
        ] 
        36 [parse-DefineBitsLossless] 
        37 [parse-DefineEditText] 
        39 [convert-DefineSprite] 
        40 [parse-SWT-CharacterName] 
        41 [parse-SerialNumber] 
        42 [parse-DefineTextFormat] 
        43 [probe readSTRING] 
        45 [parse-SoundStreamHead] 
        46 [parse-DefineMorphShape] 
        48 [parse-DefineFont2] 
        56 [parse-ExportAssets] 
        57 [parse-ImportAssets] 
        58 [parse-EnableDebugger] 
        59 [parse-DoInitAction] 
        60 [parse-DefineVideoStream] 
        61 [parse-VideoFrame] 
        62 [parse-DefineFontInfo2] 
        64 [parse-EnableDebugger2] 
        65 [parse-ScriptLimits] 
        66 [parse-SetTabIndex] 
        67 [optimize-detectBmpFillBounds] 
        69 [ajoin ["FileAttributes " mold parse-FileAttributes]] 
        70 [parse-PlaceObject3] 
        71 [parse-ImportAssets2] 
        73 [parse-DefineAlignZones] 
        74 [parse-CSMTextSettings] 
        75 [parse-DefineFont2] 
        77 [as-string tagData] 
        78 [parse-DefineScalingGrid] 
        72 [parse-DoABC] 
        76 [parse-SymbolClass] 
        82 [parse-DoABC2] 
        83 [optimize-detectBmpFillBounds] 
        84 [parse-DefineMorphShape2] 
        86 [parse-DefineSceneAndFrameLabelData] 
        87 [parse-DefineBinaryData] 
        88 [parse-DefineFontName]
    ] 
    swfTagOptimizeActions2: make hash! [
        2 [optimize-updateShape] 
        22 [optimize-updateShape] 
        32 [optimize-updateShape] 
        67 [optimize-updateShape] 
        83 [optimize-updateShape]
    ] 
    comment {---- end of include %parsers/swf-optimize-actions.r ----} 
    comment {
#### Include: %swf-tag-parser.r
#### Title:   "swf-tag-parser"
#### Author:  ""
----} 
    swf-tag-parser: make stream-io [
        verbal?: on 
        output-file: none 
        parseActions: copy [] 
        tagSpecifications: copy [] 
        onlyTagIds: none 
        swfVersion: none 
        swfDir: swfName: none 
        tmp: none 
        file: none 
        data: none 
        used-ids: none 
        last-depth: none 
        init-depth: 0 
        tag-checksums: copy [] 
        set 'parse-swf-tag func [tagId tagData /local err action st st2] [
            swf-parser/tagId: tagId 
            either none? action: select parseActions tagId [
                result: none
            ] [
                setStreamBuffer tagData 
                if error? set/any 'err try [
                    set/any 'result do bind/copy action 'self
                ] [
                    print ajoin ["!!! ERROR while parsing tag:" select swfTagNames tagId "(" tagId ")"] 
                    throw err
                ]
            ] 
            if spriteLevel = 0 [
                if verbal? [
                    prin getTagInfo tagId result
                ] 
                if port? output-file [
                    insert tail output-file getTagInfo tagId result
                ]
            ] 
            result
        ] 
        set 'swf-tag-to-rswf func [tagId tagData /local err action st st2] [
            either none? action: select parseActions tagId [
                result: none
            ] [
                setStreamBuffer tagData 
                if error? set/any 'err try [
                    set/any 'result do bind/copy action 'self
                ] [
                    print ajoin ["!!! ERROR while parsing tag:" select swfTagNames tagId "(" tagId ")"] 
                    throw err
                ]
            ] 
            if spriteLevel = 0 [
                switch/default type?/word result [
                    string! [print result] 
                    none! []
                ] [
                    print select swfTagNames tagId
                ]
            ] 
            result
        ] 
        readID: :readUI16 
        readUsedID: :readUI16 
        spriteLevel: 0 
        names-to-ids: copy [] 
        JPEGTables: none 
        export-file: func [tag id ext data /local file] [
            write/binary probe file: rejoin [swfDir %tag tag %_id id ext] data 
            file
        ] 
        StreamSoundCompression: none 
        comment {
^-StreamSoundCompression -
^-^-defined in SoundStreamHead tag
^-^-used in SoundStreamBlock
^-} 
        tabs: copy "" 
        tabsspr: copy "" 
        tabind+: does [append tabs "^-"] 
        tabind-: does [remove tabs] 
        tabspr+: does [append tabsspr "^-"] 
        tabspr-: does [remove tabsspr] 
        getTagInfo: func [tagId data /local fields] [
            ajoin [
                tabsspr select swfTagNames tagId "(" either tagId < 10 [join "0" tagId] [tagId] "):" 
                either fields: select tagFields tagId [
                    join LF getTagFields data :fields true
                ] [join either none? data ["x"] [join " " mold data] LF]
            ]
        ] 
        getTagFields: func [data fields indent? /local result fld res p name ind l] [
            unless data [return ""] 
            if indent? [tabind+] 
            result: copy "" 
            unless block? data [data: reduce [data]] 
            either function? :fields [
                insert tail result fields data
            ] [
                parse fields [any [
                        p: (if any [not block? data tail? data] [p: tail p]) :p 
                        [
                            set fld string! (
                                res: either none? data/1 [""] [
                                    ajoin [
                                        tabs fld ": " 
                                        either all [
                                            binary? data/1 
                                            20 < l: length? data/1
                                        ] [
                                            ajoin [l " Bytes = " head remove back tail mold copy/part data/1 10 "..."]
                                        ] [mold data/1] 
                                        LF
                                    ]
                                ]
                            ) 
                            | set fld block! set ind ['noIndent | none] (
                                res: getTagFields data/1 fld (ind <> 'noIndent)
                            ) 
                            | set fld function! (res: fld data/1) 
                            | 'group set name string! set fld block! set ind ['noIndent | none] (
                                res: either none? data/1 [""] [
                                    ajoin [tabs name ": [^/" getTagFields data/1 fld (ind <> 'noIndent) tabs "]^/"]
                                ]
                            ) 
                            | 'get set name [lit-word! | word!] set ind ['noIndent | none] (
                                if ind = 'noIndent [tabind-] 
                                res: ajoin [tabs name ": " getFieldData name data/1 LF] 
                                if ind = 'noIndent [tabind+]
                            )
                        ] (
                            insert tail result res 
                            data: next data
                        )
                    ]] 
                data: head data 
                fields: head fields
            ] 
            if indent? [tabind-] 
            result
        ] 
        comment {
#### Include: %parsers/swf-tags-fields.r
#### Title:   "swfTags - Fields"
#### Author:  ""
----} 
        pad: func [val num] [head insert/dup tail val: form val #" " num - length? val] 
        formatFillStyle: func [data /local] [
            if none? data [
                return ""
            ] 
            ajoin switch/default data/1 [0 [["color: " data/2 LF]] 
                16 [[
                        "linearGradiend:" LF 
                        getTagFields data/2/1 fieldsMATRIX true 
                        getFieldData 'Gradients data/2/2 
                        LF
                    ]] 
                18 [[
                        "radialGradient:" LF 
                        getTagFields data/2/1 fieldsMATRIX true 
                        getFieldData 'Gradients data/2/2 
                        LF
                    ]] 
                19 [[
                        "focalGradient:" LF 
                        getTagFields data/2/1 fieldsMATRIX true 
                        getFieldData 'Gradients data/2/2 
                        LF
                    ]] 
                64 [[
                        "repeating bitmap ID: " data/2/1 LF 
                        getTagFields data/2/2 fieldsMATRIX true 
                        LF
                    ]] 
                65 [[
                        "clipped bitmap ID:" data/2/1 LF 
                        getTagFields data/2/2 fieldsMATRIX true 
                        LF
                    ]] 
                66 [[
                        "non-smoothed repeating bitmap ID:" data/2/1 LF 
                        getTagFields data/2/2 fieldsMATRIX true 
                        LF
                    ]] 
                67 [[
                        "non-smoothed clipped bitmap ID:" data/2/1 LF 
                        getTagFields data/2/2 fieldsMATRIX true 
                        LF
                    ]]
            ] [[data LF]]
        ] 
        formatMorphFillStyle: func [data /local] [
            if none? data [
                return ""
            ] 
            ajoin switch/default data/1 [0 [["color: " data/2 LF]] 
                16 [[
                        "linearGradiend:" LF 
                        getTagFields data/2/1 fieldsMATRIX true 
                        getTagFields data/2/2 fieldsMATRIX true 
                        getFieldData 'MorphGradients data/2/3 
                        LF
                    ]] 
                18 [[
                        "radialGradient:" LF 
                        getTagFields data/2/1 fieldsMATRIX true 
                        getTagFields data/2/2 fieldsMATRIX true 
                        getFieldData 'MorphGradients data/2/3 
                        LF
                    ]] 
                19 [[
                        "focalGradient:" LF 
                        getTagFields data/2/1 fieldsMATRIX true 
                        getTagFields data/2/2 fieldsMATRIX true 
                        getFieldData 'MorphGradients data/2/3 
                        LF
                    ]] 
                64 [[
                        "repeating bitmap ID: " data/2/1 LF 
                        getTagFields data/2/2 fieldsMATRIX true 
                        getTagFields data/2/3 fieldsMATRIX true 
                        LF
                    ]] 
                65 [[
                        "clipped bitmap ID:" data/2/1 LF 
                        getTagFields data/2/2 fieldsMATRIX true 
                        getTagFields data/2/3 fieldsMATRIX true 
                        LF
                    ]] 
                66 [[
                        "non-smoothed repeating bitmap ID:" data/2/1 LF 
                        getTagFields data/2/2 fieldsMATRIX true 
                        getTagFields data/2/3 fieldsMATRIX true 
                        LF
                    ]] 
                67 [[
                        "non-smoothed clipped bitmap ID:" data/2/1 LF 
                        getTagFields data/2/2 fieldsMATRIX true 
                        getTagFields data/2/3 fieldsMATRIX true 
                        LF
                    ]]
            ] [[data LF]]
        ] 
        getFieldData: func [type data /local i row result val] [
            result: copy "" 
            unless data [return result] 
            tabind+ 
            switch type [
                FillStyles [
                    append result LF 
                    i: 1 
                    while [not tail? data] [
                        row: data/1 
                        append result ajoin [
                            tabs "#" i " " 
                            formatFillStyle row
                        ] 
                        i: i + 1 
                        comment {
^-^-^-^-type >= 64 [ ;bitmap
^-^-^-^-^-reduce [
^-^-^-^-^-^-readID ;bitmapID
^-^-^-^-^-^-readMATRIX
^-^-^-^-^-]
^-^-^-^-]
^-^-^-]"
^-^-^-^-^-mold data/1 LF
^-^-^-^-]
^-^-^-^-} 
                        data: next data
                    ]
                ] 
                MorphFillStyles [
                    append result LF 
                    i: 1 
                    while [not tail? data] [
                        row: data/1 
                        append result ajoin [
                            tabs "#" i " " 
                            formatMorphFillStyle row
                        ] 
                        i: i + 1 
                        data: next data
                    ]
                ] 
                LineStyles [
                    i: 1 
                    while [not tail? data] [
                        probe row: data/1 
                        append result ajoin [
                            LF tabs "#" i ": " 
                            "width: " row/1 
                            either none? row/2 [""] [" miterLimit:" row/2] 
                            ajoin either tuple? row/3 [
                                [" color: " row/3]
                            ] [[" " formatFillStyle row/3]] 
                            either row/4 [ajoin [LF tabs formatFillStyle row/4]] [""]
                        ] 
                        data: next data 
                        i: i + 1
                    ]
                ] 
                Gradients [
                    append result ajoin [tabs "SpreadMode: " pick ["Pad" "Reflect" "Repeat" "-"] (data/1 + 1) LF] 
                    append result ajoin [tabs "InterpolationMode: " pick ["Normal RGB" "Linear RGB" "-" "-"] (data/2 + 1) LF] 
                    append result ajoin [tabs "GradientColors: " LF] 
                    foreach [ratio color] data/3 [
                        append result ajoin [tabs "^-" pad ratio 5 color LF]
                    ] 
                    if data/4 [append result ajoin [tabs "FocalPoint: " data/4 LF]]
                ] 
                MorphGradients [
                    append result ajoin [tabs "SpreadMode: " pick ["Pad" "Reflect" "Repeat" "-"] (data/1 + 1) LF] 
                    append result ajoin [tabs "InterpolationMode: " pick ["Normal RGB" "Linear RGB" "-" "-"] (data/2 + 1) LF] 
                    append result ajoin [tabs "GradientColors: " LF] 
                    foreach [ratio color] data/3 [
                        append result ajoin [tabs "^-" pad ratio 5 color LF]
                    ] 
                    if data/4 [append result ajoin [tabs "FocalPoint: " data/4 LF]]
                ] 
                ShapeRecords [
                    append result ajoin [LF tabs "Style:" LF] 
                    parse data [any [
                            'style set val block! (
                                append result ajoin [tabs "ChangeStyle: " LF getTagFields val fieldsStyleChangeRecord true]
                            ) 
                            | 'line copy val some [integer!] (
                                append result ajoin [tabs "Line: " val LF]
                            ) 
                            | 'curve copy val some [integer!] (
                                append result ajoin [tabs "Curve: " val LF]
                            )
                        ]]
                ] 
                SpriteTags [
                    append result LF 
                    tabspr+ 
                    while [not tail? data] [
                        append result getTagInfo data/1/1 data/1/2 
                        data: next data
                    ] 
                    tabspr-
                ] 
                SoundStreamBlock [
                    if data/1 = 2 [
                        append result ajoin [
                            "MP3" LF 
                            getTagFields next data [
                                "SampleCount" 
                                group "MP3SOUNDDATA" [
                                    "SeekSamples" 
                                    get 'MP3FRAMEs
                                ]
                            ] true
                        ]
                    ]
                ] 
                MP3FRAMEs [
                    foreach [
                        Syncword 
                        MpegVersion 
                        Layer 
                        ProtectionBit 
                        ChannelMode 
                        ModeExtension 
                        Copyright 
                        Original 
                        Emphasis 
                        Bitrate 
                        SamplingRate 
                        soundata
                    ] data [
                        append result ajoin [
                            LF 
                            tabs 
                            "MpegVersion: " pick [2.5 "" 2 1] (1 + MpegVersion) 
                            " Layer: " pick ["" "III" "II" "I"] (1 + Layer) 
                            " CRC: " ProtectionBit = 1 
                            LF 
                            tabs 
                            "Bitrate: " Bitrate 
                            " SamplingRate: " SamplingRate 
                            " PaddingBit: " PaddingBit = 1 
                            LF 
                            tabs 
                            "ChannelMode: " pick ["Stereo" "Joint stereo (Stereo)" "Dual channel" "Single channel (Mono)"] (1 + ChannelMode) 
                            " Copyright: " Copyright = 1 
                            " Original: " Original = 1 
                            " Emphasis: " pick [none "50/15 ms" "" "CCIT J.17"] (1 + Emphasis) 
                            LF 
                            tabs "SampleDataSize: " length? soundata
                        ]
                    ]
                ] 
                BUTTONRECORDs [
                    append result LF 
                    while [not tail? data] [
                        append result getTagFields data/1 fieldsBUTTONRECORDs true 
                        data: next data
                    ]
                ] 
                BUTTONstates [
                    append result ajoin [
                        data " =" 
                        either isSetBit? data 1 [" up"] [""] 
                        either isSetBit? data 2 [" over"] [""] 
                        either isSetBit? data 3 [" down"] [""] 
                        either isSetBit? data 4 [" hit"] [""] 
                        LF
                    ]
                ]
            ] 
            error? try [data: head data] 
            tabind- 
            trim/tail result
        ] 
        fieldsFillStyles: func [data] [
            tabind+ 
            result: copy ""
        ] 
        fieldsDefineShape: [
            "ID" 
            "Bounds" 
            group "Edge" [
                "EdgeBounds" 
                "UsesNonScalingStrokes" 
                "UsesScalingStrokes"
            ] 
            group "StylesAndShapes" [
                get 'FillStyles 
                get 'LineStyles 
                get 'ShapeRecords
            ]
        ] 
        fieldsMATRIX: [
            "Scale" 
            "Rotate" 
            "Translate"
        ] 
        fieldsCXFORM: [
            "Multiplication" 
            "Addition"
        ] 
        fieldsBUTTONRECORDs: reduce [
            'get 'BUTTONstates 'noIndent 
            "ID" 
            "PlaceDepth" 
            fieldsMATRIX 'noIndent 
            fieldsCXFORM 'noIndent
        ] 
        fieldsStyleChangeRecord: [
            "Move" 
            "FillStyle0" 
            "FillStyle1" 
            "LineStyle" 
            group "NewStyles" [
                get 'FillStyles 
                get 'LineStyles 
                "numFillBits" 
                "numLineBits"
            ]
        ] 
        fieldsDefineText: reduce [
            "ID" 
            "TextBounds" 
            fieldsMATRIX 'noIndent 
            'group "TextRecords" [
                "FontID" 
                "Color" 
                "XOffset" 
                "YOffset" 
                "TextHeight" 
                "Glyphs"
            ]
        ] 
        fieldsDefineBitsLossless: [
            "BitmapID" 
            "BitmapFormat" 
            "BitmapWidth" 
            "BitmapHeight" 
            "BitmapColorTableSize" 
            "ZlibBitmapData"
        ] 
        fieldsSoundStreamHead: [
            "reserved" 
            "PlaybackSoundRate" 
            "16bit?" 
            "Stereo?" 
            "StreamSoundCompression" 
            "StreamSoundRate" 
            "StreamSoundSize" 
            "StreamSoundType" 
            "StreamSoundSampleCount" 
            "LatencySeek"
        ] 
        fieldsSOUNDINFO: [
            "reserved" 
            "SyncStop?" 
            "SyncNoMultiple?" 
            "InPoint" 
            "OutPoint" 
            "Loops" 
            "Envelope"
        ] 
        fieldsStartSound: reduce [
            "SoundID" 
            fieldsSOUNDINFO 'noIndent
        ] 
        comment {
#### Include: %format/actions.r
#### Title:   "SWF Actions formater"
#### Author:  ""
----} 
        actionFormater: context [
            bin-to-int: func [bin] [to-integer reverse as-binary bin] 
            str-to-int: func [str] [bin-to-int as-binary str] 
            bin-to-si: func [bin [binary!] /local i] [
                i: to integer! reverse bin 
                if i > 32767 [
                    i: (i and 32767) - 32768
                ] 
                i
            ] 
            cp: ["^H" copy v 1 skip 
                (append vals rejoin ["CP:" pick ConstantPool v: 1 + str-to-int v])
            ] 
            i32: ["^G" copy v 4 skip 
                (append vals v: str-to-int v)
            ] 
            pstr: ["^@" copy v to "^@" 1 skip 
                (append vals v)
            ] 
            logic: ["^E" copy v 1 skip 
                (append vals pick [false true] 1 + str-to-int v)
            ] 
            null: ["^B" (append vals 'null)] 
            undefined: ["^C" (append vals 'undefined)] 
            dec: ["^F" copy v 8 skip 
                (append vals from-ieee64f as-binary v)
            ] 
            reg: ["^D" copy v 1 skip 
                (append vals to-path join "R:" str-to-int v)
            ] 
            str: [copy v to "^@" 1 skip (append vals v)] 
            word: [copy v 2 skip (append vals str-to-int v)] 
            ConstantPool: copy [] 
            parseDefineFunc: func [data /local s params] [
                s: make stream-io [inBuffer: data] 
                context [
                    name: s/readStringP 
                    params: (
                        params: copy [] 
                        loop s/readShort [
                            repend params [
                                s/readStringP
                            ]
                        ] 
                        params
                    ) 
                    length: s/readShort
                ]
            ] 
            parseDefineFunc2: func [data /local s params] [
                s: make stream-io [inBuffer: data] 
                context [
                    name: s/readStringP 
                    arg_count: s/readShort 
                    reg_count: s/readUI8 
                    preload_parent: s/readBitLogic 
                    preload_root: s/readBitLogic 
                    suppress_super: s/readBitLogic 
                    preload_super: s/readBitLogic 
                    suppress_arguments: s/readBitLogic 
                    preload_arguments: s/readBitLogic 
                    suppress_this: s/readBitLogic 
                    preload_this: s/readBitLogic 
                    preload_global: (s/skipBits 7 s/readBitLogic) 
                    params: (
                        params: copy [] 
                        loop arg_count [
                            repend params [
                                s/readUI8 
                                s/readStringP
                            ]
                        ] 
                        params
                    ) 
                    length: s/readShort
                ]
            ] 
            fieldsACTIONRECORDs: func [
                actionRecords 
                /indents ind 
                /local result val aTagName data tabs tabsinner tmp indentStack index aTagId aTagData ofs
            ] [
                result: copy "" 
                tabs: either indents [head insert/dup copy "" "^-" int] ["^-"] 
                tabsinner: "" 
                indentStack: copy [] 
                while [not tail? actionRecords] [
                    set [index aTagId aTagData] copy/part actionRecords 3 
                    actionRecords: skip actionRecords 3 
                    unless empty? indentStack [
                        while [
                            all [
                                not empty? indentStack 
                                indentStack/1 <= index
                            ]
                        ] [
                            remove/part tabsinner 4 
                            remove indentStack
                        ]
                    ] 
                    unless aTagName: select actionids aTagId [
                        "UnknownTag"
                    ] 
                    result: ajoin [result tabs to-hex index tab aTagId " " tabsinner aTagName] 
                    unless empty? aTagData [
                        attempt [
                            append result join " " switch/default aTagName [
                                "aGetURL" [parse/all as-string aTagData "^@"] 
                                "aConstantPool" [
                                    clear ConstantPool 
                                    parse/all aTagData [
                                        2 skip 
                                        any [copy val to "^@" 1 skip (insert tail ConstantPool val)]
                                    ] 
                                    mold ConstantPool
                                ] 
                                "aPush" [
                                    vals: make block! [] 
                                    parse/all aTagData [some [cp | i32 | dec | pstr | logic | reg | null | undefined]] 
                                    mold vals
                                ] 
                                "aDefineFunction" [
                                    tmp: parseDefineFunc aTagData 
                                    data: copy "" 
                                    foreach [sw val] third tmp [
                                        if val [
                                            data: ajoin [data lf tabs "                    " tabsinner sw tab mold val]
                                        ]
                                    ] 
                                    insert indentStack (actionRecords/1 + tmp/length) 
                                    sort indentStack 
                                    append tabsinner "    " 
                                    data
                                ] 
                                "aDefineFunction2" [
                                    tmp: parseDefineFunc2 aTagData 
                                    data: copy "" 
                                    foreach [sw val] third tmp [
                                        if val [
                                            data: ajoin [data lf tabs "                    " tabsinner sw tab mold val]
                                        ]
                                    ] 
                                    insert indentStack (actionRecords/1 + tmp/length) 
                                    sort indentStack 
                                    append tabsinner "    " 
                                    data
                                ] 
                                "aIf" [
                                    ofs: actionRecords/1 + bin-to-si aTagData 
                                    if ofs > 0 [
                                        insert indentStack ofs 
                                        sort indentStack 
                                        append tabsinner "    "
                                    ] 
                                    ajoin ["jumpTo " to-hex ofs]
                                ] 
                                "aJump" [
                                    ofs: actionRecords/1 + bin-to-si aTagData 
                                    ajoin ["to " to-hex ofs]
                                ] 
                                "aStoreRegister" [
                                    to-integer aTagData
                                ]
                            ] [mold aTagData]
                        ]
                    ] 
                    append result lf
                ] 
                result
            ] 
            actionids: make hash! [
                #{00} "END of aRecord" 
                #{04} "aNextFrame" 
                #{05} "aPrevFrame" 
                #{06} "aPlay" 
                #{07} "aStop" 
                #{08} "aToggleQuality" 
                #{09} "aStopSounds" 
                #{81} "aGotoFrame" 
                #{83} "aGetURL" 
                #{8A} "aWaitForFrame" 
                #{8B} "aSetTarget" 
                #{8C} "aGoToLabel" 
                #{96} "aPush" 
                #{17} "aPop" 
                #{0A} "aAdd" 
                #{0B} "aSubtract" 
                #{0C} "aMultiply" 
                #{0D} "aDivide" 
                #{0E} "aEquals" 
                #{0F} "aLess" 
                #{10} "aAnd" 
                #{11} "aOr" 
                #{12} "aNot" 
                #{13} "aStringEquals" 
                #{14} "aStringLength" 
                #{21} "aStringAdd" 
                #{15} "aStringExtract" 
                #{29} "aStringLess" 
                #{31} "aMBStringLength" 
                #{35} "aMBStringExtract" 
                #{18} "aToInteger" 
                #{32} "aCharToAscii" 
                #{33} "aAsciiToChar" 
                #{36} "aMBCharToAscii" 
                #{37} "aMBAsciiToChar" 
                #{99} "aJump" 
                #{9D} "aIf" 
                #{9E} "aCall" 
                #{1C} "aGetVariable" 
                #{1D} "aSetVariable" 
                #{9A} "aGetURL2" 
                #{9F} "aGotoFrame2" 
                #{20} "aSetTarget2" 
                #{22} "aGetProperty" 
                #{23} "aSetProperty" 
                #{24} "aCloneSprite" 
                #{25} "aRemoveSprite" 
                #{27} "aStartDrag" 
                #{28} "aEndDrag" 
                #{8D} "aWaitForFrame2" 
                #{26} "aTrace" 
                #{34} "aGetTime" 
                #{30} "aRandomNumber" 
                #{3D} "aCallFunction" 
                #{52} "aCallMethod" 
                #{88} "aConstantPool" 
                #{9B} "aDefineFunction" 
                #{3C} "aDefineLocal" 
                #{41} "aDefineLocal2" 
                #{43} "aDefineObject" 
                #{3A} "aDelete" 
                #{3B} "aDelete2" 
                #{46} "aEnumerate" 
                #{49} "aEquals2" 
                #{4E} "aGetMember" 
                #{42} "aInitArray/Object" 
                #{53} "aNewMethod" 
                #{40} "aNewObject" 
                #{4F} "aSetMember" 
                #{45} "aTargetPath" 
                #{94} "aWith" 
                #{4A} "aToNumber" 
                #{4B} "aToString" 
                #{44} "aTypeOf" 
                #{47} "aAdd2" 
                #{48} "aLess2" 
                #{3F} "aModulo" 
                #{60} "aBitAnd" 
                #{63} "aBitLShift" 
                #{61} "aBitOr" 
                #{64} "aBitRShift" 
                #{65} "aBitURShift" 
                #{62} "aBitXor" 
                #{51} "aDecrement" 
                #{50} "aIncrement" 
                #{4C} "aPushDuplicate" 
                #{3E} "aReturn" 
                #{4D} "aStackSwap" 
                #{87} "aStoreRegister" 
                #{54} "aInstanceOf" 
                #{55} "aEnumerate2" 
                #{66} "aStrictEqual" 
                #{67} "aGreater" 
                #{68} "aStringGreater" 
                #{69} "aExtends" 
                #{2A} "aThrow" 
                #{2B} "aCastOp" 
                #{2C} "aImplementsOp" 
                #{8E} "aDefineFunction2" 
                #{8F} "aTry"
            ]
        ] 
        comment "---- end of include %format/actions.r ----" 
        fieldsACTIONRECORDs: get in actionFormater 'fieldsACTIONRECORDs 
        tagFields: make hash! reduce [
            2 fieldsDefineShape 
            4 reduce [
                "ID" 
                "Depth" 
                fieldsMATRIX 
                fieldsCXFORM
            ] 
            5 ["ID" "Depth"] 
            6 ["ID" "JPEGData"] 
            7 reduce [
                "ID" 
                'get 'BUTTONRECORDs 
                :fieldsACTIONRECORDs
            ] 
            8 ["JPEGData"] 
            10 ["ID" "GlyphShapeTable"] 
            11 fieldsDefineText 
            12 :fieldsACTIONRECORDs 
            13 [
                "FontID" 
                "Name" 
                "Flags" 
                "CodeTable"
            ] 
            14 [
                "ID" 
                "Format" 
                "Rate" 
                "Size" 
                "Type" 
                "SampleCount" 
                "Data"
            ] 
            15 reduce [
                "ID" 
                'group fieldsSOUNDINFO
            ] 
            17 reduce [
                "ButtonID" 
                'group "OverUpToIdle" fieldsStartSound 
                'group "IdleToOverUp" fieldsStartSound 
                'group "OverUpToOverDown" fieldsStartSound 
                'group "OverDownToOverUp" fieldsStartSound
            ] 
            18 fieldsSoundStreamHead 
            19 [
                get 'SoundStreamBlock
            ] 
            20 fieldsDefineBitsLossless 
            21 ["ID" "JPEGData"] 
            22 fieldsDefineShape 
            23 [
                "ButtonID" 
                fieldsCXFORM
            ] 
            26 reduce [
                "Depth" 
                "Move?" 
                "Character" 
                fieldsMATRIX 
                fieldsCXFORM 
                "Ratio" 
                "Name" 
                "ClipDepth" 
                'group "CLIPACTIONS" [
                    "reserved" 
                    "AllEventFlags" 
                    "Actions"
                ]
            ] 
            28 ["Depth"] 
            32 fieldsDefineShape 
            33 fieldsDefineText 
            34 reduce [
                "ID" 
                'get 'BUTTONRECORDs 
                :fieldsACTIONRECORDs
            ] 
            35 ["ID" "JPEGData" "BitmapAlphaData"] 
            36 fieldsDefineBitsLossless 
            37 [
                "ID" 
                "Bounds" 
                "WordWrap?" 
                "Multiline?" 
                "Password?" 
                "ReadOnly?" 
                "Reserved1" 
                "AutoSize?" 
                "NoSelect?" 
                "Border?" 
                "Reserved2" 
                "HTML?" 
                "UseOutlines?" 
                group "Font" ["FontID" "Height"] 
                "TextColor" 
                "MaxLength" 
                group "Layout" [
                    "Align" 
                    "LeftMargin" 
                    "RightMargin" 
                    "Indent" 
                    "Leading"
                ] 
                "VariableName" 
                "InitialText"
            ] 
            39 [
                "ID" 
                "FrameCount" 
                get 'SpriteTags
            ] 
            43 [readSTRING] 
            45 fieldsSoundStreamHead 
            46 [
                "ID" 
                "StartBounds" 
                "EndBounds" 
                "Offset" 
                get 'MorphFillStyles 
                "MorphLineStyles" 
                "StartEdges" 
                "EndEdges"
            ] 
            48 [
                "ID" 
                "Flags" 
                "LangCode" 
                "FontName" 
                "GlyphShapeTable" 
                "CodeTable" 
                group "Layout" [
                    "FontAscent" 
                    "FontDescent" 
                    "FontLeading" 
                    "FontAdvanceTable" 
                    "FontBoundsTable" 
                    "KERNINGRECORDs"
                ]
            ] 
            57 [
                "FromURL" 
                "Assets"
            ] 
            59 reduce [
                "CharacterID" 
                :fieldsACTIONRECORDs
            ] 
            60 [] 
            61 [] 
            62 [] 
            64 [] 
            65 [] 
            66 [] 
            67 fieldsDefineShape 
            69 [] 
            70 reduce [
                "Depth" 
                "Move?" 
                "Character" 
                fieldsMATRIX 
                fieldsCXFORM 
                "Ratio" 
                "Name" 
                "ClipDepth" 
                "Filters" 
                "Blend" 
                "BitmapCaching" 
                'group "CLIPACTIONS" [
                    "reserved" 
                    "AllEventFlags" 
                    "Actions"
                ]
            ] 
            73 [] 
            74 [] 
            75 [] 
            77 ["MetaData"] 
            78 [
                "CharID" 
                "GridRectangle"
            ] 
            72 [] 
            76 ["ID" "frame"] 
            82 ["Flags" "Name" "ABC decompiled"] 
            83 fieldsDefineShape 
            84 [
                "ID" 
                "StartBounds" 
                "EndBounds" 
                "StartEdgeBounds" 
                "EndEdgeBounds" 
                "UsesNonScalingStrokes" 
                "UsesScalingStrokes" 
                "Offset" 
                "MorphFillStyles" 
                "MorphLineStyles" 
                "StartEdges" 
                "EndEdges"
            ] 
            86 [
                "Scenes" 
                "FrameLabels"
            ] 
            87 [] 
            88 [] 
            89 reduce [
                "SoundClassName" 
                'group fieldsSOUNDINFO
            ] 
            90 [
                "ID" 
                "DeblockParam" 
                "JPEGData" 
                "BitmapAlphaData"
            ] 
            91 [
                "FontID" 
                "flags" 
                "FontName" 
                "FontData"
            ]
        ] 
        convert-ExportAssets: has [result] [
            result: copy "Assets [^/" 
            foreach [id name] parse-ExportAssets [
                append result ajoin [tab id " " mold as-string name lf]
            ] 
            append result "]" 
            result
        ] 
        convert-DefineShape: has [shape result fillStyles lineStyles pos st dx dy tmp lineStyle fillStyle0 fillStyle1] [
            probe shape: parse-DefineShape 
            fillStyles: shape/4/1 
            lineStyles: shape/4/2 
            lineStyle: fillStyle0: fillStyle1: none 
            pos: 0x0 
            result: ajoin [
                "Shape " shape/1 " [^/^-units twips^/" 
                "^-bounds " shape/2/1 "x" shape/2/3 " " shape/2/2 "x" shape/2/4 lf 
                either shape/3 [
                    ajoin [
                        "^-edge [^/" 
                        "^-^-bounds " shape/3/1/1 "x" shape/3/1/2 " " shape/3/1/3 "x" shape/3/1/4 
                        either shape/3/2 ["^-^-UsesNonScalingStrokes^/"] [""] 
                        either shape/3/2 ["^-^-UsesScalingStrokes^/"] [""] 
                        "^-]^/"
                    ]
                ] [""]
            ] 
            parse shape/4/3 [
                any [
                    'style set st block! (
                        if st/2 [
                            if fillStyle0 <> st/2 [
                                fillStyle0: st/2 
                                either tmp: fillStyles/(fillStyle0) [
                                    append result ajoin [
                                        "^-fill " 
                                        switch tmp/1 [0 [reduce ["color" tmp/2]] 
                                            64 66 [rejoin [
                                                    "bitmap [" reduce [
                                                        "id" tmp/2/1 
                                                        convert-MATRIX tmp/2/2
                                                    ] 
                                                    "]"
                                                ]
                                            ]
                                        ] 
                                        lf
                                    ]
                                ] [
                                    append result "^-fill none^/"
                                ]
                            ]
                        ] 
                        if st/4 [
                            if lineStyle <> st/4 [
                                lineStyle: st/4 
                                append result ajoin [
                                    "^-pen " lineStyles/(linestyle) lf
                                ]
                            ]
                        ] 
                        if st/1 [
                            pos: as-pair st/1/1 st/1/2
                        ]
                    ) 
                    | 
                    'line (
                        append result ajoin ["^-line " pos " "]
                    ) some [set dx integer! set dy integer! (
                            pos: pos + as-pair dx dy 
                            append result ajoin [pos " "]
                        )] (append result lf) 
                    | 
                    'curve (
                        append result ajoin ["^-curve " pos " "]
                    ) some [
                        set dx integer! set dy integer! (
                            pos: pos + as-pair dx dy 
                            append result ajoin [pos " "]
                        )
                    ] (append result lf)
                ]
            ] 
            append result "^/]" 
            result
        ] 
        convert-PlaceObject2: has [data] [
            data: parse-PlaceObject2 
            ajoin [
                either data/7 [rejoin [as-string data/7 ": "]] [""] 
                "Place " data/3 " [" 
                either data/2 ["move "] [""] 
                either data/1 [join "depth " data/1] [""] 
                either data/4 [convert-MATRIX data/4] [""] 
                either data/6 [join " ratio " data/6] [""] 
                either data/8 [join " clipDepth " data/8] [""] 
                "]"
            ]
        ] 
        convert-MATRIX: func [m] [
            ajoin [
                either m/3 [join " at " to-pair m/3] [""] 
                either m/1 [join " scale " mold m/1] [""] 
                either m/2 [join " rotate " mold m/2] [""]
            ]
        ] 
        convert-DefineSprite: has [spr result] [
            spr: parse-DefineSprite 
            result: rejoin ["Sprite " spr/1 " [^/"] 
            foreach tag spr/3 [
                append result ajoin ["^-" tag/2 lf]
            ] 
            append result "]^/" 
            result
        ] 
        comment {---- end of include %parsers/swf-tags-fields.r ----} 
        comment {
#### Include: %parsers/basic-datatypes.r
#### Title:   "SWF basic datatypes parse functions"
#### Author:  ""
----} 
        readMATRIX: does [
            byteAlign 
            reduce [
                either readBitLogic [readPair] [none] 
                either readBitLogic [readPair] [none] 
                readSBPair
            ]
        ] 
        writeMATRIX: func [m] [
            either m/1 [
                writeBitLogic true 
                writePair m/1
            ] [
                writeBitLogic false
            ] 
            either m/2 [
                writeBitLogic true 
                writePair m/2
            ] [
                writeBitLogic false
            ] 
            writeSBPair m/3
        ] 
        carryMATRIX: does [
            alignBuffers 
            if carryBitLogic [
                carryPair
            ] 
            if carryBitLogic [
                carryPair
            ] 
            carrySBPair 
            alignBuffers
        ] 
        readCXFORM: has [HasAddTerms? HasMultTerms? nbits tmp] [
            HasAddTerms?: readBitLogic 
            HasMultTerms?: readBitLogic 
            nbits: readUB 4 
            tmp: reduce [
                either HasMultTerms? [
                    reduce [
                        readSB nbits 
                        readSB nbits 
                        readSB nbits
                    ]
                ] [none] 
                either HasAddTerms? [
                    reduce [
                        readSB nbits 
                        readSB nbits 
                        readSB nbits
                    ]
                ] [none]
            ] 
            byteAlign 
            tmp
        ] 
        readCXFORMa: has [HasAddTerms? HasMultTerms? nbits tmp] [
            HasAddTerms?: readBitLogic 
            HasMultTerms?: readBitLogic 
            nbits: readUB 4 
            tmp: reduce [
                either HasMultTerms? [
                    reduce [
                        readSB nbits 
                        readSB nbits 
                        readSB nbits 
                        readSB nbits
                    ]
                ] [none] 
                either HasAddTerms? [
                    reduce [
                        readSB nbits 
                        readSB nbits 
                        readSB nbits 
                        readSB nbits
                    ]
                ] [none]
            ] 
            byteAlign 
            tmp
        ] 
        comment {---- end of include %parsers/basic-datatypes.r ----} 
        comment {
#### Include: %parsers/font-and-text.r
#### Title:   "SWF font and text parse functions"
#### Author:  ""
----} 
        parse-DefineFont: has [id OffsetTable GlyphShapeTable last-ofs] [
            reduce [
                readID 
                (
                    OffsetTable: make block! ofs / 2 
                    loop (ofs / 2) - 1 [
                        append OffsetTable (readUI16) - ofs
                    ] 
                    append OffsetTable length? inBuffer 
                    GlyphShapeTable: make block! (ofs / 2) 
                    last-ofs: 0 
                    foreach ofs OffsetTable [
                        append GlyphShapeTable readBytes (ofs - last-ofs) 
                        last-ofs: ofs
                    ] 
                    GlyphShapeTable
                )
            ]
        ] 
        parse-DefineFont2: has [
            flags OffsetTable NumGlyphs WideOffsets? CodeTableOffset GlyphShapeTable last-ofs
        ] [
            reduce [
                readID 
                flags: readUI8 
                readUI8 
                as-string readBytes readUI8 
                (
                    NumGlyphs: readUI16 
                    WideOffsets?: 8 = (8 and flags) 
                    loop NumGlyphs [
                        either WideOffsets? [readUI32] [readUI16]
                    ] 
                    either WideOffsets? [readUI32] [readUI16] 
                    GlyphShapeTable: copy [] 
                    loop NumGlyphs [
                        byteAlign 
                        append/only GlyphShapeTable readSHAPE
                    ] 
                    GlyphShapeTable
                ) 
                readStringNum (NumGlyphs * either WideOffsets? [4] [2]) 
                either 128 = (128 and flags) [
                    reduce [
                        readSI16 
                        readSI16 
                        readSI16 
                        (
                            tmp: copy [] 
                            loop NumGlyphs [append tmp readSI16] 
                            tmp
                        ) 
                        (
                            clear tmp 
                            loop NumGlyphs [append tmp readRECT] 
                            tmp
                        ) 
                        (
                            byteAlign 
                            readKERNINGRECORDs WideOffsets?
                        )
                    ]
                ] [none]
            ]
        ] 
        parse-DefineFont4: does [
            reduce [
                readID 
                readUI8 
                as-string readString 
                readRest
            ]
        ] 
        parse-DefineText: does [
            reduce [
                probe readID 
                readRECT 
                readMATRIX 
                readTEXTRECORD (byteAlign readUI8) readUI8
            ]
        ] 
        parse-DefineEditText: has [HasText? HasTextColor? HasMaxLength? HasFont? HasLayout?] [
            reduce [
                readID 
                readRECT 
                (
                    byteAlign 
                    HasText?: readBitLogic 
                    readBitLogic
                ) 
                readBitLogic 
                readBitLogic 
                readBitLogic 
                (
                    HasTextColor?: readBitLogic 
                    HasMaxLength?: readBitLogic 
                    HasFont?: readBitLogic 
                    readBit
                ) 
                readBitLogic 
                (
                    HasLayout?: readBitLogic 
                    readBitLogic
                ) 
                readBitLogic 
                readBit 
                readBitLogic 
                readBitLogic 
                either HasFont? [reduce [readUsedID readUI16]] [none] 
                either HasTextColor? [readRGBA] [none] 
                either HasMaxLength? [readUI16] [none] 
                either HasLayout? [
                    reduce [
                        readUI8 
                        readUI16 
                        readUI16 
                        readUI16 
                        readUI16
                    ]
                ] [none] 
                readString 
                either HasText? [readString] [none]
            ]
        ] 
        parse-DefineTextFormat: does [
            readRest
        ] 
        readTEXTRECORD: func [GlyphBits AdvanceBits /local records HasFont? HasColor? HasYOffset? HasXOffset?] [
            records: copy [] 
            while [readBitLogic] [
                readUB 3 
                HasFont?: readBitLogic 
                HasColor?: readBitLogic 
                HasYOffset?: readBitLogic 
                HasXOffset?: readBitLogic 
                append records reduce [
                    either HasFont? [readUsedID] [none] 
                    either HasColor? [either tagId = 11 [readRGB] [readRGBA]] [none] 
                    either HasXOffset? [readSI16] [none] 
                    either HasYOffset? [readSI16] [none] 
                    either HasFont? [readUI16] [none] 
                    readGLYPHENTRY GlyphBits AdvanceBits
                ] 
                byteAlign
            ] 
            records
        ] 
        readGLYPHENTRY: func [GlyphBits AdvanceBits /local glyphs] [
            glyphs: copy [] 
            loop readUI8 [
                insert tail glyphs reduce [
                    readUB GlyphBits 
                    readSB AdvanceBits
                ]
            ] 
            glyphs
        ] 
        readKERNINGRECORDs: func [wide? /local result] [
            result: copy [] 
            either wide? [
                loop readUI16 [
                    insert tail result reduce [
                        readUI16 
                        readUI16 
                        readSI16
                    ]
                ]
            ] [
                loop readUI16 [
                    insert tail result reduce [
                        readUI8 
                        readUI8 
                        readSI16
                    ]
                ]
            ] 
            result
        ] 
        parse-DefineFontInfo: has [flags] [
            reduce [
                readUsedID 
                as-string readBytes readUI8 
                readUI8 
                readRest
            ]
        ] 
        parse-DefineFontInfo2: has [flags] [
            reduce [
                readUsedID 
                as-string readBytes readUI8 
                readUI8 
                readUI8 
                readRest
            ]
        ] 
        parse-DefineAlignZones: does [reduce [
                readUsedID 
                readUB 2 
                readALIGNZONERECORDs
            ]] 
        readALIGNZONERECORDs: has [records numZoneData zoneData] [
            records: copy [] 
            while [not tail? inBuffer] [
                repend/only records [
                    (
                        numZoneData: readUI8 
                        zoneData: make block! numZoneData 
                        loop numZoneData [
                            insert tail zoneData readUI32
                        ] 
                        zoneData
                    ) 
                    readUI8
                ]
            ] 
            records
        ] 
        parse-CSMTextSettings: does [reduce [
                readUsedID 
                readUB 2 
                readUB 3 
                readUB 3 
                readUI32 
                readUI32 
                readUI8
            ]] 
        parse-DefineFontName: does [reduce [
                readUsedID 
                readString 
                readString
            ]] 
        comment "---- end of include %parsers/font-and-text.r ----" 
        comment {
#### Include: %parsers/shape.r
#### Title:   "SWF shape parse functions"
#### Author:  ""
----} 
        readFILLSTYLEARRAY: has [FillStyles] [
            byteAlign 
            FillStyles: copy [] 
            loop readCount [
                append/only FillStyles readFILLSTYLE
            ] 
            FillStyles
        ] 
        readFILLSTYLE: has [type] [
            byteAlign 
            reduce [
                type: readUI8 
                case [
                    type = 0 [
                        case [
                            find [46 84] tagId [
                                reduce [readRGBA readRGBA]
                            ] 
                            tagId >= 32 [readRGBA] 
                            true [readRGB]
                        ]
                    ] 
                    any [
                        type = 16 
                        type = 18 
                        type = 19
                    ] [
                        reduce either find [46 84] tagId [
                            [readMATRIX readMATRIX readGRADIENT type]
                        ] [
                            [readMATRIX readGRADIENT type]
                        ]
                    ] 
                    type >= 64 [
                        reduce either find [46 84] tagId [
                            [readUsedID readMATRIX readMATRIX]
                        ] [
                            [readUsedID readMATRIX]
                        ]
                    ]
                ]
            ]
        ] 
        readLINESTYLEARRAY: has [LineStyles] [
            LineStyles: copy [] 
            byteAlign 
            loop readCount [
                append/only LineStyles readLINESTYLE
            ] 
            LineStyles
        ] 
        readLINESTYLE: has [flags] [
            byteAlign 
            reduce case [
                tagId = 46 [
                    [
                        readUI16 
                        readUI16 
                        readRGBA 
                        readRGBA
                    ]
                ] 
                any [tagId = 67 tagId = 83] [
                    [
                        readUI16 
                        reduce [
                            readUB 2 
                            joinStyle: readUB 2 
                            hasFill?: readBitLogic 
                            readBitLogic 
                            readBitLogic 
                            readBitLogic 
                            (
                                skipBits 5 
                                readBitLogic
                            ) 
                            readUB 2
                        ] 
                        either joinStyle = 2 [readUI16] [none] 
                        either hasFill? [print "HASFILL" readFILLSTYLE] [readRGBA]
                    ]
                ] 
                tagId = 84 [
                    [
                        readUI16 
                        readUI16 
                        reduce [
                            readUB 2 
                            joinStyle: readUB 2 
                            hasFill?: readBitLogic 
                            readBitLogic 
                            readBitLogic 
                            readBitLogic 
                            (
                                skipBits 5 
                                readBitLogic
                            ) 
                            readUB 2
                        ] 
                        either joinStyle = 2 [readUI16] [none] 
                        either hasFill? [readFILLSTYLE] [reduce [readRGBA readRGBA]]
                    ]
                ] 
                true [
                    [
                        readUI16 
                        either tagId = 32 [readRGBA] [readRGB]
                    ]
                ]
            ]
        ] 
        readGRADIENT: func [type /local gradients] [
            byteAlign 
            reduce [
                readUB 2 
                readUB 2 
                (
                    gradients: copy [] 
                    loop readUB 4 [
                        insert tail gradients readGRADRECORD
                    ] 
                    gradients
                ) 
                either all [type = 19 tagId = 83] [readSShortFixed] [none]
            ]
        ] 
        readGRADRECORD: has [] [
            reduce [
                readUI8 
                either tagId >= 32 [readRGBA] [readRGB]
            ]
        ] 
        readSHAPERECORD: func [numFillBits numLineBits /local nBits lineType states records] [
            records: copy [] 
            lineType: none 
            byteAlign 
            until [
                either readBitLogic [
                    either readBitLogic [
                        if lineType <> 'line [insert tail records lineType: 'line] 
                        nBits: 2 + readUB 4 
                        insert tail records reduce either readBitLogic [
                            [
                                readSB nBits 
                                readSB nBits
                            ]
                        ] [
                            either readBitLogic [
                                [0 readSB nBits]
                            ] [
                                [readSB nBits 0]
                            ]
                        ]
                    ] [
                        if lineType <> 'curve [insert tail records lineType: 'curve] 
                        nBits: 2 + readUB 4 
                        insert tail records reduce [
                            readSB nBits 
                            readSB nBits 
                            readSB nBits 
                            readSB nBits
                        ]
                    ] 
                    false
                ] [
                    states: readUB 5 
                    either states = 0 [
                        true
                    ] [
                        lineType: none 
                        insert tail records 'style 
                        insert/only tail records reduce [
                            either 0 < (states and 1) [readSBPair] [none] 
                            either 0 < (states and 2) [readUB numFillBits] [none] 
                            either 0 < (states and 4) [readUB numFillBits] [none] 
                            either 0 < (states and 8) [readUB numLineBits] [none] 
                            either 0 < (states and 16) [
                                reduce [
                                    readFILLSTYLEARRAY 
                                    readLINESTYLEARRAY 
                                    numFillBits: readUB 4 
                                    numLineBits: readUB 4
                                ]
                            ] [none]
                        ] 
                        false
                    ]
                ]
            ] 
            records
        ] 
        readSHAPE: does [
            readSHAPERECORD (byteAlign readUB 4) readUB 4
        ] 
        readSHAPEWITHSTYLES: does [
            byteAlign 
            reduce [
                readFILLSTYLEARRAY 
                readLINESTYLEARRAY 
                readSHAPERECORD (byteAlign readUB 4) readUB 4
            ]
        ] 
        parse-DefineShape: does [
            reduce [
                readID 
                readRect 
                either tagId >= 67 [
                    reduce [
                        readRect 
                        (
                            readUB 6 
                            readBitLogic
                        ) 
                        readBitLogic
                    ]
                ] [none] 
                readSHAPEWITHSTYLES
            ]
        ] 
        comment "---- end of include %parsers/shape.r ----" 
        comment {
#### Include: %parsers/button.r
#### Title:   "SWF buttons parse functions"
#### Author:  ""
----} 
        readBUTTONRECORDs: has [records reserved states hasBlendMode hasFilterList] [
            records: copy [] 
            until [
                byteAlign 
                reserved: readUB 2 
                hasBlendMode: readBitLogic 
                hasFilterList: readBitLogic 
                states: readUB 4 
                either all [reserved = 0 states = 0] [true] [
                    repend/only records [
                        states 
                        readUsedID 
                        readUI16 
                        readMATRIX 
                        either tagId = 34 [readCXFORMa] [none] 
                        either all [hasFilterList tagId = 34] [readFILTERS] [none] 
                        either all [hasBlendMode tagId = 34] [readUI8] [none]
                    ] 
                    false
                ]
            ] 
            records
        ] 
        readBUTTONCONDACTIONs: has [actions CondActionSize] [
            actions: copy [] 
            byteAlign 
            until [
                either any [
                    tail? inBuffer 0 = CondActionSize: readUI16
                ] [true] [
                    repend actions [
                        readBitLogic 
                        readBitLogic 
                        readBitLogic 
                        readBitLogic 
                        readBitLogic 
                        readBitLogic 
                        readBitLogic 
                        readBitLogic 
                        readUB 7 
                        readBitLogic 
                        readACTIONRECORDs
                    ] 
                    false
                ]
            ] 
            actions
        ] 
        parse-DefineButton: does [
            reduce [
                readID 
                readBUTTONRECORDs 
                readACTIONRECORDs
            ]
        ] 
        parse-DefineButton2: does [
            reduce [
                readID 
                (
                    readUI8 
                    readUI16 
                    readBUTTONRECORDs
                ) 
                readBUTTONCONDACTIONs
            ]
        ] 
        parse-DefineButtonCxform: does [
            reduce [
                readUsedID 
                readCXFORM
            ]
        ] 
        parse-DefineButtonSound: has [id] [
            reduce [
                readUsedID 
                either 0 < id: readUsedID [reduce [id readSOUNDINFO]] [none] 
                either 0 < id: readUsedID [reduce [id readSOUNDINFO]] [none] 
                either 0 < id: readUsedID [reduce [id readSOUNDINFO]] [none] 
                either 0 < id: readUsedID [reduce [id readSOUNDINFO]] [none]
            ]
        ] 
        comment "---- end of include %parsers/button.r ----" 
        comment {
#### Include: %parsers/sprite.r
#### Title:   "SWF sprites and movie clip related parse functions"
#### Author:  ""
----} 
        parse-DefineSprite: has [] [
            reduce [
                readID 
                readUI16 
                readSWFTAGs inBuffer
            ]
        ] 
        parse-PlaceObject: does [
            reduce [
                readUsedID 
                readUI16 
                readMATRIX 
                either tail? inBuffer [none] [readCXFORM]
            ]
        ] 
        parse-PlaceObject2: has [flags] [reduce [
                (
                    flags: readUI8 
                    readUI16
                ) 
                isSetBit? flags 1 
                either isSetBit? flags 2 [readUsedID] [none] 
                either isSetBit? flags 3 [readMATRIX] [none] 
                either isSetBit? flags 4 [byteAlign readCXFORMa] [none] 
                either isSetBit? flags 5 [byteAlign readUI16] [none] 
                either isSetBit? flags 6 [byteAlign readString] [none] 
                either isSetBit? flags 7 [byteAlign readUI16] [none] 
                either isSetBit? flags 8 [byteAlign readCLIPACTIONS] [none]
            ]] 
        parse-PlaceObject3: has [flags flags2] [reduce [
                (
                    flags: readUI8 
                    flags2: readUI8 
                    readUI16
                ) 
                (
                    isSetBit? flags 1
                ) 
                either isSetBit? flags 2 [readUsedID] [none] 
                either isSetBit? flags 3 [readMATRIX] [none] 
                either isSetBit? flags 4 [byteAlign readCXFORMa] [none] 
                either isSetBit? flags 5 [byteAlign readUI16] [none] 
                either isSetBit? flags 6 [byteAlign readString] [none] 
                either isSetBit? flags 7 [byteAlign readUI16] [none] 
                either isSetBit? flags2 1 [readFILTERS] [none] 
                either isSetBit? flags2 2 [readUI8] [none] 
                either isSetBit? flags2 3 [readUI8] [none] 
                either isSetBit? flags 8 [readCLIPACTIONS] [none]
            ]] 
        readFILTERS: has [filters type columns rows] [
            filters: copy [] 
            loop readUI8 [
                byteAlign 
                repend filters [
                    type: readUI8 
                    reduce case [
                        type = 1 [
                            [
                                readULongFixed 
                                readULongFixed 
                                readUB 5
                            ]
                        ] 
                        find [0 2 3] type [
                            inBuffer 
                            [
                                readRGBA 
                                readSLongFixed 
                                readSLongFixed 
                                either type <> 2 [
                                    reduce [
                                        readSLongFixed 
                                        readSLongFixed
                                    ]
                                ] [none] 
                                readSShortFixed 
                                readBitLogic 
                                readBitLogic 
                                readBitLogic 
                                readBitLogic
                            ]
                        ] 
                        find [4 7] type [
                            count: readUI8 
                            [
                                readRGBAArray count 
                                readUI8Array count 
                                readSLongFixed 
                                readSLongFixed 
                                readSLongFixed 
                                readSLongFixed 
                                readSShortFixed 
                                readBitLogic 
                                readBitLogic 
                                readBitLogic 
                                (skipBits 1 
                                    readUB 4
                                )
                            ]
                        ] 
                        type = 5 [
                            [
                                columns: readUI8 
                                rows: readUI8 
                                readLongFloat 
                                readLongFloat 
                                readLongFloatArray (columns * rows) 
                                readRGBA 
                                skipBits 6 
                                readBitLogic 
                                readBitLogic
                            ]
                        ] 
                        type = 6 [
                            readLongFloatArray 20
                        ]
                    ]
                ]
            ] 
            filters
        ] 
        parse-RemoveObject: does [
            reduce [
                readUsedID 
                readUI16
            ]
        ] 
        parse-RemoveObject2: does [
            readUI16
        ] 
        parse-SWT-CharacterName: does [
            reduce [
                readID 
                readSTRING
            ]
        ] 
        readCLIPACTIONS: does [reduce [
                readUI16 
                readUI32 
                readCLIPACTIONRECORDs
            ]] 
        readCLIPACTIONRECORDs: has [records flags] [
            records: copy [] 
            until [
                insert/only tail records reduce [
                    flags: readUI32 
                    readUI32 
                    either isSetBit? flags 10 [readUI8] [none] 
                    readACTIONRECORDs
                ] 0 = either swfVersion > 5 [readUI32] [readUI16]
            ] 
            records
        ] 
        comment "---- end of include %parsers/sprite.r ----" 
        comment {
#### Include: %parsers/sound.r
#### Title:   "SWF sound related parse functions"
#### Author:  ""
----} 
        parse-DefineSound: does [
            reduce [
                readID 
                readUB 4 
                readUB 2 
                readBitLogic 
                readBitLogic 
                readUI32 
                readRest
            ]
        ] 
        parse-StartSound: does [
            reduce [
                readUsedID 
                readSOUNDINFO
            ]
        ] 
        parse-StartSound2: does [
            reduce [
                as-string readString 
                readSOUNDINFO
            ]
        ] 
        parse-SoundStreamHead: does [
            reduce [
                (readUB 4 none) 
                readUB 2 
                readBitLogic 
                readBitLogic 
                StreamSoundCompression: readUB 4 
                readUB 2 
                readBitLogic 
                readBitLogic 
                readUI16 
                either StreamSoundCompression = 2 [readSI16] [none]
            ]
        ] 
        parse-SoundStreamBlock: does [
            reduce [
                switch/default StreamSoundCompression [
                    2 [readMP3STREAMSOUNDDATA]
                ] [readRest]
            ]
        ] 
        readMP3STREAMSOUNDDATA: does [
            reduce [
                StreamSoundCompression 
                readUI16 
                readMP3SOUNDDATA
            ]
        ] 
        readMP3SOUNDDATA: does [
            reduce [
                readSI16 
                readMP3FRAMEs
            ]
        ] 
        readMP3FRAMEs: has [frames MpegVersion Layer Bitrate SamplingRate sampleDataSize] [
            frames: copy [] 
            while [not tail? inBuffer] [
                repend frames [
                    readUB 11 
                    MpegVersion: readUB 2 
                    Layer: readUB 2 
                    readBitLogic 
                    (
                        Bitrate: readUB 4 
                        SamplingRate: readUB 2 
                        PaddingBit: readBit 
                        readBit 
                        readUB 2
                    ) 
                    readUB 2 
                    readBitLogic 
                    readBitLogic 
                    readUB 2 
                    Bitrate: transMP3Bitrate Layer MpegVersion Bitrate 
                    SamplingRate: transMP3SamplingRate MpegVersion SamplingRate 
                    (
                        sampleDataSize: to integer! either MpegVersion = 3 [
                            (((either Layer = 3 [48000] [144000]) * Bitrate) / SamplingRate) + PaddingBit - 4
                        ] [
                            (((either Layer = 3 [24000] [72000]) * Bitrate) / SamplingRate) + PaddingBit - 4
                        ] 
                        readBytes sampleDataSize
                    )
                ]
            ] 
            frames
        ] 
        transMP3Bitrate: func [Layer MpegVersion Bitrate] [
            pick (switch Layer either MpegVersion = 3 [[
                        3 [[32 64 96 128 160 192 224 256 288 320 352 384 416 448]] 
                        2 [[32 48 56 64 80 96 112 128 160 192 224 256 320 384]] 1 [[32 40 48 56 64 80 96 112 128 160 192 224 256 320]]
                    ]] [[
                        3 [[32 48 56 64 80 96 112 128 144 160 176 192 224 256]] 
                        2 [[8 16 24 32 40 48 56 64 80 96 112 128 144 160]] 1 [[8 16 24 32 40 48 56 64 80 96 112 128 144 160]]
                    ]]) Bitrate
        ] 
        transMP3SamplingRate: func [MpegVersion SamplingRate] [
            pick switch MpegVersion [
                3 [[44100 48000 32000 "--"]] 
                2 [[22050 24000 16000 "--"]] 0 [[11025 12000 8000 "--"]]
            ] (1 + SamplingRate)
        ] 
        readSOUNDINFO: has [HasEnvelope? HasLoops? HasOutPoint? HasInPoint?] [
            reduce [
                (readUB 2 none) 
                readBitLogic 
                readBitLogic 
                (
                    HasEnvelope?: readBitLogic 
                    HasLoops?: readBitLogic 
                    HasOutPoint?: readBitLogic 
                    HasInPoint?: readBitLogic 
                    either HasInPoint? [readUI32] [none]
                ) 
                either HasOutPoint? [readUI32] [none] 
                either HasLoops? [readUI16] [none] 
                either HasEnvelope? [readSOUNDENVELOPE] [none]
            ]
        ] 
        readSOUNDENVELOPE: does [
            result: copy [] 
            loop readUI8 [
                insert tail result reduce [
                    readUI32 
                    readUI16 
                    readUI16
                ]
            ] 
            result
        ] 
        comment "---- end of include %parsers/sound.r ----" 
        comment {
#### Include: %parsers/bitmap.r
#### Title:   "SWF bitmaps parse functions"
#### Author:  ""
----} 
        parse-DefineBitsLossless: has [id BitmapFormat BitmapWidth BitmapHeight argb a rgb ZlibBitmapData] [
            reduce [
                id: readID 
                BitmapFormat: readUI8 
                BitmapWidth: readUI16 
                BitmapHeight: readUI16 
                either BitmapFormat = 3 [readUI8] [none] 
                (
                    ZlibBitmapData: readRest 
                    ZlibBitmapData
                )
            ]
        ] 
        parse-DefineBits: does [
            reduce [
                readID 
                readRest
            ]
        ] 
        parse-JPEGTables: does [
            readRest
        ] 
        parse-DefineBitsJPEG2: does [
            reduce [
                readID 
                readRest
            ]
        ] 
        parse-DefineBitsJPEG3: does [
            reduce [
                readID 
                readBytes readUI32 
                readRest
            ]
        ] 
        parse-DefineBitsJPEG4: has [AlphaDataOffset] [
            reduce [
                readID 
                (
                    AlphaDataOffset: readUI32 
                    readUI16
                ) 
                readBytes AlphaDataOffset 
                readRest
            ]
        ] 
        comment "---- end of include %parsers/bitmap.r ----" 
        comment {
#### Include: %parsers/actions.r
#### Title:   "SWF actions related parse functions"
#### Author:  ""
----} 
        parse-DoAction: 
        readACTIONRECORDs: has [records Length ActionCode i] [
            records: copy [] 
            until [
                i: index? inBuffer 
                insert tail records reduce [
                    (i - 1) 
                    ActionCode: readByte 
                    readBytes either (to integer! actionCode) > 127 [readUI16] [0]
                ] 
                ActionCode = #{00}
            ] 
            new-line/skip records true 3 
            records
        ] 
        parse-DoInitAction: does [reduce [
                readUsedID 
                readACTIONRECORDs
            ]] 
        comment {^-
^-parse-DoABC: has[abc][
^-^-write/binary join rswf-root-dir %tmp.abc abc: readRest
^-^-if error? try [
^-^-^-call/wait rejoin [ to-local-file rswf-root-dir/bin/abcdump.exe " " to-local-file rswf-root-dir/tmp.abc]
^-^-^-return read rswf-root-dir/tmp.abc.il
^-^-][ abc ]
^-]
^-
^-parse-DoABC2: does [reduce [
^-^-readSI32   ;skip
^-^-as-string readString ;frame
^-^-parse-DoABC
^-]]
^-
^-parse-SymbolClass: has[classes][
^-^-classes: copy []
^-^-loop readUI16 [
^-^-^-insert tail classes reduce [
^-^-^-^-readUsedID ;id
^-^-^-^-as-string readString ;frame
^-^-^-]
^-^-]
^-^-classes
^-]
} 
        readNamespace: does [
            reduce [
                select [
                    #{08} Namespace 
                    #{16} PackageNamespace 
                    #{17} PackageInternalNs 
                    #{18} ProtectedNamespace 
                    #{19} ExplicitNamespace 
                    #{1A} StaticProtectedNs 
                    #{05} PrivateNs
                ] readByte 
                ABC/Cpool/string/(readUI30)
            ]
        ] 
        readNSset: funct [] [
            count: readUI30 
            result: make block! count 
            loop count [
                append result ABC/Cpool/namespace/(readUI30)
            ] 
            new-line/skip result true 2 
            result
        ] 
        readMultiname: funct [] [
            reduce switch/default kind: readByte [
                #{07} [['QName ABC/Cpool/namespace/(readUI30) ABC/Cpool/string/(readUI30)]] 
                #{0D} [['QNameA ABC/Cpool/namespace/(readUI30) ABC/Cpool/string/(readUI30)]] 
                #{0F} [['RTQName ABC/Cpool/string/(readUI30)]] 
                #{10} [['RTQNameA ABC/Cpool/string/(readUI30)]] 
                #{11} [['RTQNameL]] 
                #{12} [['RTQNameLA]] 
                #{09} [['Multiname ABC/Cpool/string/(readUI30) ABC/Cpool/nsset/(readUI30)]] 
                #{0E} [['MultinameA ABC/Cpool/string/(readUI30) ABC/Cpool/nsset/(readUI30)]] 
                #{1B} [['MultinameL ABC/Cpool/nsset/(readUI30)]] 
                #{1C} [['MultinameLA ABC/Cpool/nsset/(readUI30)]] 
                #{1D} [['GenericName ABC/Cpool/multiname/(readUI30) readGenericName]]
            ] [ask ["UNKNOWN multiname kind:" mold kind]]
        ] 
        readGenericName: funct [] [
            count: readUI30 
            result: make block! count 
            loop count [
                append result ABC/Cpool/multiname/(readUI30)
            ] 
            result
        ] 
        readParamTypes: funct [count] [
            result: make block! count 
            loop count [
                append result readUI30
            ] 
            result
        ] 
        readParamNames: funct [count] [
            result: make block! count 
            loop count [
                append result readUI30
            ] 
            result
        ] 
        readOptions: funct [] [
            count: readUI30 
            result: make block! count 
            loop count [
                append/only result reduce [
                    readUI30 
                    select [
                        #{03} Int 
                        #{04} UInt 
                        #{06} Double 
                        #{01} Utf8 
                        #{0B} True 
                        #{0A} False 
                        #{0C} Null 
                        #{00} Undefined 
                        #{08} Namespace 
                        #{16} PackageNamespace 
                        #{17} PackageInternalNs 
                        #{18} ProtectedNamespace 
                        #{19} ExplicitNamespace 
                        #{1A} StaticProtectedNs 
                        #{05} PrivateNs
                    ] readByte
                ]
            ] 
            result
        ] 
        readMethod: func [num /local param_count] [
            param_count: readUI30 
            context [
                method: num 
                return_type: readUI30 
                param_type: readParamTypes param_count 
                name: ABC/Cpool/string/(readUI30) 
                flags: readByte 
                options: either (flags and #{08}) = #{08} [readOptions] [none] 
                param_names: either (flags and #{80}) = #{80} [readParamNames param_count] [none]
            ]
        ] 
        readItemsArray: funct [] [
            count: readUI30 
            result: make block! count 
            loop count [
                append/only result reduce [
                    ABC/Cpool/string/(readUI30) 
                    ABC/Cpool/string/(readUI30)
                ]
            ] 
            new-line/all result true
        ] 
        readMetadata: funct [] [
            new-line/skip reduce [
                ABC/Cpool/string/(readUI30) 
                readItemsArray
            ] true 2
        ] 
        readNamespaceArray: func [/local count result] [
            count: readUI30 - 1 
            either count >= 0 [
                result: make block! count 
                loop count [append/only result readNamespace] 
                result
            ] [copy []]
        ] 
        readNSsetArray: func [/local count result] [
            count: readUI30 - 1 
            either count >= 0 [
                result: make block! count 
                loop count [append/only result readNSset] 
                result
            ] [copy []]
        ] 
        readStringInfoArray: func [/local count result] [
            count: readUI30 - 1 
            either count >= 0 [
                result: make block! count 
                loop count [append/only result readStringInfo] 
                result
            ] [copy []]
        ] 
        readMultinameArray: funct [] [
            count: readUI30 - 1 
            either count >= 0 [
                ABC/Cpool/multiname: make block! count 
                loop count [append/only ABC/Cpool/multiname readMultiname] 
                ABC/Cpool/multiname
            ] [ABC/Cpool/multiname: copy []]
        ] 
        readMethodArray: funct [] [
            count: readUI30 
            either count >= 0 [
                result: make block! count 
                repeat i count [append/only result readMethod i] 
                result
            ] [copy []]
        ] 
        readMetadataArray: funct [] [
            count: readUI30 
            either count >= 0 [
                result: make block! count 
                loop count [append/only result readMetadata] 
                result
            ] [copy []]
        ] 
        readInstanceArray: funct [count] [
            result: make block! count 
            loop count [append result readInstance] 
            result
        ] 
        readClassArray: funct [count] [
            result: make block! count 
            loop count [append/only result readClass] 
            result
        ] 
        readScriptArray: funct [] [
            count: readUI30 
            result: make block! count 
            loop count [append/only result readScript] 
            result
        ] 
        readMethodBodyArray: funct [] [
            count: readUI30 
            result: make block! count 
            loop count [append/only result readMethodBody] 
            result
        ] 
        readTrait: has [vindex tmp count] [
            context [
                name: ABC/Cpool/multiname/(readUI30) 
                kind: (tmp: readUI8 tmp and 15) 
                atts: (tmp and 240) 
                data: (
                    reduce switch/default kind [0 6 [
                            [
                                select [0 Slot 6 Const] kind 
                                readUI30 
                                ABC/Cpool/multiname/(readUI30) 
                                vindex: readUI30 
                                either vindex > 0 [
                                    readUI8
                                ] [none]
                            ]
                        ] 
                        4 [
                            [
                                'Class 
                                readUI30 
                                readUI30
                            ]
                        ] 
                        5 [
                            [
                                'Function 
                                readUI30 
                                readUI30
                            ]
                        ] 1 2 3 [
                            [
                                select [1 Method 2 Getter 3 Setter] kind 
                                readUI30 
                                readUI30
                            ]
                        ]
                    ] [
                    ]
                ) 
                metadata: (
                    either (atts and 64) = 64 [
                        count: readUI30 
                        tmp: make block! count 
                        loop count [append/only tmp ABC/Metadata/(1 + readUI30)] 
                        tmp
                    ] [none]
                )
            ]
        ] 
        formInstanceFlags: func [flags /local result] [
            result: make block! 4 
            if #{01} = (flags and #{01}) [append result 'Sealed] 
            if #{02} = (flags and #{02}) [append result 'Final] 
            if #{04} = (flags and #{04}) [append result 'Interface] 
            if #{08} = (flags and #{08}) [append result 'ProtectedNS] 
            result
        ] 
        readInstance: has [blk count] [
            context [
                name: ABC/Cpool/multiname/(readUI30) 
                super_name: ABC/Cpool/multiname/(readUI30) 
                flags: formInstanceFlags readByte 
                protectedNs: either find flags 'ProtectedNS [ABC/Cpool/namespace/(readUI30)] [none] 
                interface: (
                    blk: make block! count: readUI30 
                    loop count [append blk readUI30] 
                    blk
                ) 
                iinit: ABC/MethodInfo/(1 + readUI30) 
                trait: (
                    blk: make block! count: readUI30 
                    loop count [append blk readTrait] 
                    blk
                )
            ]
        ] 
        readClass: has [blk count] [
            context [
                cinit: readUI30 
                trait: (
                    blk: make block! count: readUI30 
                    loop count [append blk readTrait] 
                    blk
                )
            ]
        ] 
        readScript: has [blk count] [
            context [
                init: ABC/MethodInfo/(1 + readUI30) 
                trait: (
                    blk: make block! count: readUI30 
                    loop count [append blk readTrait] 
                    blk
                )
            ]
        ] 
        readException: does [
            reduce [
                readUI30 
                readUI30 
                readUI30 
                readUI30 
                ABC/Cpool/multiname/(readUI30)
            ]
        ] 
        readMethodBody: has [blk count] [
            context [
                method: ABC/MethodInfo/(1 + readUI30) 
                max_stack: readUI30 
                local_count: readUI30 
                init_scope_depth: readUI30 
                max_scope_depth: readUI30 
                code: parse-ABC-code readBytes readUI30 
                exception: (
                    blk: make block! count: readUI30 
                    loop count [append blk readException] 
                    blk
                ) 
                trait: (
                    blk: make block! count: readUI30 
                    loop count [append blk readTrait] 
                    blk
                )
            ]
        ] 
        readLookupOffsets: has [count result] [
            result: copy [] 
            loop readUI30 [append result readS24] 
            result
        ] 
        opcode-reader: make stream-io [] 
        parse-ABC-code: funct [opcodes [binary!]] [
            result: copy [] 
            with opcode-reader [
                setStreamBuffer opcodes 
                while [not empty? inBuffer] [
                    op: readByte 
                    result: insert result new-line reduce [
                        switch/default op [
                            #{A0} ['add] 
                            #{C5} ['add_i] 
                            #{86} ['astype] 
                            #{87} ['astypelate] 
                            #{A8} ['bitand] 
                            #{97} ['bitnot] 
                            #{A9} ['bitor] 
                            #{AA} ['bitxor] 
                            #{41} ['call] 
                            #{43} ['callmethod] 
                            #{46} ['callproperty] 
                            #{4C} ['callproplex] 
                            #{4F} ['callpropvoid] 
                            #{44} ['callstatic] 
                            #{45} ['callsuper] 
                            #{4E} ['callsupervoid] 
                            #{78} ['checkfilter] 
                            #{80} ['coerce] 
                            #{82} ['coerce_a] 
                            #{85} ['coerce_s] 
                            #{42} ['construct] 
                            #{4A} ['constructprop] 
                            #{49} ['constructsuper] 
                            #{76} ['convert_b] 
                            #{75} ['convert_d] 
                            #{73} ['convert_i] 
                            #{77} ['convert_o] 
                            #{70} ['convert_s] 
                            #{74} ['convert_u] 
                            #{EF} ['debug] 
                            #{F1} ['debugfile] 
                            #{F0} ['debugline] 
                            #{94} ['declocal] 
                            #{C3} ['declocal_i] 
                            #{93} ['decrement] 
                            #{C1} ['decrement_i] 
                            #{6A} ['deleteproperty] 
                            #{A3} ['divide] 
                            #{2A} ['dup] 
                            #{06} ['dxns] 
                            #{07} ['dxnslate] 
                            #{AB} ['equals] 
                            #{72} ['esc_xattr] 
                            #{71} ['esc_xelem] 
                            #{5E} ['findproperty] 
                            #{5D} ['findpropstrict] 
                            #{59} ['getdescendants] 
                            #{64} ['getglobalscope] 
                            #{6E} ['getglobalslot] 
                            #{60} ['getlex] 
                            #{62} ['getlocal] 
                            #{D0} ['getlocal_0] 
                            #{D1} ['getlocal_1] 
                            #{D2} ['getlocal_2] 
                            #{D3} ['getlocal_3] 
                            #{66} ['getproperty] 
                            #{65} ['getscopeobject] 
                            #{6C} ['getslot] 
                            #{04} ['getsuper] 
                            #{B0} ['greaterthan] 
                            #{AF} ['greaterthan] 
                            #{1F} ['hasnext] 
                            #{32} ['hasnext2] 
                            #{13} ['ifeq] 
                            #{12} ['iffalse] 
                            #{18} ['ifge] 
                            #{17} ['ifgt] 
                            #{16} ['ifle] 
                            #{15} ['iflt] 
                            #{14} ['ifne] 
                            #{0F} ['ifnge] 
                            #{0E} ['ifngt] 
                            #{0D} ['ifnle] 
                            #{0C} ['ifnlt] 
                            #{19} ['ifstricteq] 
                            #{1A} ['ifstrictne] 
                            #{11} ['iftrue] 
                            #{B4} ['in] 
                            #{92} ['inclocal] 
                            #{C2} ['inclocal_i] 
                            #{91} ['increment] 
                            #{C0} ['increment_i] 
                            #{68} ['initproperty] 
                            #{B1} ['instanceof] 
                            #{B2} ['istype] 
                            #{B3} ['istypelate] 
                            #{10} ['jump] 
                            #{08} ['kill] 
                            #{09} ['label] 
                            #{AE} ['lessequals] 
                            #{AD} ['lessthan] 
                            #{38} ['lf32] 
                            #{35} ['lf64] 
                            #{36} ['li16] 
                            #{37} ['li32] 
                            #{35} ['li8] 
                            #{1B} ['lookupswitch] 
                            #{A5} ['lshift] 
                            #{A4} ['modulo] 
                            #{A2} ['multiply] 
                            #{C7} ['multiply_i] 
                            #{90} ['negate] 
                            #{C4} ['negate_i] 
                            #{57} ['newactivation] 
                            #{56} ['newarray] 
                            #{5A} ['newcatch] 
                            #{58} ['newclass] 
                            #{40} ['newfunction] 
                            #{55} ['newobject] 
                            #{1E} ['nextname] 
                            #{23} ['nextvalue] 
                            #{02} ['nop] 
                            #{96} ['not] 
                            #{29} ['pop] 
                            #{1D} ['popscope] 
                            #{24} ['pushbyte] 
                            #{2F} ['pushdouble] 
                            #{27} ['pushfalse] 
                            #{2D} ['pushint] 
                            #{31} ['pushnamespace] 
                            #{28} ['pushnan] 
                            #{20} ['pushnull] 
                            #{30} ['pushscope] 
                            #{25} ['pushshort] 
                            #{2C} ['pushstring] 
                            #{26} ['pushtrue] 
                            #{2E} ['pushuint] 
                            #{21} ['pushundefined] 
                            #{1C} ['pushwith] 
                            #{48} ['returnvalue] 
                            #{47} ['returnvoid] 
                            #{A6} ['rshift] 
                            #{6F} ['setglobalslot] 
                            #{63} ['setlocal] 
                            #{D4} ['setlocal_0] 
                            #{D5} ['setlocal_1] 
                            #{D6} ['setlocal_2] 
                            #{D7} ['setlocal_3] 
                            #{61} ['setproperty] 
                            #{6D} ['setslot] 
                            #{05} ['setsuper] 
                            #{3D} ['sf32] 
                            #{3D} ['sf32] 
                            #{3B} ['si16] 
                            #{3C} ['si32] 
                            #{3A} ['si8] 
                            #{AC} ['strictequals] 
                            #{A1} ['subtract] 
                            #{C6} ['subtract_i] 
                            #{2B} ['swap] 
                            #{50} ['sxi_1] 
                            #{52} ['sxi_16] 
                            #{51} ['sxi_8] 
                            #{03} ['throw] 
                            #{95} ['typeof] 
                            #{A7} ['urshift]
                        ] [ask ["!!!!!unknown op:" mold op] none]
                    ] true 
                    if args: switch op [
                        #{86} [ABC/Cpool/multiname/(readUI30)] 
                        #{41} [readUI30] 
                        #{43} [reduce [readUI30 readUI30]] 
                        #{46} [reduce [ABC/Cpool/multiname/(readUI30) readUI30]] 
                        #{4C} [reduce [ABC/Cpool/multiname/(readUI30) readUI30]] 
                        #{4F} [reduce [ABC/Cpool/multiname/(readUI30) readUI30]] 
                        #{44} [reduce [readUI30 readUI30]] 
                        #{45} [reduce [readUI30 readUI30]] 
                        #{4E} [reduce [readUI30 readUI30]] 
                        #{80} [ABC/Cpool/multiname/(readUI30)] 
                        #{42} [readUI30] 
                        #{4A} [reduce [readUI30 readUI30]] 
                        #{49} [readUI30] 
                        #{EF} [context [type: readUI8 name: ABC/Cpool/string/(readUI30) register: readUI8 extra: readUI30]] 
                        #{F1} [ABC/Cpool/string/(readUI30)] 
                        #{F0} [readUI30] 
                        #{94} [readUI30] 
                        #{C3} [readUI30] 
                        #{6A} [ABC/Cpool/multiname/(readUI30)] 
                        #{06} [ABC/Cpool/string/(readUI30)] 
                        #{5E} [ABC/Cpool/multiname/(readUI30)] 
                        #{5D} [ABC/Cpool/multiname/(readUI30)] 
                        #{59} [ABC/Cpool/multiname/(readUI30)] 
                        #{6E} [readUI30] 
                        #{60} [ABC/Cpool/multiname/(readUI30)] 
                        #{62} [readUI30] 
                        #{66} [ABC/Cpool/multiname/(readUI30)] 
                        #{65} [readUI30] 
                        #{6C} [readUI30] 
                        #{04} [ABC/Cpool/multiname/(readUI30)] 
                        #{32} [reduce [readUI30 readUI30]] 
                        #{13} [readS24] 
                        #{12} [readS24] 
                        #{18} [readS24] 
                        #{17} [readS24] 
                        #{16} [readS24] 
                        #{15} [readS24] 
                        #{14} [readS24] 
                        #{0F} [readS24] 
                        #{0E} [readS24] 
                        #{0D} [readS24] 
                        #{0C} [readS24] 
                        #{19} [readS24] 
                        #{1A} [readS24] 
                        #{11} [readS24] 
                        #{92} [readUI30] 
                        #{C2} [readUI30] 
                        #{68} [ABC/Cpool/multiname/(readUI30)] 
                        #{B2} [ABC/Cpool/multiname/(readUI30)] 
                        #{10} [readS24] 
                        #{08} [readUI30] 
                        #{1B} [context [default_offset: readS24 offsets: readLookupOffsets]] 
                        #{56} [readUI30] 
                        #{5A} [readUI30] 
                        #{58} [ABC/ClassInfo/(readUI30)] 
                        #{40} [ABC/MethodInfo/(readUI30)] 
                        #{55} [readUI30] 
                        #{24} [readUI8] 
                        #{2F} [ABC/Cpool/double/(readUI30)] 
                        #{2D} [ABC/Cpool/integer/(readUI30)] 
                        #{31} [ABC/Cpool/namespace/(readUI30)] 
                        #{25} [readUI30] 
                        #{2C} [ABC/Cpool/string/(readUI30)] 
                        #{2E} [ABC/Cpool/integer/(readUI30)] 
                        #{6F} [readUI30] 
                        #{63} [readUI30] 
                        #{61} [ABC/Cpool/multiname/(readUI30)] 
                        #{6D} [readUI30] 
                        #{05} [ABC/Cpool/multiname/(readUI30)]
                    ] [
                        result: insert/only result args
                    ]
                ] 
                clear head inBuffer
            ] 
            head result
        ] 
        ABC: context [
            Version: none 
            Cpool: context [
                integer: 
                uinteger: 
                double: 
                string: 
                namespace: 
                nsset: 
                multiname: none
            ] 
            MethodInfo: 
            Metadata: 
            InstanceInfo: 
            ClassInfo: 
            ScriptInfo: 
            MethodBodies: none
        ] 
        parse-DoABC: has [class_count tmp] [
            write %tmp.abc inBuffer 
            ABC/Version: reduce [readUI16 readUI16] 
            ABC/Cpool/integer: (readS32array) 
            ABC/Cpool/uinteger: (readU32array) 
            ABC/Cpool/double: (readD64array) 
            ABC/Cpool/string: (readStringInfoArray) 
            ABC/Cpool/namespace: (readNamespaceArray) 
            ABC/Cpool/nsset: (readNSsetArray) 
            (readMultinameArray) 
            ABC/MethodInfo: readMethodArray 
            ABC/Metadata: readMetadataArray 
            foreach tmp [
                integer 
                uinteger 
                double 
                string 
                namespace 
                nsset 
                multiname
            ] [error? try [new-line/all ABC/Cpool/(tmp) true]] 
            foreach tmp [
                MethodInfo 
                Metadata
            ] [error? try [new-line/all ABC/(tmp) true]] 
            ABC/InstanceInfo: (
                class_count: readUI30 
                readInstanceArray class_count
            ) 
            ABC/ClassInfo: readClassArray class_count 
            ABC/ScriptInfo: readScriptArray 
            ABC/MethodBodies: readMethodBodyArray 
            foreach tmp [string namespace nsset multiname] [
                new-line/all ABC/Cpool/(tmp) true
            ] 
            foreach tmp [
                MethodInfo 
                InstanceInfo 
                ClassInfo 
                ScriptInfo 
                MethodBodies
            ] [new-line/all ABC/(tmp) true] 
            print ["DONE ABC" length? inBuffer] 
            if 0 < length? inBuffer [
                print "!!!!!!! still data left !!!!!!!!!!" 
                ask ""
            ] 
            ABC
        ] 
        parse-DoABC2: does [as-string inBuffer reduce [
                readSI32 
                readString 
                parse-DoABC
            ]] 
        parse-SymbolClass: has [symbols] [
            symbols: copy [] 
            loop readUI16 [
                append symbols reduce [
                    readUsedID 
                    as-string readString
                ]
            ] 
            symbols
        ] 
        comment "---- end of include %parsers/actions.r ----" 
        comment {
#### Include: %parsers/morphing.r
#### Title:   "SWF morphing shapes related parse functions"
#### Author:  ""
----} 
        readMORPHFILLSTYLEARRAY: has [FillStyles] [
            byteAlign 
            FillStyles: copy [] 
            loop readCount [
                append/only FillStyles readMORHFILLSTYLE
            ] 
            FillStyles
        ] 
        readMORPHLINESTYLEARRAY: has [LineStyles] [
            LineStyles: copy [] 
            loop readCount [
                append/only LineStyles either tagId = 46 [
                    reduce [
                        readUI16 
                        readUI16 
                        readRGBA 
                        readRGBA
                    ]
                ] [readMORPHLINESTYLE2]
            ] 
            LineStyles
        ] 
        readMORPHLINESTYLE2: has [joinStyle hasFill?] [
            reduce [
                readUI16 
                readUI16 
                reduce [
                    readUB 2 
                    joinStyle: readUB 2 
                    hasFill?: readBitLogic 
                    readBitLogic 
                    readBitLogic 
                    readBitLogic 
                    (
                        skipBits 5 
                        readBitLogic
                    ) 
                    readUB 2
                ] 
                either joinStyle = 2 [readUI16] [none] 
                either hasFill? [readFILLSTYLE] [reduce [readRGBA readRGBA]]
            ]
        ] 
        readMORHFILLSTYLE: has [type] [
            byteAlign 
            reduce [
                type: readUI8 
                reduce case [
                    type = 0 [
                        [readRGBA readRGBA]
                    ] 
                    any [
                        type = 16 
                        type = 18 
                        type = 19
                    ] [
                        [readMATRIX readMATRIX readMORPHGRADIENT type]
                    ] 
                    type >= 64 [
                        [readUsedID readMATRIX readMATRIX]
                    ]
                ]
            ]
        ] 
        readMORPHGRADIENT: func [type /local gradients] [
            byteAlign 
            gradients: copy [] 
            loop readUI8 [
                insert/only tail gradients reduce [
                    readUI8 
                    readRGBA 
                    readUI8 
                    readRGBA
                ]
            ] 
            gradients
        ] 
        parse-DefineMorphShape: does [
            reduce [
                readID 
                readRECT 
                readRECT 
                readUI32 
                readMORPHFILLSTYLEARRAY 
                readMORPHLINESTYLEARRAY 
                readSHAPE 
                readSHAPE
            ]
        ] 
        parse-DefineMorphShape2: does [
            reduce [
                readID 
                readRECT 
                readRECT 
                readRECT 
                readRECT 
                (
                    readUB 6 
                    readBitLogic
                ) 
                readBitLogic 
                readUI32 
                readMORPHFILLSTYLEARRAY 
                readMORPHLINESTYLEARRAY 
                readSHAPE 
                readSHAPE
            ]
        ] 
        comment "---- end of include %parsers/morphing.r ----" 
        comment {
#### Include: %parsers/control-tags.r
#### Title:   "SWF control tags related parse functions"
#### Author:  ""
----} 
        parse-ExportAssets: has [result] [
            result: copy [] 
            loop readUI16 [
                repend result [readUsedID readSTRING]
            ] 
            result
        ] 
        parse-ImportAssets: has [result] [reduce [
                readSTRING 
                either swfVersion >= 8 [
                    reduce [
                        readUI8 
                        readUI8
                    ]
                ] [none] 
                (
                    result: copy [] 
                    loop readUI16 [
                        repend result [readID readSTRING]
                    ] 
                    result
                )
            ]] 
        parse-ImportAssets2: :parse-ImportAssets 
        parse-EnableDebugger: does [readRest] 
        parse-EnableDebugger2: does [reduce [
                readUI16 
                readRest
            ]] 
        parse-ScriptLimits: does [reduce [
                readUI16 
                readUI16
            ]] 
        parse-SetTabIndex: does [reduce [
                readUI16 
                readUI16
            ]] 
        parse-FileAttributes: does [
            print ["...FileAtts:" mold inBuffer] 
            reduce [
                readUB 3 
                readBitLogic 
                readBitLogic 
                readBitLogic 
                readBitLogic 
                readBitLogic 
                readUB 24
            ]
        ] 
        parse-DefineBinaryData: does [reduce [
                readID 
                readSI32 
                readRest
            ]] 
        parse-DefineScalingGrid: does [reduce [
                readUsedID 
                readRECT
            ]] 
        parse-DefineSceneAndFrameLabelData: has [scenes frameLabels] [
            scenes: copy [] 
            loop readUI8 [
                insert tail scenes reduce [
                    readUI30 
                    as-string readString
                ]
            ] 
            new-line/skip scenes true 2 
            frameLabels: copy [] 
            loop readUI8 [
                insert tail frameLabels reduce [
                    readUI30 
                    as-string readString
                ]
            ] 
            new-line/skip frameLabels true 2 
            reduce [scenes frameLabels]
        ] 
        parse-SerialNumber: does [
            reduce [
                readSI32 
                readSI32 
                readUI8 
                readUI8 
                readBytes 8 
                readBytes 8
            ]
        ] 
        comment "---- end of include %parsers/control-tags.r ----" 
        comment {
#### Include: %parsers/swf-importing.r
#### Title:   "SWF importing"
#### Author:  ""
----} 
        RemoveFilters: [1] 
        set 'import-swf-tag func [tagId tagData /local err action st st2] [
            reduce either none? action: select parseActions tagId [
                form-tag tagId tagData
            ] [
                setStreamBuffer tagData 
                if error? set/any 'err try [
                    set/any 'result do bind/copy action 'self
                ] [
                    print ajoin ["!!! ERROR while importing tag:" select swfTagNames tagId "(" tagId ")"] 
                    throw err
                ] 
                either inBuffer [
                    form-tag tagId head inBuffer
                ] [
                    copy #{}
                ]
            ]
        ] 
        form-tag: func [
            "Creates the SWF-TAG" 
            id [integer!] "Tag ID" 
            data [binary!] "Tag data block" 
            /local len
        ] [
            either any [
                62 < len: length? data 
                find [2 20 34 36 37 48] id
            ] [
                rejoin [
                    int-to-ui16 (63 or (id * 64)) 
                    int-to-ui32 len 
                    data
                ]
            ] [
                rejoin [
                    int-to-ui16 (len or (id * 64)) 
                    data
                ]
            ]
        ] 
        get-replacedID: func [id /local tmp] [
            foreach [oid nid] replaced-ids [
                if id = oid [
                    return nid
                ]
            ] 
            id
        ] 
        replacedID: func [/ui /local id newid] [
            id: copy/part inBuffer 2 
            newid: get-replacedID id 
            inBuffer: change inBuffer newid 
            newid
        ] 
        changeID: func [/local id new-id idbin newbin] [
            id: to-integer reverse copy idbin: copy/part inBuffer 2 
            tag-bin: either find used-ids id [
                new-id: 1 + (last used-ids) 
                insert tail used-ids new-id 
                newbin: int-to-ui16 new-id 
                repend replaced-ids [idbin newbin] 
                inBuffer: change inBuffer newbin 
                new-id
            ] [
                insert tail used-ids id 
                used-ids: sort used-ids 
                inBuffer: skip inBuffer 2 
                id
            ]
        ] 
        import-or-reuse: func [
            "Imports a new tag or uses already existing" 
            /local idbin sum usedid
        ] [
            idbin: copy/part inBuffer 2 
            sum: checksum/secure skip inBuffer 2 
            either usedid: select tag-checksums sum [
                print ["reusing..." mold usedid] 
                append replaced-ids reduce [idbin usedid] 
                clear head inBuffer 
                inBuffer: none
            ] [
                repend tag-checksums [sum int-to-ui16 changeID]
            ]
        ] 
        skipMATRIX: does [
            byteAlign 
            if readBitLogic [skipPair] 
            if readBitLogic [skipPair] 
            skipPair 
            byteAlign
        ] 
        skipGRADIENT: func [type] [
            byteAlign 
            skipBits 4 
            loop readUB 4 [
                skipUI8 
                either tagId >= 32 [skipRGBA] [skipRGB]
            ] 
            if type = 19 [skipBytes 2]
        ] 
        skipCXFORM: has [HasAddTerms? HasMultTerms? nbits] [
            HasAddTerms?: readBitLogic 
            HasMultTerms?: readBitLogic 
            nbits: readUB 4 
            if HasMultTerms? [skipBits (3 * nbits)] 
            if HasAddTerms? [skipBits (3 * nbits)]
        ] 
        skipCXFORMa: has [HasAddTerms? HasMultTerms? nbits] [
            HasAddTerms?: readBitLogic 
            HasMultTerms?: readBitLogic 
            nbits: readUB 4 
            if HasMultTerms? [skipBits (4 * nbits)] 
            if HasAddTerms? [skipBits (4 * nbits)]
        ] 
        skipSOUNDINFO: has [HasEnvelope? HasLoops? HasOutPoint? HasInPoint?] [
            skipBits 4 
            HasEnvelope?: readBitLogic 
            HasLoops?: readBitLogic 
            HasOutPoint?: readBitLogic 
            HasInPoint?: readBitLogic 
            if HasInPoint? [skipUI32] 
            if HasOutPoint? [skipUI32] 
            if HasLoops? [skipUI16] 
            if HasEnvelope? [skipBytes (readUI8 * 8)]
        ] 
        import-FILLSTYLEARRAY: does [
            byteAlign 
            loop readCount [
                import-FILLSTYLE
            ]
        ] 
        import-MORPHFILLSTYLEARRAY: does [
            byteAlign 
            loop readCount [
                import-MORPHFILLSTYLE
            ]
        ] 
        import-LINESTYLEARRAY: has [flags joinStyle hasFill?] [
            loop readCount [
                byteAlign 
                case [
                    tagId = 46 [skipBytes 12] 
                    any [tagId = 67 tagId = 83] [
                        skipUI16 
                        skipBits 2 
                        joinStyle: readUB 2 
                        hasFill?: readBitLogic 
                        skipBits 11 
                        if joinStyle = 2 [skipUI16] 
                        either hasFill? [import-FILLSTYLE] [skipRGBA]
                    ] 
                    tagId = 84 [
                        skipUI16 
                        skipUI16 
                        skipBits 2 
                        joinStyle: readUB 2 
                        hasFill?: readBitLogic 
                        skipBits 11 
                        if joinStyle = 2 [skipUI16] 
                        either hasFill? [import-FILLSTYLE] [skipBytes 8]
                    ] 
                    true [
                        skipUI16 
                        either tagId = 32 [skipRGBA] [skipRGB]
                    ]
                ]
            ]
        ] 
        import-MORPHLINESTYLEARRAY: has [flags joinStyle hasFill?] [
            loop readCount [
                either tagId = 46 [
                    skipBytes 12
                ] [
                    skipUI16 
                    skipUI16 
                    skipBits 2 
                    joinStyle: readUB 2 
                    hasFill?: readBitLogic 
                    skipBits 11 
                    if joinStyle = 2 [skipUI16] 
                    either hasFill? [import-FILLSTYLE] [skipBytes 8]
                ]
            ]
        ] 
        import-FILLSTYLE: has [type] [
            byteAlign 
            type: readUI8 
            case [
                type = 0 [
                    case [
                        find [46 84] tagId [
                            skipBytes 8
                        ] 
                        tagId >= 32 [skipRGBA] 
                        true [skipRGB]
                    ]
                ] 
                any [
                    type = 16 
                    type = 18 
                    type = 19
                ] [
                    either find [46 84] tagId [
                        skipMATRIX 
                        skipMATRIX 
                        skipGRADIENT type
                    ] [
                        skipMATRIX 
                        skipGRADIENT type
                    ]
                ] 
                type >= 64 [
                    either find [46 84] tagId [
                        replacedID 
                        skipMATRIX 
                        skipMATRIX
                    ] [
                        replacedID 
                        skipMATRIX
                    ]
                ]
            ]
        ] 
        import-MORPHFILLSTYLE: has [type] [
            type: readUI8 
            case [
                type = 0 [
                    skipBytes 8
                ] 
                any [
                    type = 16 
                    type = 18 
                    type = 19
                ] [
                    skipMATRIX 
                    skipMATRIX 
                    skipBytes (readUI8 * 10)
                ] 
                type >= 64 [
                    replacedID 
                    skipMATRIX 
                    skipMATRIX
                ]
            ]
        ] 
        import-SHAPERECORD: func [numFillBits numLineBits /local nBits lineType states records] [
            byteAlign 
            until [
                either readBitLogic [
                    either readBitLogic [
                        nBits: 2 + readUB 4 
                        either readBitLogic [
                            skipBits (2 * nBits)
                        ] [
                            skipBits (1 + nBits)
                        ]
                    ] [
                        nBits: 2 + readUB 4 
                        skipBits (4 * nBits)
                    ] 
                    false
                ] [
                    states: readUB 5 
                    either states = 0 [
                        true
                    ] [
                        if 0 < (states and 1) [skipPair] 
                        if 0 < (states and 2) [skipBits numFillBits] 
                        if 0 < (states and 4) [skipBits numFillBits] 
                        if 0 < (states and 8) [skipBits numLineBits] 
                        if 0 < (states and 16) [
                            import-FILLSTYLEARRAY 
                            import-LINESTYLEARRAY 
                            numFillBits: readUB 4 
                            numLineBits: readUB 4
                        ] 
                        false
                    ]
                ]
            ]
        ] 
        import-Shape: has [type] [
            changeID 
            skipRect 
            if tagId = 83 [
                skipRect 
                skipByte
            ] 
            import-FILLSTYLEARRAY 
            import-LINESTYLEARRAY 
            import-SHAPERECORD (byteAlign readUB 4) readUB 4
        ] 
        import-DefineButton: does [
            changeID 
            import-BUTTONRECORDs
        ] 
        import-DefineButton2: does [
            changeID 
            skipBytes 3 
            import-BUTTONRECORDs
        ] 
        import-DefineButtonSound: has [id] [
            replacedID 
            loop 4 [
                if #{0000} <> replacedID [skipSOUNDINFO]
            ]
        ] 
        import-BUTTONRECORDs: has [reserved states] [
            until [
                byteAlign 
                reserved: readUB 2 
                hasBlendMode: readBitLogic 
                hasFilterList: readBitLogic 
                states: readUB 4 
                either all [reserved = 0 states = 0] [true] [
                    replacedID 
                    skipUI16 
                    skipMATRIX 
                    if tagId = 34 [skipCXFORMa] 
                    if all [hasFilterList tagId = 34] [readFILTERS] 
                    if all [hasBlendMode tagId = 34] [skipUI8] 
                    false
                ]
            ]
        ] 
        import-PlaceObject2: has [flags1 flags2 atFiltersBufer filters] [
            flags1: readUI8 
            atFlags2Buffer: inBuffer 
            if tagId = 70 [
                flags2: readUI8
            ] 
            either spriteLevel = 0 [
                last-depth: init-depth + readUI16 
                change (skip inBuffer -2) int-to-ui16 last-depth
            ] [skipUI16] 
            either tagId = 70 [
                if any [
                    isSetBit? flags2 4 
                    all [
                        isSetBit? flags1 2 
                        isSetBit? flags2 5
                    ]
                ] [
                    skipString
                ] 
                if isSetBit? flags1 2 [replacedID] 
                if all [
                    isSetBit? flags2 1 
                    not empty? RemoveFilters
                ] [
                    if isSetBit? flags1 3 [skipMatrix] 
                    if isSetBit? flags1 4 [skipCXFORMa] 
                    if isSetBit? flags1 5 [skipUI16] 
                    if isSetBit? flags1 6 [skipString] 
                    if isSetBit? flags1 7 [skipUI16] 
                    atFiltersBufer: inBuffer 
                    filters: readFILTERS 
                    if all [1 = filters/1 2 = length? filters] [
                        remove/part atFiltersBufer ((index? inBuffer) - (index? atFiltersBufer)) 
                        atFlags2Buffer/1: to-char (flags2 and 254)
                    ]
                ]
            ] [
                if isSetBit? flags1 2 [replacedID]
            ]
        ] 
        import-DefineText: has [GlyphBits AdvanceBits HasFont? HasColor? HasYOffset? HasXOffset?] [
            changeID 
            skipRECT 
            skipMATRIX 
            byteAlign 
            GlyphBits: readUI8 
            AdvanceBits: readUI8 
            while [readBitLogic] [
                skipBits 3 
                HasFont?: readBitLogic 
                HasColor?: readBitLogic 
                HasYOffset?: readBitLogic 
                HasXOffset?: readBitLogic 
                if HasFont? [replacedID] 
                if HasColor? [either tagId = 11 [skipRGB] [skipRGBA]] 
                if HasXOffset? [skipSI16] 
                if HasYOffset? [skipSI16] 
                if HasFont? [skipUI16] 
                skipBits (readUI8 * (GlyphBits + AdvanceBits)) 
                byteAlign
            ]
        ] 
        import-DefineEditText: has [HasText? HasTextColor? HasMaxLength? HasFont? HasLayout?] [
            changeID 
            skipRECT 
            HasText?: readBitLogic 
            skipBits 4 
            HasTextColor?: readBitLogic 
            HasMaxLength?: readBitLogic 
            HasFont?: readBitLogic 
            skipBits 2 
            HasLayout?: readBitLogic 
            byteAlign 
            if HasFont? [replacedID skipUI16] 
            if HasTextColor? [skipRGBA] 
            if HasMaxLength? [skipUI16] 
            if HasLayout? [skipBytes 9] 
            skipString 
            if HasText? [skipString]
        ] 
        import-DefineSprite: has [i h] [
            changeID 
            skipUI16 
            i: index? inbuffer 
            h: copy/part head inBuffer (i - 1) 
            inBuffer: at join h importSWFTAGs inBuffer i
        ] 
        import-DefineMorphShape: does [
            changeID 
            skipRECT 
            skipRECT 
            skipUI32 
            import-MORPHFILLSTYLEARRAY 
            skipBytes (readCount * 12) 
            import-SHAPERECORD readUB 4 readUB 4 
            import-SHAPERECORD readUB 4 readUB 4
        ] 
        import-DefineMorphShape2: does [
            changeID 
            skipRECT 
            skipRECT 
            skipRECT 
            skipRECT 
            skipBytes 5 
            import-MORPHFILLSTYLEARRAY 
            import-MORPHLINESTYLEARRAY 
            import-SHAPERECORD readUB 4 readUB 4 
            import-SHAPERECORD readUB 4 readUB 4
        ] 
        import-ExportAssets: has [id name] [
            loop readUI16 [
                id: replacedID 
                name: join "imp_" readSTRING 
                unless find imported-names [name] [
                    repend imported-names [to-word name to integer! reverse copy id]
                ]
            ]
        ] 
        import-ImportAssets: does [
            skipSTRING 
            if swfVersion >= 8 [
                skipUI16
            ] 
            loop readUI16 [changeID skipSTRING]
        ] 
        import-SymbolClass: does [
            print "symbolClass" 
            loop readUI16 [replacedID skipSTRING]
        ] 
        comment "---- end of include %parsers/swf-importing.r ----" 
        comment {
#### Include: %parsers/swf-rescaling.new.r
#### Title:   "SWF sprites and movie clip related parse functions"
#### Author:  ""
----} 
        [
            rs/run 'imagick rs/run 'jpg-size 
            rs/run/fresh 'rswf rs/go 'robotek 
            rescale-swf %ovladac_olejak.swf run %xxx.swf
        ] 
        round2: func [m] [make 1 (m: m + 0.5) - mod m 1.0] 
        force-image-update?: true 
        unless value? 'scale-x [scale-x: 1] 
        unless value? 'scale-y [scale-y: 1] 
        rswf-rescale-index: 
        rswf-rescale-index-x: scale-x 
        rswf-rescale-index-y: scale-y 
        rsci: func [m] [
            to integer! 20 * (
                (m: 2.5E-2 + (
                        (max rswf-rescale-index-x rswf-rescale-index-y) * m / 20
                    )) - mod m 5E-2
            )
        ] 
        rsci-x: func [m] [
            to integer! 20 * ((m: 2.5E-2 + (rswf-rescale-index-x * m / 20)) - mod m 5E-2)
        ] 
        rsci-y: func [m] [
            to integer! 20 * ((m: 2.5E-2 + (rswf-rescale-index-y * m / 20)) - mod m 5E-2)
        ] 
        rscr: func [m [block!]] [
            reduce [
                rsci-x m/1 
                rsci-x m/2 
                rsci-y m/3 
                rsci-y m/4
            ]
        ] 
        rsc: func [val] [
            switch/default type?/word val [
                integer! [rsci-x val] 
                pair! [as-pair rsci-x val/x rsci-y val/y] 
                block! [forall val [change val rsc val/1] val: head val]
            ] [
                to (type? val) val * rswf-rescale-index-x
            ]
        ] 
        set 'rescale-swf-tag func [tagId tagData /local err action st st2] [
            reduce either none? action: select parseActions tagId [
                form-tag tagId tagData
            ] [
                setStreamBuffer tagData 
                clearOutBuffer 
                if error? set/any 'err try [
                    set/any 'result do bind/copy action 'self
                ] [
                    print ajoin ["!!! ERROR while rescaling tag:" select swfTagNames tagId "(" tagId ")"] 
                    throw err
                ] 
                if tagId = 6 [tagId: 21] 
                if tagId = 43 [print as-string tagData] 
                either result [
                    form-tag tagId result
                ] [copy #{}]
            ]
        ] 
        rescale-PlaceObject2: has [flags] [
            writeUI8 flags: readUI8 
            carryBytes 2 
            if isSetBit? flags 2 [carryBytes 2] 
            if isSetBit? flags 3 [rescaleMATRIX] 
            if isSetBit? flags 4 [carryCXFORMa] 
            if isSetBit? flags 5 [carryBytes 2] 
            if isSetBit? flags 6 [carryString] 
            if isSetBit? flags 7 [carryBytes 2] 
            carryBytes length? inBuffer 
            head outBuffer
        ] 
        rescale-PlaceObject3: has [flags1] [
            f: context [
                HasClipActions?: carryBitLogic 
                HasClipDepth?: carryBitLogic 
                HasName?: carryBitLogic 
                HasRatio?: carryBitLogic 
                HasColorTransform?: carryBitLogic 
                HasMatrix?: carryBitLogic 
                HasCharacter?: carryBitLogic 
                Move?: carryBitLogic 
                carryBits 3 
                HasImage?: carryBitLogic 
                HasClassName?: carryBitLogic 
                HasCacheAsBitmap?: carryBitLogic 
                HasBlendMode?: carryBitLogic 
                HasFilterList?: carryBitLogic
            ] 
            carryBytes 2 
            if any [
                f/HasClassName? 
                all [f/HasImage? f/HasCharacter?]
            ] [writeString readString] 
            if f/HasCharacter? [carryBytes 2] 
            if f/HasMatrix? [rescaleMATRIX] 
            carryBytes length? inBuffer 
            comment {
^-if f/HasColorTransform? [carryCXFORMa]
^-if f/HasRatio? [carryBytes 2]
^-if f/HasName?  [writeString readString]
^-if f/HasClipDepth?  [carryBytes 2]
^-carryBytes length? inBuffer

^-if f/HasFilterList? [rescaleFILTERLIST]
^-if f/BlendMode?     [carryBytes 1]
^-
^-} 
            head outBuffer
        ] 
        rescale-Shape: has [data tmp] [
            carryBytes 2 
            writeRect tmp: rscr readRect 
            if tagId >= 67 [
                writeRect rscr readRect 
                carryBytes 1
            ] 
            rescaleFILLSTYLEARRAY 
            rescaleLINESTYLEARRAY 
            rescaleSHAPERECORD (alignBuffers carryUB 4) carryUB 4 
            head outBuffer
        ] 
        rescale-DefineMorphShape: has [tmp] [
            carryBytes 2 
            writeRect rscr readRect 
            writeRect rscr readRect 
            if tagId = 84 [
                writeRect rscr readRect 
                writeRect rscr readRect 
                carryBytes 1
            ] 
            tmp: outBuffer 
            readBytes 4 
            rescaleMORPHFILLSTYLEARRAY 
            rescaleLINESTYLEARRAY 
            rescaleSHAPERECORD (alignBuffers carryUB 4) carryUB 4 
            alignBuffers 
            offs: (index? outBuffer) - (index? tmp) 
            outBuffer: tmp 
            writeUI32 offs 
            outBuffer: tail outBuffer 
            rescaleSHAPERECORD (carryUB 4) carryUB 4 
            head outBuffer
        ] 
        get-image-size-from-tagData: func [data /local tagId md5 file] [
            tagId: first data 
            md5: last data 
            either exists? probe file: rejoin [
                swfDir %tag tagId %_ md5 
                either find [20 36] tagId [%.png] [%.jpg]
            ] [
                get-image-size file
            ] [none]
        ] 
        combine-files: func [files size into /local tmp png? *wand2 *pixel] [
            print ["COMBINE to size:" size into] 
            with ctx-imagick [
                start 
                *pixel: NewPixelWand 
                not zero? MagickNewImage *wand size/x size/y *pixel 
                *wand2: NewMagickWand 
                png?: find into %.png 
                foreach [pos size file] files [
                    if block? file [parse file [to file! set file 1 skip]] 
                    if png? [file: replace copy file %.jpg %.png] 
                    unless all [
                        not zero? MagickReadImage *wand2 utf8/encode to-local-file file 
                        tmp: make image! size 
                        not zero? MagickExportImagePixels *wand2 0 0 size/x size/y "RGBO" 1 address? tmp 
                        not zero? MagickImportImagePixels *wand pos/x pos/y size/x size/y "RGBO" 1 address? tmp
                    ] [
                        errmsg: reform [
                            Exception/Severity "=" 
                            ptr-to-string tmp: MagickGetException *wand2 Exception
                        ] 
                        MagickRelinquishMemory tmp 
                        ClearMagickWand *wand2 
                        DestroyMagickWand *wand2 
                        ClearPixelWand *pixel 
                        DestroyPixelWand *pixel 
                        end 
                        make error! errmsg
                    ] 
                    ClearMagickWand *wand2
                ] 
                not zero? MagickWriteImages *wand to-local-file into 
                ClearMagickWand *wand2 
                DestroyMagickWand *wand2 
                ClearPixelWand *pixel 
                DestroyPixelWand *pixel 
                end
            ]
        ] 
        export-image-tag: func [tagId md5 data /alpha /rescale /local px py file file-sc img ext] [
            ext: either any [find [20 36] tagId alpha] [%.png] [%.jpg] 
            unless exists? probe file: rejoin [swfDir %tag tagId %_ md5 ext] [
                switch tagId [
                    6 [write/binary file JPG-repair either JPEGTables [join JPEGTables data/2] [data/2]] 
                    20 [
                        write/binary file ImageCore/PIX24-to-PNG context [
                            bARGB: as-binary zlib-decompress data/6 (4 * data/3 * data/4) 
                            size: as-pair data/3 data/4
                        ]
                    ] 
                    21 [write/binary file JPG-repair data/2] 
                    35 [
                        either alpha [
                            unless data/4 [
                                append data get-image-size replace copy file %.png %.jpg
                            ] 
                            img: make image! data/4 
                            img/alpha: as-binary zlib-decompress data/3 (img/size/1 * img/size/2) 
                            save/png file img
                        ] [
                            write/binary file JPG-repair data/2 
                            append data get-image-size file
                        ]
                    ] 
                    36 [
                        write/binary file ImageCore/ARGB2PNG context [
                            bARGB: as-binary zlib-decompress data/6 (4 * data/3 * data/4) 
                            size: as-pair data/3 data/4
                        ]
                    ]
                ]
            ] 
            either rescale [
                if any [not exists? file-sc: rejoin [scDir %tag tagId %_ md5 ext] force-image-update?] [
                    resize-image file file-sc reduce [rswf-rescale-index-x rswf-rescale-index-y]
                ] 
                read/binary file-sc
            ] [file]
        ] 
        rescale-DefineBits: has [md5 tmp] [
            md5: enbase/base checksum/method skip inBuffer 2 'md5 16 
            tmp: parse-DefineBits 
            writeUI16 tmp/1 
            writeBytes export-image-tag/rescale 6 md5 tmp 
            head outBuffer
        ] 
        rescale-DefineBitsJPEG2: has [md5 tmp] [
            md5: enbase/base checksum/method skip inBuffer 2 'md5 16 
            tmp: parse-DefineBitsJPEG2 
            writeUI16 tmp/1 
            writeBytes export-image-tag/rescale 21 md5 tmp 
            head outBuffer
        ] 
        rescale-DefineBitsJPEG3: has [md5 tmp img alphaimg] [
            md5: enbase/base checksum/method skip inBuffer 2 'md5 16 
            tmp: parse-DefineBitsJPEG3 
            writeUI16 tmp/1 
            img: export-image-tag/rescale 35 md5 tmp 
            writeUI32 length? img 
            writeBytes img 
            img: load export-image-tag/rescale/alpha 35 md5 tmp 
            writeBytes head head remove/part tail compress img/alpha -4 
            head outBuffer
        ] 
        rescale-DefineBitsLossless: has [md5 tmp img] [
            md5: enbase/base checksum/method skip inBuffer 2 'md5 16 
            tmp: parse-DefineBitsLossless 
            writeUI16 tmp/1 
            img: export-image-tag/rescale 20 md5 tmp 
            writeBytes ImageCore/ARGB2BLL ImageCore/load img 
            head outBuffer
        ] 
        rescale-DefineBitsLossless2: has [md5 tmp file file-sc] [
            md5: enbase/base checksum/method skip inBuffer 2 'md5 16 
            tmp: parse-DefineBitsLossless 
            writeUI16 tmp/1 
            img: export-image-tag/rescale 36 md5 tmp 
            writeBytes ImageCore/ARGB2BLL ImageCore/load img 
            head outBuffer
        ] 
        rescale-DefineSprite: has [] [
            carryBytes 4 
            writeBytes rescaleSWFTags inBuffer 
            head outBuffer
        ] 
        rescaleSHAPERECORD: func [numFillBits numLineBits /local states nBits cx cy dx dy posx posy rposx rposy mainPoints mp newx newy odx ody] [
            alignBuffers 
            posx: 0 
            posy: 0 
            rposx: 0 
            rposy: 0 
            oposx: 0 
            oposy: 0 
            moveX: moveY: none 
            mainPoints: copy [] 
            minX: minY: 1000000 
            maxX: maxY: -1000000 
            until [
                either readBitLogic [
                    either readBitLogic [
                        nBits: 2 + readUB 4 
                        either readBitLogic [
                            dx: readSB nBits 
                            dy: readSB nBits
                        ] [
                            either readBitLogic [
                                dx: 0 
                                dy: readSB nBits
                            ] [
                                dx: readSB nBits 
                                dy: 0
                            ]
                        ] 
                        oposx: oposx + dx 
                        oposy: oposy + dy 
                        dx: - rposx + rposx: (rsci-x oposx) 
                        dy: - rposy + rposy: (rsci-y oposy) 
                        either rposx > maxX [maxX: rposx] [if rposx < minX [minX: rposx]] 
                        either rposy > maxY [maxY: rposy] [if rposy < minY [minY: rposy]] 
                        case [
                            all [dx <> 0 dy <> 0] [
                                writeBit true 
                                writeBit true 
                                writeUB (-2 + nBits: getSBnBits reduce [dx dy]) 4 
                                writeBit true 
                                writeSB dx nBits 
                                writeSB dy nBits
                            ] 
                            dx <> 0 [
                                writeBit true 
                                writeBit true 
                                nBits: getSBitsLength dx 
                                writeUB (-2 + nBits) 4 
                                writeBit false 
                                writeBit false 
                                writeSB dx nBits
                            ] 
                            dy <> 0 [
                                writeBit true 
                                writeBit true 
                                nBits: getSBitsLength dy 
                                writeUB (-2 + nBits) 4 
                                writeBit false 
                                writeBit true 
                                writeSB dy nBits
                            ] 
                            true [
                                if find [46 84] tagId [
                                    writeBit true 
                                    writeBit true 
                                    writeUB 0 4 
                                    writeBit false 
                                    writeBit false 
                                    writeSB 0 2
                                ]
                            ]
                        ]
                    ] [
                        nBits: 2 + readUB 4 
                        cx: readSB nBits 
                        cy: readSB nBits 
                        oposx: oposx + cx 
                        oposy: oposy + cy 
                        cx: - rposx + rposx: (rsci-x oposx) 
                        cy: - rposy + rposy: (rsci-y oposy) 
                        dx: readSB nBits 
                        dy: readSB nBits 
                        oposx: oposx + dx 
                        oposy: oposy + dy 
                        dx: - rposx + rposx: (rsci-x oposx) 
                        dy: - rposy + rposy: (rsci-y oposy) 
                        either any [
                            false
                        ] [
                            case [
                                all [dx <> 0 dy <> 0] [
                                    print ["xy" dx dy] 
                                    writeBit true 
                                    writeBit true 
                                    writeUB (-2 + nBits: getSBnBits reduce [dx dy]) 4 
                                    writeBit true 
                                    writeSB dx nBits 
                                    writeSB dy nBits
                                ] 
                                dx <> 0 [
                                    writeBit true 
                                    writeBit true 
                                    nBits: getSBitsLength dx 
                                    writeUB (-2 + nBits) 4 
                                    writeBit false 
                                    writeBit false 
                                    writeSB dx nBits
                                ] 
                                dy <> 0 [
                                    writeBit true 
                                    writeBit true 
                                    nBits: getSBitsLength dy 
                                    writeUB (-2 + nBits) 4 
                                    writeBit false 
                                    writeBit true 
                                    writeSB dy nBits
                                ]
                            ]
                        ] [
                            either all [(abs cx) < 60 (abs cy) < 60] [
                                dx: cx + dx 
                                dy: cy + dy 
                                case [
                                    all [dx <> 0 dy <> 0] [
                                        writeBit true 
                                        writeBit true 
                                        writeUB (-2 + nBits: getSBnBits reduce [dx dy]) 4 
                                        writeBit true 
                                        writeSB dx nBits 
                                        writeSB dy nBits
                                    ] 
                                    dx <> 0 [
                                        writeBit true 
                                        writeBit true 
                                        nBits: getSBitsLength dx 
                                        writeUB (-2 + nBits) 4 
                                        writeBit false 
                                        writeBit false 
                                        writeSB dx nBits
                                    ] 
                                    dy <> 0 [
                                        writeBit true 
                                        writeBit true 
                                        nBits: getSBitsLength dy 
                                        writeUB (-2 + nBits) 4 
                                        writeBit false 
                                        writeBit true 
                                        writeSB dy nBits
                                    ]
                                ]
                            ] [
                                writeBit true 
                                writeBit false 
                                writeUB (-2 + nBits: getSBnBits reduce [cx cy dx dy]) 4 
                                writeSB cx nBits 
                                writeSB cy nBits 
                                writeSB dx nBits 
                                writeSB dy nBits
                            ]
                        ] 
                        either rposx > maxX [maxX: rposx] [if rposx < minX [minX: rposx]] 
                        either rposy > maxY [maxY: rposy] [if rposy < minY [minY: rposy]]
                    ] 
                    false
                ] [
                    states: readUB 5 
                    comment {
^-^-^-^-if all [
^-^-^-^-^-not none? moveX
^-^-^-^-^-any [
^-^-^-^-^-^-moveX <> posX
^-^-^-^-^-^-moveY <> posY
^-^-^-^-^-]
^-^-^-^-^-;all [
^-^-^-^-^-;^-5 > abs (dx: moveX - posx)
^-^-^-^-^-;^-5 > abs (dy: moveY - posy)
^-^-^-^-^-;]
^-^-^-^-][
^-^-^-^-^-mindiffx: mindiffy: 10000
^-^-^-^-^-newPos: none
^-^-^-^-^-forall mainPoints [
^-^-^-^-^-^-
^-^-^-^-^-^-;print [abs (mainPoints/1  - (as-pair posx posy))]
^-^-^-^-^-^-if all [
^-^-^-^-^-^-^-mindiffx > tmpx: abs (mainPoints/1/x  - posx)
^-^-^-^-^-^-^-mindiffy > tmpy: abs (mainPoints/1/y  - posy)
^-^-^-^-^-^-][
^-^-^-^-^-^-^-mindiffx: tmpx
^-^-^-^-^-^-^-mindiffy: tmpy
^-^-^-^-^-^-^-newPos: mainPoints/1
^-^-^-^-^-^-]
^-^-^-^-^-]
^-^-^-^-^-mainPoints: head mainPoints
^-^-^-^-^-print ["midiff:" mindiffx mindiffy "newPos:" newPos "oldPos:" as-pair posX posY]
^-^-^-^-^-if all [
^-^-^-^-^-^-mindiffx < 20
^-^-^-^-^-^-mindiffy < 20
^-^-^-^-^-][
^-^-^-^-^-^-dx: newPos/x - posx
^-^-^-^-^-^-dy: newPos/y - posy
^-^-^-^-^-^-posX: newPos/x
^-^-^-^-^-^-posY: newPos/y
^-^-^-^-^-
^-^-^-^-^-
^-^-^-^-^-^-;print ["AAAAAAAAAAAA:" moveX posX MoveY posY dx dy]
^-^-^-^-^-^-;dx: moveX - posx
^-^-^-^-^-^-;dy: moveY - posy
^-^-^-^-^-^-case [
^-^-^-^-^-^-^-all [dx <> 0 dy <> 0][
^-^-^-^-^-^-^-^-;print "xy"
^-^-^-^-^-^-^-^-writeBit true
^-^-^-^-^-^-^-^-writeBit true
^-^-^-^-^-^-^-^-writeUB (-2 + nBits: getSBnBits reduce [dx dy]) 4 ;new nBits
^-^-^-^-^-^-^-^-writeBit true
^-^-^-^-^-^-^-^-writeSB dx nBits
^-^-^-^-^-^-^-^-writeSB dy nBits
^-^-^-^-^-^-^-]
^-^-^-^-^-^-^-dx <> 0 [
^-^-^-^-^-^-^-^-;print "x"
^-^-^-^-^-^-^-^-writeBit true
^-^-^-^-^-^-^-^-writeBit true
^-^-^-^-^-^-^-^-nBits: getSBitsLength dx
^-^-^-^-^-^-^-^-writeUB (-2 + nBits) 4
^-^-^-^-^-^-^-^-writeBit false
^-^-^-^-^-^-^-^-writeBit false
^-^-^-^-^-^-^-^-writeSB dx nBits
^-^-^-^-^-^-^-]
^-^-^-^-^-^-^-dy <> 0 [
^-^-^-^-^-^-^-^-;print "y"
^-^-^-^-^-^-^-^-writeBit true
^-^-^-^-^-^-^-^-writeBit true
^-^-^-^-^-^-^-^-nBits: getSBitsLength dy
^-^-^-^-^-^-^-^-writeUB (-2 + nBits) 4
^-^-^-^-^-^-^-^-writeBit false
^-^-^-^-^-^-^-^-writeBit true
^-^-^-^-^-^-^-^-writeSB dy nBits
^-^-^-^-^-^-^-]
^-^-^-^-^-^-^-;true [print "!!!!!!!!!!!!!!!!!!"]
^-^-^-^-^-^-]
^-^-^-^-^-]
^-^-^-^-]
^-^-^-^-} 
                    either states = 0 [
                        writeBit false 
                        writeUB 0 5 
                        alignBuffers 
                        true
                    ] [
                        writeBit false 
                        writeUB states 5 
                        if 0 < (states and 1) [
                            set [oposx oposy] readSBPair 
                            moveX: oposx 
                            moveY: oposy 
                            rposx: rsci-x oposx 
                            rposy: rsci-y oposy 
                            writeSBPair reduce [
                                rposx 
                                rposy
                            ]
                        ] 
                        if 0 < (states and 2) [carryUB numFillBits] 
                        if 0 < (states and 4) [carryUB numFillBits] 
                        if 0 < (states and 8) [carryUB numLineBits] 
                        if 0 < (states and 16) [
                            rescaleFILLSTYLEARRAY 
                            rescaleLINESTYLEARRAY 
                            numFillBits: carryUB 4 
                            numLineBits: carryUB 4
                        ] 
                        false
                    ]
                ]
            ]
        ] 
        rescaleSBPair: has [nBits x y] [
            nBits: readUB 5 
            x: rsci-x readSB nBits 
            y: rsci-y readSB nBits 
            writeSBPair reduce [x y]
        ] 
        rescaleMATRIX: does [
            alignBuffers 
            {nsx: (scx * sx)
nry: (scx * ry)
ntx: (scx * tx)
nrx: (scy * rx)
nsy: (scy * sy)
nty: (scy * ty)

[(scx * sx) (scx * ry) (scx * tx)]
[(scy * rx) (scy * sy) (scy * ty)]
[ 0         0          1         ]





sx: 0.789321899414063
sy: 1.05244445800781
rx: 0.287307739257813
ry: -0.383087158203125
tx: 1939
ty: 434
x: 0
y: 0
mm: func[x y sx sy rx ry tx ty][
^-x: x / 20
^-y: y / 20
^-a: sx / 20
^-c: ry / 20
^-b: rx / 20
^-d: sy / 20
^-tx: tx / 20
^-ty: ty / 20
^-
^-
^-tmp: (a * d) - (b * c)
^-ai:   d / tmp
^-bi: - b / tmp
^-ci: - c / tmp
^-di:   a / tmp
^-txi: ((c * ty) - (d * tx)) / tmp
^-tyi: -((a * ty) - (b * tx)) / tmp

^-reduce [
^-^-20 * (xA: (x * ai) + (y * ci) + txi)
^-^-20 * (yA: (x * bi) + (y * di) + tyi)
^-]
]

;sx ry tx
;rx sy ty
;0  0  1

I have a placeObject with some transformation:
Scale: [0.707107543945313 0.707107543945313]
Rotate: [0.70709228515625 -0.707107543945313]
Translate: [5000 1000]

which can be writen in matrix as:
[ 0.707107543945313  -0.707107543945313 5000 ]
[ 0.70709228515625    0.707107543945313 1000 ]
[ 0                   0                 1    ]

I was scaling it proportionaly, which was easy, I just scaled the transform part.
But now I need to scale unproportionaly, which leads to distortion:/

Don't you have any idea how to solve it? If you understand me?

      
;.5 0 0
; 0 1 0
; 0 0 1

nsx: (sx * scx)

[scx 0 0] [sx ry tx
[0 scy 0] [rx sy ty
[0   0 1] [0  0  1 ]

nsx: (scx * sx)
nry: (scx * ry)
ntx: (scx * tx)
nrx: (scy * rx)
nsy: (scy * sy)
nty: (scy * ty)

[
(a1 * a2)  + (b1 * c2)^-^-(a1 * b1) + (b1 * d2)
(c1 * a2)  + (d1 * c2)^-^-(c1 * b2) + (d1 * d2)
(tx1 * a2) + (ty1 * c2) + tx2^-(tx1 * b2) + (ty1 * d2) + ty2
]^-^-

n: probe mm 0 0 sx sy rx ry tx ty
n/1: n/1 / 2
;ask ""
probe reduce [
^-round ((0 + ((n/1 * sx) + (n/2 * ry))) / -20)
^-round ((0 + ((n/2 * sy) + (n/1 * rx))) / -20)
]
a: 
xx: (x * a) + (y * c) + tx
yy: (x * b) + (y * d) + ty^-^-
^-^-^-
;probe mm n/1 n/2  sx sy rx ry tx ty


} 
            if carryBitLogic [
                writePair readPair
            ] 
            if carryBitLogic [
                tmp: readPair 
                writePair reduce [(rswf-rescale-index-y * tmp/1 * power rswf-rescale-index-x -1) (rswf-rescale-index-x * tmp/2 * power rswf-rescale-index-y -1)]
            ] 
            rescaleSBPair 
            alignBuffers
        ] 
        rescaleMATRIXall: does [
            alignBuffers 
            if carryBitLogic [
                tmp: readPair 
                writePair reduce [rswf-rescale-index-x * tmp/1 rswf-rescale-index-y * tmp/2]
            ] 
            if carryBitLogic [
                tmp: readPair 
                writePair reduce [rswf-rescale-index-y * tmp/1 rswf-rescale-index-x * tmp/2]
            ] 
            rescaleSBPair 
            alignBuffers
        ] 
        rescaleGRADIENT: func [type] [
            alignBuffers 
            carryBits 4 
            loop carryUB 4 [
                carryBytes either tagId >= 32 [5] [4]
            ] 
            if all [type = 19 tagId = 83] [carryBytes 2]
        ] 
        rescaleMORPHGRADIENT: func [type /local gradients] [
            alignBuffers 
            loop carryUI8 [
                carryBytes 10
            ]
        ] 
        rescaleFILLSTYLEARRAY: does [
            alignBuffers 
            loop carryCount [
                rescaleFILLSTYLE
            ]
        ] 
        rescaleMORPHFILLSTYLEARRAY: does [
            alignBuffers 
            loop carryCount [
                rescaleMORPHFILLSTYLE
            ]
        ] 
        rescaleFILLSTYLE: has [type] [
            alignBuffers 
            type: readUI8 
            case [
                type = 66 [type: 64 print "66 000000000000000000000000"] 
                type = 67 [type: 65 print "67 000000000000000000000000"]
            ] 
            writeUI8 type 
            case [
                type = 0 [
                    case [
                        find [46 84] tagId [
                            carryBytes 8
                        ] 
                        tagId >= 32 [carryBytes 4] 
                        true [carryBytes 3]
                    ]
                ] 
                any [
                    type = 16 
                    type = 18 
                    type = 19
                ] [
                    either find [46 84] tagId [
                        rescaleMATRIX 
                        rescaleMATRIX 
                        rescaleMORPHGRADIENT type
                    ] [
                        rescaleMATRIXall 
                        rescaleGRADIENT type
                    ]
                ] 
                type >= 64 [
                    reduce either find [46 84] tagId [
                        carryBytes 2 
                        rescaleMATRIX 
                        rescaleMATRIX
                    ] [
                        carryBytes 2 
                        rescaleMATRIX
                    ]
                ]
            ]
        ] 
        rescaleMORPHFILLSTYLE: does [
            alignBuffers 
            type: readUI8 
            case [
                type = 66 [type: 64 print "66 000000000000000000000000"] 
                type = 67 [type: 65 print "67 000000000000000000000000"]
            ] 
            writeUI8 type 
            case [
                type = 0 [
                    carryBytes 8
                ] 
                any [
                    type = 16 
                    type = 18 
                    type = 19
                ] [
                    rescaleMATRIXall 
                    rescaleMATRIXall 
                    rescaleMORPHGRADIENT type
                ] 
                type >= 64 [
                    carryBytes 2 
                    rescaleMATRIX 
                    rescaleMATRIX
                ]
            ]
        ] 
        rescaleLINESTYLEARRAY: has [LineStyles joinStyle hasFill?] [
            alignBuffers 
            loop carryCount [
                alignBuffers 
                case [
                    tagId = 46 [
                        writeUI16 rsci readUI16 
                        writeUI16 rsci readUI16 
                        carryBytes 8
                    ] 
                    any [tagId = 67 tagId = 83] [
                        writeUI16 rsci readUI16 
                        carryBits 2 
                        joinStyle: carryUB 2 
                        hasFill?: carryBitLogic 
                        carryBits 11 
                        if joinStyle = 2 [carryBytes 2] 
                        either hasFill? [rescaleFILLSTYLE] [carryBytes 4]
                    ] 
                    tagId = 84 [
                        writeUI16 rsci readUI16 
                        writeUI16 rsci readUI16 
                        carryBits 2 
                        joinStyle: carryUB 2 
                        hasFill?: carryBitLogic 
                        carryBits 11 
                        if joinStyle = 2 [carryBytes 2] 
                        either hasFill? [rescaleFILLSTYLE] [carryBytes 8]
                    ] 
                    true [
                        writeUI16 rsci readUI16 
                        carryBytes either tagId = 32 [4] [3]
                    ]
                ]
            ]
        ] 
        rescaleMORPHLINESTYLEARRAY: has [LineStyles] [
            alignBuffers 
            loop carryCount [
                alignBuffers 
                writeUI16 rsci readUI16 
                writeUI16 rsci readUI16 
                case [
                    tagId = 46 [
                        writeUI16 rsci readUI16 
                        writeUI16 rsci readUI16 
                        carryBytes 8
                    ] 
                    any [tagId = 67 tagId = 83] [
                        writeUI16 rsci readUI16 
                        carryBits 2 
                        joinStyle: carryUB 2 
                        hasFill?: carryBitLogic 
                        carryBits 11 
                        if joinStyle = 2 [carryBytes 2] 
                        either hasFill? [rescaleFILLSTYLE] [carryBytes 4]
                    ] 
                    tagId = 84 [
                        writeUI16 rsci readUI16 
                        writeUI16 rsci readUI16 
                        carryBits 2 
                        joinStyle: carryUB 2 
                        hasFill?: carryBitLogic 
                        carryBits 11 
                        if joinStyle = 2 [carryBytes 2] 
                        either hasFill? [rescaleFILLSTYLE] [carryBytes 8]
                    ] 
                    true [
                        writeUI16 rsci readUI16 
                        carryBytes either tagId = 32 [4] [3]
                    ]
                ]
            ]
        ] 
        carryCXFORM: has [HasAddTerms? HasMultTerms? nbits] [
            HasAddTerms?: carryBitLogic 
            HasMultTerms?: carryBitLogic 
            nbits: carryUB 4 
            if HasMultTerms? [
                carrySB nbits 
                carrySB nbits 
                carrySB nbits
            ] 
            if HasAddTerms? [
                carrySB nbits 
                carrySB nbits 
                carrySB nbits
            ] 
            alignBuffers
        ] 
        carryCXFORMa: has [HasAddTerms? HasMultTerms? nbits] [
            HasAddTerms?: carryBitLogic 
            HasMultTerms?: carryBitLogic 
            nbits: carryUB 4 
            if HasMultTerms? [
                carrySB nbits 
                carrySB nbits 
                carrySB nbits 
                carrySB nbits
            ] 
            if HasAddTerms? [
                carrySB nbits 
                carrySB nbits 
                carrySB nbits 
                carrySB nbits
            ] 
            alignBuffers
        ] 
        comment {---- end of include %parsers/swf-rescaling.new.r ----} 
        comment {
#### Include: %parsers/swf-optimize.r
#### Title:   "SWF sprites and movie clip related parse functions"
#### Author:  ""
----} 
        use-BB-optimization?: false 
        set 'swf-tag-optimize func [tagId tagData /local err action st st2] [
            reduce either none? action: select parseActions tagId [
                form-tag tagId tagData
            ] [
                setStreamBuffer tagData 
                clearOutBuffer 
                if error? set/any 'err try [
                    set/any 'result do bind/copy action 'self
                ] [
                    print ajoin ["!!! ERROR while optimizing tag:" select swfTagNames tagId "(" tagId ")"] 
                    throw err
                ] 
                result
            ]
        ] 
        optimize-detectBmpFillBounds: has [
            shape result fillStyles lineStyles pos st dx dy tmp lineStyle fillStyle0 fillStyle1 p fill 
            posX posY t0x t0y s0x s0y r0x r0y t1x t1y s1x s1y r1x r1y bmpFills noCropBitmaps usedFills usedLines allUsedLines allUsedFills 
            lastBmpFill
        ] [
            bmpFills: copy [] 
            noCropBitmaps: copy [] 
            id: readUI16 
            bounds: readRect 
            if tagId >= 67 [
                readRect 
                skipBytes 1
            ] 
            fillStyles: readFILLSTYLEARRAY 
            lineStyles: readLINESTYLEARRAY 
            byteAlign 
            lineStyle: fillStyle0: fillStyle1: none 
            pos: 0x0 
            posX: posY: 0 
            fill: fill0posX: fill1posX: fill0posY: fill1posY: fill0: fill1: none 
            minX: fill0minX: fill1minX: 
            minY: fill0minY: fill1minY: 100000000 
            maxX: fill0maxX: fill1maxX: 
            maxY: fill0maxY: fill1maxY: -100000000 
            usedFills: copy [] 
            usedLines: copy [] 
            allUsedFills: copy [] 
            allUsedLines: copy [] 
            allBounds: copy [] 
            add-BmpFill: func [id minx miny maxx maxy sx sy rx ry tx ty /local lastBmpFill] [
                lastBmpFill: skip tail bmpFills -11 
                either all [
                    id = lastBmpFill/1 
                    sx = lastBmpFill/6 
                    sy = lastBmpFill/7 
                    rx = lastBmpFill/8 
                    ry = lastBmpFill/9 
                    tx = lastBmpFill/10 
                    ty = lastBmpFill/11
                ] [
                    change/part next lastBmpFill reduce [
                        min minX lastBmpFill/2 
                        min minY lastBmpFill/3 
                        max maxX lastBmpFill/4 
                        max maxY lastBmpFill/5
                    ] 4
                ] [
                    repend bmpFills [id minx miny maxx maxy sx sy rx ry tx ty]
                ]
            ] 
            numFillBits: readUB 4 
            numLineBits: readUB 4 
            until [
                either readBitLogic [
                    either readBitLogic [
                        nBits: 2 + readUB 4 
                        either readBitLogic [
                            posX: posX + readSB nBits 
                            posY: posY + readSB nBits
                        ] [
                            either readBitLogic [
                                posY: posY + readSB nBits
                            ] [posX: posX + readSB nBits]
                        ] 
                        if fill0posX [
                            fill0posX: posX 
                            fill0posY: posY 
                            fill0minX: min fill0minX fill0posX 
                            fill0maxX: max fill0maxX fill0posX 
                            fill0minY: min fill0minY fill0posY 
                            fill0maxY: max fill0maxY fill0posY
                        ] 
                        if fill1posX [
                            fill1posX: posX 
                            fill1posY: posY 
                            fill1minX: min fill1minX fill1posX 
                            fill1maxX: max fill1maxX fill1posX 
                            fill1minY: min fill1minY fill1posY 
                            fill1maxY: max fill1maxY fill1posY
                        ] 
                        minX: min minX posX 
                        maxX: max maxX posX 
                        minY: min minY posY 
                        maxY: max maxY posY
                    ] [
                        nBits: 2 + readUB 4 
                        x0: posX 
                        y0: posY 
                        x1: x0 + readSB nBits 
                        y1: y0 + readSB nBits 
                        posX: x1 + readSB nBits 
                        posY: y1 + readSB nBits 
                        minY: min minY yMin: either y0 > posY [
                            either y1 > posY [posY] [
                                t: - (y1 - y0) / (posY - (2 * y1) + y0) 
                                (t1: 1 - t) * t1 * y0 + (2 * t * t1 * y1) + (t * t * posY)
                            ]
                        ] [
                            either y1 > y0 [y0] [
                                t: - (y1 - y0) / (posY - (2 * y1) + y0) 
                                (t1: 1 - t) * t1 * y0 + (2 * t * t1 * y1) + (t * t * posY)
                            ]
                        ] 
                        maxY: max maxY yMax: either y0 > posY [
                            either y1 < y0 [y0] [
                                t: - (y1 - y0) / (posY - (2 * y1) + y0) 
                                (t1: 1 - t) * t1 * y0 + (2 * t * t1 * y1) + (t * t * posY)
                            ]
                        ] [
                            either posY > y1 [posY] [
                                t: - (y1 - y0) / (posY - (2 * y1) + y0) 
                                (t1: 1 - t) * t1 * y0 + (2 * t * t1 * y1) + (t * t * posY)
                            ]
                        ] 
                        minX: min minX xMin: either x0 > posX [
                            either x1 > posX [posX] [
                                t: - (x1 - x0) / (posX - (2 * x1) + x0) 
                                (t1: 1 - t) * t1 * x0 + (2 * t * t1 * x1) + (t * t * posX)
                            ]
                        ] [
                            either x1 > x0 [x0] [
                                t: - (x1 - x0) / (posX - (2 * x1) + x0) 
                                (t1: 1 - t) * t1 * x0 + (2 * t * t1 * x1) + (t * t * posX)
                            ]
                        ] 
                        maxX: max maxX xMax: either x0 > posX [
                            either x1 < x0 [x0] [
                                t: - (x1 - x0) / (posX - (2 * x1) + x0) 
                                (t1: 1 - t) * t1 * x0 + (2 * t * t1 * x1) + (t * t * posX)
                            ]
                        ] [
                            either x1 < posX [posX] [
                                t: - (x1 - x0) / (posX - (2 * x1) + x0) 
                                (t1: 1 - t) * t1 * x0 + (2 * t * t1 * x1) + (t * t * posX)
                            ]
                        ] 
                        if fill0posX [
                            fill0posX: posX 
                            fill0posY: posY 
                            fill0minX: min fill0minX xMin 
                            fill0maxX: max fill0maxX xMax 
                            fill0minY: min fill0minY yMin 
                            fill0maxY: max fill0maxY yMax
                        ] 
                        if fill1posX [
                            fill1posX: posX 
                            fill1posY: posY 
                            fill1minX: min fill1minX xMin 
                            fill1maxX: max fill1maxX xMax 
                            fill1minY: min fill1minY yMin 
                            fill1maxY: max fill1maxY yMax
                        ]
                    ] 
                    false
                ] [
                    states: readUB 5 
                    either states = 0 [
                        byteAlign 
                        true
                    ] [
                        if 0 < (states and 1) [
                            set [posX posY] readSBPair 
                            if 0 = (states and 16) [
                                minX: min minX posX 
                                maxX: max maxX posX 
                                minY: min minY posY 
                                maxY: max maxY posY
                            ]
                        ] 
                        prevFill0: fillStyle0 
                        prevFill1: fillStyle1 
                        fill0: fill1: none 
                        if 0 < (states and 2) [
                            fillStyle0: either fill0: readUB numFillBits [
                                either fill0 > 0 [
                                    append usedFills fill0 
                                    pick fillStyles fill0
                                ] [none]
                            ] [none]
                        ] 
                        if 0 < (states and 4) [
                            fillStyle1: either fill1: readUB numFillBits [
                                either fill1 > 0 [
                                    append usedFills fill1 
                                    pick fillStyles fill1
                                ] [none]
                            ] [none]
                        ] 
                        if 0 < (states and 8) [
                            lineStyle: either tmp: readUB numLineBits [
                                either tmp > 0 [
                                    append usedLines tmp 
                                    pick lineStyles tmp
                                ] [none]
                            ] [none]
                        ] 
                        if fillStyle0 <> prevFill0 [
                            if all [prevFill0 find [64 65 66 67] prevFill0/1 not none? fill0] [
                                add-BmpFill prevFill0/2/1 fill0minX fill0minY fill0maxX fill0maxY s0x s0y r0x r0y t0x t0y
                            ] 
                            either all [
                                fillStyle0 
                                find [64 65 66 67] fillStyle0/1
                            ] [
                                tmp: fillStyle0/2/2 
                                t0x: tmp/3/1 
                                t0y: tmp/3/2 
                                either tmp/2 [
                                    r0x: tmp/2/1 
                                    r0y: tmp/2/2
                                ] [
                                    r0x: r0y: 0
                                ] 
                                either tmp/1 [
                                    s0x: tmp/1/1 
                                    s0y: tmp/1/2
                                ] [
                                    s0x: s0y: 0
                                ] 
                                fill0posX: posX 
                                fill0posY: posY 
                                fill0minX: fill0minY: 100000000 
                                fill0maxX: fill0maxY: -100000000
                            ] [
                                t0x: t0y: r0x: r0y: s0x: s0y: 
                                fill0posX: fill0posY: none
                            ]
                        ] 
                        if fillStyle1 <> prevFill1 [
                            if all [prevFill1 find [64 65 66 67] prevFill1/1 not none? fill1] [
                                add-BmpFill prevFill1/2/1 fill1minX fill1minY fill1maxX fill1maxY s1x s1y r1x r1y t1x t1y
                            ] 
                            either all [
                                fillStyle1 
                                find [64 65 66 67] fillStyle1/1
                            ] [
                                tmp: fillStyle1/2/2 
                                t1x: tmp/3/1 
                                t1y: tmp/3/2 
                                either tmp/2 [
                                    r1x: tmp/2/1 
                                    r1y: tmp/2/2
                                ] [
                                    r1x: r1y: 0
                                ] 
                                either tmp/1 [
                                    s1x: tmp/1/1 
                                    s1y: tmp/1/2
                                ] [
                                    s1x: s1y: 0
                                ] 
                                fill1posX: posX 
                                fill1posY: posY 
                                fill1minX: fill1minY: 100000000 
                                fill1maxX: fill1maxY: -100000000
                            ] [
                                t1x: t1y: r1x: r1y: s1x: s1y: 
                                fill1posX: fill1posY: none
                            ]
                        ] 
                        if fill0posX [
                            fill0minX: min fill0minX fill0posX 
                            fill0maxX: max fill0maxX fill0posX 
                            fill0minY: min fill0minY fill0posY 
                            fill0maxY: max fill0maxY fill0posY
                        ] 
                        if fill1posX [
                            fill1minX: min fill1minX fill1posX 
                            fill1maxX: max fill1maxX fill1posX 
                            fill1minY: min fill1minY fill1posY 
                            fill1maxY: max fill1maxY fill1posY
                        ] 
                        if 0 < (states and 16) [
                            repend/only allUsedFills [
                                copy/deep fillStyles 
                                copy sort unique usedFills
                            ] 
                            repend/only allUsedLines [
                                copy/deep lineStyles 
                                copy sort unique usedLines
                            ] 
                            append/only allBounds reduce [to-integer minX round maxX to-integer minY round maxY] 
                            clear head usedFills 
                            clear head usedLines 
                            byteAlign 
                            fillStyles: readFILLSTYLEARRAY 
                            lineStyles: readLINESTYLEARRAY 
                            prevFill0: prevFill1: lineStyle: fillStyle0: fillStyle1: none 
                            pos: 0x0 
                            posX: posY: 0 
                            fill: fill0posX: fill1posX: fill0posY: fill1posY: fill0: fill1: none 
                            minX: fill0minX: fill1minX: 
                            minY: fill0minY: fill1minY: 100000000 
                            maxX: fill0maxX: fill1maxX: 
                            maxY: fill0maxY: fill1maxY: -100000000 
                            numFillBits: readUB 4 
                            numLineBits: readUB 4
                        ] 
                        false
                    ]
                ]
            ] 
            if all [fill0posX fillStyle0 find [64 65 66 67] fillStyle0/1] [
                add-BmpFill fillStyle0/2/1 fill0minX fill0minY fill0maxX fill0maxY s0x s0y r0x r0y t0x t0y
            ] 
            if all [fill1posX fillStyle1 find [64 65 66 67] fillStyle1/1] [
                add-BmpFill fillStyle1/2/1 fill1minX fill1minY fill1maxX fill1maxY s1x s1y r1x r1y t1x t1y
            ] 
            repend/only allUsedFills [
                copy/deep fillStyles 
                copy sort unique usedFills
            ] 
            repend/only allUsedLines [
                copy/deep lineStyles 
                copy sort unique usedLines
            ] 
            append/only allBounds reduce [to-integer minX round maxX to-integer minY round maxY] 
            clear usedLines 
            clear usedFills 
            comment {
^-shape: parse-DefineShape
^-;print length? shape
^-;ask ""
^-;print "-=-=-=-"
^-fillStyles: shape/4/1


^-lineStyles: shape/4/2
^-lineStyle: fillStyle0: fillStyle1: none
^-pos: 0x0
^-posX: posY: 0
^-fill: fill0posX: fill1posX: fill0posY: fill1posY: none
^-minX: fill0minX: fill1minX:
^-minY: fill0minY: fill1minY:  100000000
^-maxX: fill0maxX: fill1maxX:
^-maxY: fill0maxY: fill1maxY: -100000000
^-
^-
^-allUsedFills: copy []
^-usedFills: copy []
^-usedLines: copy []
^-allUsedLines: copy []
^-allBounds: copy []
^-
^-parse shape/4/3 [
^-^-any [
^-^-^-'style set st block! p: (
^-^-^-^-;print ["style:" mold st]
^-^-^-^-if all [st/2 st/2 > 0] [append usedFills st/2]
^-^-^-^-if all [st/3 st/3 > 0] [append usedFills st/3]
^-^-^-^-if all [st/4 st/4 > 0] [append usedLines st/4]
^-^-^-^-;ask ""
^-^-^-^-if all [fill0posX fill0bmp find [64 65 66 67] fill0bmp/1 not none? st/2] [
^-^-^-^-^-;print ["end fill0-" fill0posX fill0posY]
^-^-^-^-^-repend bmpFills reduce [fill0bmp/2/1 fill0minX fill0minY fill0maxX fill0maxY s0x s0y r0x r0y t0x t0y]
^-^-^-^-^-fill0bmp: none
^-^-^-^-]
^-^-^-^-if all [fill1posX fill1bmp find [64 65 66 67] fill1bmp/1 not none? st/3] [
^-^-^-^-^-;print ["end fill1-" fill1posX fill1posY]
^-^-^-^-^-repend bmpFills reduce [fill1bmp/2/1 fill1minX fill1minY fill1maxX fill1maxY s1x s1y r1x r1y t1x t1y]
^-^-^-^-^-fill1bmp: none
^-^-^-^-]
^-^-^-^-;smazat?-> if fill1pos [fill1pos: fill1pos + as-pair dx dy]
^-^-^-^-fill0bmp: either fill0: st/2 [fillStyles/(fill0)][none]
^-^-^-^-fill1bmp: either fill1: st/3 [fillStyles/(fill1)][none]
^-^-^-^-if st/1 [
^-^-^-^-^-posX: st/1/1
^-^-^-^-^-posY: st/1/2
^-^-^-^-^-minX: min minX posX
^-^-^-^-^-maxX: max maxX posX
^-^-^-^-^-minY: min minY posY
^-^-^-^-^-maxY: max maxY posY
^-^-^-^-]
^-^-^-^-;print ["POS:" posX posY]
^-^-^-^-either any [
^-^-^-^-^-all [fill0bmp find [64 65 66 67] fill0bmp/1]
^-^-^-^-^-all [fill1bmp find [64 65 66 67] fill1bmp/1]
^-^-^-^-][
^-^-^-^-;^-print ["bmpfill" mold fill0bmp mold fill1bmp]
^-^-^-^-^-;if fill0bmp [print ["????????????????????????" fill0bmp/2/1 fill0bmp/1]]
^-^-^-^-^-;if fill1bmp [print ["????????????????????????" fill1bmp/2/1 fill1bmp/1]]
^-^-^-^-^-either all [
^-^-^-^-^-^-fill0bmp
^-^-^-^-^-^-find [64 65 66 67] fill0bmp/1
^-^-^-^-^-][
^-^-^-^-^-;^-probe fillStyles
^-^-^-^-^-^-tmp: fill0bmp/2/2

^-^-^-^-^-^-t0x: tmp/3/1
^-^-^-^-^-^-t0y: tmp/3/2
^-^-^-^-^-^-either tmp/2 [
^-^-^-^-^-^-^-r0x: tmp/2/1
^-^-^-^-^-^-^-r0y: tmp/2/2
^-^-^-^-^-^-][
^-^-^-^-^-^-^-r0x: r0y: 0^-
^-^-^-^-^-^-]
^-^-^-^-^-^-either tmp/1 [
^-^-^-^-^-^-^-s0x: tmp/1/1
^-^-^-^-^-^-^-s0y: tmp/1/2
^-^-^-^-^-^-][
^-^-^-^-^-^-^-s0x: s0y: 0^-
^-^-^-^-^-^-]
^-^-^-^-^-^-fill0posX: posX ;(posX * s0x) + (posY * r0y) + t0x
^-^-^-^-^-^-fill0posY: posY ;(posY * s0y) + (posX * r0x) + t0y 
^-^-^-^-^-^-fill0minX: fill0minY:  100000000
^-^-^-^-^-^-fill0maxX: fill0maxY: -100000000
^-^-^-^-^-][
^-^-^-^-^-^-t0x: t0y: r0x: r0y: s0x: s0y:
^-^-^-^-^-^-fill0posX: fill0posY: none
^-^-^-^-^-]
^-^-^-^-^-either all [fill1bmp find [64 65 66 67] fill1bmp/1] [
^-^-^-^-^-^-tmp: fill1bmp/2/2

^-^-^-^-^-^-t1x: tmp/3/1
^-^-^-^-^-^-t1y: tmp/3/2
^-^-^-^-^-^-either tmp/2 [
^-^-^-^-^-^-^-r1x: tmp/2/1
^-^-^-^-^-^-^-r1y: tmp/2/2
^-^-^-^-^-^-][
^-^-^-^-^-^-^-r1x: r1y: 0^-
^-^-^-^-^-^-]
^-^-^-^-^-^-either tmp/1 [
^-^-^-^-^-^-^-s1x: tmp/1/1
^-^-^-^-^-^-^-s1y: tmp/1/2
^-^-^-^-^-^-][
^-^-^-^-^-^-^-s1x: s1y: 1^-
^-^-^-^-^-^-]
^-^-^-^-^-^-fill1posX: posX ;(posX * s1x) + (posY * r1y) + t1x
^-^-^-^-^-^-fill1posY: posY ;(posY * s1y) + (posX * r1x) + t1y 
^-^-^-^-^-^-fill1minX: fill1minY:  100000000
^-^-^-^-^-^-fill1maxX: fill1maxY: -100000000
^-^-^-^-^-][
^-^-^-^-^-^-t1x: t1y: r1x: r1y: s1x: s1y:
^-^-^-^-^-^-fill1posX: fill1posY: none
^-^-^-^-^-]

^-^-^-^-^-;print ["FILL0:" fill0posX fill0posY t0x t0y s0x s0y r0x r0y]
^-^-^-^-^-;print ["FILL1:" fill1posX fill1posY t1x t1y s1x s1y r1x r1y]
^-^-^-^-^-
^-^-^-^-^-if fill0posX [
^-^-^-^-^-^-;print ["fill0pos" fill0posX fill0posY]
^-^-^-^-^-^-fill0minX: min fill0minX fill0posX
^-^-^-^-^-^-fill0maxX: max fill0maxX fill0posX
^-^-^-^-^-^-fill0minY: min fill0minY fill0posY
^-^-^-^-^-^-fill0maxY: max fill0maxY fill0posY
^-^-^-^-^-^-print ["??" fill0minX fill0minY ]
^-^-^-^-^-]
^-^-^-^-^-if fill1posX [
^-^-^-^-^-^-fill1minX: min fill1minX fill1posX
^-^-^-^-^-^-fill1maxX: max fill1maxX fill1posX
^-^-^-^-^-^-fill1minY: min fill1minY fill1posY
^-^-^-^-^-^-fill1maxY: max fill1maxY fill1posY
^-^-^-^-^-]
^-^-^-^-][
^-^-^-^-^-;print "nobmpfill"
^-^-^-^-^-either tmp: find p 'style [p: tmp][p: tail p]
^-^-^-^-]
^-^-^-^-
^-^-^-^-
^-^-^-^-if st/5 [
^-^-^-^-^-repend/only allUsedFills [
^-^-^-^-^-^-copy/deep fillStyles
^-^-^-^-^-^-copy sort unique usedFills
^-^-^-^-^-] 
^-^-^-^-^-repend/only allUsedLines [
^-^-^-^-^-^-copy/deep lineStyles
^-^-^-^-^-^-copy sort unique usedLines
^-^-^-^-^-]
^-^-^-^-^-append/only allBounds reduce [minX maxX minY maxY]
^-^-^-^-^-
^-^-^-^-^-clear head usedFills
^-^-^-^-^-clear head usedLines
^-^-^-^-^-
^-^-^-^-^-;print ["new fillStyles:" mold st/5/1]
^-^-^-^-^-;ask ""
^-^-^-^-^-;new-style
^-^-^-^-^-fillStyles: st/5/1
^-^-^-^-^-lineStyles: st/5/2
^-^-^-^-^-lineStyle: fillStyle0: fillStyle1: none
^-^-^-^-^-pos: 0x0
^-^-^-^-^-posX: posY: 0
^-^-^-^-^-fill: fill0posX: fill1posX: fill0posY: fill1posY: none
^-^-^-^-^-minX: fill0minX: fill1minX:
^-^-^-^-^-minY: fill0minY: fill1minY:  100000000
^-^-^-^-^-maxX: fill0maxX: fill1maxX:
^-^-^-^-^-maxY: fill0maxY: fill1maxY: -100000000
^-^-^-^-]
^-^-^-) :p
^-^-^-| 'line some [
^-^-^-^-set dx integer! set dy integer! (
^-^-^-^-^-posX: posX + dx
^-^-^-^-^-posY: posY + dy
^-^-^-^-^-if fill0posX [
^-^-^-^-^-^-fill0posX: posX ;(posX * s0x) + (posY * r0y) + t0x
^-^-^-^-^-^-fill0posY: posY ;(posY * s0y) + (posX * r0x) + t0y 
^-^-^-^-^-^-;print ["FILL0 pos:" fill0posX fill0posY]
^-^-^-^-^-^-fill0minX: min fill0minX fill0posX
^-^-^-^-^-^-fill0maxX: max fill0maxX fill0posX
^-^-^-^-^-^-fill0minY: min fill0minY fill0posY
^-^-^-^-^-^-fill0maxY: max fill0maxY fill0posY
^-^-^-^-^-]
^-^-^-^-^-if fill1posX [
^-^-^-^-^-^-fill1posX: posX ;(posX * s1x) + (posY * r1y) + t1x
^-^-^-^-^-^-fill1posY: posY ;(posY * s1y) + (posX * r1x) + t1y 
^-^-^-^-^-^-fill1minX: min fill1minX fill1posX
^-^-^-^-^-^-fill1maxX: max fill1maxX fill1posX
^-^-^-^-^-^-fill1minY: min fill1minY fill1posY
^-^-^-^-^-^-fill1maxY: max fill1maxY fill1posY
^-^-^-^-^-]
^-^-^-^-^-minX: min minX posX
^-^-^-^-^-maxX: max maxX posX
^-^-^-^-^-minY: min minY posY
^-^-^-^-^-maxY: max maxY posY
^-^-^-^-)]
^-^-^-|
^-^-^-'curve some [
^-^-^-^-;set cx integer! set cy integer!
^-^-^-^-set dx integer! set dy integer! (
^-^-^-^-^-posX: posX + dx
^-^-^-^-^-posY: posY + dy
^-^-^-^-^-if fill0posX [
^-^-^-^-^-^-fill0posX: posX ;(posX * s0x) + (posY * r0y) + t0x
^-^-^-^-^-^-fill0posY: posY ;(posY * s0y) + (posX * r0x) + t0y 
^-^-^-^-^-^-fill0minX: min fill0minX fill0posX
^-^-^-^-^-^-fill0maxX: max fill0maxX fill0posX
^-^-^-^-^-^-fill0minY: min fill0minY fill0posY
^-^-^-^-^-^-fill0maxY: max fill0maxY fill0posY
^-^-^-^-^-]
^-^-^-^-^-if fill1posX [
^-^-^-^-^-^-fill1posX: posX ;(posX * s1x) + (posY * r1y) + t1x
^-^-^-^-^-^-fill1posY: posY ;(posY * s1y) + (posX * r1x) + t1y 
^-^-^-^-^-^-fill1minX: min fill1minX fill1posX
^-^-^-^-^-^-fill1maxX: max fill1maxX fill1posX
^-^-^-^-^-^-fill1minY: min fill1minY fill1posY
^-^-^-^-^-^-fill1maxY: max fill1maxY fill1posY
^-^-^-^-^-]
^-^-^-^-^-minX: min minX posX
^-^-^-^-^-maxX: max maxX posX
^-^-^-^-^-minY: min minY posY
^-^-^-^-^-maxY: max maxY posY
^-^-^-^-)
^-^-^-]
^-^-]
^-]
^-if all [fill0posX fill0bmp] [
^-^-;print ["end fill0" fill0posX fill0posY]
^-^-repend bmpFills reduce [fill0bmp/2/1 fill0minX fill0minY fill0maxX fill0maxY s0x s0y r0x r0y t0x t0y]
^-^-
^-]
^-if all [fill1posX fill1bmp] [
^-^-;print ["end fill1" fill1posX fill1posY]
^-^-repend bmpFills reduce [fill1bmp/2/1 fill1minX fill1minY fill1maxX fill1maxY s1x s1y r1x r1y t1x t1y]
^-^-
^-]


^-;probe fill0bmp
print ["bmpFills" mold bmpFills]


;^-bmpFills: copy []
;^-foreach fill fillStyles [
;^-^-if find [64 65 66 67] fill/1 [
;^-^-^-repend bmpFills probe reduce [fill/2/1 fill/2/2/3  fill/3 fill/4 fill/5 fill/6]
;^-^-]
;^-]


^-repend/only allUsedFills [
^-^-copy/deep fillStyles
^-^-copy sort unique usedFills
^-]
^-repend/only allUsedLines [
^-^-copy/deep lineStyles
^-^-copy sort unique usedLines
^-]
^-append/only allBounds reduce [minX maxX minY maxY]

^-clear usedLines
^-clear usedFills

^-;print "======"
^-;probe allUsedFills
^-;probe allUsedLines
^-;ask ""
^-^-^-^-^-
^-;print ["usedFills:" length? allUsedFills tab mold allUsedFills]
^-;ask ""
^-} 
            reduce [
                bmpFills 
                id 
                context compose/only [
                    fills: (new-line allUsedFills true) 
                    lines: (new-line allUsedLines true) 
                    bounds: (allBounds)
                ]
            ]
        ] 
        optimize-updateShape: has [id bounds styles fillsMap linesMap end?] [
            id: carryUI16 
            writeRect bounds: readRect 
            if tagId >= 67 [
                writeRect readRect 
                carryBytes 1
            ] 
            alignBuffers 
            styles: select data/shapeStyles id 
            fillsMap: optimize-processFills styles/fills/1/2 
            linesMap: optimize-processLines styles/lines/1/2 
            numFillBits: carryUB 4 
            numLineBits: carryUB 4 
            end?: false 
            until [
                either all [
                    false 
                    use-BB-optimization? 
                    empty? linesMap 1 = length? fillsMap 
                    tmp: pick styles/fills/1/1 fillsMap/1 
                    find [64 65 66] tmp/1 
                    find [35 36] first select swfBitmaps tmp/2/1 
                    none? find data/noBBids tmp/2/1
                ] [
                    until [
                        either readBitLogic [
                            either readBitLogic [
                                nBits: 2 + readUB 4 
                                either readBitLogic [
                                    skipBits (2 * nBits)
                                ] [skipBits (1 + nBits)]
                            ] [
                                skipBits (4 * (2 + readUB 4))
                            ] 
                            false
                        ] [
                            states: readUB 5 
                            either states = 0 [
                                optimize-writeBBshape styles/bounds/1 
                                writeBit false 
                                writeUB 0 5 
                                alignBuffers 
                                end?: 
                                true
                            ] [
                                either 0 < (states and 16) [
                                    optimize-writeBBshape styles/bounds/1 
                                    writeBit false 
                                    writeUB states 5 
                                    if 0 < (states and 1) [carrySBPair] 
                                    if 0 < (states and 2) [
                                        writeUB either 0 < tmp: readUB numFillBits [index? find fillsMap tmp] [0] numFillBits
                                    ] 
                                    if 0 < (states and 4) [
                                        writeUB either 0 < tmp: readUB numFillBits [index? find fillsMap tmp] [0] numFillBits
                                    ] 
                                    if 0 < (states and 8) [
                                        writeUB either 0 < tmp: readUB numLineBits [index? find linesMap tmp] [0] numLineBits
                                    ] 
                                    alignBuffers 
                                    styles/fills: next styles/fills 
                                    styles/lines: next styles/lines 
                                    styles/bounds: next styles/bounds 
                                    fillsMap: optimize-processFills styles/fills/1/2 
                                    linesMap: optimize-processLines styles/lines/1/2 
                                    numFillBits: carryUB 4 
                                    numLineBits: carryUB 4 
                                    break
                                ] [
                                    if 0 < (states and 1) [
                                        skipSBPair
                                    ] 
                                    if 0 < (states and 2) [skipBits numFillBits] 
                                    if 0 < (states and 4) [skipBits numFillBits] 
                                    if 0 < (states and 8) [skipBits numLineBits]
                                ] 
                                false
                            ]
                        ]
                    ]
                ] [
                    until [
                        either carryBitLogic [
                            either carryBitLogic [
                                nBits: 2 + carryUB 4 
                                either carryBitLogic [
                                    carrySB nBits 
                                    carrySB nBits
                                ] [
                                    carryBitLogic 
                                    carrySB nBits
                                ]
                            ] [
                                nBits: 2 + carryUB 4 
                                carrySB nBits 
                                carrySB nBits 
                                carrySB nBits 
                                carrySB nBits
                            ] 
                            false
                        ] [
                            states: carryUB 5 
                            either states = 0 [
                                alignBuffers 
                                end?: 
                                true
                            ] [
                                if 0 < (states and 1) [
                                    carrySBPair
                                ] 
                                if 0 < (states and 2) [
                                    writeUB either 0 < tmp: readUB numFillBits [index? find fillsMap tmp] [0] numFillBits
                                ] 
                                if 0 < (states and 4) [
                                    writeUB either 0 < tmp: readUB numFillBits [index? find fillsMap tmp] [0] numFillBits
                                ] 
                                if 0 < (states and 8) [
                                    writeUB either 0 < tmp: readUB numLineBits [index? find linesMap tmp] [0] numLineBits
                                ] 
                                if 0 < (states and 16) [
                                    alignBuffers 
                                    styles/fills: next styles/fills 
                                    styles/lines: next styles/lines 
                                    styles/bounds: next styles/bounds 
                                    fillsMap: optimize-processFills styles/fills/1/2 
                                    linesMap: optimize-processLines styles/lines/1/2 
                                    numFillBits: carryUB 4 
                                    numLineBits: carryUB 4 
                                    break
                                ] 
                                false
                            ]
                        ]
                    ]
                ] 
                end?
            ] 
            comment {
^-foreach fill usedFills [
^-^-print "+++++++++++++++++++"
^-^-probe fill
^-^-writeUI8 type: fill/1
^-^-case  [
^-^-^-type = 0 [
^-^-^-^-;solid fill
^-^-^-^-case [
^-^-^-^-^-find [46 84] tagId [
^-^-^-^-^-^-;morph
^-^-^-^-^-^-writeRGBA fill/2/1
^-^-^-^-^-^-writeRGBA fill/2/2
^-^-^-^-^-]
^-^-^-^-^-tagId >= 32 [writeRGBA fill/2]
^-^-^-^-^-true [writeRGB fill/2]
^-^-^-^-]
^-^-^-]
^-^-^-any [
^-^-^-^-type = 16 ;linear gradient fill
^-^-^-^-type = 18 ;radial gradient fill
^-^-^-^-type = 19 ;focal gradient fill (swf8)
^-^-^-][
^-^-^-^-;gradient
^-^-^-^-either find [46 84] tagId [
^-^-^-^-^-;morph
^-^-^-^-^-writeMATRIX   fill/2/1
^-^-^-^-^-writeMATRIX   fill/2/2
^-^-^-^-^-writeGRADIENT fill/2/3 type
^-^-^-^-][^-;shape
^-^-^-^-^-writeMATRIX   fill/2/1
^-^-^-^-^-writeGRADIENT fill/2/2 type
^-^-^-^-]
^-^-^-]
^-^-^-type >= 64 [
^-^-^-^-;bitmap
^-^-^-^-reduce either find [46 84] tagId [
^-^-^-^-^-;morph
^-^-^-^-^-writeUI16 fill/2/1
^-^-^-^-^-writeMATRIX   fill/2/2
^-^-^-^-^-writeMATRIX   fill/2/3
^-^-^-^-][^-;shape
^-^-^-^-^-writeUI16 fill/2/1
^-^-^-^-^-writeMATRIX   fill/2/2
^-^-^-^-]
^-^-^-]
^-^-] 
^-]
^-;zapsal jsem pouze pouzite fills
^-} 
            alignBuffers 
            data/shapeReduction: data/shapeReduction + (length? head inBuffer) - length? head outBuffer 
            head outBuffer
        ] 
        optimize-processLines: func [usedLineIds /local linesMap i LineStyles joinStyle hasFill?] [
            alignBuffers 
            linesMap: copy [] 
            writeCount length? usedLineIds 
            i: 0 
            loop readCount [
                alignBuffers 
                either find usedLineIds i: i + 1 [
                    append linesMap i 
                    optimizeLINESTYLE
                ] [
                    skipLINESTYLE
                ]
            ] 
            alignBuffers 
            linesMap
        ] 
        optimize-processFills: func [usedFillIds /local i fillMap type id] [
            fillMap: copy [] 
            writeCount length? usedFillIds 
            i: 0 
            loop readCount [
                alignBuffers 
                either find usedFillIds i: i + 1 [
                    append fillMap i 
                    optimizeFILLSTYLE
                ] [
                    skipFILLSTYLE
                ]
            ] 
            alignBuffers 
            fillMap
        ] 
        optimize-writeBBshape: func [bounds /local minx miny maxx maxy] [
            set [minx maxx miny maxy] bounds 
            print reform ["USING BBShape" mold bounds] 
            writeBit false 
            writeUB 3 5 
            writeSBPair reduce [minx miny] 
            writeUB 1 numFillBits 
            writeBit true 
            writeBit true 
            writeUB (nBits: to integer! log-2 tmp: (maxx - minx)) 4 
            nBits: nBits + 2 
            writeBit false 
            writeBit false 
            writeSB tmp nBits 
            writeBit true 
            writeBit true 
            writeUB (nBits: to integer! log-2 tmp: (maxy - miny)) 4 
            nBits: nBits + 2 
            writeBit false 
            writeBit true 
            writeSB tmp nBits 
            writeBit true 
            writeBit true 
            writeUB (nBits: to integer! log-2 abs tmp: (minx - maxx)) 4 
            nBits: nBits + 2 
            writeBit false 
            writeBit false 
            writeSB tmp nBits 
            writeBit true 
            writeBit true 
            writeUB (nBits: to integer! log-2 abs tmp: (miny - maxy)) 4 
            nBits: nBits + 2 
            writeBit false 
            writeBit true 
            writeSB tmp nBits
        ] 
        updateCombinedBmpMATRIX: func [id /local ofs sc ro pos] [
            either ofs: select data/combined-bitmaps id [
                alignBuffers 
                either carryBitLogic [
                    writePair sc: readPair
                ] [sc: 0x0] 
                either carryBitLogic [
                    writePair ro: readPair
                ] [ro: 0x0] 
                pos: readSBPair 
                writeSBPair probe reduce [
                    round (pos/1 - ((ofs/x * sc/1) + (ofs/y * ro/2))) 
                    round (pos/2 - ((ofs/y * sc/2) + (ofs/x * ro/1)))
                ] 
                alignBuffers
            ] [
                carryMATRIX
            ]
        ] 
        updateBmpMATRIX: func [id /local size pos sc ro] [
            either any [
                none? size: select data/crops id
            ] [
                carryMATRIX
            ] [
                alignBuffers 
                either carryBitLogic [
                    writePair sc: readPair
                ] [sc: 0x0] 
                either carryBitLogic [
                    writePair ro: readPair
                ] [ro: 0x0] 
                pos: readSBPair 
                writeSBPair reduce [
                    round (pos/1 + ((size/5 * sc/1) + (size/6 * ro/2))) 
                    round (pos/2 + ((size/6 * sc/2) + (size/5 * ro/1)))
                ] 
                alignBuffers
            ]
        ] 
        optimizeFILLSTYLE: has [type id newid] [
            alignBuffers 
            writeUI8 type: readUI8 
            case [
                type = 0 [
                    case [
                        find [46 84] tagId [
                            carryBytes 8
                        ] 
                        tagId >= 32 [carryBytes 4] 
                        true [carryBytes 3]
                    ]
                ] 
                any [
                    type = 16 
                    type = 18 
                    type = 19
                ] [
                    either find [46 84] tagId [
                        carryMATRIX 
                        carryMATRIX 
                        byteAlign 
                        loop carryUI8 [
                            carryBytes 10
                        ]
                    ] [
                        carryMATRIX 
                        byteAlign 
                        carryBits 4 
                        loop carryUB 4 [
                            carryBytes either tagId >= 32 [5] [4]
                        ] 
                        if all [type = 19 tagId = 83] [carryBytes 2]
                    ]
                ] 
                type >= 64 [
                    reduce either find [46 84] tagId [
                        id: readUI16 
                        either find first data 'combined-bitmaps [
                            either find data/combined-bitmaps id [
                                writeUI16 data/combined-bmp-id 
                                updateCombinedBmpMATRIX id 
                                updateCombinedBmpMATRIX id
                            ] [
                                writeUI16 id 
                                carryMATRIX 
                                carryMATRIX
                            ]
                        ] [
                            writeUI16 id 
                            updateBmpMATRIX id 
                            updateBmpMATRIX id
                        ]
                    ] [
                        id: readUI16 
                        either find first data 'combined-bitmaps [
                            either find data/combined-bitmaps id [
                                writeUI16 data/combined-bmp-id 
                                updateCombinedBmpMATRIX id
                            ] [
                                writeUI16 id 
                                carryMATRIX
                            ]
                        ] [
                            writeUI16 id 
                            updateBmpMATRIX id
                        ]
                    ]
                ]
            ]
        ] 
        optimizeLINESTYLE: has [joinStyle hasFill?] [
            alignBuffers 
            case [
                tagId = 46 [
                    carryBytes 12
                ] 
                any [tagId = 67 tagId = 83] [
                    carryBytes 2 
                    carryBits 2 
                    joinStyle: carryUB 2 
                    hasFill?: carryBitLogic 
                    carryBits 11 
                    if joinStyle = 2 [carryBytes 2] 
                    either hasFill? [optimizeFILLSTYLE] [carryBytes 4]
                ] 
                tagId = 84 [
                    carryBytes 4 
                    carryBits 2 
                    joinStyle: carryUB 2 
                    hasFill?: carryBitLogic 
                    carryBits 11 
                    if joinStyle = 2 [carryBytes 2] 
                    either hasFill? [optimizeFILLSTYLE] [carryBytes 8]
                ] 
                true [
                    carryBytes either tagId = 32 [6] [5]
                ]
            ]
        ] 
        skipFILLSTYLE: has [type id] [
            alignBuffers 
            type: readUI8 
            case [
                type = 0 [
                    case [
                        find [46 84] tagId [
                            skipBytes 8
                        ] 
                        tagId >= 32 [skipBytes 4] 
                        true [skipBytes 3]
                    ]
                ] 
                any [
                    type = 16 
                    type = 18 
                    type = 19
                ] [
                    either find [46 84] tagId [
                        readMATRIX 
                        readMATRIX 
                        byteAlign 
                        loop readUI8 [
                            skipBytes 10
                        ]
                    ] [
                        readMATRIX 
                        byteAlign 
                        skipBits 4 
                        loop readUB 4 [
                            skipBytes either tagId >= 32 [5] [4]
                        ] 
                        if all [type = 19 tagId = 83] [skipBytes 2]
                    ]
                ] 
                type >= 64 [
                    reduce either find [46 84] tagId [
                        skipUI16 
                        readMATRIX 
                        readMATRIX
                    ] [
                        skipUI16 
                        readMATRIX
                    ]
                ]
            ]
        ] 
        skipLINESTYLE: has [] [
            alignBuffers 
            case [
                tagId = 46 [
                    skipBytes 12
                ] 
                any [tagId = 67 tagId = 83] [
                    skipBytes 2 
                    skipBits 2 
                    joinStyle: readUB 2 
                    hasFill?: readBitLogic 
                    skipBits 11 
                    if joinStyle = 2 [skipBytes 2] 
                    either hasFill? [skipFILLSTYLE] [skipBytes 4]
                ] 
                tagId = 84 [
                    skipBytes 4 
                    skipyBits 2 
                    joinStyle: readUB 2 
                    hasFill?: readBitLogic 
                    skipBits 11 
                    if joinStyle = 2 [skipBytes 2] 
                    either hasFill? [skipFILLSTYLE] [skipBytes 8]
                ] 
                true [
                    skipBytes either tagId = 32 [6] [5]
                ]
            ]
        ] 
        comment "---- end of include %parsers/swf-optimize.r ----" 
        comment {
#### Include: %parsers/swf-combine-bmps.r
#### Title:   ""
#### Author:  ""
----} 
        combine-updateShape: has [id bounds end?] [
            id: carryUI16 
            writeRect bounds: readRect 
            if tagId >= 67 [
                writeRect readRect 
                carryBytes 1
            ] 
            alignBuffers 
            loop carryCount [
                alignBuffers 
                optimizeFILLSTYLE
            ] 
            loop carryCount [
                alignBuffers 
                optimizeLINESTYLE
            ] 
            numFillBits: carryUB 4 
            numLineBits: carryUB 4 
            end?: false 
            until [
                until [
                    either carryBitLogic [
                        either carryBitLogic [
                            nBits: 2 + carryUB 4 
                            either carryBitLogic [
                                carrySB nBits 
                                carrySB nBits
                            ] [
                                carryBitLogic 
                                carrySB nBits
                            ]
                        ] [
                            nBits: 2 + carryUB 4 
                            carrySB nBits 
                            carrySB nBits 
                            carrySB nBits 
                            carrySB nBits
                        ] 
                        false
                    ] [
                        states: carryUB 5 
                        either states = 0 [
                            alignBuffers 
                            end?: 
                            true
                        ] [
                            if 0 < (states and 1) [
                                carrySBPair
                            ] 
                            if 0 < (states and 2) [
                                carryUB numFillBits
                            ] 
                            if 0 < (states and 4) [
                                carryUB numFillBits
                            ] 
                            if 0 < (states and 8) [
                                carryUB numLineBits
                            ] 
                            if 0 < (states and 16) [
                                alignBuffers 
                                loop carryCount [
                                    alignBuffers 
                                    optimizeFILLSTYLE
                                ] 
                                loop carryCount [
                                    alignBuffers 
                                    optimizeLINESTYLE
                                ] 
                                numFillBits: carryUB 4 
                                numLineBits: carryUB 4 
                                break
                            ] 
                            false
                        ]
                    ]
                ] 
                end?
            ] 
            alignBuffers 
            head outBuffer
        ] 
        comment {---- end of include %parsers/swf-combine-bmps.r ----}
    ] 
    comment "---- end of include %swf-tag-parser.r ----"
] 
save-jpgs: func [[catch] swf-file /local tmpdata swfDir swfName jpegTables] [
    swfName: copy find/last/tail swf-file #"/" 
    unless swfDir: export-dir [
        swfDir: either url? swf-file [
            what-dir
        ] [first split-path swf-file]
    ] 
    probe swfDir: rejoin [swfDir swfName %_export/] 
    if not exists? swfDir [make-dir/deep swfDir] 
    swf-parser/swf-tag-parser/swfDir: swfDir 
    if not error? try [
        swfName: copy/part swfname find/last swfname %.swf
    ] [
        exam-swf/file/parseActions/only swf-file [
            6 [
                tmpdata: parse-DefineBits 
                write/binary rejoin [swfDir swfname %_id tmpdata/1 %.jpg] join jpegTables skip tmpdata/2 2 
                tmpdata
            ] 
            8 [
                jpegTables: parse-JPEGTables 
                head remove/part skip tail jpegTables -2 2
            ] 
            21 [
                tmpdata: parse-DefineBitsJPEG2 
                write/binary probe rejoin [swfDir %tag21 %_id tmpdata/1 %.jpg] tmpdata/2 
                tmpdata
            ] 
            35 [
                tmpdata: parse-DefineBitsJPEG3 
                replace tmpdata/2 #{FFD9FFD8} #{} 
                write/binary rejoin [swfdir swfname %_id tmpdata/1 %.jpg] tmpdata/2 
                alphaimg: make image! jpg-size tmpdata/2 
                alphaimg/alpha: as-binary zlib-decompress tmpdata/3 (alphaimg/size/1 * alphaimg/size/2) 
                save/png rejoin [swfdir swfname %_id tmpdata/1 %.png] alphaimg 
                tmpdata
            ] 
            39 [parse-DefineSprite]
        ] [6 8 20 21 35 36 39]
    ]
] 
save-mp3-samples: func [swf-file /local tmpdata swfDir swfName jpegTables] [
    swfName: copy find/last/tail swf-file #"/" 
    unless swfDir: export-dir [
        swfDir: either url? swf-file [
            what-dir
        ] [first split-path swf-file]
    ] 
    print ".." 
    probe swfDir: rejoin [swfDir swfName %_export/] 
    if not exists? swfDir [make-dir/deep swfDir] 
    swf-parser/swf-tag-parser/swfDir: swfDir 
    exam-swf/file/parseActions/only probe swf-file [
        14 [
            print "..sound..." 
            tmpdata: parse-DefineSound 
            if tmpdata/2 = 2 [
                print tmpdata/1 
                write/binary rejoin [swfdir swfname %_id tmpdata/1 %.mp3] tmpdata/7
            ] 
            tmpdata
        ]
    ] [14]
] 
comment "---- end of RS include %swf-parser.r ----" 
system/options/binary-base: 16 
ctx-form-timeline: context [
    shapes: copy [] 
    bitmaps: copy [] 
    sounds: copy [] 
    sprites: copy [] 
    names: copy [] 
    types: copy [] 
    offsets: copy [] 
    replaced-sprites: copy [] 
    sprite-images: copy [] 
    usage-counter: copy [] 
    analyse-shape: func [
        data [block!] "Parsed SWF Shape data" 
        /local 
        id bounds edge shape 
        FillStyles LineStyles ShapeRecords 
        fill 
        name 
        style
    ] [
        set [id bounds edge shape] data 
        set [FillStyles LineStyles ShapeRecords] shape 
        forall FillStyles [
            style: FillStyles/1 
            if style/2/1 = 65535 [
                remove FillStyles
            ]
        ] 
        FillStyles: head FillStyles 
        forall LineStyles [
            style: LineStyles/1 
            if style/2/1 = 65535 [
                remove LineStyles
            ]
        ] 
        LineStyles: head LineStyles 
        fill: FillStyles/1 
        either all [
            fill 
            fill/1 >= 64 
            name: select names fill/2/1
        ] [
            repend names [id name] 
            repend types [id 'image] 
            either all [
                ShapeRecords/2/1 
                ShapeRecords/2/1/1 = fill/2/2/3/1 
                ShapeRecords/2/1/2 = fill/2/2/3/2
            ] [
                repend/only repend offsets id reduce [bounds/1 bounds/3]
            ] [
                repend/only repend offsets id fill/2/2/3
            ] 
            print ["^-Image instead of shape:" id mold name]
        ] [
            result: copy "" 
            parse/all ShapeRecords [any [
                    'style set style block! (
                        if all [
                            style/4 
                            tmp: pick LineStyles style/4
                        ] [
                            result: insert result reform ["^-lineStyle" tmp/1 tmp/4 "^/"]
                        ] 
                        if tmp: style/1 [
                            result: insert result reform ["^-moveTo" tmp/1 tmp/2 "^/"]
                        ]
                    ) 
                    | 
                    'curve copy tmp some integer! (
                        result: insert result reform ["^-curve" mold tmp "^/"]
                    ) 
                    | 
                    'line copy tmp some integer! (
                        result: insert result reform ["^-line" mold tmp "^/"]
                    )
                ]] 
            result: head result 
            repend types [id 'shape] 
            repend shapes [id result]
        ]
    ] 
    analyse-sprite: func [
        data [block!] "Parsed SWF Sprite data" 
        /local 
        id frames tags 
        tag tagId tagData matrix 
        name 
        result 
        offset
    ] [
        set [id frames tags] data 
        either frames = 1 [
            tag: tags/1 
            tagId: tag/1 
            tagData: tag/2 
            matrix: tagData/4 
            either all [
                false 
                3 = length? tags 
                tagId = 26 
                name: select names tagData/3 
                all [
                    none? matrix/1 
                    none? matrix/2 
                    matrix/3/1 = 0 
                    matrix/3/2 = 0
                ]
            ] [
                repend names [id name] 
                repend types [id 'image] 
                if offset: select offsets tagData/3 [
                    repend/only repend offsets id offset
                ] 
                print ["^-Image instead of sprite:" id mold name mold tag]
            ] [
                form-sprite-tags id frames tags
            ]
        ] [
            form-sprite-tags id frames tags
        ]
    ] 
    form-sprite-tags: func [
        id frames tags 
        /local 
        result 
        tagId tagData offset 
        tmp 
        depth move cid ids attributes oldAttributes colorAtts 
        maxDepth depths-replaced depths-to-remove ids-at-depth currentFrame
    ] [
        result: tail rejoin ["^-TotalFrames " frames "^/"] 
        maxDepth: 0 
        currentFrame: 1 
        depth-to-id: copy [] 
        depth-attributes: copy [] 
        ids: copy [] 
        ids-at-depth: copy [] 
        depths: copy [] 
        foreach tag tags [
            tagId: tag/1 
            tagData: tag/2 
            switch/default tagId [
                26 70 [
                    set [depth move cid attributes colorAtts] tagData 
                    if tmp: find replaced-sprites cid [
                        cid: sprite-images/(index? tmp)
                    ] 
                    either tmp: find depths depth [
                        realDepth: index? tmp
                    ] [
                        realDepth: none 
                        forall depths [
                            if depths/1 > depth [
                                realDepth: index? depths 
                                insert depths depth 
                                break
                            ]
                        ] 
                        depths: head depths 
                        if none? realDepth [
                            append depths depth 
                            realDepth: length? depths
                        ]
                    ] 
                    if none? attributes [
                        attributes: any [
                            select depth-attributes depth 
                            [none none [0 0]]
                        ]
                    ] 
                    either oldAttributes: select depth-attributes depth [
                        either all [move none? cid] [
                            foreach att attributes [
                                if att [
                                    change/only oldAttributes att
                                ] 
                                oldAttributes: next oldAttributes
                            ] 
                            attributes: oldAttributes: head oldAttributes
                        ] [
                            depth-attributes/(depth): attributes
                        ]
                    ] [
                        if all [move none? cid] [
                        ] 
                        repend/only repend depth-attributes depth attributes
                    ] 
                    if offset: select offsets cid [
                        attributes/3/1: attributes/3/1 + offset/1 
                        attributes/3/2: attributes/3/2 + offset/2
                    ] 
                    either cid [
                        append usage-counter cid 
                        result: insert result rejoin [
                            either move ["^-Replace "] ["^-Place "] (select types cid) 
                            #" " cid 
                            #" " realDepth 
                            mold/all attributes 
                            either colorAtts [mold/all colorAtts] [""] 
                            #"^/"
                        ]
                    ] [
                        result: insert result rejoin [
                            "^-Move " 
                            realDepth #" " 
                            mold/all attributes 
                            either colorAtts [mold/all colorAtts] [""] 
                            #"^/"
                        ]
                    ]
                ] 
                28 [
                    depth: tagData 
                    realDepth: index? tmp: find depths depth 
                    remove tmp 
                    remove/part find depth-attributes depth 2 
                    result: insert result rejoin [
                        "^-Remove " realDepth #"^/"
                    ]
                ] 1 [
                    result: insert result ajoin ["^-ShowFrame ;" currentFrame "^/"] 
                    currentFrame: currentFrame + 1
                ] 
                43 [
                    result: insert result rejoin ["^-Label " mold as-string tagData "^/"]
                ] 
                45 [
                ] 
                15 [
                    result: insert result rejoin ["^-Sound " tagData/1 " " mold tagData/2 "^/"] 
                    append usage-counter tagData/1
                ] 
                12 [
                ] 0 []
            ] [
                ask reform ["Unknown tag" tagId "!"]
            ]
        ] 
        either all [
            false 1 = frames 1 = length? depths 
            'image = (select types cid) 
            none? attributes/1 
            none? attributes/2 0 = attributes/3/1 0 = attributes/3/2 
            none? colorAtts
        ] [
            append replaced-sprites id 
            append sprite-images cid 
            print ["^-Image instead of sprite:" id mold name cid]
        ] [
            append usage-counter id 
            repend types [id 'object] 
            result: head result 
            repend sprites [id reduce [frames result]]
        ]
    ] 
    set 'form-timeline func [
        src-swf [file!] 
        /local tags tagId tagData parsed
    ] [
        clear shapes 
        clear bitmaps 
        clear sprites 
        clear names 
        clear types 
        clear offsets 
        clear usage-counter 
        with swf-parser/swf-tag-parser [
            verbal?: false 
            parseActions: swf-parser/swfTagParseActions
        ] 
        tags: extract-swf-tags src-swf [
            2 22 32 67 83 
            39 
            56 
            14
        ] 
        foreach [tagId tagData] tags [
            parsed: parse-swf-tag tagId tagData 
            switch tagId [
                2 22 32 67 83 [
                    analyse-shape parsed
                ] 
                39 [
                    analyse-sprite parsed
                ] 
                43 [
                    print "" 
                    probe as-string parsed
                ] 
                56 [
                    foreach [id name] parsed [
                        replace/all name "_" "/" 
                        parse/all name ["Bitmaps/" copy name to end] 
                        repend names [id as-string name]
                    ]
                ] 
                14 [
                    probe parsed 
                    ask "" 
                    repend types [parsed/1 'sound]
                ]
            ]
        ] 
        code: copy "" 
        foreach [id name] names [
            if find usage-counter id [
                append code reform ["Name" id mold name "^/"]
            ]
        ] 
        print code 
        foreach [id def] shapes [
            print ["shape" id] 
            append code ajoin ["Shape " id " [^/" def "]^/"]
        ] 
        foreach [id def] sprites [
            print ["sprite" id] 
            append code rejoin [
                either def/1 = 1 ["Sprite "] ["Movie "] 
                id " [^/" def/2 "]^/"
            ]
        ] 
        write head change find/last src-swf "." ".txt" code
    ]
] 
comment "---- end of RS include %form-timeline.r ----" 
with: func [obj body] [do bind body obj] 
ctx-pack-assets: context [
    texturePacker: {c:\dev\GDX\libGDX\gdx.jar;c:\dev\GDX\libGDX\extensions\gdx-tools.jar com.badlogic.gdx.tools.imagepacker.TexturePacker2} 
    dirAssetsRoot: %./Assets/ 
    dirBinUtils: %./Utils/ 
    dirPacks: join dirAssetsRoot %Packs/ 
    pngQuantExe: "c:\UTILS\pngquant\pngquant.exe" 
    chNotSpace: complement charset "^/^- " 
    chDigits: charset "0123456789" 
    cmdUseLevel: 1 
    cmdLoadTexture: 2 
    cmdInitTexture: 3 
    cmdDefineImage: 4 
    cmdStartMovie: 5 
    cmdAddMovieTexture: 6 
    cmdAddMovieTextureWithFrame: 7 
    cmdEndMovie: 8 
    cmdLoadSWF: 9 
    cmdInitSWF: 10 
    cmdATFTexture: 11 
    cmdATFTextureMovie: 12 
    cmdTimelineObject: 13 
    cmdTimelineName: 14 
    cmdTimelineShape: 15 
    cmdStartMovie2: 16 
    cmdLineStyle: 1 
    cmdMoveTo: 2 
    cmdCurve: 3 
    cmdLine: 4 
    cmdPlace: 1 
    cmdMove: 2 
    cmdRemove: 3 
    cmdLabel: 4 
    cmdReplace: 5 
    cmdSound: 6 
    cmdShowFrame: 128 
    out: make stream-io [] 
    write-bitmap-assets: func [
        level [any-string!] "Lavel's name" 
        name [any-string!] "Per level texture sheet's name" 
        /local 
        srcDir 
        packFile 
        rlPair 
        data 
        regions 
        sequences 
        bitmapName 
        imgFile partId x y xy size orig offset index var value
    ] [
        srcDir: rejoin [dirAssetsRoot %Bitmaps/ level #"\" name] 
        packFile: join name %.pack 
        unless exists? dirPacks/:packFile [
            if 0 < call/wait/console probe reform [
                "java -classpath" texturePacker 
                to-local-file srcDir 
                to-local-file dirPacks 
                packFile
            ] [
                print "Packing failed!" 
                halt
            ]
        ] 
        imgFile: none 
        partId: none 
        regions: none 
        sequences: none 
        data: copy [] 
        rlPair: [copy x some chDigits ", " copy y some chDigits (value: as-pair to-integer x to-integer y) #"^/"] 
        parse/all read dirPacks/:packFile [
            some [
                #"^/" [
                    copy imgFile to #"^/" 1 skip (
                        probe imgFile print "========================" 
                        bitmapName: uppercase/part replace/all copy imgFile "." "_" 1 
                        regions: copy [] 
                        sequences: copy [] 
                        repend data [imgFile bitmapName regions sequences]
                    ) 
                    thru #"^/" 
                    thru #"^/" 
                    thru #"^/" 
                    some [
                        some [
                            "  " [
                                "xy: " copy xy to #"^/" 1 skip 
                                "  size: " copy size to #"^/" 1 skip 
                                "  orig: " copy orig to #"^/" 1 skip 
                                "  offset: " copy offset to #"^/" 1 skip 
                                "  index: " copy index to #"^/" 1 skip 
                                (
                                    index: to-integer index 
                                    either index < 0 [
                                        if offset <> "0, 0" [
                                            ask reform ["!! Found trimed image" mold partId "offset:" offset]
                                        ] 
                                        repend regions [partId xy size]
                                    ] [
                                        sequence: select sequences partId 
                                        if none? sequence [
                                            append sequences partId 
                                            append/only sequences sequence: copy []
                                        ] 
                                        repend sequence [index xy size orig offset]
                                    ]
                                ) 
                                | copy var to #":" 2 skip copy value to #"^/" 1 skip
                            ]
                        ] 
                        | 
                        copy partId [some chNotSpace to #"^/"] thru #"^/"
                    ]
                ]
            ]
        ] 
        if regions [
            sort/skip/reverse regions 3 
            new-line/skip regions true 3
        ] 
        foreach [imgFile bitmapName regions sequences] data [
            foreach [partId xy size] regions [
                xy: load trim/all/with xy "," 
                size: load trim/all/with size "," 
                out/writeUI8 cmdDefineImage 
                out/writeUTF partId 
                out/writeUI16 xy/1 
                out/writeUI16 xy/2 
                out/writeUI16 size/1 
                out/writeUI16 size/2
            ] 
            unless empty? sequences [
                foreach [id sequence] sequences [
                    print ["Sequence" mold id "with length" ((length? sequence) / 5)] 
                    sort/skip sequence 5 
                    out/writeUI8 cmdStartMovie2 
                    out/writeUTF id 
                    foreach [index xy size orig offs] sequence [
                        xy: load trim/all/with xy "," 
                        size: load trim/all/with size "," 
                        orig: load trim/all/with orig "," 
                        offs: load trim/all/with offs "," 
                        out/writeUI8 cmdAddMovieTextureWithFrame 
                        out/writeUI16 xy/1 
                        out/writeUI16 xy/2 
                        out/writeUI16 size/1 
                        out/writeUI16 size/2 
                        out/writeUI16 - offs/1 
                        out/writeUI16 size/2 - orig/2 + offs/2 
                        out/writeUI16 orig/1 
                        out/writeUI16 orig/2
                    ] 
                    out/writeUI8 cmdEndMovie
                ]
            ]
        ]
    ] 
    has-atf-version: func [
        atf-type "Required ATF file extension (%dxt or %etc)" 
        file [any-string!] "Name of the bitmap file without extension" 
        /local 
        origFile 
        imageFile
    ] [
        origFile: rejoin [dirPacks file %.png] 
        all [
            atf-type 
            any [
                all [
                    exists? imageFile: rejoin [file #"." atf-type] 
                    (modified? imageFile) > (modified? origFile)
                ] 
                (
                    switch/default atf-type [
                        %dxt [
                            call/wait/console probe rejoin [
                                dirBinUtils " PVRTexTool.exe -m -yflip0 -f DXT5 -dds" 
                                " -i " to-local-file origFile 
                                " -o " to-local-file file ".dds"
                            ] 
                            call/wait/console probe rejoin [
                                dirBinUtils " dds2atf.exe -2" 
                                " -i " to-local-file file ".dds" 
                                " -o " to-local-file imageFile
                            ] 
                            true
                        ] 
                        %etc [
                            call/wait/console probe rejoin [
                                dirBinUtils " png2atf.exe -c e -2" 
                                " -i " to-local-file file ".png" 
                                " -o " to-local-file imageFile
                            ] 
                            true
                        ]
                    ] [false]
                )
            ]
        ]
    ] 
    set 'make-packs func [
        level [any-string!] "Level's ID" 
        /atf atf-type {ATF extension which could be used for bitmap compression (dxt or etc)} 
        /local 
        sourceDir 
        sourceSWF 
        sourceTXT 
        bin 
        indx 
        origImageFile 
        imageFile 
        name 
        xml 
        x y width height frameX frameY frameWidth frameHeight
    ] [
        either dirAssetsRoot [
            dirAssetsRoot: to-file dirAssetsRoot 
            if #"/" <> pick dirAssetsRoot 1 [insert dirAssetsRoot what-dir]
        ] [make error! "Unspecified dirAssetsRoot"] 
        either dirBinUtils [
            dirBinUtils: to-file dirBinUtils 
            if #"/" <> pick dirBinUtils 1 [insert dirBinUtils what-dir]
        ] [make error! "Unspecified dirBinUtils"] 
        probe dirBinUtils 
        if all [atf-type none? find [%dxt %etc] atf-type] [atf-type: none] 
        out/clearBuffers 
        out/writeBytes as-binary "LVL" 
        out/writeUI8 cmdUseLevel 
        out/writeUTF probe level 
        sourceDir: dirize rejoin [dirAssetsRoot %Bitmaps/ level] 
        if exists? sourceDir [
            foreach dir read sourceDir [
                if all [
                    #"/" = last dir 
                    #"_" <> first dir
                ] [
                    remove back tail dir 
                    indx: index? out/outBuffer 
                    write-bitmap-assets level dir 
                    out/outBuffer: at head out/outBuffer indx 
                    origImageFile: rejoin [dirPacks dir %.png] 
                    any [
                        has-atf-version atf-type dir 
                        all [
                            exists? imageFile: rejoin [dirPacks dir %-fs8.png] 
                            any [
                                (modified? imageFile) > (modified? origImageFile) 
                                (
                                    delete imageFile 
                                    call/wait/console probe rejoin [
                                        to-local-file pngQuantExe " " 
                                        to-local-file join what-dir origImageFile
                                    ] 
                                    true
                                )
                            ]
                        ] 
                        exists? imageFile: origImageFile
                    ] 
                    bin: read/binary probe imageFile 
                    either atf-type [
                        out/writeUI8 cmdATFTexture 
                        out/writeUI32 length? bin 
                        out/writeBytes bin
                    ] [
                        out/writeUI8 cmdLoadTexture 
                        out/writeUI32 length? bin 
                        out/writeBytes bin 
                        out/writeUI8 cmdInitTexture
                    ] 
                    out/writeUTF dir 
                    out/outBuffer: tail out/outBuffer
                ]
            ]
        ] 
        sourceDir: dirize rejoin [dirAssetsRoot %Starling/ level] 
        if exists? sourceDir [
            foreach file read sourceDir [
                if all [
                    parse file [copy name to ".xml" 4 skip end] 
                    any [
                        has-atf-version atf-type join sourceDir name 
                        exists? imageFile: rejoin [sourceDir name %-fs8.png] 
                        exists? imageFile: rejoin [sourceDir name %.png]
                    ]
                ] [
                    bin: read/binary probe imageFile 
                    either atf-type [
                        out/writeUI8 cmdATFTextureMovie 
                        out/writeUI32 length? bin 
                        out/writeBytes bin
                    ] [
                        out/writeUI8 cmdLoadTexture 
                        out/writeUI32 length? bin 
                        out/writeBytes bin 
                        out/writeUI8 cmdStartMovie
                    ] 
                    out/writeUTF name 
                    xml: read/binary sourceDir/:file 
                    replace/all xml "^@" "" 
                    parse/all xml [
                        any [
                            thru {<SubTexture name="} copy name to {"} 
                            thru {x="} copy x to {"} 
                            thru {y="} copy y to {"} 
                            thru {width="} copy width to {"} 
                            thru {height="} copy height to {"} 
                            thru {frameX="} copy frameX to {"} 
                            thru {frameY="} copy frameY to {"} 
                            thru {frameWidth="} copy frameWidth to {"} 
                            thru {frameHeight="} copy frameHeight to {"} 
                            (
                                out/writeUI8 cmdAddMovieTextureWithFrame 
                                out/writeUI16 to-integer x 
                                out/writeUI16 to-integer y 
                                out/writeUI16 to-integer width 
                                out/writeUI16 to-integer height 
                                out/writeUI16 to-integer frameX 
                                out/writeUI16 to-integer frameY 
                                out/writeUI16 to-integer frameWidth 
                                out/writeUI16 to-integer frameHeight
                            )
                        ]
                    ] 
                    out/writeUI8 cmdEndMovie
                ]
            ]
        ] 
        sourceDir: dirize rejoin [dirAssetsRoot %SWFs/ level] 
        if exists? sourceDir [
            foreach file read sourceDir [
                if all [
                    parse file [copy name to ".swf" 4 skip end]
                ] [
                    bin: read/binary probe rejoin [sourceDir file] 
                    out/writeUI8 cmdLoadSWF 
                    out/writeUTF name 
                    out/writeUI32 length? bin 
                    out/writeBytes bin 
                    out/writeUI8 cmdInitSWF
                ]
            ]
        ] 
        sourceSWF: rejoin [dirAssetsRoot %TimelineSWFs/ level %.swf] 
        sourceTXT: rejoin [dirAssetsRoot %TimelineSWFs/ level %.txt] 
        if exists? sourceSWF [
            indx: index? out/outBuffer 
            if any [
                not exists? sourceTXT 
                (modified? sourceTXT) < (modified? sourceSWF)
            ] [
                form-timeline sourceSWF
            ] 
            parse-timeline sourceTXT 
            print ["Timeline bytes:" (index? out/outBuffer) - indx]
        ] 
        out/writeUI8 0 
        write/binary join %./bin/ rejoin either atf-type [
            [uppercase atf-type "/" level %.lvl]
        ] [
            [%Data/ level %.lvl]
        ] head out/outBuffer
    ] 
    parse-timeline: func [
        file [file!] "Formed timeline specification" 
        /local 
        type id data name 
        indx
    ] [
        print ["====== parse-timeline "] 
        parse/all load file [
            any [
                set type ['Movie | 'Sprite] set id integer! set data block! (
                    out/writeUI8 cmdTimelineObject 
                    out/writeUI16 id 
                    indx: index? out/outBuffer 
                    parse-controlTags data 
                    out/writeUI8 0 
                    out/outBuffer: at head out/outBuffer indx 
                    out/writeUI32 length? out/outBuffer 
                    out/outBuffer: tail out/outBuffer
                ) 
                | 
                'Name set id integer! set name string! (
                    out/writeUI8 cmdTimelineName 
                    out/writeUI16 id 
                    out/writeUTF name
                ) 
                | 
                'Shape set id integer! set data block! (
                    comment {
^-^-^-^-^-out/writeUI8  cmdTimelineShape
^-^-^-^-^-out/writeUI16 id
^-^-^-^-^-indx: index? out/outBuffer
^-^-^-^-^-parse-ShapeDefinition data
^-^-^-^-^-out/outBuffer: at head out/outBuffer indx
^-^-^-^-^-out/writeUI32 length? out/outBuffer
^-^-^-^-^-out/outBuffer: tail out/outBuffer
^-^-^-^-^-}
                )
            ]
        ]
    ] 
    write-transform: func [
        transform color flags 
        /local 
        colorMult hasColorMult removeTint alpha
    ] [
        if transform/1 [flags: flags or 8] 
        if transform/2 [flags: flags or 16] 
        if color [
            either block? colorMult: color/1 [
                flags: flags or 32 
                alpha: colorMult/4 
                if any [
                    colorMult/1 <> 256 
                    colorMult/2 <> 256 
                    colorMult/3 <> 256
                ] [
                    flags: flags or 64 
                    hasColorMult: true
                ]
            ] [
                flags: flags or 64 
                colorMult: [255 255 255] 
                hasColorMult: true
            ]
        ] 
        out/writeUI8 flags 
        either transform/3 [
            out/writeFloat transform/3/1 / 20 
            out/writeFloat transform/3/2 / 20
        ] [
            out/writeFloat 0 
            out/writeFloat 0
        ] 
        if transform/1 [
            out/writeFloat transform/1/1 
            out/writeFloat transform/1/2
        ] 
        if transform/2 [
            out/writeFloat transform/2/1 
            out/writeFloat transform/2/2
        ] 
        if alpha [
            out/writeUI8 min 255 alpha
        ] 
        if hasColorMult [
            out/writeUI8 min 255 colorMult/1 
            out/writeUI8 min 255 colorMult/2 
            out/writeUI8 min 255 colorMult/3
        ]
    ] 
    parse-ShapeDefinition: func [
        data 
        /local 
        thickness color 
        points x y 
        err
    ] [
        parse/all data [any [
                'lineStyle set thickness integer! set color tuple! (
                    out/writeUI8 cmdLineStyle 
                    out/writeUI16 thickness 
                    out/writeBytes to-binary color
                ) 
                | 
                'moveTo set x integer! set y integer! (
                    out/writeUI8 cmdMoveTo 
                    out/writeUI16 x 
                    out/writeUI16 y
                ) 
                | 
                'curve set points block! (
                    out/writeUI8 cmdCurve 
                    out/writeUI16 (length? points) / 4 
                    foreach [cx cy ax ay] points [
                        out/writeUI16 cx 
                        out/writeUI16 cy 
                        out/writeUI16 ax 
                        out/writeUI16 ay
                    ]
                ) 
                | 
                'line set points block! (
                    out/writeUI8 cmdLine 
                    out/writeUI16 (length? points) / 2 
                    foreach [x y] points [
                        out/writeUI16 x 
                        out/writeUI16 y
                    ]
                ) 
                | copy err 1 skip (
                    ask reform ["Invalid shape definition:" mold err]
                )
            ]] 
        out/writeUI8 0
    ] 
    parse-controlTags: func [
        data 
        /local 
        id depth transform type frames name colorTransform 
        flags soundData
    ] [
        parse/all data [
            'TotalFrames set frames integer! (
                out/writeUI16 frames
            ) 
            any [
                'Move set depth integer! set transform block! set color [block! | none] (
                    out/writeUI8 cmdMove 
                    out/writeUI16 depth - 1 
                    flags: 0 
                    write-transform transform color flags
                ) 
                | 
                'ShowFrame (
                    out/writeUI8 cmdShowFrame
                ) 
                | 
                'Place set type word! set id integer! set depth integer! set transform block! set color [block! | none] (
                    out/writeUI8 cmdPlace 
                    out/writeUI16 id 
                    out/writeUI16 depth - 1 
                    flags: select [image 0 object 1 shape 2] type 
                    write-transform transform color flags
                ) 
                | 
                'Replace set type word! set id integer! set depth integer! set transform block! set color [block! | none] (
                    out/writeUI8 cmdReplace 
                    out/writeUI16 id 
                    out/writeUI16 depth - 1 
                    flags: select [image 0 object 1 shape 2] type 
                    write-transform transform color flags
                ) 
                | 
                'Remove set depth integer! (
                    out/writeUI8 cmdRemove 
                    out/writeUI16 depth - 1
                ) 
                | 
                'Label set name string! (
                    out/writeUI8 cmdlabel 
                    out/writeUTF name
                ) 
                | 
                'Sound set id integer! set soundData block! (
                    out/writeUI8 cmdSound 
                    out/writeUI16 id
                ) 
                | pos: 1 skip (
                    ask reform ["UNKNOWN COMMAND near:" mold copy/part pos 20 "..."]
                )
            ]
        ]
    ]
]