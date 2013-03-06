#!/Applications/rebol -qs 
REBOL [
	comment: {
		Use this script to create data assets.
		To run this script, you must have REBOL/View, which is available here:
		http://www.rebol.com/download-view.html

		TexturePacker is required to pack bitmap sheets:
			http://code.google.com/p/libgdx/wiki/TexturePacker
			http://code.google.com/p/libgdx/downloads/list
		Optionaly can be used PNGquant tool for converting 24/32-bit PNG images to paletted (8-bit) PNGs.
			http://pngquant.org/
	}
]

do %/c/dev/GIT/RS/rs.r
rs/run/version 'pack-assets 'fastmem
;do %scripts/pack-assets.r

;http://code.google.com/p/libgdx/wiki/TexturePacker
with ctx-pack-assets [
	
	dirAssetsRoot: %./Assets/
	
	switch system/version/4 [
		2 [;MacOSX
			dirBinUtils:   %./Utils/
			pngQuantExe:   dirBinUtils/pngquant
			texturePacker: "./Utils/gdx.jar:./Utils/gdx-tools.jar com.badlogic.gdx.tools.imagepacker.TexturePacker2"
		]
		3 [;Windows
			dirBinUtils:   %/c/dev/Utils/
			pngQuantExe:   dirBinUtils/pngquant.exe
			texturePacker: "c:/dev/Utils/gdx.jar;c:/dev/Utils/gdx-tools.jar com.badlogic.gdx.tools.imagepacker.TexturePacker2"
		]
	]	
]


atf-type: none

foreach level [
	%Mlok
][
	make-packs/atf level atf-type
]
ask "DONE"