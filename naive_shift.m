%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main file - uncomment the required inpainting %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load_data
max_disparity = 85;
[height, width,~] = size(im);
%% Naive right camera view, propagate last known value to the right.
%% Create a mask to inpaint concurrently.
reconstruction = zeros(height,width,3);
mask = false(height,width);

for row=1:height
    for col=2:width
        disparity = round(dmap(row,col)*max_disparity);
        px_l = max(1,col-disparity);
        px_r = col;
        if(px_l <= px_r)
            mask(row,px_l:px_r) = true;
            mask(row,px_l) = false;
            reconstruction(row,px_l:px_r,:) = repmat(im(row,col,:),1,px_r-px_l+1);
        end
    end
end
%% Display naive shift
% subplot(1,2,1);
% imshow(im2);
% title('Ground truth');
% subplot(1,2,2);
% imshow(reconstruction);
% title('Right view reconstruction');
% pause;
%% Display map of uncertainty
% subplot(1,2,1);
% imshow(reconstruction);
% title('Right view reconstruction');
% subplot(1,2,2);
% imshow(mask);
% title('Map of uncertainty');
% pause;
%% Display fast reconstruction
% mask_noedge = mask;
% mask_noedge(:,1) = false;
% mask_noedge(:,size(im,2)) = false;
% mask_noedge(1,:) = false;
% mask_noedge(size(im,1),:) = false;
% im_fast = fast_inpaint(reconstruction,mask_noedge,10);
% subplot(1,2,1);
% imshow(im2);
% title('Ground truth');  
% subplot(1,2,2);
% imshow(im_fast);
% title('Fast reconstruction (no annotations)');
% pause;
%% Display structure reconstruction
% im_struc = structure_inpaint(reconstruction,mask,im2);
% subplot(1,2,1);
% imshow(uint8(im2));
% title('Ground truth');  
% subplot(1,2,2);
% imshow(im_struc);
% title('Structure inpainting');
%% Display bertalmio inpainting
mask_noedge = mask;
mask_noedge(:,1:2) = false;
mask_noedge(:,end-1:end) = false;
mask_noedge(1:2,:) = false;
mask_noedge(end-1:end,:) = false;
% Multiscale processing
recon2 = imresize(reconstruction,0.5);
mask2 = imresize(mask_noedge,0.5);
mask2(:,1:2) = false;
mask2(:,end-1:end) = false;
mask2(1:2,:) = false;
mask2(end-1:end,:) = false;
recon3 = imresize(recon2,0.5);
mask3 = imresize(mask2,0.5);
mask3(:,1:2) = false;
mask3(:,end-1:end) = false;
mask3(1:2,:) = false;
mask3(end-1:end,:) = false;
recon4 = imresize(recon3,0.5);
mask4 = imresize(mask3,0.5);
mask4(:,1:2) = false;
mask4(:,end-1:end) = false;
mask4(1:2,:) = false;
mask4(end-1:end,:) = false;
%inpaint 12.5%
disp('scale 12.5% - Inpainting R');
recon4(:,:,1) = bertalmio_inpaint(recon4(:,:,1),mask4, 250, true);
disp('scale 12.5% - Inpainting G');
recon4(:,:,2) = bertalmio_inpaint(recon4(:,:,2),mask4, 250, true);
disp('scale 12.5% - Inpainting B');
recon4(:,:,3) = bertalmio_inpaint(recon4(:,:,3),mask4, 250, true);
results4 = imresize(recon4,2);
%inpaint 25%
recon3(repmat(mask3,1,1,3)) = results4(repmat(mask3,1,1,3));
disp('scale 25% - Inpainting R');
recon3(:,:,1) = bertalmio_inpaint(recon3(:,:,1),mask3, 175);
disp('scale 25% - Inpainting G');
recon3(:,:,2) = bertalmio_inpaint(recon3(:,:,2),mask3, 175);
disp('scale 25% - Inpainting B');
recon3(:,:,3) = bertalmio_inpaint(recon3(:,:,3),mask3, 175);
results3 = imresize(recon3,2);
%inpaint 50%
recon2(repmat(mask2,1,1,3)) = results3(repmat(mask2,1,1,3));
disp('scale 50% - Inpainting R');
recon2(:,:,1) = bertalmio_inpaint(recon2(:,:,1),mask2, 150);
disp('scale 50% - Inpainting G');
recon2(:,:,2) = bertalmio_inpaint(recon2(:,:,2),mask2, 150);
disp('scale 50% - Inpainting B');
recon2(:,:,3) = bertalmio_inpaint(recon2(:,:,3),mask2, 150);
results2 = imresize(recon2,2);
%inpaint 100%
reconstruction(repmat(mask,1,1,3)) = results2(repmat(mask,1,1,3));
disp('scale 100% - Inpainting R');
im_bertalmio(:,:,1) = bertalmio_inpaint(reconstruction(:,:,1),mask_noedge);
disp('scale 100% - Inpainting G');
im_bertalmio(:,:,2) = bertalmio_inpaint(reconstruction(:,:,2),mask_noedge);
disp('scale 100% - Inpainting B');
im_bertalmio(:,:,3) = bertalmio_inpaint(reconstruction(:,:,3),mask_noedge);
time = toc / 60;
fprintf('Done after %.1f minutes',time);
subplot(1,2,1);
imshow(im2);
title('Ground truth');  
subplot(1,2,2);
imshow(im_bertalmio);
title('Bertalmio inpainting');