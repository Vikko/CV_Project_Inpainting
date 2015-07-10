function [ im ] = bertalmio_inpaint(im, mask, iterations, maskwhite)
    %im - naive reconstructed image, single color band
    %mask - mask of uncertainty
    % -> show intermediate inpainting results, uncomment the last lines
    if nargin==0
        %custom test image if no arguments
        im = imread('MiddleBury/CustomTest/test.png');
        im = im(:,:,1);
        mask = logical(imread('MiddleBury/CustomTest/mask.png'));
        mask = mask(:,:,1);     
    end
    
    if size(im,3) > 1
        error('No color channels allowed!');
    end
    im = im2double(im);
    
    if nargin<=2
       iterations = 100;
    end
    
    if nargin>3
       if maskwhite == true
           im(mask) = 1;
       end
    end
    
    mask_size = sum(sum(mask));
    [height,width] = size(im);
    i = 1;
    mask_dil = imdilate(mask,strel('disk',3));
    N_inpaint = 15;
    N_anidiff = 2;
    %define filter kernels
    grady = [-1 0 1];
    gradx = grady';
    gradyb = [-1 1 0];
    gradxb = gradyb';
    gradyf = [0 -1 1];
    gradxf = gradyf';
    lap = fspecial('laplacian',0);
    change_per_pixel = -1;
    %while ~(change_per_pixel < 0.0005 || i > 1000)
    while (i < iterations)
    %% Start inpainting
    fprintf('Iteration %i\n',i);
    for inpaint_iter=1:N_inpaint
        im2 = zeros(height,width);
        im2(mask_dil) = im(mask_dil);
        %% Determine update
        %Calculate gradients
        im_y = imfilter(im2,grady)/2;
        im_x = imfilter(im2,gradx)/2;
        im_yb = imfilter(im2,gradyb);
        im_xb = imfilter(im2,gradxb);
        im_yf = imfilter(im2,gradyf);
        im_xf = imfilter(im2,gradxf);
        %% Get smoothness estimation
        laplacian = imfilter(im_x,gradx)+imfilter(im_y,grady);
        delta_Ly = imfilter(laplacian,gradx);
        delta_Lx = imfilter(laplacian,grady);

        
        %% Get isophote direction
        N_norm = zeros(height, width);
        N_y = zeros(height, width);
        N_x = zeros(height, width);
        N_norm = sqrt(eps+im_y.^2+im_x.^2);
        N_y = -im_y ;%./ N_norm(mask_dil);
        N_x = im_x ;%./ N_norm(mask_dil);
        %N_y(isnan(N_y)) = 0;
        %N_x(isnan(N_x)) = 0;
        
        beta = zeros(height,width);
        I_grad_norm = zeros(height,width);
        for row=1:height
            for col=1:width
                %Project smoothness on direction
                b = [delta_Ly(row,col);delta_Lx(row,col)]'*[N_x(row,col);N_y(row,col)];
                beta(row,col) = b;
                %Get slope-limited norm of gradient
                if b > 0
                    I_grad_norm(row,col) = sqrt(min(im_xb(row,col),0)^2 + ...
                                                max(im_xf(row,col),0)^2 + ...
                                                min(im_yb(row,col),0)^2 + ...
                                                max(im_yf(row,col),0)^2);
                else
                    I_grad_norm(row,col) = sqrt(max(im_xb(row,col),0)^2 + ...
                                                min(im_xf(row,col),0)^2 + ...
                                                max(im_yb(row,col),0)^2 + ...
                                                min(im_yf(row,col),0)^2);
                end
            end
        end
        I_delta = zeros(height, width);
        I_delta = beta.* I_grad_norm;
        im2(mask) = im2(mask) + 0.1*I_delta(mask);
    end
  %% Start diffusion
    %lambda=100;
    %I_diff = im2;
    %co1=1./sqrt(repmat(eps.^2,height,width)+(im_xf.*mask).^2+(im_y.*mask).^2);
    %co1(1,:) = 0; co1(:,1) = 0; co1(height,:) = 0; co1(:,width) = 0;
    %co2=1./sqrt(repmat(eps.^2,height,width)+(im_xb.*mask).^2+(im_y.*mask).^2);
    %co2(1,:) = 0; co2(:,1) = 0; co2(height,:) = 0; co2(:,width) = 0;
    %co3=1./sqrt(repmat(eps.^2,height,width)+(im_x.*mask).^2+(im_yf.*mask).^2);
    %co3(1,:) = 0; co3(:,1) = 0; co3(height,:) = 0; co3(:,width) = 0;
    %co4=1./sqrt(repmat(eps.^2,height,width)+(im_x.*mask).^2+(im_yb.*mask).^2);
    %co4(1,:) = 0; co4(:,1) = 0; co4(height,:) = 0; co4(:,width) = 0;
    %co=1+2*0.1*(~mask.*lambda)+0.1*(co1+co2+co3+co4);
    %co(1,:) = 0; co(:,1) = 0; co(height,:) = 0; co(:,width) = 0;
    %for diffuse_iter=1:N_anidiff
    %    div=co1.*imfilter(I_diff,[0 0 0;0 0 0;0 1 0])+...
    %        co2.*imfilter(I_diff,[0 1 0;0 0 0;0 0 0])+...
    %        co3.*imfilter(I_diff,[0 0 0;0 0 1;0 0 0])+...
    %        co4.*imfilter(I_diff,[0 0 0;1 0 0;0 0 0]);
    %    im_diff=(1./co).*(I_diff+2*0.1*(~mask.*lambda.*im2)+0.1*div);
    %    %border conditions
    %    im_diff(1,:)=im_diff(2,:);
    %    im_diff(end,:)=im_diff(end-1,:);
    %    im_diff(:,1)=im_diff(:,2);
    %    im_diff(:,end)=im_diff(:,end-1);
    %    im_diff(1,1) = im_diff(2,2);
    %    im_diff(1,end) = im_diff(2,end-1);
    %    im_diff(end,1) = im_diff(end-1,2);
    %    im_diff(end,end) = im_diff(end-1,end-1);
    %end
    %im2(mask) = im_diff(mask);
    im2 = anisodiff2D(im2,N_anidiff,1/7,30,2);
    %% Update for stop condition
        change_per_pixel = sum(sum(abs(im - im2))) / mask_size;
        i = i + 1;
        im(mask) = im2(mask);
        %Draw image
        %imshow(im); hold on;
        %set(gca, 'xtick', [], 'ytick', []);
        %title('Inpainted Image', 'FontSize', 12);
        %drawnow;
        %hold off;
    end
    
end

