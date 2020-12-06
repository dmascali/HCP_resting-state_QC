function SetPath
% Set the path variable for the current project

% In case of messy path, let's clean it, otherwise comment the line
disp('SetPath - Warning: restoring default Matlab Path');
restoredefaultpath

% Add the utils directory (cifti utils and...)
disp('SetPath - Adding toolbox from current folder');
pcf = mfilename('fullpath');
base = fileparts(pcf);
p = [base,'/utils']; p = genpath_noGit(p); addpath(p);
p = [base,'/subfunc']; p = genpath_noGit(p); addpath(p);
p = [base,'/subjlists']; p = genpath_noGit(p); addpath(p);

% Add fMRI denoising toolbox (git clone https://github.com/dmascali/fmri_denoising.git )
% Add MatlabMailFeedback (git clone https://github.com/dmascali/MatlabMailFeedback.git )
disp('SetPath - Adding project specific toolbox');

if ispc
    computername = getenv('computername');
elseif isunix || ismac   %not tested on mac
    [~, computername] = system('hostname');
    computername = strtrim(computername);
end

switch computername
    case {'aristotele','parmenide','platone','democrito','cygnus'}
        FD  = '/home/local/LAB_G1/danielem/Documents/MATLAB/repos/fmri_denoising';
        MMF = '/home/local/LAB_G1/danielem/Documents/MATLAB/repos/MatlabMailFeedback';
    otherwise
        error('Not recognized machine.');
end

p = genpath_noGit(FD); addpath(p);
p = genpath_noGit(MMF); addpath(p);

% Connectome Workbench needs to be installed on the system

return
end

function p = genpath_noGit(d)
%GENPATH Generate recursive toolbox path.
%   P = GENPATH returns a new path string by adding all the subdirectories 
%   of MATLABROOT/toolbox, including empty subdirectories. 
%
%   P = GENPATH(D) returns a path string starting in D, plus, recursively, 
%   all the subdirectories of D, including empty subdirectories.
%   
%   NOTE 1: GENPATH will not exactly recreate the original MATLAB path.
%
%   NOTE 2: GENPATH only includes subdirectories allowed on the MATLAB
%   path.
%
%   See also PATH, ADDPATH, RMPATH, SAVEPATH.

%   Copyright 1984-2006 The MathWorks, Inc.
%------------------------------------------------------------------------------

if nargin==0,
  p = genpath(fullfile(matlabroot,'toolbox'));
  if length(p) > 1, p(end) = []; end % Remove trailing pathsep
  return
end

% initialise variables
classsep = '@';  % qualifier for overloaded class directories
packagesep = '+';  % qualifier for overloaded package directories
p = '';           % path to be returned

% Generate path based on given root directory
files = dir(d);
if isempty(files)
  return
end

% Add d to the path even if it is empty.
p = [p d pathsep];

% set logical vector for subdirectory entries in d
isdir = logical(cat(1,files.isdir));
%
% Recursively descend through directories which are neither
% private nor "class" directories.
%
dirs = files(isdir); % select only directory entries from the current listing

for i=1:length(dirs)
   dirname = dirs(i).name;
   if    ~strcmp( dirname,'.')          && ...
         ~strcmp( dirname,'..')         && ...
         ~strcmp( dirname,'.git')         && ... DM
         ~strncmp( dirname,classsep,1) && ...
         ~strncmp( dirname,packagesep,1) && ...
         ~strcmp( dirname,'private')
      p = [p genpath(fullfile(d,dirname))]; % recursive calling of this function.
   end
end

return
end

%------------------------------------------------------------------------------