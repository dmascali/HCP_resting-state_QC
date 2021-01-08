function nuisance_mask_creation(wmparc,outfolder,ref)
wm_ero_cycles = 6; % maximum number of erosion cycles
csf_ero_cycles = 2; % maximum number of erosion cycles

if nargin == 1
    outfolder = '.'; %current workfolder
    ref = [];
elseif nargin == 2
    ref = [];
end
% remove any "/" at the end of outfolder
if outfolder(end) == '/'; outfolder(end) = []; end
    
% white matter 
system(['fslmaths ',wmparc,' -thr 3001 -uthr 5002 -bin ',outfolder,'/wm']); 
% erode
for l = 1:wm_ero_cycles
    if l == 1
        system(['fslmaths ',outfolder,'/wm -ero ',outfolder,'/wm_e',num2str(l)]); 
    else
        system(['fslmaths ',outfolder,'/wm_e',num2str(l-1),' -ero ',outfolder,'/wm_e',num2str(l)]); 
    end
end
%resample if requested
if not(isempty(ref))
    for l = 1:wm_ero_cycles
        system(['flirt -in ',outfolder,'/wm_e',num2str(l),' -ref ',ref,' -out ',outfolder,'/rwm_e',num2str(l),' -applyxfm -interp nearestneighbour']);
        % write out the number of voxels in the roi
        [status,result] = system(['fslstats ',outfolder,'/rwm_e',num2str(l),'.nii.gz -V']);
        tmp = str2num(result); 
        dlmwrite([outfolder,'/rwm_e',num2str(l),'_voxel_count.txt'],tmp(1));
    end
end

%csf
system(['fslmaths ',wmparc,' -thr 4 -uthr 4 -bin ',outfolder,'/_tmp1']); 
system(['fslmaths ',wmparc,' -thr 43 -uthr 43 -bin ',outfolder,'/_tmp2']); 
system(['fslmaths ',outfolder,'/_tmp1 -add ',outfolder,'/_tmp2 -bin ',outfolder,'/csf']); 
system(['rm ',outfolder,'/_tmp*.nii.gz']);

% erode
for l = 1:csf_ero_cycles
    if l == 1
        system(['fslmaths ',outfolder,'/csf -ero ',outfolder,'/csf_e',num2str(l)]); 
    else
        system(['fslmaths ',outfolder,'/csf_e',num2str(l-1),' -ero ',outfolder,'/csf_e',num2str(l)]); 
    end
end
%resample if requested
if not(isempty(ref))
    for l = 1:csf_ero_cycles
        system(['flirt -in ',outfolder,'/csf_e',num2str(l),' -ref ',ref,' -out ',outfolder,'/rcsf_e',num2str(l),' -applyxfm -interp nearestneighbour']);
        % write out the number of voxels in the roi
        [status,result] = system(['fslstats ',outfolder,'/rcsf_e',num2str(l),'.nii.gz -V']);
        tmp = str2num(result); dlmwrite([outfolder,'/rcsf_e',num2str(l),'_voxel_count.txt'],tmp(1));
    end
end

return
end