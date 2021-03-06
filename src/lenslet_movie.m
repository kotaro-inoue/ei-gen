%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fast elemental image generator   %  
% Copyright 2018 Kotaro Inoue.     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%%
Dir = '../datasets/mmd/';
img_name = [Dir 'rgb.mp4'];
depth_name = [Dir 'depth.mp4'];

img_mov = VideoReader(img_name);
depth_mov = VideoReader(depth_name);

img = readFrame(img_mov);
depth = readFrame(depth_mov);
[ey, ex, ~] =  size(img);

% Depth Setting ---------------------------------------------
Z_start = 15;  %0
Z_end = 35;     %255
Depth_resolution = 8;   %[bit]
cutoff_depth = 0.6; % It defines the deepest depth (0[far]~1.0[near])
Z_step = (Z_end - Z_start)/ (2^Depth_resolution-1);

% Display Setting -------------------------------------------
Display_inch = 9.7;
Display_npx = 2048;                     % Display's pixel number of x direction
Display_npy = 1536;                     % Display's pixel number of y direction

Display_ratio = Display_npx/Display_npy;
Display_w = Display_inch*25.4*sin(atan(Display_ratio));  % width[mm]
Display_h = Display_inch*25.4*sin(atan(1/Display_ratio));  % height[mm]
Display_psx = Display_w/Display_npx;    % Display pixel size (x) [mm/px]
Display_psy = Display_h/Display_npy;    % Display pixel size (y) [mm/px]

% Lenslet Parameters ----------------------------------------
Lens_p = 1.6056;    % Lens pitch[mm]
Lens_f = 8.028;     % Lens focal length[mm]

Lens_x = Display_w / Lens_p;    % Lens number of x direction [num]
Lens_y = Display_h / Lens_p;    % Lens number of y direction [num]
Lens_psx = ceil(Lens_p/Display_psx);    % Lens's pixel size of x direction [px]
Lens_psy = ceil(Lens_p/Display_psy);    % Lens's pixel size of y direction [px]
Lens_center = Lens_p/2;         % Center of lens[mm]

% Calculation view angle each lenslet's pixel %%%%%%%%%%%%%%%%%
Zr_max = max([abs(Z_start) abs(Z_end)]);            % I wrote the detail to ppt 
View_angle = zeros(Lens_psx+1,1);
for x=1:Lens_psx
    dx = x*Display_psx-Lens_p/2;
    View_angle(x) = atan(dx/Lens_f); %/pi*180;
end
Shift_max = ceil(Zr_max * tan(max(abs(View_angle(:))))/Display_psx)+1;

% Caluculation LUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LUT_size = Lens_psx + Shift_max*2;                  % I wrote the detail to ppt 
LUT = zeros(LUT_size, 2^Depth_resolution-1);
for x=1:Lens_psx
    xpos = (Shift_max +x)*Display_psx;
    for z=1:255
        Zr = Z_start + Z_step * z;
        if Zr<0
            dx = round( (xpos - Zr*tan(View_angle(x)) )/Display_psx);
            LUT(dx,z) = x;
        else
            dx = round( (xpos + Zr*tan(View_angle(x)) )/Display_psx);
            LUT(dx,z) = Lens_psx-x+1;
        end
    end
end
%%
% Memory allocation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EI_sizex = ceil(Lens_x)*Lens_psx;
EI_sizey = ceil(Lens_y)*Lens_psy;

fprintf("Movies loading...  ");
count = 1;
while hasFrame(img_mov)
    tmp = readFrame(img_mov);
    count = count + 1;
end
frames = count;

img_mov = VideoReader(img_name);
depth_mov = VideoReader(depth_name);
img_arr = zeros(ey,ex,3,frames,'uint8');
depth_arr = zeros(ey,ex,frames,'uint8');
count = 1;
while hasFrame(img_mov)
    img_arr(:,:,:,count) = readFrame(img_mov);
    tmp = readFrame(depth_mov);
    tmp = im2double(tmp(:,:,1));
    tmp(tmp<cutoff_depth) = cutoff_depth;
    tmp = tmp - min(tmp(:));
    tmp = tmp / max(tmp(:));
    tmp = uint8(tmp*255);
    tmp(tmp==0) = 1;
    depth_arr(:,:,count) = tmp;
    count = count + 1;
end
fprintf("Done\n");
%%
fprintf("Number of lenslet Row: %d Col:%d, Number of frame: %d \n", ceil(Lens_y), ceil(Lens_x), frames);
mkdir('../out/movie/');
parfor i = 1:frames
    fprintf("Frame:%d start processing\n", i);

    img = img_arr(:,:,:,i);
    depth = depth_arr(:,:,i);
    
    EI = (zeros(EI_sizey, EI_sizex,3,'uint8'));
    Ref_img = imresize(img,[EI_sizey, EI_sizex]);
    Ref_depth = imresize(depth,[EI_sizey, EI_sizex]);
    Ref_img = padarray(Ref_img,[Shift_max, Shift_max]);
    Ref_depth = padarray(Ref_depth,[Shift_max, Shift_max]);

    % Sort %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for x = 1:ceil(Lens_x)
        for y = 1:ceil(Lens_y)
            %range_eix = 1+(x-1)*Lens_psx+outrange:x*Lens_psx+outrange;
            range_maskedx = 1+(x-1)*Lens_psx:x*Lens_psx+Shift_max*2;    % Calculate maske range of x axis
            %range_eiy = 1+(y-1)*Lens_psy+outrange:y*Lens_psy+outrange;
            range_maskedy = 1+(y-1)*Lens_psy:y*Lens_psy+Shift_max*2;

            part_mono = Ref_depth(range_maskedy,range_maskedx,1);       % Region selection by depth
            [part_posy, part_posx] = find(part_mono>0);                 % find depth>0
            dep_list = part_posy + (part_posx-1)*size(range_maskedy,2); % Convert to 1D access for array(faster than 2D)
            dep = part_mono(dep_list);                                  % Obtain depth list
            [deps, index] = sort(dep);                                  % Depth sort

            dy_list = part_posy(index) + (double(deps)-1)*LUT_size;     % Convert to 1D access for LUT
            dy = LUT(dy_list);                                          % dy means LUT's return value(Lenslet's screen position)
            dy_pos = find(dy>0);                                        % dy_pos means effective position in dy. 0 means ray is not hit on the lenslet screen, so it have no effect
            dx_list = part_posx(index) + (double(deps)-1)*LUT_size;
            dx = LUT(dx_list);
            dx_pos = find(dx>0);
            rewrite = ismember(dy_pos,dx_pos);                          % rewrite is logical array. If find (dy_pos == dx_pos) case, rewrite is set 1.
            rewrite_pos = find(rewrite>0);                              % rewrite_pos means effective position in rewrite. 0 mean ray is not hit on the lenslet screen, so it have no effect

            ref_posx = 1+(x-1)*Lens_psx + part_posx(index(dy_pos(rewrite_pos)));    % Refarence image's position list (x axis)
            ref_posy = 1+(y-1)*Lens_psy + part_posy(index(dy_pos(rewrite_pos)));
            ei_posx = 1+(x-1)*Lens_psx + dx(dy_pos(rewrite_pos)) -1;                % Elemental image's position list (x axis)
            ei_posy = 1+(y-1)*Lens_psy + dy(dy_pos(rewrite_pos)) -1;      
            EI(ei_posy,ei_posx,:) = Ref_img(ref_posy,ref_posx,:);                   % image sort
        end
    end
    fprintf("Frame:%d is finished\n", i);
    imwrite(EI(1:Display_npy,1:Display_npx,:),['../out/movie/' num2str(i) '.png']);
end
