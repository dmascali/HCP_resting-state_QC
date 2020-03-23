function [status] = HcpDownloadCommand(subj,hcp_file_path,local_folder,varargin)
% subj = HCP subjID
% hcp_file_path = path of the file to download
% local_folder = HCP folder on your local system (where to download the
% files)
%__________________________________________________________________________
%Daniele Mascali - danielemascali@gmail.com

%--------------VARARGIN----------------------
params  =  {'aws_path',                                   'HCP_release'};
defParms = { '/home/local/LAB_G1/danielem/.local/bin/aws',   'HCP_1200'};
legalValues{1} = [];
legalValues{2} = [];
[aws_path,HCP_release] = ParseVarargin(params,defParms,legalValues,varargin,1);
% --------------------------------------------

% convert subj to string if it is not 
if ~ischar(subj); subj=num2str(subj); end

% remove any "/" at the beginning of hcp_file_path
if hcp_file_path(1) == '/'; hcp_file_path(1) = []; end
% remove any "/" at the end of local_folder 
if local_folder(end) == '/'; local_folder(end) = []; end

[fp,na,ex] = fileparts(hcp_file_path);

% create destination folder
destination_folder = [local_folder,'/',subj,'/',fp];
%system(['mkdir -p ',destination_folder]);

command_str = [aws_path,' s3 cp ', ...  %cp
               's3://hcp-openaccess/',HCP_release,'/',subj,'/',hcp_file_path,' ',...  %source
               destination_folder,'/',na,ex]; %destination

%run the command
[status]= system(command_str);

return
end