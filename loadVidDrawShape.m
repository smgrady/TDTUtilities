function [mov,thesePix,h,w,FR,nFrames] = loadVidDrawShape(fileName,redraw,thesePix)
% DESCRIPTION:
% given a file location, load the file using VideoReader, save each frame
% into a structure after converting to grayscale, then draw a polygon
% around the mouse cage to isolate only those pixels for subsequent
% analysis. mov is the height x width x nFrames video array (grayscale) and
% thesePix are the pixels that fall within in selected shape. 

% EXAMPLE: 
% fileName = 'W:\Data\PassiveEphys\2019\19315-005\2019_19315-005_Cam1.avi';
% redraw = true; %will have user redraw the ROI to analyze
% thesePix = []; 

% TO-DO: 1) add error handling 2) optimize

disp('creating VideoReader object');
v = VideoReader(fileName); %create video reader object
w = v.Width; %query parameters about the video
h = v.Height;
FR = v.FrameRate;
nFrames = v.Duration*FR; %calculate total number of frames in the video 

mov = zeros(h,w,nFrames); %preallocate mov, where we store the movie array


disp(['Loading video. This will take about ' num2str(v.Duration/60*1.5) 'seconds']); %took ~70 seconds for an hour of video on Gilgamesh
iFrames = 1;
tic
while hasFrame(v) %load frame in using readframe while VideoReader object still has frames
    mov(:,:,iFrames) = rgb2gray(readFrame(v)); %convert frame into grayscale
    iFrames=iFrames+1;
end
toc
disp('Video loading complete.');

disp('selecting random frame to display');
randFrame = randi(nFrames); %select random frame
frame2Disp = uint8(mov(:,:,randFrame)); %convert frame back to uint8 to allow plotting
figure('name',['frame = ' num2str(randFrame)]);

if redraw
    disp('please draw shape around bottom of cage at animal height');
    [BW] = roipoly(frame2Disp); %draw polygon around mouse area                          
    hold on
    imshow(BW,[]); %show selection
    [R,C] = size(BW);
    thesePix = zeros(h,w);
    for i = 1:R
       for j =  1:C
           if BW(i,j) == 1
               thesePix(i,j) = frame2Disp(i,j);
           else
               thesePix(i,j) = nan;
               mov(i,j,:) = nan; %exclude pix in all frames %TODO fix this!
           end
       end
    end
else
    disp('using previous ROI');
    %WIP 3/29/2019
    [R,C] = size(thesePix);
    for i = 1:R
       for j =  1:C
           if isnan(thesePix(i,j))
               mov(i,j,:) = nan;
           end
       end
    end
    %WIP: check to make sure the pixels you've excluded still line up
    figure
    imshow(uint8(mov(:,:,randFrame)));
end

disp('setting first and last second of data to nan');
mov(:,:,1:FR) = nan; %set first second of data to nan to help remove artifacts
mov(:,:,nFrames-FR:nFrames) = nan; %set last second of data to nan to help remove artifacts
end

%DUMPSTER: 
% S = struct;
% S.fileName = fileName;
% for iFrame = 1:1800
%     S.mov(iFrame).cdata = rgb2gray(readFrame(S.v));
% end
% vidHeight = S.v.Height;
% vidWidth = S.v.Width;
% 
% switch nargin
%     case 0
%         error('zero inputs given - this program expects at least a video file location!');
%     case 1
%         if ~exist(fileName,'var')
%             error('no fileName detected - this program expects at least a video file location!');
%         end
%         disp('a new ROI will need to be drawn');
%         redraw = true;
%         thesePix = [];
%     case 2 %this is the weirdest case
%         if ~exist(fileName,'var')
%             error('no fileName detected - this program expects at least a video file location!');
%         end
%         redraw = varargin{1};
%         if redraw
%             thesePix = [];
%         end
%     case 3
%         if ~exist(fileName,'var')
%             error('no fileName detected - this program expects at least a video file location!');
%         end
%         redraw = varargin{1};
%         thesePix = varargin{2}; 
% end
%DONE: 
%add way to save previous ROI and display over video. Perhaps hand
% as one of the variable inputs? Use a boolean called something like
% 'redraw'?