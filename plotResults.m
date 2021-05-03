function plotResults(resultsPath,prefix,namesFeat,excludeFigs)

load([resultsPath prefix]);

% The scores can now be prented, as well as visualized in a
% graph. This uses two simple functions defined below in this file.

repeatability(:,:,excludeFigs) = [];
repeatabMean = mean(repeatability,3);
numCorresp(:,:,excludeFigs) = [];
numCorrespMean = mean(numCorresp,3);
matchScore(:,:,excludeFigs) = [];
matchScoreMean = mean(matchScore,3);
numMatches(:,:,excludeFigs) = [];
numMatchesMean = mean(numMatches,3);

figure(2); clf; 
plotScores(namesFeat, 'Sieve mesh', namesDataset, 100 * repeatabMean', 'Repeatability %');
helpers.printFigure(resultsPath,[prefix '_repeatability'],0.6);

figure(3); clf; 
plotScores(namesFeat, 'Sieve mesh', namesDataset, numCorrespMean', '# correspondences');
helpers.printFigure(resultsPath,[prefix '_numCorresp'],0.6);

figure(4); clf; 
plotScores(namesFeat, 'Sieve mesh', namesDataset, 100 * matchScoreMean','Matching score %');
helpers.printFigure(resultsPath,[prefix '_matchingScore'],0.6);

figure(5); clf; 
plotScores(namesFeat, 'Sieve mesh', namesDataset, numMatchesMean','# matches');
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

[~, ~, siftCorresps, siftReprojFrames] = ...
  repBenchmark.testFeatureExtractor(featExtractors{feat}, ...
                            datasets{sieve}.getTransformation(image), ...
                            datasets{sieve}.getImagePath(1), ...
                            datasets{sieve}.getImagePath(image));

% And plot the feature frame correspondences

figure(6); clf;
imshow(datasets{sieve}.getImagePath(image));
benchmarks.helpers.plotFrameMatches(siftCorresps,...
                                    siftReprojFrames,...
                                    'IsReferenceImage',false,...
                                    'PlotMatchLine',false,...
                                    'PlotUnmatched',false);
helpers.printFigure(resultsPath,[prefix '_correspondences'],0.75);

% --------------------------------------------------------------------
% Helper functions
% --------------------------------------------------------------------

function plotScores(detectorNames, xLabel, xTicks, score, titleText)
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
  axis([xstart xend 0 maxScore]);
end

end