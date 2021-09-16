import datasets.*;
import benchmarks.*;
import localFeatures.*;
vl_setup();

% Parameters
% Supress figures: /Applications/MATLAB_R2021a.app/bin/matlab -noFigureWindows
plotSize = 1;
plotExt = 'jpg';
resultsPath = 'results/singlecases/';

catSieve = {'orig','sieve','sieveband','sievehigh'};
catType  = {'bw','sqi'};
catMesh  = {10^0, 10^1, 10^2, 10^3, 10^4, 10^5};

% Initialise benckmarks
repBenchmark = RepeatabilityBenchmark('Mode','Repeatability');
matBenchmark = RepeatabilityBenchmark('Mode','MatchingScore');

% Prepare detectors
asift = VlFeatCovdet('EstimateAffineShape',true); asift.Name = "asift";
sift = VlFeatSift(); sift.Name = "sift";
mser = DescriptorAdapter(VlFeatMser(), asift); mser.Name = "mser";
featExtractors = {asift, sift, mser};

% Initialise vars

% Get points

for f = 1:numel(featExtractors)
  for iSieve = 1:numel(catSieve)
    for iType = 1:numel(catType)
      for iMesh = 1:numel(catMesh)

        if iSieve == 1 && iMesh > 1, continue, end
        strCat = [catSieve{iSieve} '-' catType{iType}];
        
        if iSieve == 1
          strType = strCat;
          ds = AFrankHouseDataset('Category',strCat);
        else
          strType = [strCat '-' num2str(catMesh{iMesh})];
          ds = AFrankHouseDataset('Category',strCat,'Mesh',catMesh{iMesh});
        end

        for i = 2:ds.NumImages
          fname = sprintf('afrank%05.0f-%s-%s-%s',...
                                  i, 'corresp', featExtractors{f}.Name, strType);
          if isfile([resultsPath fname '.' plotExt]), continue, end
          if isnan(ds.getTransformation(i)), continue; end
          try
            % save on file
            savefig = false;
            fig = figure(1); clf;
            colormap('gray');
%             fig.RendererMode = 'manual';
            imshow(ds.getImagePath(i));
            savefig = true;
            
            [~, ~, corresps, reprojFrames] = ...
                repBenchmark.testFeatureExtractor(featExtractors{f}, ...
                                  ds.getTransformation(i), ...
                                  ds.getImagePath(1), ...
                                  ds.getImagePath(i));
            benchmarks.helpers.plotFrameMatches(corresps,reprojFrames,...
                                  'IsReferenceImage',false,...
                                  'PlotMatchLine',false,...
                                  'PlotUnmatched',false);
          catch
            fprintf('Inconsistent data in iteration ds=%s, feat=%s, img=%i. Skipped.\n',...
                                  strType, featExtractors{f}.Name, i);
          end
          if savefig
%             helpers.printFigure(resultsPath,fname,plotSize,plotExt);
%             matlab2tikz('showInfo', false, 'showWarnings', false,...
%                                   [resultsPath fname '.tex']);
            exportgraphics(gcf,[resultsPath fname '.' plotExt],...
                                  'ContentType','vector',...
                                  'Resolution',300,...
                                  'BackgroundColor','none');
          end
        end
          
      end 
    end
  end
end

