% VBM Step 3: Create a symmetric DARTEL template from original and flipped tissue images.

% This script uses the affine gray matter (rp1) and white matter (rp2) images
% from CAT12, together with their left-right flipped versions from Step 2.
% Including both original and flipped images helps create a symmetric template,
% which is important when the later goal is to compare hemispheres and calculate
% voxel-wise asymmetry maps.

% The main outputs are the DARTEL templates (Template_0 to Template_6) and the
% subject-specific flow fields (u_*.nii), which are used in later normalization steps.

tic;
fprintf('Starting DARTEL template creation at %s\n', datestr(now));

% 1. Paths 
% Define the main project folders.
base_dir    = '/media/anneaasengen/CEVAULT2TB';
project_dir = fullfile(base_dir, 'VBM_project_HCP');
t1_dir      = fullfile(project_dir, 'T1_scans');


% 2. Skip entire step if Template_6.nii already exists

% Template_6 is the final DARTEL template. If it already exists, this step has
% most likely been completed before, so the script stops to avoid recomputing it.
template6 = fullfile(project_dir, 'Template_6.nii');
if isfile(template6)
    fprintf('Skipping Step 3 – Template_6.nii already exists in project root.\n');
    return;
end

% 3. Find input GM/WM images 

% Find the original and flipped affine gray matter and white matter images.
% rp1 corresponds to gray matter and rp2 corresponds to white matter.
gm_files   = dir(fullfile(t1_dir, '*', 'mri', 'rp1*_affine.nii'));
gm_flip    = dir(fullfile(t1_dir, '*', 'mri', 'rp1*_affine_flipped.nii'));
wm_files   = dir(fullfile(t1_dir, '*', 'mri', 'rp2*_affine.nii'));
wm_flip    = dir(fullfile(t1_dir, '*', 'mri', 'rp2*_affine_flipped.nii'));

% Convert the file structures returned by dir() into full file paths
gm_list    = fullfile({gm_files.folder},   {gm_files.name});
gm_flip_l  = fullfile({gm_flip.folder},    {gm_flip.name});
wm_list    = fullfile({wm_files.folder},   {wm_files.name});
wm_flip_l  = fullfile({wm_flip.folder},    {wm_flip.name});


% Stop if any of the required inputs are missing.
% This usually means that Step 1 or Step 2 has not been completed successfully.
if isempty(gm_list) || isempty(gm_flip_l)
    error('Missing GM affine or flipped files – did you finish Step 2?');
end
if isempty(wm_list) || isempty(wm_flip_l)
    error('Missing WM affine or flipped files – did you finish Step 2?');
end

% Combine original and flipped images. DARTEL will use both versions to build
% a symmetric template.
gm_all = [gm_list(:); gm_flip_l(:)];
wm_all = [wm_list(:); wm_flip_l(:)];

fprintf('Found %d GM images and %d WM images.\n', numel(gm_all), numel(wm_all));

% 4. Check completeness per subject (folder-based) 

% Check that each subject has all required GM and WM images before running DARTEL.
% This makes it easier to detect incomplete preprocessing from earlier steps.
fprintf('Checking GM/WM affine + flipped files per subject...\n');

subj_dirs = unique(cellfun(@fileparts, gm_list, 'UniformOutput', false));
missing = {};

for i = 1:numel(subj_dirs)
    mri_dir = subj_dirs{i};
    
    % These four files are required for each subject
    req = {
        'rp1*_affine.nii'
        'rp1*_affine_flipped.nii'
        'rp2*_affine.nii'
        'rp2*_affine_flipped.nii'
    };

    % Store a message for each missing file instead of stopping immediately.
    % This gives a full overview of missing data across all subjects.
    for r = 1:numel(req)
        if isempty(dir(fullfile(mri_dir, req{r})))
            missing{end+1,1} = sprintf('Missing %s in %s', req{r}, mri_dir);
        end
    end
end

if ~isempty(missing)
    fprintf('Warning: Missing files detected:\n');
    disp(missing);
else
    fprintf('All subjects appear to have complete affine + flipped GM/WM sets.\n');
end

% 5. Skip subjects that already have flow fields (folder-based)

% Flow fields (u_*.nii) are created by DARTEL and describe how each subject
% should be warped to the template. Subjects with existing flow fields are
% skipped so the script can be restarted without reprocessing everything.
fprintf('Checking existing flow fields...\n');

keep_gm = true(size(gm_all));
keep_wm = true(size(wm_all));

for i = 1:numel(gm_all)
    mri_dir = fileparts(gm_all{i});
    if ~isempty(dir(fullfile(mri_dir, 'u_*.nii')))
        keep_gm(i) = false;
        keep_wm(i) = false;
    end
end

% Keep only the images that still need DARTEL flow fields
gm_all = gm_all(keep_gm);
wm_all = wm_all(keep_wm);

if isempty(gm_all)
    fprintf('All subjects already have flow fields – skipping DARTEL computation.\n');
    fprintf('Delete u_*.nii files to force reprocessing if needed.\n');
    return;
else
    % Each subject contributes both an original and a flipped image, so the
    % number of subjects is half the number of files.
    fprintf('Proceeding with %d subjects missing flow fields.\n', numel(gm_all)/2);
end

% 6. Run DARTEL

% Initialize SPM before setting up and running the DARTEL batch
spm('defaults','FMRI');
spm_jobman('initcfg');

% DARTEL uses paired GM and WM image lists to estimate the common template and
% the subject-specific deformations to that template.
matlabbatch = {};
matlabbatch{1}.spm.tools.dartel.warp.images = {gm_all, wm_all};

fprintf('Running DARTEL template creation...\n');
spm_jobman('run', matlabbatch);

% 7. Move Template_*.nii to project root

% SPM writes the template files to the folder of the first input image.
% Move them to the project root so later scripts can find them more easily.
first_mri_dir = fileparts(gm_all{1});
template_files = dir(fullfile(first_mri_dir, 'Template_*.nii'));

for i = 1:numel(template_files)
    src  = fullfile(template_files(i).folder, template_files(i).name);
    dest = fullfile(project_dir, template_files(i).name);

    % Replace any existing template file in the project root
    if isfile(dest)
        delete(dest);
    end
    movefile(src, dest);
end

fprintf('Templates moved to %s\n', project_dir);
fprintf('Step 3 complete! Total time: %.1f minutes\n', toc/60);

