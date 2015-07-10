% Load image
path = 'Middlebury/Bowling1/';
im = double(imread([path 'view1.png']));
im = im./255;
im2 = double(imread([path 'view5.png']));
im2 = im2./255;
dmap = double(imread([path 'disp1.png']));
dmap = dmap./255;
dmap2 = double(imread([path 'disp5.png']));
dmap2 = dmap2./255;