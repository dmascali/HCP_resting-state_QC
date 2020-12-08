function check_extraction

subjs = load ("HCPlist.txt"); %it should be in the path if you ran SetPath

dest_folder = '/home/local/LAB_G1/danielem/Desktop/HCP_resting-state_QC/DATA';

total = length(subjs);

Y = nan(total,4);

for l = 1:total 

load([dest_folder,'/',num2str(subjs(l)),'_QC_RP.mat']);

rp = [isempty(REST1_LR),isempty(REST1_RL),isempty(REST2_LR),isempty(REST2_RL)];

% load([dest_folder,'/',num2str(subjs(l)),'_QC_IB_stats.mat']);
% 
% Y(l,2) = sum([isempty(REST1_LR),isempty(REST1_RL),isempty(REST2_LR),isempty(REST2_RL)]);

load([dest_folder,'/',num2str(subjs(l)),'_QC_IB_tcs.mat']);

ib = [isempty(REST1_LR),isempty(REST1_RL),isempty(REST2_LR),isempty(REST2_RL)];

Y(l,:) = rp - ib;
    
end

indx = find(sum(Y,2));


dlmwrite('failed_subjs.txt', subjs(indx),'precision','%6d')

return
end