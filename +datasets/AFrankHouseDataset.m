classdef AFrankHouseDataset < datasets.GenericTransfDataset & helpers.Logger...
    & helpers.GenericInstaller
% datasets.AFrankHouseDataset Wrapper around the Anne Frank House dataset
%   datasets.AFrankHouseDataset('Option','OptionValue',...) Constructs
%   an object which implements access to Anne Frank House dataset used for
%   affine invariant detectors evaluation.
%
%   Following options are supported:
%
%   Category :: ['sieve-bw']
%     The category within the dataset has to be one of
%     'orig-bw', 'orig-rgb', 'orig-sqi', 'sieve-bw', 'sieve-rgb', 'sieve-sqi'
%
%   Mesh :: [1]
%     The sieve mesh, one of
%     1, 10, 100, 1000, 10000, 100000
%
% Created by: Renato Busatto
% Original authors: Varun Gulshan, Karel Lenc

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    Category = 'sieve-bw'; % Dataset category
    Mesh     = 1;       % Sieve mesh
    Sieve;              % Sieve data set?
    DataDir;            % Image location
    ListImages;         % Table with info about each image
    ImgExt;             % Image extension
    CategoryLong;       % Dataset category with mesh size
    Info;
  end

  properties (Constant)
    % All dataset categories
    AllCategories = {...
      'orig-bw', 'orig-rgb', 'orig-sqi', ...
      'sieve-bw', 'sieve-rgb', 'sieve-sqi', ...
      'sievehigh-bw', 'sievehigh-rgb', 'sievehigh-sqi', ...
      'sieveband-bw', 'sieveband-rgb', 'sieveband-sqi', ...
    };
    AllMeshes = [1, 10, 100, 1000, 10000, 100000];
  end

  properties (Constant, Hidden)
    % Installation directory
    RootInstallDir = fullfile('data','datasets','AFrankHouseDataset');
    % Names of the image transformations in particular categories
    ImageNamesLabel = 'Image';
    % Image labels for particular categories (degree of transf.)
    ImageNames = 0:22;
    % Root url for dataset tarballs
    RootUrl = 'http://renatobusatto.me/dataset/afrankhouse.tar.gz';
  end

  methods
    function obj = AFrankHouseDataset(varargin)
      import datasets.*;
      import helpers.*;
      opts.Category = obj.Category;
      opts.Mesh = obj.Mesh;
      [opts, varargin] = vl_argparse(opts,varargin);
      
      [valid, loc] = ismember(opts.Mesh,obj.AllMeshes);
      assert(valid,...
        sprintf('Invalid mesh size for dataset: %s\n',opts.Mesh));
      [valid, loc] = ismember(opts.Category,obj.AllCategories);
      assert(valid,...
        sprintf('Invalid category for dataset: %s\n',opts.Category));
      
      obj.DatasetName = ['AFrankHouseDataset-' opts.Category];
      obj.Category = opts.Category;
      obj.Mesh = opts.Mesh;
      obj.Sieve = startsWith(obj.Category,'sieve');
      obj.CategoryLong = obj.Category;
      if obj.Sieve
          obj.CategoryLong = [obj.Category '-' num2str(obj.Mesh)];
      end
      obj.DataDir = fullfile(obj.RootInstallDir,obj.CategoryLong);
      obj.Info = load(fullfile(obj.RootInstallDir,'info.mat'));
      obj.Info.imgs = obj.Info.imgs(strcmp(obj.Info.imgs.category,obj.CategoryLong),:);
      obj.Info.imgs.Properties.RowNames = obj.Info.imgs.filename;
      obj.NumImages = obj.Info.category{obj.CategoryLong,'size'};
      obj.ListImages = obj.Info.imgs(strcmp(obj.Info.imgs.category,obj.Category),:);
      obj.ImgExt = obj.Info.category{obj.CategoryLong,'ext'};
      obj.checkInstall(varargin);
    end

    function imgPath = getImagePath(obj,imgNo)
      assert(imgNo >= 1 && imgNo <= obj.NumImages,'Out of bounds idx\n');
      imgPath = fullfile(obj.DataDir,strjoin(obj.Info.imgs{imgNo,{'filename','ext'}},''));
    end
    
    function tfs = getTransformation(obj,imgNo)
      assert(imgNo >= 1 && imgNo <= obj.NumImages,'Out of bounds idx\n');
      tfs = obj.Info.imgs.transform{imgNo};
      if isnan(tfs), return; end
      tfs = inv(tfs');
    end
  end

  methods (Access = protected)
    function [urls dstPaths] = getTarballsList(obj)
      import datasets.*;
      installDir = AFrankHouseDataset.RootInstallDir;
      dstPaths = {fullfile(installDir)};
      urls = {AFrankHouseDataset.RootUrl};
    end
  end
end
