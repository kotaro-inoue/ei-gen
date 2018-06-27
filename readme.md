# Fast elemental image (light-field) generator from RGBD image
Currently, it can generate rectangle lenslet elemental images and horizontal lenticular images.
I believe that it works fast but if you disagree with it, please modify it.

# License
Academic usage only now. 
If you want to use it for your business, please ask me.

# How to use it?
Run lenlet.m or lenticular.m in Matlab.

# Adjustable parameters
It is optimized for iPad(9.7 inch).
In order to optimize on your system, please modify depth, display, and lenslet parameters.

|Variable|Definition|
|:-:|:-:|
|Z_start|Farthest reconstruction depth (You can set minus value)|
|Z_end|Closest reconstruction depth (You can set minus value)|
|Deisplay_inch|Diagonal length of the display|
|Display_npx|Resolution of the displays in X (col) axis|
|Display_npy|Resolution of the displays in Y (row) axis|
|Lens_p|Pitch of the lenslet/lenticular|
|Lens_f|Focal length of the lenslet/lenticular|

# Algorithm
It is pixel remapping by ray tracing using LUT (Look-up table).
The novelty is that it is implemented by bit operation and sorting.

# Comment
I don't submit it to any journal because I think that it is weak.
If you are researcher or student, please tell me your comment.

# Special thanks

* [MMD (Miku Miku Dance)](http://www.geocities.jp/higuchuu4/)
* [MME (Miku Miku Effect)](https://bowlroll.net/file/35013)
* [Depthmap effect for MMD](http://seiga.nicovideo.jp/seiga/im4372355)
