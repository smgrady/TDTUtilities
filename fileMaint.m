function fileMaint(animal)
% A utility  to run that replicates the import data pathway in
% synapseFrontEnd
% 1. move files
% 2. import data
% 3. move downsampled to W (renamed EEG channels) sorry, this is expected in an analysis.  I'll change once I get to that one...
% 4. Turn movie into a grid file
% 5. This is also set to run the video analysis program at end of day
% (needs all finished video files)
% notes
% absolutely do not run on anything except synapse data!!!!
% WARNING this is only operating upon EEGdata files for now!!!
% WARNING a few locations are hardcoded!!!


%animal = 'DREADD07';
%listOfAnimalExpts = getExperimentsByAnimal(animal,'Spon');
%animal = 'LFP18';
%animal = 'EEG55';

listOfAnimalExpts = getExperimentsByAnimal(animal);



% animal = 'LFPU01';
% listOfAnimalExpts = getExperimentsByAnimal(animal);
forceReimport = 0;
forceRegrid = 0;
forceReimportTrials = 0;


% before full automation, we can use this to set drug parameters in the DB
% so that below we can run
manuallySetGlobalParamUI(animal); 

% % possibly use in getBatchParams program?
% for iList = 1:length(listOfAnimalExpts)
%     b(iList,1) = str2num(listOfAnimalExpts{iList,1}(1:5));
% end
% c = unique(b)
descOfAnimalExpts = listOfAnimalExpts(:,2);
listOfAnimalExpts = listOfAnimalExpts(:,1);


% check to see if probe has been entered, and if not prompt user for that
% info
try
    [electrodeLocation] = getElectrodeLocationFromDateIndex(listOfAnimalExpts{1}(1:5),listOfAnimalExpts{1}(7:9));
catch
    display('Probe information not found.  Using template.');
    display('WARNING!!! if probe configuration has changed, stop now and correct in database!!!');
    if strcmp(animal(1:3),'EEG')
        setElectrodeLocationFromAnimal('EEG52',animal);
    elseif strcmp(animal(1:3),'LFP')
        setElectrodeLocationFromAnimal('LFP16',animal);
    elseif strcmp(animal(1:3),'DRE')
        setElectrodeLocationFromAnimal('DREADD07',animal);
    else
        error('Animal type not recognized.')
    end
end


if ~exist(['W:\Data\PassiveEphys\EEG animal data\' animal '\'],'dir')
    mkdir(['W:\Data\PassiveEphys\EEG animal data\' animal '\']);
    display(['making dir: W:\Data\PassiveEphys\EEG animal data\' animal '\']);
end

for iList = 1:length(listOfAnimalExpts)
%for iList = 26:length(listOfAnimalExpts)
    date = listOfAnimalExpts{iList}(1:5);
    index = listOfAnimalExpts{iList}(7:9);
    dirStrAnalysis = ['M:\PassiveEphys\' '20' date(1:2) '\' date '-' index '\'];
    dirStrRecSource = ['\\144.92.237.187\c\Data\20' date(1:2) '\' date '-' index '\'];
    dirStrRawData = ['W:\Data\PassiveEphys\' '20' date(1:2) '\' date '-' index '\'];
    display(['$$$ Processing ' date '-' index ' $$$']);
    % %% STEP 1 MOVE 
    moveDataRecToRaw(dirStrRecSource,dirStrRawData);
    % %% STEP 2 IMPORT 
    dirCheck = dir([dirStrAnalysis '*data*']); % check to see if ephys info is imported
    if isempty(dirCheck) || forceReimport
        display('Handing info to existing importData function.  This will take a few minutes.');
        try
            importDataSynapse(date,index);
        catch
            display([date '-' index 'not imported!!']);
        end
    elseif forceReimportTrials
        display('Data already imported, but updating trialinfo');
        updateStimInfoSynapse(date,index);
    end
    % %% STEP 3 (sadly) move to W (sadly because analyzed data are going to 'raw data' storage zone)
    if ~exist(['W:\Data\PassiveEphys\EEG animal data\' animal '\' date '-' index '\'],'dir')
        mkdir(['W:\Data\PassiveEphys\EEG animal data\' animal '\'  date '-' index '\']);
        display(['making dir: W:\Data\PassiveEphys\EEG animal data\' animal '\'  date '-' index '\']);
    end
    currentDir = dir(dirStrAnalysis);
    for iDir = 1:length(currentDir) %could add a check to see if files exist to save time (if they do)
        
        
        if strfind(currentDir(iDir).name,'EEGdata') >0
            fileString = [dirStrAnalysis currentDir(iDir).name];
            load(fileString);
            DSephysData = ephysData;
            DSdT = dT;
            save(['W:\Data\PassiveEphys\EEG animal data\' animal '\' date '-' index '\DS-' currentDir(iDir).name],'DSephysData','DSdT');
            clear ephysData
            clear DSephysData
        end
        if strfind(currentDir(iDir).name,'trial') >0
            display(['Copying ' currentDir(iDir).name]);
            copyfile([dirStrAnalysis currentDir(iDir).name],['W:\Data\PassiveEphys\EEG animal data\' animal '\' date '-' index '\' currentDir(iDir).name])
        end
    end
    % MOVIES: grid, prep % 
    addpath('Z:\DataBanks\mmread');
    vidFile = dir([dirStrRawData '*.avi']); % simplified version for Synapse
    if isempty(vidFile)
        error('video file not found!  This program expects video!')
    end
    vidFilePath = [dirStrRawData vidFile.name];
    repeatedAttempts = 1;
    maxAttempts = 4;
    if isempty(dir([dirStrAnalysis '*-framegrid.mat']))|| forceRegrid
        while repeatedAttempts < maxAttempts
            try
                display('attempting to run mmread on video...')
                videoFrameGridMakerSynapse(vidFilePath);
                repeatedAttempts = maxAttempts;
            catch
                display(['mmread is slightly unstable.  Let''s try ' num2str(maxAttempts-repeatedAttempts) ' more times.' ])
                repeatedAttempts = repeatedAttempts+1;
            end
        end
    end
    
    
    
    
    % insert some method to figure out which index is the control index
    
    
    
    
    
    % %% MUA CHECK %% might want to fix up 'artifact rejection' option - some need it, some don't
    if ~isempty(strfind(descOfAnimalExpts{iList}{:},'Stim'))
        display('Running MUA analysis')
        dirCheck = dir([dirStrAnalysis '*TrshldMUA_Stim*']);
        if isempty(dirCheck)
            analyzeMUAthresholdArtifactRejection('PassiveEphys',date,index,index,0,1,0,1,0,-.5,1.5,-.001,3,2,1,false);
%             analyzeMUAthresholdArtifactRejection(exptType,exptDate,exptIndex,threshIndex,rejectAcrossChannels,...
%     filterMUA,subtrCommRef,detection,interpolation,tPltStart,tPltStop,PSTHPlotMin,...
%     PSTHPlotMax,threshFac,batchBoolean,isArduino)
        else
            disp([date '-' index ' analyze MUA already done.']);
        end
    end
end



% this section is run after all indices for a whole day have been
for i =1:length(listOfAnimalExpts)
    a(i) = {listOfAnimalExpts{i}(1:5)};
end
b = unique(a)';
for i = 1:length(b)
    try
        videoMovementScoreByGridSynapse(animal,b{i}) 
    catch
        disp([b{i} ' didn''t process.'])
    end
end



% Add a check here to see if plotting is finished !for *each* day otherwise
% rerunning this each time will take a very long time - possibly add a
% 'force___' run toggle?
addpath('Z:\fieldtrip-20170405\','Z:\DataBanks\mouseDeliriumEphysAnalysis');
[gBatchParams, gMouseEphys_out] = mouseDelirium_specAnalysis_Synapse(animal);
% save mouseEphys_out, gBatchParams, and spectra
% !! TODO !! need to put this after the behave/video processing !!
saveBatchParamsAndEphysOut(gBatchParams,gMouseEphys_out)
% run Ziyad's plotting program
plotFieldTripSpectra_ZS({animal},1,gMouseEphys_out,gBatchParams); %spectra will save if second param = 1


% phase lag; 
[gBatchParams, gMouseEphys_conn] = mouseDelirium_WPLI_dbt_Synapse(animal,0);
saveBatchParamsAndEphysConn(gBatchParams,gMouseEphys_conn);
% update table so we can compare total power between WT and AD


% slope analysis; 







