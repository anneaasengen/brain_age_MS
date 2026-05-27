% Step 5: Create a right-hemisphere mask in symmetric template space
% This script creates a binary mask that keeps only the right hemisphere.
% The mask is later used to extract one hemispheric half from the symmetric
% template space, so that asymmetry maps can be stored without duplicating
% the same information in both hemispheres.

% 1. Define paths 
% The mask is created from the final DARTEL template from Step 3.
% The output is saved in a separate masks folder inside the project directory.
template_dir = '/media/anneaasengen/CEVAULT2TB/VBM_project_HCP';
template_file = fullfile(template_dir, 'Template_6.nii');
output_dir    = fullfile(template_dir, 'masks');
output_file   = fullfile(output_dir, 'right_mask.nii');

% 2. Skip if mask already exists 
% This makes the script safe to rerun without overwriting an existing mask.
if isfile(output_file)
    fprintf('Skipping Step 5 – right_mask.nii already exists in %s\n', output_dir);
    return;
end

% 3. Verify template exists 
% The mask must be created in the same space as the warped images.
% Therefore, Template_6.nii from the DARTEL template creation step is required.
if ~isfile(template_file)
    error('Template_6.nii not found in %s. Did you finish Step 3?', template_dir);
end

% 4. Load DARTEL template (gray matter = image 1) 
% Template_6.nii is a multi-volume image. The first volume is used here
% only to obtain the correct image dimensions and spatial header information.
fprintf('Reading template: %s\n', template_file);
V = spm_vol([template_file ',1']);  % use only the first volume (GM)
[Y, ~] = spm_read_vols(V);

% 5. Get image dimensions and determine midline 
% The left-right direction corresponds to the first image dimension.
% The midline is estimated as the middle voxel along this dimension.
nx = size(Y,1);
mid_x = floor(nx/2);
fprintf('Template dimensions: %d x %d x %d\n', size(Y));
fprintf('Midline at voxel x = %d\n', mid_x);

% 6. Create binary mask for the right hemisphere 
% Voxels included in the mask are assigned the value 1.
% Voxels outside the selected hemisphere remain 0.
mask = zeros(size(Y));
mask(1:mid_x, :, :) = 1;  % all voxels right of midline in MNI space (x > 0)

% 7. Save mask as NIfTI file 
% The template header is reused so that the mask has the same voxel size,
% orientation and coordinate system as the DARTEL template.
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
V_mask = V;
V_mask.fname = output_file;
V_mask.descrip = 'Right-hemisphere mask';
spm_write_vol(V_mask, mask);

% 8. Coordinate sanity check 
% These values are printed to verify that the selected half corresponds
% to the intended hemisphere in template/MNI space.
xMNI = V.mat(1,1)*1 + V.mat(1,4);          % x-value for voxel 1
xMNI_mid = V.mat(1,1)*mid_x + V.mat(1,4);  % x-value for midline
fprintf('x-value for voxel 1: %.2f mm\n', xMNI);
fprintf('x-value for midline: %.2f mm\n', xMNI_mid);

% Print the MNI coordinate of the first voxel included in the mask.
% This provides an additional check that the mask starts on the expected side.
idx = find(mask,1,'first'); % first voxel in the mask
[x,y,z] = ind2sub(size(mask), idx);
world_coord = V.mat * [x y z 1]';
fprintf('MNI x-value for first voxel in the mask: %.2f mm\n', world_coord(1));

fprintf('Mask saved as: %s\n', V_mask.fname);
fprintf('Step 5 complete. You can now proceed to Step 6.\n');

