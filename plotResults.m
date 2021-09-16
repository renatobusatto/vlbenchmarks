function plotResults(matFile)
% Default:
% resultsPath = 'results/';
% prefix = 'afrank';
% namesFeat{1} = 'SIFT-Affine';
% namesFeat{2} = 'SIFT';
% namesFeat{3} = 'MSER-Affine';
% excludeFigs = [6 9];
% ylimit = [25 0 5 0];
%'resultsPath','prefix','namesFeat','excludeFigs','ylimit'

vl_setup;
v = load(matFile);

% The scores can now be prented, as well as visualized in a
% graph. This uses two simple functions defined below in this file.

v.repeatability(:,:,v.excludeFigs) = [];
repeatabMean = mean(v.repeatability,3);
v.numCorresp(:,:,v.excludeFigs) = [];
numCorrespMean = mean(v.numCorresp,3);
v.matchScore(:,:,v.excludeFigs) = [];
matchScoreMean = mean(v.matchScore,3);
v.numMatches(:,:,v.excludeFigs) = [];
numMatchesMean = mean(v.numMatches,3);

% Correct some variables
v.ylimit = [25 620 5 55];
band = false;
switch v.Sieve
    case 'sievehigh'
        repeatabMean(1,:) = 0;
        numCorrespMean(1,:) = 0;
        matchScoreMean(1,:) = 0;
        numMatchesMean(1,:) = 0;
    case 'sieveband'
        repeatabMean(1,:) = 0;
        numCorrespMean(1,:) = 0;
        matchScoreMean(1,:) = 0;
        numMatchesMean(1,:) = 0;
        band = true;
end

figure(2); clf; 
plotScores(v.namesFeat, 'Sieve mesh', v.namesDataset, 100 * repeatabMean', 'Mean repeatability %', v.ylimit(1), band);
helpers.printFigure(v.resultsPath,[v.prefix '_repeatability'],0.6);

figure(3); clf; 
plotScores(v.namesFeat, 'Sieve mesh', v.namesDataset, numCorrespMean', 'Mean number of correspondences', v.ylimit(2), band);
helpers.printFigure(v.resultsPath,[v.prefix '_numCorresp'],0.6);

figure(4); clf; 
plotScores(v.namesFeat, 'Sieve mesh', v.namesDataset, 100 * matchScoreMean','Mean matching score %', v.ylimit(3), band);
helpers.printFigure(v.resultsPath,[v.prefix '_matchingScore'],0.6);

figure(5); clf; 
plotScores(v.namesFeat, 'Sieve mesh', v.namesDataset, numMatchesMean','Mean number of matches', v.ylimit(4), band);
helpers.printFigure(v.resultsPath,[v.prefix '_numMatches'],0.6);

figure(6); clf;
plot(numCorrespMean,100 * repeatabMean,'+-','linewidth', 2); hold on ;
xlabel('Mean number of correspondences'); ylabel('Mean repeatability %');
legend(v.namesFeat,'Location','NorthEast'); grid on;
axis([0 700 0 25]);
helpers.printFigure(v.resultsPath,[v.prefix '_corresp-repeat'],0.6);

figure(7); clf;
plot(numMatchesMean,100 * matchScoreMean,'+-','linewidth', 2); hold on ;
xlabel('Mean number of matches'); ylabel('Mean matching score %');
legend(v.namesFeat,'Location','NorthEast'); grid on;
axis([0 55 0 5]);
helpers.printFigure(v.resultsPath,[v.prefix '_matches-score'],0.6);

figure(8); clf;
plot(numCorrespMean,numMatchesMean,'+-','linewidth', 2); hold on ;
xlabel('Mean number of correspondences'); ylabel('Mean number of matches');
legend(v.namesFeat,'Location','NorthWest'); grid on;
if band, axis([0 450 0 25]); 
else     axis([0 700 0 55]); end
helpers.printFigure(v.resultsPath,[v.prefix '_corresp-matches'],0.6);

figure(9); clf;
plot(100 * repeatabMean,100 * matchScoreMean,'+-','linewidth', 2); hold on ;
xlabel('Mean repeatability %'); ylabel('Mean matching score %');
legend(v.namesFeat,'Location','NorthWest'); grid on;
axis([0 25 0 5]);
helpers.printFigure(v.resultsPath,[v.prefix '_repeat-score'],0.6);


% Optionally, we can also see the matched frames itself. In this
% example we examine the matches between the reference and fourth
% image.
%
% We do this by running the repeatabiltiy score again. However, since
% the results are cached, this is fast.

image = 10;
feat  = 3;
sieve = 1;

[~, ~, v.siftCorresps, v.siftReprojFrames] = ...
  v.repBenchmark.testFeatureExtractor(v.featExtractors{feat}, ...
                            v.datasets{sieve}.getTransformation(image), ...
                            v.datasets{sieve}.getImagePath(1), ...
                            v.datasets{sieve}.getImagePath(image));

% And plot the feature frame correspondences

figure(1); clf;
imshow(v.datasets{sieve}.getImagePath(image));
benchmarks.helpers.plotFrameMatches(v.siftCorresps,...
                                    v.siftReprojFrames,...
                                    'IsReferenceImage',false,...
                                    'PlotMatchLine',false,...
                                    'PlotUnmatched',false);
helpers.printFigure(v.resultsPath,[v.prefix '_correspondences'],0.75);

% --------------------------------------------------------------------
% Helper functions
% --------------------------------------------------------------------

function plotScores(detectorNames, xLabel, xTicks, score, titleText, ylimit, band)
  %xstart = max([find(sum(score,1) == 0, 1) + 1 1]);
  xstart = 1;
  xend = size(score,2);
  if band
    xplot = xstart:xend-1;
    yplot = score(:,xstart+1:xend)';
    xticks = 0.5:1:size(score,2)-0.5;
  else
    xplot = xstart:xend;
    yplot = score(:,xstart:xend)';
    xticks = 1:size(score,2);
  end
  plot(xplot,yplot,'+-','linewidth', 2); hold on ;
  ylabel(titleText) ;
  xlabel(xLabel);
  %title(titleText);
  maxScore = max([max(score(:)) ylimit 1]);
  if max(max(score(:,end-1:end)))/maxScore < .8
    legendLocation = 'NorthEast';
  else
    legendLocation = 'NorthWest';
  end
  legend(detectorNames,'Location',legendLocation);
  grid on;
  set(gca,'XTick',xstart:1:xend);
  set(gca,'XTickLabel',xTicks);
  set(gca,'xtick',xticks);
  axis([xticks(1) xticks(end) 0 maxScore]);
end

end