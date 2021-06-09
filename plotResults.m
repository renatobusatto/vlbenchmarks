function plotResults(resultsPath,prefix,namesFeat,excludeFigs,ylimit)
% Default:
% resultsPath = 'results/';
% prefix = 'afrank';
% namesFeat{1} = 'SIFT-Affine';
% namesFeat{2} = 'SIFT';
% namesFeat{3} = 'MSER-Affine';
% excludeFigs = [6 9];
% ylimit = [25 0 5 0];

v = load([resultsPath prefix]);

% The scores can now be prented, as well as visualized in a
% graph. This uses two simple functions defined below in this file.

v.repeatability(:,:,excludeFigs) = [];
repeatabMean = mean(v.repeatability,3);
v.numCorresp(:,:,excludeFigs) = [];
numCorrespMean = mean(v.numCorresp,3);
v.matchScore(:,:,excludeFigs) = [];
matchScoreMean = mean(v.matchScore,3);
v.numMatches(:,:,excludeFigs) = [];
numMatchesMean = mean(v.numMatches,3);

figure(2); clf; 
plotScores(namesFeat, 'Sieve mesh', v.namesDataset, 100 * repeatabMean', 'Average repeatability %', ylimit(1));
helpers.printFigure(resultsPath,[prefix '_repeatability'],0.6);

figure(3); clf; 
plotScores(namesFeat, 'Sieve mesh', v.namesDataset, numCorrespMean', 'Average number of correspondences', ylimit(2));
helpers.printFigure(resultsPath,[prefix '_numCorresp'],0.6);

figure(4); clf; 
plotScores(namesFeat, 'Sieve mesh', v.namesDataset, 100 * matchScoreMean','Average matching score %', ylimit(3));
helpers.printFigure(resultsPath,[prefix '_matchingScore'],0.6);

figure(5); clf; 
plotScores(namesFeat, 'Sieve mesh', v.namesDataset, numMatchesMean','Average number of matches', ylimit(4));
helpers.printFigure(resultsPath,[prefix '_numMatches'],0.6);


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

figure(6); clf;
imshow(v.datasets{sieve}.getImagePath(image));
benchmarks.helpers.plotFrameMatches(v.siftCorresps,...
                                    v.siftReprojFrames,...
                                    'IsReferenceImage',false,...
                                    'PlotMatchLine',false,...
                                    'PlotUnmatched',false);
helpers.printFigure(resultsPath,[prefix '_correspondences'],0.75);

% --------------------------------------------------------------------
% Helper functions
% --------------------------------------------------------------------

function plotScores(detectorNames, xLabel, xTicks, score, titleText, ylimit)
  xstart = max([find(sum(score,1) == 0, 1) + 1 1]);
  xend = size(score,2);
  plot(xstart:xend,score(:,xstart:xend)','+-','linewidth', 2); hold on ;
  ylabel(titleText) ;
  xlabel(xLabel);
  set(gca,'XTick',xstart:1:xend);
  set(gca,'XTickLabel',xTicks);
  %title(titleText);
  set(gca,'xtick',1:size(score,2));
  maxScore = max([max(max(score)) 1]);
  meanEndValue = mean(score(:,xend));
  legendLocation = 'SouthEast';
  if meanEndValue < maxScore/2
    legendLocation = 'NorthEast';
  end
  legend(detectorNames,'Location',legendLocation);
  grid on ;
  if ylimit == 0
      ylimit = maxScore;
  end
  axis([xstart xend 0 ylimit]);
end

end