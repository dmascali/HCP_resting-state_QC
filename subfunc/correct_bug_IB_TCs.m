function correct_bug_IB_TCs
% IB_TCs were not assigned properly. This function fix the bug. 

error('The error has already been corrected! Do not run this function!');

subjs = load ("HCPlist.txt"); %it should be in the path if you ran SetPath

dest_folder = '/home/local/LAB_G1/danielem/Desktop/HCP_resting-state_QC/DATA';

total = length(subjs);
reverseStr  ='';

for l = 1:total 
    
    output_path = [dest_folder,'/',num2str(subjs(l)),'_QC_IB_tcs.mat'];
    
    OLD = load(output_path);
    
    REST1_LR = OLD.REST1_LR; 
    REST1_RL = OLD.REST2_LR; 
    REST2_LR = OLD.REST1_RL; 
    REST2_RL = OLD.REST2_RL; 
    
    save(output_path,'REST1_LR','REST2_LR','REST1_RL','REST2_RL');

    percentDone = 100 * l / total;
    msg = sprintf('Percent done: %3.1f (%s)', percentDone);
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));   
end

fprintf('\n');

return
end