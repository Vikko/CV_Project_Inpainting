function [ err ] = im_error(im1, im2, mask)
    % Calculates the dissimilarity in the two pictures, if mask is given,
    % only on masked locations (where the data is predicted)
    if(nargin == 2)
       mask = true(size(im1,1),size(im1,2)); 
    end
    if(size(im1) ~= size(im2))
        err = 1;
    else 
        mask3d = repmat(mask,1,1,3);
        count = abs(im1(mask3d) - im2(mask3d));
        err = sum(sum(sum(count)))/(255*sum(sum(sum(mask3d))));
    end
end

