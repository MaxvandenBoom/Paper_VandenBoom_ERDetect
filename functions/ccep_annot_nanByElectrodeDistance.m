%
%   Set NaN values for recording electrode-channels that are within a specific (mm) distance of stimulated-pair electrodes
%
%   outStruct = ccep_annot_nanByElectrodeDistance(inStruct, electrodesFile, electrode_excludeDist, verbose)
%
%       inStruct                = the annotation struct to filter the stim-pair and recording channels from
%       channelFile             = path to the channels.tsv file to determine the channel types
%       electrode_excludeDist   = the distance (in mm) from a stimuluted pair of electrodes at which recording electrode-channels should be nanned
%       verbose                 = Display messages (default = 1)
%
%   Returns: 
%       outStruct               = A annotation struct with the annotations in it nanned if electrode-channels were found to be to close to a stim-pair
%
%

%   Max van den Boom (Multimodal Neuroimaging Lab, Mayo Clinic, Rochester MN), 2022
%
function outStruct = ccep_annot_nanByElectrodeDistance(inStruct, electrodesFile, electrode_excludeDist, verbose)
    if ~exist('verbose', 'var'), verbose = 1;   end
    
    % assign the output
    outStruct = inStruct;
    
    % skip if the distance is 0
    if electrode_excludeDist <= 0,     return;  end
    
    % load electrodes    
    electrodes = readtable(electrodesFile, 'FileType', 'text', 'Delimiter', '\t', ...
                            'TreatAsEmpty', {'N/A', 'n/a'}, 'ReadVariableNames', true);
    
    % remove any electrodes that have nans as coordinates
    elecNans = find(any(isnan([electrodes.x, electrodes.y, electrodes.z]), 2));
    if ~isempty(elecNans)
       warning(['Electrodes were found with nan in the coordinates, excluding: ', strjoin(electrodes.name(elecNans), ', ')]);
       electrodes(elecNans, :) = [];
    end
    clear elecNans;
    
    % variable to hold the list of nanned stim-pairs and recording channels combinations
    exclCombos = [];
    
    % loop through the stim-pairs
    for iStimpair = 1:length(outStruct.stimpairs)
        stimpair = outStruct.stimpairs{iStimpair};
        stimpair_split = split(stimpair, '-');

        % determine the electrode indices of the stimulated electrodes
        electrode_ind1 = find(strcmpi(stimpair_split{1}, [electrodes.name]));
        electrode_ind2 = find(strcmpi(stimpair_split{2}, [electrodes.name]));
        if isempty(electrode_ind1)
            error(['Error: Could not find (coordinates for) channel ', stimpair_split{1} , ' in electrodes.tsv, could not exclude nearby electrodes']);
            continue;
        end
        if isempty(electrode_ind2)
            error(['Error: Could not find (coordinates for) channel ', stimpair_split{2} , ' in electrodes.tsv, could not exclude nearby electrodes']);
            continue;
        end
        electrode_indices = [electrode_ind1, electrode_ind2];

        % calculate the distances between the two stimulated electrodes and all of the other electrodes
        electrode_dist =    (electrodes.x(electrode_indices)' - [electrodes.x]) .^ 2 + ...
                            (electrodes.y(electrode_indices)' - [electrodes.y]) .^ 2 + ...
                            (electrodes.z(electrode_indices)' - [electrodes.z]) .^ 2;
        
        % loop through the recording channels
        for iChannel = 1:length(outStruct.channels)
            channel = outStruct.channels{iChannel};

            % find the coordinates of the current channel
            channel_idx = find(strcmpi([electrodes.name], channel));
            if isempty(channel_idx)
                error(['Could not find (coordinates for) recording channel ', channel , ' in electrodes.tsv, could not exclude nearby electrodes']);
            end

            % check if the current electrode is one of the stimulus-pair
            if any(electrode_indices == channel_idx)
                % current electrode is part of stim-pair
                
                % should already be NaN, check
                % TODO:
                
            else
                % current electrode is not part of stim-pair

                % retrieve the distance between the current channel and both of the stim-pair channels in MM
                distMM = sqrt(electrode_dist(channel_idx, :));
                
                % check if the current recording channel is too close to either of channels in the stim-pair
                if any(electrode_dist(channel_idx, :) < (electrode_excludeDist ^ 2))

                    % nan the value
                    outStruct.annotations(iChannel, iStimpair) = nan;
                    
                    % add to list of nanned combinations
                    exclCombos{end + 1} = [stimpair, ' x ', channel, ' (', char(strjoin(string(round(distMM, 1)), ', ')), 'mm)'];

                            
                end
                
            end
            
        end
        
        
    end

    % message
    if verbose && ~isempty(exclCombos)
        warning('backtrace', 'off')
        warning(['  The following stim-pairs & electrode combinations were nanned by distance: ', strjoin(exclCombos, '\n')]);
    end

    
end