function meanMovementPerWindow = segmentMovementDataForAnalysis(fileNameStub,windowLength,windowOverlap)
% Load behav data, divide into segments w/ overlap,calculate mean of each segment
fileFound = 0;
try
    load(['W:\Data\' fileNameStub],'finalLEDTimes','finalMovementArray','frameTimeStampsAdj');
    fileFound = 1;
catch
    try
        load(['M:\' fileNameStub],'finalLEDTimes','finalMovementArray','frameTimeStampsAdj');
        fileFound = 1;
    catch
        warning('No movement data found. Continuing without.');
        meanMovementPerWindow = nan(1220,1);
    end
end

if ~fileFound
    meanMovementPerWindow = zeros(10000,1);
    meanMovementPerWindow(:,:) = NaN;
else
    indexLength = frameTimeStampsAdj(end);
    
    for iWindow = 1:indexLength
        if ((iWindow-1)*windowLength)*(1-windowOverlap) + windowLength < indexLength
            windowTimeLims(iWindow,1) = ((iWindow-1)*windowLength)*(1-windowOverlap);
            windowTimeLims(iWindow,2) = ((iWindow-1)*windowLength)*(1-windowOverlap) + windowLength;
        end
    end
    for iWindow = 1:size(windowTimeLims,1)
        timeStampsInWindow = frameTimeStampsAdj(frameTimeStampsAdj <= windowTimeLims(iWindow,2));
        timeStampsInWindow = timeStampsInWindow(timeStampsInWindow >= windowTimeLims(iWindow,1));
        if ~isempty(timeStampsInWindow)
            for iFrame = 1:length(timeStampsInWindow)
                framesToUse(iFrame) = find(frameTimeStampsAdj == timeStampsInWindow(iFrame));
            end
            meanMovementPerWindow(iWindow,1) = mean(finalMovementArray(framesToUse));
        else
            meanMovementPerWindow(iWindow,1) = NaN;
        end
        clear timeStampsInWindow framesToUse
    end
    
end