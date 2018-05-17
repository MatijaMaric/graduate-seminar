function mouseStrokeSegmentation(datadir,echodir,params,lbldir,resdir)

% Automated ischemic lesion segmentation in MRI mouse brain data
%
% Usage: % mouseStrokeSegmentation(datadir,echodir,params,lbldir,resdir)
%
% ********************************* Inputs ********************************
%
% datadir: string pointing to the folder in which T2-maps (in .mhd format)
%          are located
% echodir: string pointing to the folder in which all the echoes (in .mhd 
%          format) are located. This parameter is optional: in case not 
%          specified, the corresponding T2-map will be used. However, for 
%          optimal segmentation performance we recommend using the echoe 
%          images as well.
% params : vector of segmentation parameters. This parameter is optional:
%          in case not specified, the default values will be used; see [1]
% lbldir : string pointing to the folder where results of label propagation
%          (calculated during previous run of the software) are stored.
%          This parameter is optional: in case not specified, the labels
%          will be calculated using the labelled atlas
% resdir : string pointing to the folder in which the results will be
%          saved. This parameter is optional: in case not specified, the 
%          default location will be used
% 
% Examples: mouseStrokeSegmentation('C:\MyData\T2maps');
%           mouseStrokeSegmentation('C:\MyData\T2maps', 'C:\MyData\Echoes');
%           mouseStrokeSegmentation('C:\MyData\T2maps', 'C:\MyData\Echoes', ...
%              [5; 2; 2; 0.1; 0; 3; 2; 1.5; 3; 0.3; 0; 2]);
%           mouseStrokeSegmentation('C:\MyData\T2maps', 'C:\MyData\Echoes', ...
%              [5; 2; 2; 0.1; 0; 3], 'C:\MyData\Labels');
%           mouseStrokeSegmentation('C:\MyData\T2maps', 'C:\MyData\Echoes', ...
%              [], 'C:\MyData\Labels');
%
% ********************************* Outputs *******************************
%
% The software produces two types of image results: 1) Tiled images with
% superimposed segmentation results, and 2) Metavolumes of segmented
% structures (whole brain, ventricles, and stroke region) in 'Volumes'     
% folder. Calculated volumes of the stroke regions are stored in the 
% '_measurements.txt' file. Results of label propagation are stored in the
% 'Labels' folder and can be used as an input for the subsequent runs (e.g. 
% with a different set of parameters)
%
% ******************************* References ******************************
%
% [1] I.A. Mulder, A. Khmelinskii, O. Dzyubachyk, S. de Jong, N. Rieff, 
% M.J.H. Wermer, M. Hoehn, B.P.F. Lelieveldt, A.M.J.M. van den Maagdenberg,
% Automated ischemic lesion segmentation in MRI mouse brain after transient 
% middle cerebral artery occlusion, Frontiers in NeuroInformatics, 2017; 
% 11(3). http://doi.org/10.3389/fninf.2017.00003
%
% [2] I.A. Mulder, A. Khmelinskii, O. Dzyubachyk, S. de Jong, 
% M.J.H. Wermer, M. Hoehn, B.P.F. Lelieveldt, A.M.J.M. van den Maagdenberg,
% MRI mouse brain data of ischemic lesion after transient middle cerebral 
% artery occlusion, Frontiers in NeuroInformatics, 2017
%
% *************************************************************************
%
% 27-07-2017
% version 1.0

tic;

if (nargin < 2) || isempty(echodir),
    bechodir = false;
    echodir = datadir;
else
    bechodir = true;
end;

if (nargin < 3) || isempty(params),
    params = [5; 2; 2; 0.1; 0; 3; 2; 1.5; 3; 0.3; 0; 2];
else
    params = params(:);
    params(3:3:numel(params)) = ceil(params(3:3:numel(params)) / 40);
end;

if (nargin < 4) || isempty(lbldir),
    lbldir = '';
    blabel = false;
else
    blabel = true;
end;

if (nargin < 5) || isempty(resdir),
    resdir = fullfile(fileparts(datadir),'Results');
    resdir = fullfile(resdir,['Results ',datestr(now, 'yy_mm_dd HH_MM_SS')]);
end;

if ~exist(resdir,'dir'),
    mkdir(resdir);
end;

fstats = fullfile(resdir,'_measurements.txt');

if ~isempty(params),
    fid = fopen(fstats, 'at');
    fprintf(fid,['Parameters: [', regexprep(num2str(params'),' +',', '),']\n\n']);
    fclose(fid);
end;

s = 'Data set';
s = [s,':	Volume(mm3)'];
s = [s,' \n'];

fid = fopen(fstats, 'at');
fprintf(fid,s);
fclose(fid);

fls = dir(datadir);
fls = fls(~[fls.isdir]);
fls = fls(cellfun(@(x)((numel(x)>=4) & strcmp(x(end-3:end),'.mhd')),{fls.name},'UniformOutput',true));

prfx = getPrefix(fls);

wdir = fileparts(mfilename('fullpath'));
atlasdir = fullfile(wdir,'Template');
prmsdir = fullfile(wdir,'Parameters');

prmsfile = [{fullfile(prmsdir,'Parameters_Rigid.txt')};...
            {fullfile(prmsdir,'Parameters_Affine.txt')};...
            {fullfile(prmsdir,'Parameters_BSpline.txt')}];

prmsfileinv = fullfile(prmsdir,'Parameters_Invert.txt');

elastixdir = 'D:\DATA\Work\elastix_win7_64bit';

if bechodir,
    tmplimg = fullfile(atlasdir,'Template_24h_SUM20echoes.mhd');
else
    tmplimg = fullfile(atlasdir,'Template_24h_T2map.mhd');
end;
tmplmask = fullfile(atlasdir,'Template_24h_WholeBrainMask.mhd');

if isempty(lbldir),
    [~,tmpn] = fileparts(tempname);
    ds = ['matlab_tmp_',tmpn];
    tmpd = tempdir_patched;
    tmpd = fullfile(tmpd,ds);
    mkdir(tmpd);
    lbldir = tmpd;
    clear tmpn ds tmpd;
end;

if bechodir,
    [echofls,echoidx] = sortEchoes(echodir,prfx);
end;

for ii = 1:numel(fls),
    try
        lbldiri = fullfile(lbldir,prfx{ii});
        if ~blabel,
            mkdir(lbldiri);
        end;
        
        if bechodir,
            [regfile,echoe4] = calculateSumEchoes(echodir,echofls(echoidx == ii),lbldiri);
        else
            regfile = fullfile(datadir,fls(ii).name);
            echoe4 = metaImageRead(regfile);
        end;

        if ~blabel,
            registerTemplate(atlasdir,prmsfile,prmsfileinv,lbldiri,regfile,tmplimg,tmplmask,elastixdir);
        
            mkdir(fullfile(resdir,'Labels',prfx{ii}));
            for jj = 1:4,
                copyfile(fullfile(lbldiri,['Label_',num2str(jj)]),fullfile(resdir,'Labels',prfx{ii},['Label_',num2str(jj)])); 
            end;
        end;
        
        mouseStrokeQuantification(datadir,lbldiri,fls(ii).name,resdir,fstats,params,echoe4,prfx{ii});
    catch
        lerr = lasterror;
        disp([lerr.message(1:end-1),': ']);
        for jj = 1:numel(lerr.stack),
            disp([lerr.stack(jj).file,': ',lerr.stack(jj).name,'(',num2str(lerr.stack(jj).line),')']);
        end;
        clear lerr;
    end;
    toc;
end;
cd(wdir);

if ~blabel,
    rmdir(lbldir,'s');
end;
disp('Finished!');