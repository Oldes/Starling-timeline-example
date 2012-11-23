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

do %/Users/Oldes/Documents/GIT/RS/builds/pack-assets_latest.r ;%scripts/pack-assets.r

;http://code.google.com/p/libgdx/wiki/TexturePacker
with ctx-pack-assets [
	dirBinUtils:   %./Utils/
	dirAssetsRoot: %./Assets/
	texturePacker: "./Utils/gdx.jar:./Utils/gdx-tools.jar com.badlogic.gdx.tools.imagepacker.TexturePacker2"
	switch system/version/4 [
		2 [;MacOSX
			pngQuantExe:   dirBinUtils/pngquant
		]
		3 [;Windows
			pngQuantExe:   dirBinUtils/pngquant.exe
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