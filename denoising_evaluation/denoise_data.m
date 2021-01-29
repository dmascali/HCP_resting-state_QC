function denoise_data

data_folder = 'DATA';
cw = pwd; data_folder = [cw,'/',data_folder];

runs  = {'1','2'};
phase = 'RL';
hp = 2000;

WBC='wb_command';
bcmode = 'NONE';

setenv('LD_PRELOAD','/usr/lib/x86_64-linux-gnu/libQt5Network.so.5 /usr/lib/x86_64-linux-gnu/libQt5Core.so.5 /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5 /usr/lib/x86_64-linux-gnu/libQt5Xml.so.5');


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
        
       
        filtered_cifti = [subj_path,'/MNINonLinear/Results/',run_name,'/hp2000_data.mat'];
        if ~exist(filtered_cifti,'file')
            
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
            
            %remove mean
            MEAN = mean(BO.cdata,tpDim);
            BO.cdata = demean(BO.cdata,tpDim);

            %%%% Highpass each grayordinate with fslmaths according to hp variable
            fprintf('Starting fslmaths filtering of cifti input\n');
            BOdimX=size(BO.cdata,1);  BOdimZnew=ceil(BOdimX/100);  BOdimT=size(BO.cdata,tpDim);
            fprintf('About to save fakeNIFTI file. outprefix: %s\n',outprefix);
            save_avw(reshape([BO.cdata ; zeros(100*BOdimZnew-BOdimX,BOdimT)],10,10,BOdimZnew,BOdimT),[outprefix '_fakeNIFTI'],'f',[1 1 1 TR]);
            cmd_str=sprintf(['fslmaths ' outprefix '_fakeNIFTI -bptf %f -1 ' outprefix '_fakeNIFTI'],0.5*hp/TR);
            fprintf('About to execute: %s\n',cmd_str);
            system(cmd_str);  
            fprintf('About to reshape\n');
            grot=reshape(read_avw([outprefix '_fakeNIFTI']),100*BOdimZnew,BOdimT);  BO.cdata=grot(1:BOdimX,:);  clear grot;
            %save 
            save (filtered_cifti,'BO')
            %remove the fake nifti 
            system(['rm ' outprefix '_fakeNIFTI.nii.gz']);
        else
            load(filtered_cifti);
        end
        
        HighPassTCS=BO.cdata;
        
        filtered_RP = [subj_path,'/MNINonLinear/Results/',run_name,'/hp2000_RP.mat'];
        if ~exist(filtered_RP,'file')        
            %%%%  Read and prepare motion confounds
            % Read in the six motion parameters, compute the backward difference, and square
            % If 'motionparameters' input argument doesn't already have an extension, add .txt
            RP=load(RP);
            RP=RP(:,1:6); %Be sure to limit to just the first 6 elements
            %%confounds=normalise(confounds(:,std(confounds)>0.000001)); % remove empty columns
            RP12=normalise([RP [zeros(1,size(RP,2)); RP(2:end,:)-RP(1:end-1,:)] ]);
            RP24=normalise([RP12 RP12.*RP12]);

            fprintf('%Starting fslmaths filtering of motion confounds\n');
            %RP
            save_avw(reshape(RP',size(RP,2),1,1,size(RP,1)),[outprefix '_fakeNIFTI'],'f',[1 1 1 TR]);
            system(sprintf(['fslmaths ' outprefix '_fakeNIFTI -bptf %f -1 ' outprefix '_fakeNIFTI'],0.5*hp/TR));
            RP_hp2000=normalise(reshape(read_avw([outprefix '_fakeNIFTI']),size(RP,2),size(RP,1))');
            unix(['rm ' outprefix '_fakeNIFTI.nii.gz']);
            %RP12
            save_avw(reshape(RP12',size(RP12,2),1,1,size(RP12,1)),[outprefix '_fakeNIFTI'],'f',[1 1 1 TR]);
            system(sprintf(['fslmaths ' outprefix '_fakeNIFTI -bptf %f -1 ' outprefix '_fakeNIFTI'],0.5*hp/TR));
            RP12_hp2000=normalise(reshape(read_avw([outprefix '_fakeNIFTI']),size(RP12,2),size(RP12,1))');
            unix(['rm ' outprefix '_fakeNIFTI.nii.gz']);
            %RP24
            save_avw(reshape(RP24',size(RP24,2),1,1,size(RP24,1)),[outprefix '_fakeNIFTI'],'f',[1 1 1 TR]);
            system(sprintf(['fslmaths ' outprefix '_fakeNIFTI -bptf %f -1 ' outprefix '_fakeNIFTI'],0.5*hp/TR));
            RP24_hp2000=normalise(reshape(read_avw([outprefix '_fakeNIFTI']),size(RP24,2),size(RP24,1))');
            unix(['rm ' outprefix '_fakeNIFTI.nii.gz']);
            fprintf('Finished fslmaths filtering of motion confounds\n');
            %save filtered parameters
            save(filtered_RP,'RP_hp2000','RP12_hp2000','RP24_hp2000')
        else
            load(filtered_RP)
        end
            
        % NOT SURE WE WILL USE THIS
        filtered_phys_HCP = [subj_path,'/MNINonLinear/Results/',run_name,'/hp2000_phys_HCP.mat'];
        if ~exist(filtered_phys_HCP,'file')        
            WMtcOrig=demean(load(WMhcp));
            fprintf('Starting fslmaths filtering of wm tcs \n');
            save_avw(reshape(WMtcOrig',size(WMtcOrig,2),1,1,size(WMtcOrig,1)),[outprefix '_fakeNIFTI'],'f',[1 1 1 TR]);
            system(sprintf(['fslmaths ' outprefix '_fakeNIFTI -bptf %f -1 ' outprefix '_fakeNIFTI'],0.5*hp/TR));
            WMtcHP=demean(reshape(read_avw([outprefix '_fakeNIFTI']),size(WMtcOrig,2),size(WMtcOrig,1))');
            unix(['rm ' outprefix '_fakeNIFTI.nii.gz']);
            fprintf('Finished fslmaths filtering of wm tcs\n');
            
            CSFtcOrig=demean(load(CSFhcp));
            fprintf('Starting fslmaths filtering of csf tcs \n');
            save_avw(reshape(CSFtcOrig',size(CSFtcOrig,2),1,1,size(CSFtcOrig,1)),[outprefix '_fakeNIFTI'],'f',[1 1 1 TR]);
            system(sprintf(['fslmaths ' outprefix '_fakeNIFTI -bptf %f -1 ' outprefix '_fakeNIFTI'],0.5*hp/TR));
            CSFtcHP=demean(reshape(read_avw([outprefix '_fakeNIFTI']),size(CSFtcOrig,2),size(CSFtcOrig,1))');
            unix(['rm ' outprefix '_fakeNIFTI.nii.gz']);
            fprintf('Finished fslmaths filtering of csf tcs\n');            
            %save filtered series
            save(filtered_phys_HCP,'WMtcHP','CSFtcHP')
        else
            load(filtered_phys_HCP)
        end
        
        %READ ICA TS
        ICAorig = normalise(load(FIXICs));
        FIXnoise=load(FIXnoise);
                
        % Aggressively regress out RP24 from ICA and from data:
        ICA = ICAorig - (RP24_hp2000 * (pinv(RP24_hp2000,1e-6) * ICAorig));     
        PostMotionTCS = HighPassTCS - (RP24_hp2000 * (pinv(RP24_hp2000,1e-6) * HighPassTCS'))';
        
        % FIX cleanup post motion
        %total = 1:size(ICA,2);
        %FIXsignal = total(~ismember(total,FIXnoise));
        betaICA = pinv(ICA,1e-6) * PostMotionTCS';
        CleanedTCS = PostMotionTCS - (ICA(:,FIXnoise) * betaICA(FIXnoise,:))';
        
        cleaned_cifti = BO;
        cleaned_cifti.cdata = CleanedTCS;
                
        % check replication HCP fix cleaned timeseries
        %BFIXorig=ciftiopen([subj_path,'/MNINonLinear/Results/',run_name,'/rfMRI_REST1_RL_Atlas_hp2000_clean.dtseries.nii'],WBC);
        %orig = BFIXorig.cdata' - mean(BFIXorig.cdata');
        %iplot(orig,CleanedTCS')
        
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

