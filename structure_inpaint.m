function [ reconstruction ] = structure_inpaint(recon, mask, im_orig )
    %recon - naive reconstructed image
    %mask - mask of uncertainty
    %im_orig - original left eye view
    reconstruction = recon;
    reconstruction(mask)= 0;
    im_lab = rgb2lab(recon);
    im_orig_lab = rgb2lab(im_orig);
    i=1;
    edge = mask - imerode(mask,strel('disk',3));
    mask2 = mask;
    height = size(im_lab,1);
    width = size(im_lab,2);
    %create sliding window
    fprintf('Create sliding window...');
    sz = [21 21];
    sliding_window_L = zeros(sz(1)*sz(2),width*height);
    sliding_window_A = zeros(sz(1)*sz(2),width*height);
    sliding_window_B = zeros(sz(1)*sz(2),width*height);
    for row=1:height
        for col=1:width
            [patch, ~] = create_patch(im_orig_lab, mask2, row, ...
                                            col,sz);
            patch_L = patch(:,:,1);
            patch_A = patch(:,:,2);
            patch_B = patch(:,:,3);
            sliding_window_L(:,(col-1)*height+row) = patch_L(:);
            sliding_window_A(:,(col-1)*height+row) = patch_A(:);
            sliding_window_B(:,(col-1)*height+row) = patch_B(:);
        end
    end
    while sum(sum(edge)) > 0
        fprintf('Iteration: %i \n',i);
        [edge_r,edge_c] = find(edge);
        for idx=1:size(edge_r,1)
            %check if the pixel still needs to be inpainted
            if (mask2(edge_r(idx),edge_c(idx))==true)
                %create patch
                [patch, patch_mask] = create_patch(im_lab, mask2, edge_r(idx), ...
                                                    edge_c(idx),sz);
                patch_L = patch(:,:,1);
                patch_A = patch(:,:,2);
                patch_B = patch(:,:,3);

                %find most similar patch
                diff_L = repmat(patch_mask(:),1,size(sliding_window_L,2)).*(repmat(patch_L(:),1,size(sliding_window_L,2))-sliding_window_L);
                diff_A = repmat(patch_mask(:),1,size(sliding_window_A,2)).*(repmat(patch_A(:),1,size(sliding_window_A,2))-sliding_window_A);
                diff_B = repmat(patch_mask(:),1,size(sliding_window_B,2)).*(repmat(patch_B(:),1,size(sliding_window_B,2))-sliding_window_B);
                diff = zeros(1,width*height);
                for j=1:width*height
                    diff(j) = norm(diff_L(:,j))+norm(diff_A(:,j))+norm(diff_B(:,j));
                end
                [~,best_idx] = min(diff);


                %copy best patch on masked locations
                best_r = mod(best_idx-1,(height))+1;
                best_c = ceil(best_idx/height);
                for r=-round(sz(1)/2):round(sz(1)/2)
                    for c=-round(sz(2)/2):round(sz(2)/2)
                        %border conditions
                        o_r = best_r+r;
                        o_c = best_c+c;
                        r_r = edge_r(idx)+r;
                        r_c = edge_c(idx)+c;
                        if (r_r >= 1 && r_r <= height && ...
                            r_c >= 1 && r_c <= width && ...
                            o_r >= 1 && o_r <= height && ...
                            o_c >= 1 && o_c <= width)
                            %only copy masked part
                            if (mask2(r_r,r_c) == true)
                                reconstruction(r_r,r_c,:) = ...
                                    im_orig(o_r,o_c,:);
                                %set mask to false when inpainted
                                mask2(r_r,r_c) = false;
                            end
                        end
                    end
                end
                %reconstruction(edge_r(idx),edge_c(idx),:) = best_pixel;
            end
            fprintf('Updated pixel %i of %i\n',idx,size(edge_r,1));
        end
        %reduce size of the region (propagate inwards)
        %mask2 = mask2 - edge;
        edge = mask2 - imerode(mask2,strel('disk',3));
        i=i+1;
    end
end