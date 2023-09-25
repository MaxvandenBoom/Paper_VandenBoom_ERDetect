%
%   Remove stimulus-pairs and recording channels by type from an annotation struct
%
%   outStruct = ccep_annot_filterByType(inStruct, channelFile, stimIncludeTypes, recIncludeTypes, verbose)
%
%       inStruct                = the annotation struct to filter the stim-pair and recording channels from
%       channelFile             = path to the channels.tsv file to determine the channel types
%       stimIncludeTypes        = stimulus-pair channel types to keep. If one of the two stimulus-pair electrodes is not of one of the
%                                 included types then stim-pair is removed. (e.g. {'ECoG', 'SEEG'} will keep both ECOG and SEEG electrodes).
%       recIncludeTypes         = recording channel types to keep. (e.g. {'ECoG'} will keep only ECOG electrodes).
%       verbose                 = Display messages (default = 1)
%
%   Returns: 
%       outStruct               = A annotation struct with the channels and stim-pairs filtered by type
%
%

%   Max van den Boom (Multimodal Neuroimaging Lab, Mayo Clinic, Rochester MN), 2022
%
function outStruct = ccep_annot_filterByType(inStruct, channelFile, stimIncludeTypes, recIncludeTypes, verbose)
    if ~exist('verbose', 'var'), verbose = 1;   end

    % load channels    
    channels    = readtable(channelFile, 'FileType', 'text', 'Delimiter', '\t', ...
                            'TreatAsEmpty', {'N/A', 'n/a'}, 'ReadVariableNames', true);
                        
                        
    % variable to hold the list of excluded stim-pairs and recording channels
    exclStimPairIndices = [];
    exclStimPairList = {};
    exclChannelIndices = [];
    exclChannelList = {};
    
    
    if ~isempty(stimIncludeTypes)
        
        % loop through the stim-pairs
        for iStimpair = 1:length(inStruct.stimpairs)
            stimpair = inStruct.stimpairs{iStimpair};
            stimpair_split = split(stimpair, '-');

            % check stimulus-pair channel type
            channels_idx_0 = find(strcmpi(channels.name, stimpair_split{1}));
            channels_idx_1 = find(strcmpi(channels.name, stimpair_split{2}));
            if isempty(channels_idx_0), error(['Could not find stim-pair channel 0 ', stimpair_split{1} , ' in channels.tsv']);     end
            if isempty(channels_idx_1), error(['Could not find stim-pair channel 1 ', stimpair_split{2} , ' in channels.tsv']);     end
            if any(~ismember(upper({channels.type{channels_idx_0}, channels.type{channels_idx_1}}), upper(stimIncludeTypes)))

                % add to list of excluded stim-pairs
                exclStimPairIndices(end + 1) = iStimpair;
                exclStimPairList{end + 1} = [stimpair, ' (', channels.type{channels_idx_0}, ' & ', channels.type{channels_idx_1}, ')'];

                continue;
            end

        end
        
    end

    if ~isempty(recIncludeTypes)
        
        % loop through the recording channels
        for iChannel = 1:length(inStruct.channels)
            channel = inStruct.channels{iChannel};

            % check channel channel type
            channels_idx = find(strcmpi(channels.name, channel));
            if isempty(channels_idx), error(['Could not find channel ', channel , ' in channels.tsv']);     end
            if ~ismember(upper(channels.type{channels_idx}), upper(recIncludeTypes))

                % add to list of excluded channels
                exclChannelIndices(end + 1) = iChannel;
                exclChannelList{end + 1} = [channel, ' (', channels.type{channels_idx}, ')'];

                continue;
            end

        end
        
    end
    
    % assign the output and filter
    outStruct = inStruct;
    if ~isempty(exclStimPairIndices)
        outStruct.annotations(:, exclStimPairIndices) = [];
        outStruct.stimpairs(exclStimPairIndices) = [];
    end
    if ~isempty(exclChannelIndices)
        outStruct.annotations(exclChannelIndices, :) = [];
        outStruct.channels(exclChannelIndices) = [];
    end
        
    % message
    if verbose && ~isempty(exclStimPairList)
        warning('backtrace', 'off')
        warning(['  The following stim-pairs were excluded by type (only ', strjoin(stimIncludeTypes, ', '), ' allowed): ', strjoin(exclStimPairList, ', ')]);
    end
    if verbose && ~isempty(exclChannelList)
        warning('backtrace', 'off')
        warning(['  The following recoding channels were excluded by type (only ', strjoin(recIncludeTypes, ', '), ' allowed): ', strjoin(exclChannelList, ', ')]);
    end
    
end