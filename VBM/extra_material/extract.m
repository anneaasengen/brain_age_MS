function [Cluster] = extract(ClusterMap,outdir,Asymmetry,GM_orig,GM_mirrored)

%==========================================================================
% extract
%==========================================================================

% This function is written for use in Asymmetry VBM analyses as described
% in the manuscript "A 12-step user guide for analyzing voxel-wise gray 
% matter asymmetries in statistical parametric mapping (SPM)" by Florian 
% Kurth, Christian Gaser, and Eileen Luders. Basically, it performs Step 12
% of this User's Guide and is available as supplementary material. As part 
% of this Guide, the function relies heavily on SPM routines as distributed
% with SPM8 (http://www.fil.ion.ucl.ac.uk/spm).
% 
% The function needs the thresholded SPM saved as nifti. In addition all
% Asymmetry Maps (in the same space the results are in), as well as all
% warped original and warped mirrored gray matter segments (again in the
% same space the results are in) are needed as input. For each cluster in
% the thresholded SPM the mean asymmetry index and the cluster gray matter
% volumes for right and left hemisphere are extracted for every subject. In
% addition, the clusters will be saved out individually to a user specified
% output directory. Also, in this directory, for each cluster a textfile
% with mean asymmetry index, right hemispheric gray matter volume and left
% hemispheric gray matter volume will be saved. Volumes will be given in
% cubic mm.
% 
% ClusterMap    - nifti image of the thresholded SPM
% outdir        - output directory
% Asymmetry     - Asymmetry Index images used for the statistical analysis
% GM_orig       - cellstructure of warped original gray matter segments
% GM_mirrored   - cellstructure of warped mirrored gray matter segments
% 
% Cluster       - structure containing results:
%   Cluster(i).img   - path to nifti
%   Cluster(i).AI    - mean Asymmetry index for every subject
%   Cluster(i).GM_R  - Gray matter volume for every subject (right)
%   Cluster(i).GM_L  - Gray matter volume for every subject (left)
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation. It is is distributed in the hope that it 
% will be useful, but WITHOUT ANY WARRANTY; without even the implied 
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%__________________________________________________________________________

% Florian Kurth, 2014




% Get Data
% -------------------------------------------------------------------------
if nargin<1 
    clc, clear
    ClusterMap  = spm_select(1,'image','Select nifti image of thresholded SPM');
    [p,cname,~] = fileparts(ClusterMap); directory = p; clear p;
    outdir      = spm_select(1,'dir','Select output directory',[],directory);
    Asymmetry   = cellstr(spm_select(Inf,'image','Select Asymmetry Index images',[],directory));
    GM_orig     = cellstr(spm_select(numel(Asymmetry),'image','Select warped original gray matter segments',[],directory));
    GM_mirrored = cellstr(spm_select(numel(Asymmetry),'image','Select warped mirrored gray matter segments',[],directory));
else
    [~,cname,~] = fileparts(ClusterMap);
end


fprintf('Extract mean asymmetry and gray matter volume for each cluster\n')
fprintf('==========================================================================\n\n')


Cluster = struct('img',{},'AI',{},'GM_R',{},'GM_L',{});


if isempty(spm_figure('FindWin','Interactive'))
spm('CreateIntWin','on');
end





% Get Cluster
% -------------------------------------------------------------------------
vi = spm_vol(ClusterMap);
Y  = spm_read_vols(vi);

a = find(Y>0); [x,y,z] = ind2sub(vi.dim,a); A = spm_clusters([x';y';z']);
Clusternum = max(A);

fprintf('%s cluster identified\n',num2str(Clusternum))
fprintf('Calculating... \n')





% Extract...
% -------------------------------------------------------------------------
for i = 1:Clusternum
    fprintf('- %4.0f of %4.0f\n',i,Clusternum)
    
    c   = find(A == i);                         % get voxels in cluster
    ci  = sub2ind(vi.dim,x(c),y(c),z(c));       % get voxel coordinates
    Yo  = zeros(size(Y)); Yo(ci) = Y(ci);       % get cluster only
    
    XYZc        = [x(c)';y(c)';z(c)'];
    XYZc(4,:)   = 1;
    XYZc        = vi.mat*XYZc;                  % get coordinates in world space
    
    
    
    % write cluster
    %----------------------------------------------------------------------
    vo = vi; 
    vo.fname = fullfile(outdir,[cname '_cluster' num2str(i,'%04.0f') '.nii']);
    spm_write_vol(vo,Yo);
    Cluster(i).img = vo.fname;
    
    
    
    % Asymmetry index
    %----------------------------------------------------------------------
    fprintf('--> AI')  %6
    spm_figure('GetWin','Interactive');
    spm_progress_bar('Init',numel(Asymmetry),'calculate mean AI...','subjects completed');
    AI = nan(numel(Asymmetry),1);
    
    for j = 1:numel(Asymmetry)
        VAsymmetry  = spm_vol(Asymmetry{j});
        XYZ         = round(inv(VAsymmetry.mat)*XYZc);
        
        yy          = spm_get_data(VAsymmetry,XYZ);
        AI(j)       = mean(yy);
        
        clear XYZ yy VAsymmetry
        spm_progress_bar('Set',j);
    end
    
    Cluster(i).AI =  AI;
    clear AI
    spm_progress_bar('Clear');
    
    
    
    % right hemispheric GM
    %----------------------------------------------------------------------
    fprintf(', GM right')  %10
    spm_progress_bar('Init',numel(GM_orig),'calculate right GM...','subjects completed');
    GM_R = nan(numel(GM_orig),1);
    
    for j = 1:numel(GM_orig)
        VGM_orig    = spm_vol(GM_orig{j});
        XYZ         = round(inv(VGM_orig.mat)*XYZc);
        vox_vol     = abs(det(VGM_orig.mat));
        
        yy          = spm_get_data(VGM_orig,XYZ);
        GM_R(j)     = sum(yy).*vox_vol;
        
        clear XYZ yy VGM_orig vox_vol
        spm_progress_bar('Set',j);
    end
    
    Cluster(i).GM_R = GM_R;
    clear GM_R
    spm_progress_bar('Clear');
    
    
    
    % left hemispheric GM
    %----------------------------------------------------------------------
    fprintf(', GM left')  %9
    spm_progress_bar('Init',numel(GM_mirrored),'calculate right GM...','subjects completed');
    GM_L = nan(numel(GM_mirrored),1);
    
    for j = 1:numel(GM_mirrored)
        VGM_mirrored    = spm_vol(GM_mirrored{j});
        XYZ             = round(inv(VGM_mirrored.mat)*XYZc);
        vox_vol         = abs(det(VGM_mirrored.mat));
        
        yy              = spm_get_data(VGM_mirrored,XYZ);
        GM_L(j)         = sum(yy).*vox_vol;
        
        clear XYZ yy VGM_orig vox_vol
        spm_progress_bar('Set',j);
    end
    
    Cluster(i).GM_L = GM_L;
    clear GM_L
    spm_progress_bar('Clear');
    
    
    
    % print
    %----------------------------------------------------------------------
    fprintf(', print')  %7
    fid = fopen(fullfile(outdir,[cname '_cluster' num2str(i,'%04.0f') 'AI_GMR_GML.txt']),'w');
    
    for j = 1:numel(Asymmetry)
        fprintf(fid,'%f\t%f\t%f\n',Cluster(i).AI(j),Cluster(i).GM_R(j),Cluster(i).GM_L(j));
    end
    
    fclose(fid);
    fprintf(repmat('\b',1,32))
end




%Goodbye
%----------------------------------------------------------------------

fprintf('\nAll values extracted. Volumes for gray matter given in cubic mm\n')
fprintf(' done\n\n')
return

