function repeatabilityAFrankHouseSqi(resultsPath)
% REPEATABILITYDEMO Demonstrates how to run the repatability benchmark
%   REPEATABILITYDEMO() Runs the repeatability demo.
%
%   REPEATABILITYDEMO(RESULTS_PATH) Run the demo and save the results to
%   path RESULTS_PATH.

% Created by: Renato Busatto
% Original authors: Karel Lenc and Andrea Vedaldi

% AUTORIGHTS

if nargin < 1, resultsPath = ''; end;

import datasets.*;
import benchmarks.*;
import localFeatures.*;

% --------------------------------------------------------------------
% PART 2: Detector repeatability
% --------------------------------------------------------------------

% A detector repeatability is measured against a benchmark. In this
% case we create instances of the Anne Frank House dataset.

datasets = {...
    AFrankHouseDataset('Category','orig-sqi'),...
    AFrankHouseDataset('Category','sieve-sqi','Mesh',10^1),...
    AFrankHouseDataset('Category','sieve-sqi','Mesh',10^2),...
    AFrankHouseDataset('Category','sieve-sqi','Mesh',10^3),...
    AFrankHouseDataset('Category','sieve-sqi','Mesh',10^4),...
    AFrankHouseDataset('Category','sieve-sqi','Mesh',10^5)
};

% Next, the benchmark is intialised by choosing various
% parameters. The defaults correspond to the seetting in the original
% publication (IJCV05).

repBenchmark = RepeatabilityBenchmark('Mode','Repeatability');
matBenchmark = RepeatabilityBenchmark('Mode','MatchingScore');

% Prepare three detectors, the two from PART 1 and a third one that
% detects MSER image features.

asift = VlFeatCovdet('EstimateAffineShape',true); asift.Name = "ASIFT";
sift = VlFeatSift();
mser = DescriptorAdapter(VlFeatMser(), asift);
featExtractors = {asift, sift, mser};

% Now we are ready to run the repeatability test. We do this by fixing
% a reference image A and looping through other images B in the
% set. To this end we use the following information:
%
% dataset.NumImages:
%    Number of images in the dataset.
%
% dataset.getImagePath(i):
%    Path to the i-th image.
%
% dataset.getTransformation(i):
%    Transformation from the first (reference) image to image i.
%
% Like for the detector output (see PART 1), VLBenchmarks caches the
% output of the test. This can be disabled by calling
% repBenchmark.disableCaching().

dsLen = numel(datasets);
ftLen = numel(featExtractors);
imLen = datasets{1}.NumImages;
namesDataset = cell(dsLen,1);
namesFeat = cell(ftLen,1);
repeatability = zeros(dsLen,ftLen,imLen);
numCorresp = zeros(dsLen,ftLen,imLen);
matchScore = zeros(dsLen,ftLen,imLen);
numMatches = zeros(dsLen,ftLen,imLen);

for ds = 1:numel(datasets)
    namesDataset{ds} = num2str(datasets{ds}.Mesh);
    for f = 1:numel(featExtractors)
        namesFeat{f} = featExtractors{f}.Name;
        for i = 2:datasets{ds}.NumImages
            if isnan(datasets{ds}.getTransformation(i)), continue; end
            try
                [repeatability(ds,f,i), numCorresp(ds,f,i)] = ...
                    repBenchmark.testFeatureExtractor(featExtractors{f}, ...
                                        datasets{ds}.getTransformation(i), ...
                                        datasets{ds}.getImagePath(1), ...
                                        datasets{ds}.getImagePath(i));
                [matchScore(ds,f,i), numMatches(ds,f,i)] = ...
                    matBenchmark.testFeatureExtractor(featExtractors{f}, ...
                                        datasets{ds}.getTransformation(i), ...
                                        datasets{ds}.getImagePath(1), ...
                                        datasets{ds}.getImagePath(i));
            catch
                fprintf('Inconsistent data in iteration ds=%i,f=%i,i=%i. Skipped.\n',ds,f,i);
            end
        end
    end
end

save('result-sqi.mat','repeatability','numCorresp','datasets','featExtractors','namesDataset','namesFeat','repBenchmark','matchScore','numMatches','-v7.3');

resultsPath = 'results/';
prefix = 'afrank-sqi';
namesFeat{1} = 'SIFT-Affine SQI';
namesFeat{2} = 'SIFT SQI';
namesFeat{3} = 'MSER-Affine SQI';
excludeFigs = [6 9];
plotResults(resultsPath,prefix,namesFeat,excludeFigs);

end