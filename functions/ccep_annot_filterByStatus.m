%
%   Remove stimulus-pairs and recording channels that are marked as bad (by the status field in channels file) from an annotation struct
%
%   outStruct = ccep_annot_filterByStatus(inStruct, channelFile, verbose)
%
%       inStruct                = the annotation struct to filter the stim-pair and recording channels from
%       channelFile             = path to the channels.tsv file to determine the channel status
%       verbose                 = Display messages (default = 1)
%
%   Returns: 
%       outStruct               = A annotation struct with the channels and stim-pairs filtered by channel status
%
%

%   Max van den Boom (Multimodal Neuroimaging Lab, Mayo Clinic, Rochester MN), 2022
%
function outStruct = ccep_annot_filterByStatus(inStruct, channelFile, verbose)
    if ~exist('verbose', 'var'), verbose = 1;   end

    % load channels    
    channels    = readtable(channelFile, 'FileType', 'text', 'Delimiter', '\t', ...
                            'TreatAsEmpty', {'N/A', 'n/a'}, 'ReadVariableNames', true);
                        
    % variable to hold the list of excluded stim-pairs and recording channels
    exclStimPairIndices = [];
    exclStimPairList = {};
    exclChannelIndices = [];
    exclChannelList = {};

    % loop through the stim-pairs
    for iStimpair = 1:length(inStruct.stimpairs)
        stimpair = inStruct.stimpairs{iStimpair};
        stimpair_split = split(stimpair, '-');

        % check stimulus-pair channel type
        channels_idx_0 = find(strcmpi(channels.name, stimpair_split{1}));
        channels_idx_1 = find(strcmpi(channels.name, stimpair_split{2}));
        if isempty(channels_idx_0), error(['Could not find stim-pair channel 0 ', stimpair_split{1} , ' in channels.tsv']);     end
        if isempty(channels_idx_1), error(['Could not find stim-pair channel 1 ', stimpair_split{2} , ' in channels.tsv']);     end
        if any(~ismember(upper({channels.status{channels_idx_0}, channels.status{channels_idx_1}}), upper('GOOD')))

            % add to list of excluded stim-pairs
            exclStimPairIndices(end + 1) = iStimpair;
            exclStimPairList{end + 1} = [stimpair, ' (', channels.status{channels_idx_0}, ' & ', channels.status{channels_idx_1}, ')'];

            continue;
        end

    end

    % loop through the recording channels
    for iChannel = 1:length(inStruct.channels)
        channel = inStruct.channels{iChannel};

        % check channel channel type
        channels_idx = find(strcmpi(channels.name, channel));
        if isempty(channels_idx), error(['Could not find channel ', channel , ' in channels.tsv']);     end
        if ~strcmpi(channels.status{channels_idx}, 'good')

            % add to list of excluded channels
            exclChannelIndices(end + 1) = iChannel;
            exclChannelList{end + 1} = [channel, ' (', channels.status{channels_idx}, ')'];

            continue;
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
        warning(['  The following stim-pairs were excluded by status (only good allowed): ', strjoin(exclStimPairList, ', ')]);
    end
    if verbose && ~isempty(exclChannelList)
        warning('backtrace', 'off')
        warning(['  The following recoding channels were excluded by status (only good allowed): ', strjoin(exclChannelList, ', ')]);
    end
    
end