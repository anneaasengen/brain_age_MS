% Step 4: Create warped images using SPM/CAT12
% This script applies the DARTEL flow fields to the gray matter and PVE images.
% The gray matter image is modulated, while the PVE image is warped without
% modulation.

clear; clc;

% Set up SPM
spm('defaults','FMRI');
spm_jobman('initcfg');


% 1. Define project folders
base_dir = '/media/anneaasengen/CEVAULT2TB';
project_dir = fullfile(base_dir, 'VBM_project_HCP');
t1_dir   = fullfile(project_dir, 'T1_scans');

% Find all subject folders
subjects = dir(t1_dir);
subjects = subjects([subjects.isdir]);
subjects = subjects(~ismember({subjects.name}, {'.','..'}));

nSubj = numel(subjects);
fprintf('Found %d subjects.\n', nSubj);


% 2. Start parallel pool
% Use about 80% of the available CPU cores
numCores   = feature('numcores');
maxWorkers = max(1, floor(0.8 * numCores));
if isempty(gcp('nocreate'))
    parpool('local', maxWorkers);
    fprintf('Started parallel pool with %d workers (of %d cores).\n', maxWorkers, numCores);
else
    fprintf('Using existing parallel pool.\n');
end


% 3. Loop through all subjects in parallel
parfor i = 1:nSubj
    subj_id  = subjects(i).name;
    subj_mri = fullfile(t1_dir, subj_id, 'mri');
    out_dir  = fullfile(subj_mri, 'step4_warped');

    try
        % Skip subject if MRI folder does not exist
        if ~exist(subj_mri, 'dir')
            warning('[Subject %d] No mri folder for %s – skipping.', i, subj_id);
            continue;
        end

        % Skip subject if output already exists
        if exist(out_dir, 'dir')
            existing_warped = dir(fullfile(out_dir, 'mwrp1*.nii'));
            if ~isempty(existing_warped)
                fprintf('[Subject %d] Skipping %s — warped files already exist.\n', i, subj_id);
                continue;
            end
        end

        % Create output folder for this step
        if ~exist(out_dir, 'dir')
            mkdir(out_dir);
        end

        fprintf('\n[Subject %d] --- Processing %s ---\n', i, subj_id);

        
        % Find the files needed for warping
        flow_fields = spm_select('FPList', subj_mri, '^u_.*Template\.nii$');
        gm_images   = spm_select('FPList', subj_mri, '^rp1.*affine.*\.nii$');
        pve_images  = spm_select('FPList', subj_mri, '^rp0.*affine.*\.nii$');

        % Skip the subject if any required input files are missing
        if isempty(flow_fields)
            warning('[Subject %d] No flow fields found for %s.', i, subj_id);
            continue;
        end
        if isempty(gm_images)
            warning('[Subject %d] No GM images found for %s.', i, subj_id);
            continue;
        end
        if isempty(pve_images)
            warning('[Subject %d] No PVE images found for %s.', i, subj_id);
            continue;
        end

        
        % 4. Set up DARTEL warping batch
        matlabbatch = {};

        
        % Warp gray matter image and apply modulation
        % This preserves local volume information after spatial normalization.
        matlabbatch{1}.spm.tools.dartel.crt_warped.flowfields = cellstr(flow_fields);
        matlabbatch{1}.spm.tools.dartel.crt_warped.images{1}  = cellstr(gm_images);
        matlabbatch{1}.spm.tools.dartel.crt_warped.jactransf  = 1;
        matlabbatch{1}.spm.tools.dartel.crt_warped.K          = 6;
        matlabbatch{1}.spm.tools.dartel.crt_warped.interp     = 1;

        
        % Warp PVE image without modulation
        % This keeps the image intensities as probability/segmentation values.
        matlabbatch{2}.spm.tools.dartel.crt_warped.flowfields = cellstr(flow_fields);
        matlabbatch{2}.spm.tools.dartel.crt_warped.images{1}  = cellstr(pve_images);
        matlabbatch{2}.spm.tools.dartel.crt_warped.jactransf  = 0;

        
        % Run the SPM batch
        spm_jobman('run', matlabbatch);

        
        % 5. Move the warped output files to the step4_warped folder
        moved_files = 0;
        move_patterns = {'wrp0*.nii', 'mwrp1*.nii'};

        for p = 1:numel(move_patterns)
            src_files = dir(fullfile(subj_mri, move_patterns{p}));
            for f = 1:numel(src_files)
                src_path  = fullfile(subj_mri, src_files(f).name);
                dest_path = fullfile(out_dir, src_files(f).name);
                movefile(src_path, dest_path);
                fprintf('[Subject %d] Moved %s → step4_warped/\n', i, src_files(f).name);
                moved_files = moved_files + 1;
            end
        end

        % Give a warning if no output files were found after running the batch
        if moved_files == 0
            warning('[Subject %d] No warped files found to move for %s.', i, subj_id);
        end

    catch ME
        % Continue with the next subject if one subject fails
        warning('[Subject %d] Error processing %s: %s', i, subj_id, ME.message);
    end
end

fprintf('\nStep 4 complete: All warped files moved into step4_warped folders.\n');

