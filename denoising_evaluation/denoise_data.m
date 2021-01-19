function denoise_data

data_folder = 'DATA';
cw = pwd; data_folder = [cw,'/',data_folder];

runs  = {'1','2'};
phase = 'RL';
hp = 2000;

WBC='wb_command';
bcmode = 'CORRECT';

output_dir = [cw,'/results'];
if not(exist(output_dir,'dir'))
    mkdir(cw,'results');
end

%common name = DATA/101915/MNINonLinear/nuisance_masks
WM_name = '/MNINonLinear/nuisance_masks/rwm_e6.nii.gz';
CSF_name = '/MNINonLinear/nuisance_masks/rcsf_e2.nii.gz';

TR = 0.72;


%first define the set of all possible regressors that will be combined in
%different processing variants
reg_set.names = {'6RP','12RP','24RP','8Phys',...
    'aComCor50%','aComCor50% opt.',...
    'aCompCor'  ,'aCompCor opt.',...
    'FIX'};

pass_band = 'hp2000';

pv(1).band = pass_band;
pv(1).iX = {''};
pv(1).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'6RP'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'12RP'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'24RP'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'24RP','8Phys'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'24RP','aCompCor'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'24RP','aComCor50'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'24RP','aCompCor opt.'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'24RP','aComCor50 opt.'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'24RP','FIX'};
pv(end).cens = 0;

pv = pv_buildname(pv);
pv_number = length(pv);

list_subj = dir([data_folder,'/*']);
list_subj(1:2) = [];
n_subj = length(list_subj);

h = waitbar(0,'Please wait...');

for l = 1:n_subj
    fprintf('\n****** Doing Subj %s ********\n',list_subj(l).name);
    subj_path = [data_folder,'/',list_subj(l).name];
    %mkdir([subj_path,'/MNINonLinear'],'nuisance_masks');
    
    for r = 1:2
        
        run_name = ['rfMRI_REST',runs{r},'_',phase];
        
        ciftiraw = [subj_path,'/MNINonLinear/Results/',run_name,'/',run_name,'_Atlas'];
        RP =       [subj_path,'/MNINonLinear/Results/',run_name,'/Movement_Regressors.txt'];
        WMhcp =    [subj_path,'/MNINonLinear/Results/',run_name,'/',run_name,'_WM.txt'];
        CSFhcp =   [subj_path,'/MNINonLinear/Results/',run_name,'/',run_name,'_WM.txt'];
        FIXnoise = [subj_path,'/MNINonLinear/Results/',run_name,'/',run_name,'_hp2000.ica/.fix']; %noise
        FIXICs =   [subj_path,'/MNINonLinear/Results/',run_name,'/',run_name,'_hp2000.ica/filtered_func_data.ica/melodic_mix']; %ICA components
        bias= [subj_path,'/MNINonLinear/Results/',run_name,'/',run_name,'_Atlas_hp2000_clean_bias.dscalar.nii']; %bias field
        outprefix = ciftiraw;
        
        BO=ciftiopen([ciftiraw '.dtseries.nii'],WBC);
        tpDim = 2;
        
        % Revert bias field if requested
        if ~strcmp(bcmode,'NONE')
            bias=ciftiopen(bias,WBC);
            BO.cdata=BO.cdata.*repmat(bias.cdata,1,size(BO.cdata,tpDim));
        end
        
        FixVN=0;
        if exist(bcmode,'file')
            real_bias=ciftiopen(bcmode,WBC);
            BO.cdata=BO.cdata./repmat(real_bias.cdata,1,size(BO.cdata,tpDim));
            FixVN=1;
        end
        
        if ~exist([outprefix '_fakeNIFTI_filtered.nii.gz'],'file')
            %%%% Highpass each grayordinate with fslmaths according to hp variable
            fprintf('Starting fslmaths filtering of cifti input\n');
            BOdimX=size(BO.cdata,1);  BOdimZnew=ceil(BOdimX/100);  BOdimT=size(BO.cdata,tpDim);
            fprintf('About to save fakeNIFTI file. outprefix: %s\n',outprefix);
            save_avw(reshape([BO.cdata ; zeros(100*BOdimZnew-BOdimX,BOdimT)],10,10,BOdimZnew,BOdimT),[outprefix '_fakeNIFTI'],'f',[1 1 1 TR]);

            cmd_str=sprintf(['fslmaths ' outprefix '_fakeNIFTI_filtered -bptf %f -1 ' outprefix '_fakeNIFTI'],0.5*hp/TR);
            fprintf('About to execute: %s\n',cmd_str);
            system(cmd_str);  
            %remove the fake nifti 
            system(['rm ' outprefix '_fakeNIFTI.nii.gz']);
        end
        
        
        
        for z = 1:pv_number
            fprintf('\n--> Processing variant > %d %s',z,pv(z).name);
        end
        
        
    end
    
end

return
end

function pv = pv_buildname(pv)
global thr thr_pct
pv_number = length(pv);

for l = 1:pv_number
    str = [];
    if ~isempty(pv(l).band)
        str = [str,pv(l).band,'+'];
    end
    for z = 1:length(pv(l).iX)
        str = [str,pv(l).iX{z},'+'];
    end
    if pv(l).cens == 1
        str = [str,'cT',num2str(thr),'+'];
    end
    if pv(l).cens == 2
        str = [str,'cP',num2str(thr_pct),'+'];
    end
    if isempty(str)
        pv(l).name = 'RAW';
    else
        pv(l).name = str(1:end-1);
    end
    if strcmp(str(end),'+')
        str(end) = [];
    end
end

return
end

