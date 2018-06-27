import cv2
import glob
import numpy as np
import re
def numericalSort(value):
    numbers = re.compile(r'(\d+)')
    parts = numbers.split(value)
    parts[1::2] = map(int, parts[1::2])
    return parts

fdir = './out/movie/'
imglist = sorted(glob.glob(fdir + '*.png',recursive=True),key=numericalSort)

img = cv2.imread(imglist[-1])
[r,c,d] = img.shape

fourcc = cv2.VideoWriter_fourcc(*'XVID')
video = cv2.VideoWriter(fdir + '_mov.avi', fourcc, 30.0, (c, r))
itr = 1

for fname in imglist:
    print(fname)
    img = cv2.imread(fname)
    for i in range(itr):
        video.write(img)
video.release()
