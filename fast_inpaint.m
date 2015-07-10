function [ reconstruction ] = fast_inpaint(im, mask, iter)
    %im - naive reconstructed image
    %mask - mask of uncertainty
    %iter - amount of iterations to propagate colors
    %generate filter
    se = [0.073235 0.176765 0.073235; ...
                0.176765 0.000000 0.176765; ...
                0.073235 0.176765 0.073235];
    reconstruction = im;
    for i=1:iter
        fprintf('Iteration: %i \n',i);
        edge = mask - imerode(mask,strel('disk',3));
        mask2 = mask;
        while sum(sum(edge)) > 0
            %apply filter
            reconstruction(:,:,1) = roifilt2(se,reconstruction(:,:,1),edge);
            reconstruction(:,:,2) = roifilt2(se,reconstruction(:,:,2),edge);
            reconstruction(:,:,3) = roifilt2(se,reconstruction(:,:,3),edge);
            %reduce size of the region (propagate inwards)
            mask2 = mask2 - edge;
            edge = mask2 - imerode(mask2,strel('disk',3));
        end
    end
    reconstruction = reconstruction;
end

