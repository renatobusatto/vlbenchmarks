classdef retrievalBenchmark < benchmarks.genericBenchmark ...
    & helpers.GenericInstaller
  %RETREIVALBENCHMARK

  properties
    opts;
  end

  properties(Constant)
    defK = 50;
    defMaxComparisonsFactor = inf;
    resultsKeyPrefix = 'retreivalResults';
    kdtreeKeyPrefix = 'kdtree';
    datasetFeaturesKeyPrefix = 'datasetFeatures';
  end

  methods
    function obj = retrievalBenchmark(varargin)
      obj.benchmarkName = 'RetrBenchmark';
      obj.opts.k = obj.defK;
      obj.opts.maxComparisonsFactor = obj.defMaxComparisonsFactor;
      obj.opts.maxNumQueries = inf;
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      obj.configureLogger(obj.benchmarkName,varargin);
    end

    function [mAP queriesAp ] = evalDetector(obj, detector, dataset)
      import helpers.*;

      obj.info('Evaluating detector %s on dataset %s.',...
        detector.detectorName, dataset.datasetName);
      startTime = tic;

      % Try to load data from cache
      testSignature = obj.getSignature;
      detSignature = detector.getSignature;
      imagesSignature = dataset.getImagesSignature();
      queriesSignature = dataset.getQueriesSignature();
      resultsKey = strcat(obj.resultsKeyPrefix, testSignature, ...
        detSignature, imagesSignature, queriesSignature);
      results = DataCache.getData(resultsKey);
      if ~isempty(results)
        [mAP, queriesAp] = results{:};
        obj.debug('Results loaded from cache.');
        return;
      end

      % Retreive features of all images
      [frames descriptors] = obj.getAllDatasetFeatures(dataset, detector);
      
      % Compute the KDTree
      %kdtreeKey = strcat(obj.kdtreeKeyPrefix,detector.getSignature(),...
      %  dataset.getImagesSignature());
      %kdtree = DataCache.getData(kdtreeKey);
      %if isempty(kdtree)
      %  allFeaturesNum = size([descriptors{:}],2);
      %  obj.info('Building kdtree of %d features.',allFeaturesNum);
      %  kdStartTime = tic;
      %  kdtree = vl_kdtreebuild(single([descriptors{:}]));
      %  obj.debug('Kdtree built in %fs.',toc(kdStartTime));
      %  DataCache.storeData(kdtree,kdtreeKey);
      %else
      %  obj.debug(obj.benchmarkName,'Kdtree loaded from cache.');
      %end
      kdtree = [];

      % Compute average precisions
      numQueries = min([dataset.numQueries obj.opts.maxNumQueries]);
      queriesAp = zeros(numQueries,1);
      parfor q = 1:numQueries
        obj.info('Computing query %d/%d.',q,numQueries);
        query = dataset.getQuery(q);
        queriesAp(q) = obj.evalQuery(frames, descriptors, kdtree, query);
      end

      mAP = mean(queriesAp);
      obj.debug('mAP computed in %fs.',toc(startTime));
      obj.info('Computed mAP is: %f',mAP);

      results = {mAP, queriesAp};
      DataCache.storeData(results, resultsKey);
    end

    function [ap rankedList pr] = evalQuery(obj, frames, descriptors, kdtree, query)
      import helpers.*;
      import benchmarks.*;

      startTime = tic;
      k = obj.opts.k;
      kdtArgs = {'NumNeighbors', k};
      maxCompF = obj.opts.maxComparisonsFactor;
      if ~isinf(maxCompF) && maxCompF > 0
        kdtArgs = [kdtArgs {'MaxComparisons', maxCompF * k}];
      end

      qImgId = query.imageId;
      % Pick only features in the query box
      qFrames = localFeatures.helpers.frameToEllipse(frames{qImgId});
      visibleFrames = helpers.isEllipseInBBox(query.box, qFrames);
      qDescriptors = single(descriptors{qImgId}(:,visibleFrames));
      qNumDescriptors = size(qDescriptors,2);
      allDescriptors = single([descriptors{:}]);

      if qNumDescriptors == 0
        obj.info('No descriptors detected in the query box.');
        ap = 0; rankedList = []; pr = {[],[],[]};
        return;
      end

      numImages = numel(descriptors);
      numDescriptors = cellfun(@(c) size(c,2),descriptors);
      imageIdxs = arrayfun(@(v,n) repmat(v,1,n),1:numImages, ...
        numDescriptors','UniformOutput',false);
      imageIdxs = [imageIdxs{:}];
      
      obj.info('Computing %d-nearest neighbours of %d descriptors.',...
        k,qNumDescriptors);
      %[indexes, dists] = vl_kdtreequery(kdtree, allDescriptors,...
      %  qDescriptors, kdtArgs{:}) ;
      [indexes, dists] = obj.yaelKnn(allDescriptors, qDescriptors, k);

      nnImgIds = imageIdxs(indexes);

      votes= vl_binsum( single(zeros(numImages,1)),...
        repmat( dists(end,:), min(k,qNumDescriptors), 1 ) - dists,...
        nnImgIds );
      votes = votes./sqrt(numDescriptors);
      [temp, rankedList]= sort( votes, 'descend' ); 

      [precision recall inf]  = retrievalBenchmark.calcPR(query, votes);
      ap = inf.ap;
      pr = {precision recall inf};

      obj.debug('AP calculated in %fs.',toc(startTime));
      obj.info('Computed average precision is: %f',ap);
    end

    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.opts);
    end

    function [frames descriptors] = getAllDatasetFeatures(obj,dataset, detector)
      import helpers.*;
      numImages = dataset.numImages;

      % Retreive features of all images
      detSignature = detector.getSignature;
      imagesSignature = dataset.getImagesSignature();
      featKeyPrefix = obj.datasetFeaturesKeyPrefix;
      featuresKey = strcat(featKeyPrefix, detSignature,imagesSignature);
      features = DataCache.getData(featuresKey);
      if isempty(features)
        % Compute the features
        frames = cell(numImages,1);
        descriptors = cell(numImages,1);
        featStartTime = tic;
        parfor imgIdx = 1:numImages
          imagePath = dataset.getImagePath(imgIdx);
          [frames{imgIdx} descriptors{imgIdx}] = detector.extractFeatures(imagePath);
        end
        obj.debug('Features computed in %fs.',toc(featStartTime));
        DataCache.storeData({frames, descriptors},featuresKey);
      else 
        [frames descriptors] = features{:};
        obj.debug('Features loaded from cache.');
      end
    end
  end

  methods(Static)
    function [precision recall info] = calcPR(query, scores)
      y = - ones(1, numel(scores)) ;
      y(query.good) = 1 ;
      y(query.ok) = 1 ;
      y(query.junk) = 0 ;
      y(query.imageId) = 0 ;
      [precision recall info] = vl_pr(y, scores);
    end

    function [indexes dists] = yaelKnn(features, qFeatures, k)
      yaelPath = fullfile('data','software','yael_v277','matlab','');
      addpath(yaelPath);
      [indexes, dists] = yael_nn(single(features), single(qFeatures), ...
        min(k, size(qFeatures,2)));
      rmpath(yaelPath);
    end
    
    function deps = getDependencies()
      deps = {helpers.Installer(),benchmarks.helpers.Installer()};
    end
  end  
end
