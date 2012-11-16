REBOL [
	comment: {
		Use this script to create data assets.
		To run this script, you must have REBOL/View, which is available here:
		http://www.rebol.com/download-view.html
	}
]

do %scripts/pack-assets.r

;http://code.google.com/p/libgdx/wiki/TexturePacker
with ctx-pack-assets [
	texturePacker: "c:\dev\GDX\libGDX\gdx.jar;c:\dev\GDX\libGDX\extensions\gdx-tools.jar com.badlogic.gdx.tools.imagepacker.TexturePacker2"
	pngQuantExe:   "c:\UTILS\pngquant\pngquant.exe"
]

atf-type: none

foreach level [
	%Mlok
][
	make-packs/atf level atf-type
]
ask "DONE"