function denoise_data_just_HPfilterNifti

mail = 'danielemascali@gmail.com';
DeltaTime = 60*12; %every 6 hours sends a beacon
sendstatus(mail);
beacon = 1;

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
    'CompCor50%','CompCor50% opt.',...
    'CompCor'   ,'CompCor opt.',...
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
pv(end).iX = {'24RP','CompCor'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'24RP','CompCor50%'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'24RP','CompCor opt.'};
pv(end).cens = 0;

pv(end+1).band = pass_band;
pv(end).iX = {'24RP','CompCor50% opt.'};
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
        
        if beacon; sendbeacon(mail,DeltaTime); end
        
        run_name = ['rfMRI_REST',runs{r},'_',phase];
        
        ciftiraw = [subj_path,'/MNINonLinear/Results/',run_name,'/',run_name,'_Atlas'];
        niftiraw = [subj_path,'/MNINonLinear/Results/',run_name,'/',run_name];
        RP =       [subj_path,'/MNINonLinear/Results/',run_name,'/Movement_Regressors.txt'];
        WMhcp =    [subj_path,'/MNINonLinear/Results/',run_name,'/',run_name,'_WM.txt'];
        CSFhcp =   [subj_path,'/MNINonLinear/Results/',run_name,'/',run_name,'_CSF.txt'];
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
            save (filtered_cifti,'BO','MEAN')
            %remove the fake nifti 
            system(['rm ' outprefix '_fakeNIFTI.nii.gz']);
        else
            %load(filtered_cifti);
        end
        
        %HighPassTCS=BO.cdata;
        
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
            save_avw(reshape(RP24',size(RP24,2),1,1,size(RP24,1)),[outprefix '_fakeNIFTI'],'f',[1 1 1 TR]);
            system(sprintf(['fslmaths ' outprefix '_fakeNIFTI -bptf %f -1 ' outprefix '_fakeNIFTI'],0.5*hp/TR));
            RP24_hp2000=normalise(reshape(read_avw([outprefix '_fakeNIFTI']),size(RP24,2),size(RP24,1))');
            unix(['rm ' outprefix '_fakeNIFTI.nii.gz']);
            fprintf('Finished fslmaths filtering of motion confounds\n');
            %save filtered parameters
            save(filtered_RP,'RP24_hp2000')
        else
            %load(filtered_RP)
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
           % load(filtered_phys_HCP)
        end
        
%         %READ ICA TS
%         ICAorig = normalise(load(FIXICs));
%         FIXnoise=load(FIXnoise);
%                 
%         % Aggressively regress out RP24 from ICA and from data:
%         ICA = ICAorig - (RP24_hp2000 * (pinv(RP24_hp2000,1e-6) * ICAorig));     
%         PostMotionTCS = HighPassTCS - (RP24_hp2000 * (pinv(RP24_hp2000,1e-6) * HighPassTCS'))';
%         
%         % FIX cleanup post motion
%         %total = 1:size(ICA,2);
%         %FIXsignal = total(~ismember(total,FIXnoise));
%         betaICA = pinv(ICA,1e-6) * PostMotionTCS';
%         CleanedTCS = PostMotionTCS - (ICA(:,FIXnoise) * betaICA(FIXnoise,:))';
%         
%         cleaned_cifti = BO;
%         cleaned_cifti.cdata = CleanedTCS;
%                 
%         % check replication HCP fix cleaned timeseries
%         %BFIXorig=ciftiopen([subj_path,'/MNINonLinear/Results/',run_name,'/rfMRI_REST1_RL_Atlas_hp2000_clean.dtseries.nii'],WBC);
%         %orig = BFIXorig.cdata' - mean(BFIXorig.cdata');
%         %iplot(orig,CleanedTCS')
        
        
        % Filter nifti data
        nifti_filtered  = [niftiraw,'_hp2000.nii.gz'];
        if ~exist(nifti_filtered,'file')  
            tic;
            system(sprintf(['fslmaths ' niftiraw ' -bptf %f -1 ' niftiraw '_hp2000'],0.5*hp/TR));
            readsec(toc)
        end
        %load nifti_filtered
        %nifti_filtered = spm_read_vols(spm_vol(nifti_filtered));
        %nifti_filtered should be normalised?
        
        %-----------extract regressors-----------------------------
        %reg_set.run = extract_regressors(nifti_filtered,HighPassTCS,WMmask,CSFmask,WMtcHP,CSFtcHP,RP24_hp2000,reg_set.names,[],[]);
        %----------------------------------------------------------    
        
%         for z = 1:pv_number
%             fprintf('\n--> Processing variant > %d %s',z,pv(z).name);
%         end
        
        
    end
    
end

return
end


function x = extract_regressors(Yvol,Ysurf,WMmask,CSFmask,WMts,CSFts,rp24,regressor_set,TR,pass_band)
%inputs:
%Yvol = nifti hp2000 filtered
%Ysurf = gifti hp2000 filtered ( for MG?)
%WM/CSFmask = nifti mask for extracting confounds
%WM/CSFts = extracted by HCP (they have to be HP filtered)
%RP24 = hp2000 filtered
n_reg = length(regressor_set);


for l = 1:n_reg
    current = regressor_set{l};
    
    switch current
        case {'6RP'}
            x{l} = rp24(:,1:6);
        case {'12RP'}
            x{l} = rp24(:,1:12);
        case {'24RP'}
            x{l} = rp24;
        case {'Phys2'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[0 0],'confounds',[]);
        case {'Phys4'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[0 0],'confounds',[],'derivatives',[1 1]);
        case {'Phys8'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[0 0],'confounds',[],'derivatives',[1 1],'squares',[1 1]);
        case {'CCo12'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[5 5],'confounds',rp12,'firstmean','off','DatNormalise','off');
        case {'CCo24'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[5 5],'confounds',rp24,'firstmean','off','DatNormalise','off');
        case {'GSR2o12'}
            x{l} = fmri_acompcor(vol,{WB},[0],'confounds',rp12,'derivatives',[1]);
        case {'GSR2o24'}
            x{l} = fmri_acompcor(vol,{WB},[0],'confounds',rp24,'derivatives',[1]);
        case {'AROMA'}
            x{l} = fmri_acompcor(volAroma,{WM,CSF},[0 0],'confounds',[]);
        case {'AROMAagg'}
            x{l} = fmri_acompcor(volAromaAgg,{WM,CSF},[0 0],'confounds',[]);
        case {'GSR2Aroma'}
            x{l} = fmri_acompcor(volAroma,{WB},[0],'confounds',[],'derivatives',[1]);
        case {'GSR2AromaAgg'}
            x{l} = fmri_acompcor(volAromaAgg,{WB},[0],'confounds',[],'derivatives',[1]);
        case {'GSR2'}
            x{l} = fmri_acompcor(vol,{WB},[0],'confounds',[],'derivatives',[1]);
        case {'GSR4'}
            x{l} = fmri_acompcor(vol,{WB},[0],'confounds',[],'derivatives',[1],'squares',[1]);
        case {'CC'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[5 5],'confounds',[],'firstmean','off','DatNormalise','off');  
        case {'CCm'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[5 5],'confounds',[],'firstmean','on','DatNormalise','off');  
        case {'CCvn'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[5 5],'confounds',[],'firstmean','off','DatNormalise','on');  
        case {'CCoBP'}
            %BpReg = BandPassOrt(size(vol,2),TR,pass_band(1),pass_band(2),1);
            x{l} = fmri_acompcor(vol,{WM,CSF},[5 5],'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'firstmean','off','DatNormalise','off'); 
        case {'CCoBPo24'}
            %BpReg = BandPassOrt(size(vol,2),TR,pass_band(1),pass_band(2),1);
            x{l} = fmri_acompcor(vol,{WM,CSF},[5 5],'confounds',rp24,'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'firstmean','off','DatNormalise','off');            
          
        case {'CC50'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[0.5 0.5],'confounds',[],'firstmean','off','DatNormalise','off');  
        case {'CC50m'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[0.5 0.5],'confounds',[],'firstmean','on','DatNormalise','off');  
        case {'CC50oBP'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[0.5 0.5],'confounds',[],'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'firstmean','off','DatNormalise','off'); 
        case {'CC50oBPo24'}
           x{l} = fmri_acompcor(vol,{WM,CSF},[0.5 0.5],'confounds',rp24,'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'firstmean','off','DatNormalise','off');
        case {'CC50o24'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[0.5 0.5],'confounds',rp24,'firstmean','off','DatNormalise','off');

        case {'CCoBPo24F'}
            %BpReg = BandPassOrt(size(vol,2),TR,pass_band(1),pass_band(2),1);
            x{l} = fmri_acompcor(vol,{CSF,WM},[5 5],    'confounds',rp24,'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'fullOrt','on','firstmean','off','DatNormalise','off');               
        case {'CC50oBPo24F'}
            x{l} = fmri_acompcor(vol,{CSF,WM},[0.5 0.5],'confounds',rp24,'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'fullOrt','on','firstmean','off','DatNormalise','off');

            
        case {'CCoBPo24oGSR2'}
            %BpReg = BandPassOrt(size(vol,2),TR,pass_band(1),pass_band(2),1);
            gsr2 = fmri_acompcor(vol,{WB},[0],'confounds',[],'derivatives',[1]);
            x{l} = fmri_acompcor(vol,{WM,CSF},[5 5],'confounds',[rp24,gsr2],'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'fullOrt','off','firstmean','off','DatNormalise','off');              
        case {'CCoBPo24oGSR2F'}
            %BpReg = BandPassOrt(size(vol,2),TR,pass_band(1),pass_band(2),1);
            gsr2 = fmri_acompcor(vol,{WB},[0],'confounds',[],'derivatives',[1]);
            x{l} = fmri_acompcor(vol,{CSF,WM},[5 5],'confounds',[rp24,gsr2],'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'fullOrt','on','firstmean','off','DatNormalise','off');             

        case {'CC50oBPo24oGSR2'}
            gsr2 = fmri_acompcor(vol,{WB},[0],'confounds',[],'derivatives',[1]);
            x{l} = fmri_acompcor(vol,{CSF,WM},[0.5 0.5],'confounds',[rp24,gsr2],'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'fullOrt','off','firstmean','off','DatNormalise','off');
                  
        case {'CC50oBPo24oGSR2F'}
            gsr2 = fmri_acompcor(vol,{WB},[0],'confounds',[],'derivatives',[1]);
            x{l} = fmri_acompcor(vol,{CSF,WM},[0.5 0.5],'confounds',[rp24,gsr2],'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'fullOrt','on','firstmean','off','DatNormalise','off');
            
        case {'CCoBPo6'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[5 5],'confounds',rp,'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'firstmean','off','DatNormalise','off');            
        case {'CCoBPo6F'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[5 5],'confounds',rp,'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'fullOrt','on','firstmean','off','DatNormalise','off');            
        case {'CC50oBPo6'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[0.5 0.5],'confounds',rp,'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'firstmean','off','DatNormalise','off');
        case {'CC50oBPo6F'}
            x{l} = fmri_acompcor(vol,{WM,CSF},[0.5 0.5],'confounds',rp,'filter',[TR,pass_band(1),pass_band(2)],'PolOrder',1,'fullOrt','on','firstmean','off','DatNormalise','off');
             
        otherwise
            error('not recognized regression set, check name definitions');
       
            
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

