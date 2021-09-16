
runs = {...
  'sieve','bw';...
  'sieve','sqi';...
  'sieveband','bw';...
  'sieveband','sqi';...
  'sievehigh','bw';...
  'sievehigh','sqi';...
};

Sieve=runs(:,1); Type=runs(:,2);
parfor i=1:length(runs)
  repeatabilityAFrankHouse(Sieve{i},Type{i});
end

repeatabilityAFrankHouse('sieve','bw');
repeatabilityAFrankHouse('sieve','sqi');
repeatabilityAFrankHouse('sieveband','bw');
repeatabilityAFrankHouse('sieveband','sqi');
repeatabilityAFrankHouse('sievehigh','bw');
repeatabilityAFrankHouse('sievehigh','sqi');

% plotResults('results/afrank-sieve-bw');
% plotResults('results/afrank-sieve-sqi');
% plotResults('results/afrank-sieveband-bw');
% plotResults('results/afrank-sieveband-sqi');
% plotResults('results/afrank-sievehigh-bw');
% plotResults('results/afrank-sievehigh-sqi');
