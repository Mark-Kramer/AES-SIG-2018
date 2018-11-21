%--------------------------------------------------------------------------
%Compute the cross correlation functional network with confidence using an
%analytic procedure.  For details, see:
%
%  M. A. Kramer, U. T. Eden, S. S. Cash, E. D. Kolaczyk, 
%  Network inference with confidence from multivariate time series,
%  Phys Rev E, 79: 061916, 2009.
%
%Briefly, compute the maximum absolute value of the cross correlations over
%lags equal to +/- (0.25 * window_size) for all electrode pairs.
%
% INPUTS:
%  dgrid = The grid of electode data with dimensions time by electrodes
%        = e.g., "data[window of data, electrodes]"
%
% OUTPUTS:
%  C   = Inferred binary network. Each matrix entry is {0,1}. It's symmetric
%  mx  = Maximum of the absolute value of the correlation.  It's symmetric.
%  lag = Matrix of lags for each max value.
%  rho = Matrix of p-values for each max value.

% ADVANTAGES:
% x. It's fast (uses FFT and an analytic procedure to determine
%    significance).
%
% DISADVANTAGES:
% x. Analytic procedure may be wrong.
% x. We use an empirical estimate for the standard deviation of the cross
%    correlation. This is computed by first computing the standard deviation of the
%    cross correlation between all electrode pairs, and then computing the
%    mean of these standard deviations across electrode pairs. Therefore,
%    whether or not an observed max(abs(cc)) is significant depends on
%    average amount of variability in the cross correlation across all
%    electrodes.

function [C,mx,lag,rho] = infer_network_correlation(dgrid, varargin)

  %Define some useful variables.
  winSize = size(dgrid,1);          %The length of the data in time.
  N = size(dgrid,2);                %The number of electrodes.
  
  %Consider max correlations only within [-winSize/4, winSize/4].
  maxLags=floor(winSize/4);
  winSizeM = maxLags*2+1;           %Window of +/- maxLags and zero lag.
  
  %Set parameters 'an' and 'bn';  see paragraph following Eqn (4) in Kramer et al, PRE, 2009.
  %Values depend on the range of lags we consider.
  an = (2*log(winSizeM))^0.5;
  bn = (2*log(winSizeM))^0.5 - 0.5*((2*log(winSizeM))^(-0.5))*(log(log(winSizeM)) + log(4*pi));

  %Indicies for the upper half of the matrix - useful later.
  up = find(triu(ones(N,N),1));
  
  %Do the correlation analysis.    
  X = dgrid(:,:)';                                      %Call the data X.
  X = X - mean(X,2) * ones(1,winSize);                  %Remove the mean.
  X = X ./ (std(X,[],2) * ones(1,winSize));             %Set stdev to 1.
  for k=1:N                                             %Detrend activity at each electrode.
      X(k,:) = detrend(X(k,:));
  end
  
  %Zero pad.
  pad = zeros(N, maxLags);      %The padding has length of maxLags.
  X = [pad, X, pad];            %Add padding to beginning and end of data.
  winSize = size(X,2);          %The new length of the data in time.
  
  ac = ifft( fft(X,[],2) .* conj(fft(X,[],2)), [],2);   %Compute the auto-correlation
  ac = ac(:,1) * ac(:,1)';                              %... at zero lag
  ac = repmat(ac, [1,1,winSize]);                       %... make a 3-dim matrix
  ac = permute(ac, [1,3,2]);                            %... and match dims of cross-correlation.
  
                                                        %Compute the cross-correlation
  X3 = repmat(fft(X,[],2),[1,1,N]);                     %... make 3-dim [N,winSize,N]
  cc = ifft(permute(X3,[3,2,1]).*conj(X3), [], 2);      %... use FTs
  cc = cc ./ sqrt(ac);                                  %... scale by AC.

  sij = 0.5*log((1+cc)./(1-cc));                        %Fisher transform the cc.
  stdsij = squeeze(std(  sij(:,[(1:maxLags+1), ...      %Compute std over Fisher cc's.
                                (end-maxLags+1:end)],:), [], 2));
  scale0 = nanmean(stdsij(up));                         %Compute avg std of Fisher cc's
                                                        %...need nanmean in case cc={-1,1}.
 
  if nargin==3                                          %Check if using global (all time) scale.
      if strcmp(varargin{1}, 'scale')
          scale0 = varargin{2};
      end
  end                                         
                                                        
  cc0 = cc(:,[(end-maxLags+1:end), (1:maxLags+1)],:);   %Get the correlations in +/- maxLags range,
  [mx, imx] = max(abs(cc0), [], 2);                     %... find max absolute value for each pair,
  imx = squeeze(imx);                                   %... get the indices of maxes,
  mx  = triu(squeeze(mx),1);                            %... get the max values.
  lagAxis = (-maxLags:maxLags);                         %Define axis of +/- maxLags,
  lag     = lagAxis(imx);                               %... get the lags at the maxes.
  
  f0 = 0.5*log((1+mx)./(1-mx));                       %Fisher transform the maxes,
  z0 = f0 / scale0;                                     %... and scale by mean std of cross correlations,
  P0 = exp(-2*exp(-an*(z0-bn)));                        %... plug into formula for expected distribution of values,
  rho = 1-P0;                                           %... and compute a p-value.
  
  %Warning if data is identical.
  if ~isfinite(scale0)
      fprintf(['Identical data!  Correlation fails.  Returning NaN.  \n'])
      C = NaN(N);
      return
  end
  
  %Now analyze the p-values in the 'rho' matrix.  Keep only the smallest
  %(i.e., most significant) p-values.  The following bit of code thresholds
  %the p-values using the FDR method.
 
  rho(tril(ones(length(rho)))==1)=NaN;
  pvals = rho(isfinite(rho));
  pvals = sort(pvals);
  
  q  = 0.05;
  qs = (q*(1:length(pvals))/length(pvals))';
  i0 = find(pvals-qs <= 0); 
  if ~isempty(i0)
      threshold = pvals(max(i0));
  else
      threshold = -1.0;
  end
  
  %Significant p-values are smaller than threshold.
  sigPs = rho <= threshold;
  
  %Make a network with edges corresponding to significant p-values.
  C=zeros(N);
  C(sigPs)=1;
  C = C + C';
  mx = mx + mx';

end