% An Introduction to Network Analysis & EEG Interpretation
% - Engineering/Neurostimulation SIG | Using Network Analysis to Augment EEG Interpretation
% - AES 2018
%
% Mark Kramer, Dec 2018.

clear                               % Clear the workspace.
close all                           % Close all figures
addpath('helper')                   % Add a folder with helpful functions.

% Step 1. Data collection -------------------------------------------------
%
%
load('AES_data.mat');               % Load the data
                                    %    d = the data [ time, electrodes ]
                                    %    t = the time axis, in units of seconds.
figure(); eeg_plot(t,d)             % It's always a good idea to look at the raw data.
title('EEG data'); xlabel('Time [s]')

% Step 2. Re-referencing --------------------------------------------------
% 
%
d_car=common_average_reference(d);  % Apply the common average reference,
figure(); eeg_plot(t,d_car)         % ... and plot it.
title('EEG with common average reference')

% Step 3. Filtering -------------------------------------------------------
%
%
Wn = [4,50];                        % Choose filter range from [4,50] Hz,
d_filtered = simple_filter(t,d,Wn); % ... apply the filter,
figure(); eeg_plot(t,d_filtered)    % ... and plot it.
title('EEG with filtering')

% Step 4. Network inference -----------------------------------------------
%
%                                   % Infer the functional connectivity,
[C] = infer_network_correlation(d_filtered);
figure(); imagesc(C)                % ... and visualize it.
xlabel('Node number'); ylabel('Node number')

% Step 5. Network analysis ------------------------------------------------
%
%  Download the Brain Connectivity Toolbox, https://sites.google.com/site/bctnet/
%
BC = betweenness_bin(C);            % Compute a property of the network.
figure(); plot(BC)                  % ... and display it.
xlabel('Node number'); ylabel('Betweenness centrality');