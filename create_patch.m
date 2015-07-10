function [ patch, patch_mask ] = create_patch( im, mask, row, col, sz)
    patch = zeros(sz(1), sz(2), size(im,3));
    patch_mask = false(sz);
    height = size(im,1);
    width = size(im,2);
    offset = round(sz(1)/2)-1;
    %calculate offsets (border conditions)
    offset_t = offset - max(offset+(1-row),0);
    offset_b = offset - max(offset+(row-height),0);
    offset_l = offset - max(offset+(1-col),0);
    offset_r = offset - max(offset+(col-width),0);
    %set center pixel
    center_r = round(sz(1)/2);
    center_c = round(sz(2)/2);
    %copy data
    patch(center_r-offset_t:center_r+offset_b, ...
          center_c-offset_l:center_c+offset_r,:) = ...
          im(row-offset_t:row+offset_b,col-offset_l:col+offset_r,:);
    %patch mask: 1 contains data, 0 doesnt
    patch_mask(center_r-offset_t:center_r+offset_b, ...
          center_c-offset_l:center_c+offset_r) = ...
          ~mask(row-offset_t:row+offset_b,col-offset_l:col+offset_r);
end

