function runBenchmark(detectors,dataset,varargin)
% Function to run a affine co-variant feature detector on
% dataset of images, and measure repeatibility

import affineDetectors.*;

% -------- create options ------------------------
opts.showQualitative = true;
opts = commonFns.vl_argparse(opts,varargin);

% -------- Load the dataset ----------------------------------------------------
assert(isa(dataset,'affineDetectors.genericDataset'),...
    'dataset not an instance of generic dataset\n');
numImages = dataset.numImages;
images = cell(1,numImages);
for i=1:numImages
  imagePath = dataset.getImagePath(i);
  images{i} = imread(imagePath);
  tfs{i} = dataset.getTransformation(i);
end

% -------- Compute each detectors output and store the evaluation --------------
numDetectors = numel(detectors);
repeatibilityScore = zeros(numDetectors,numImages); repeatibilityScore(:,1)=1;

if opts.showQualitative
  figure(1); clf;
  plotDataset(images);
end

% Clear all the figures
if opts.showQualitative
  for i = 2:numImages, figure(i); clf; end
end

fprintf('Running evaluation on %d detectors:\n',numDetectors);

for i = 1:numel(detectors)
  assert(isa(detectors{i},'affineDetectors.genericDetector'),...
         'Detector not an instance of genericDetector\n');
  fprintf('Detector #%02d: %s\n',i,detectors{i}.getName());
end

for iDetector = 1:numel(detectors)
  frames = cell(1,numImages);
  curDetector = detectors{iDetector};
  fprintf('\nComputing affine covariant regions for method #%02d: %s\n\n', ...
          iDetector, curDetector.getName());

  if(~curDetector.isOk)
    fprintf('Detector: %s is not working, message: %s\n',curDetector.getName(),...
            curDetector.errMsg);
    repeatibilityScore(iDetector,:) = 0;
    continue;
  end

  for i = 1:numImages
    fprintf('Computing regions for image: %02d/%02d ...\r',i,numImages);
    frames{i} = curDetector.detectPoints(images{i});
  end

  fprintf('\n');

  for i=2:numImages
    fprintf('Evaluating regions for image: %02d/%02d ...\n',i,numImages);
    [framesA,framesB,framesA_,framesB_] = ...
        cropFramesToOverlapRegion(frames{1},frames{i},tfs{i},images{1},images{i});


    frameMatches = matchEllipses(framesB_, framesA);
    [bestMatches,matchIdxs] = findOneToOneMatches(frameMatches,framesA,framesB_);
    repeatibilityScore(iDetector,i) = ...
        sum(bestMatches) / min(size(framesA,2), size(framesB,2));

    if opts.showQualitative
      plotFrames(framesA,framesB,framesA_,framesB_,iDetector,i,numDetectors,...
                images{1},images{i},curDetector.getName(),matchIdxs);
    end

  end

end

% ----------------- Plot the evaluation scores ---------------------------------
figure(numImages+1) ; clf ;
plot(repeatibilityScore' * 100,'linewidth', 3) ; hold on ;
ylabel('Repeatibility. %') ;
xlabel('Image #');
title('Detector repeatibility vs. image index');
ylim([0 100]);
set(gca,'xtick',[1:numImages]);

legendStr = cell(1,numel(detectors));
for i = 1:numel(detectors), legendStr{i} = detectors{i}.getName(); end
legend(legendStr);
grid on ;

fprintf('\n------ Evaluation completed ---------\n');

for i = 1:numel(detectors),
  if ~detectors{i}.isOk,
    fprintf('Detector %s failed because: %s\n',detectors{i}.getName(),...
            detectors{i}.errMsg);
  end
end

function plotDataset(images)

  numImages = numel(images);
  numCols = ceil(sqrt(numImages));
  numRows = ceil(numImages/numCols);

  for i = 1:numImages
    %colNo = 1+mod(i-1,numCols);
    %rowNo = 1+floor((i-1)/numCols);
    %subplot(numRows,numCols,(colNo-1)*numRows+rowNo);
    subplot(numRows,numCols,i);
    imshow(images{i}); title(sprintf('Image #%02d',i));
  end
  drawnow;

function plotFrames(framesA,framesB,framesA_,framesB_,iDetector,iImg,...
                    numDetectors,imageA,imageB,detectorName,matchIdxs)

    figure(iImg);
    subplot(numDetectors,2,2*(iDetector-1)+1) ; imshow(imageA);
    colormap gray ;
    hold on ; vl_plotframe(framesA);
    % Plot the transformed and matched frames from B on A in blue
    matchLogical = false(1,size(framesB_,2));
    matchLogical(matchIdxs) = true;
    vl_plotframe(framesB_(:,matchLogical),'b','linewidth',1);
    % Plot the remaining frames from B on A in red
    vl_plotframe(framesB_(:,~matchLogical),'r','linewidth',1);
    axis equal;
    set(gca,'xtick',[],'ytick',[]);
    ylabel(detectorName);
    title('Reference image detections');

    subplot(numDetectors,2,2*(iDetector-1)+2) ; imshow(imageB) ;
    hold on ; vl_plotframe(framesB) ;axis equal; axis off;
    %vl_plotframe(framesA_, 'b', 'linewidth', 1) ;
    title('Transformed image detections');

    drawnow;

function [framesA,framesB,framesA_,framesB_] = ...
    cropFramesToOverlapRegion(framesA,framesB,tfs,imageA,imageB)
% This function transforms ellipses in A to B (and vice versa), and crops
% them according to their visibility in the transformed frame

  import affineDetectors.*;

  framesA = helpers.frameToEllipse(framesA) ;
  framesB = helpers.frameToEllipse(framesB) ;

  framesA_ = helpers.warpEllipse(tfs,framesA) ;
  framesB_ = helpers.warpEllipse(inv(tfs),framesB) ;

  % find frames fully visible in both images
  bboxA = [1 1 size(imageA, 2) size(imageA, 1)] ;
  bboxB = [1 1 size(imageB, 2) size(imageB, 1)] ;

  selA = helpers.isEllipseInBBox(bboxA, framesA ) & ...
         helpers.isEllipseInBBox(bboxB, framesA_);

  selB = helpers.isEllipseInBBox(bboxA, framesB_) & ...
         helpers.isEllipseInBBox(bboxB, framesB );

  framesA  = framesA(:, selA);
  framesA_ = framesA_(:, selA);
  framesB  = framesB(:, selB);
  framesB_ = framesB_(:, selB);

function [bestMatches,matchIdxs] = findOneToOneMatches(ev,framesA,framesB)
  matches = zeros(3,0);
  overlapThresh = 0.6; % TODO: pass this as a parameter
  bestMatches = zeros(1, size(framesA, 2)) ;

  for j=1:length(framesA)
    numNeighs = length(ev.scores{j}) ;
    if numNeighs > 0
      matches = [matches, ...
                 [j *ones(1,numNeighs) ; ev.neighs{j} ; ev.scores{j} ] ] ;
    end
  end

  % eliminate assigment by priority
  [drop, perm] = sort(matches(3,:), 'descend') ;
  matches = matches(:, perm) ;

  idx = 1 ;
  while idx < size(matches,2)
    isDup = (matches(1, idx+1:end) == matches(1, idx)) | ...
            (matches(2, idx+1:end) == matches(2, idx)) ;
    matches(:, find(isDup) + idx) = [] ;
    idx = idx + 1 ;
  end

  validMatches = matches(3,:) > overlapThresh;
  bestMatches(matches(1, validMatches)) = 1 ;
  matchIdxs = matches(2,validMatches);