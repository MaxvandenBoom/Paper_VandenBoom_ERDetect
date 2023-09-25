%
%   Remove stimulus-pairs that have too few stimulation events (trials)
%
%   outStruct = ccep_annot_filterByNumTrials(inStruct, eventsFile, concatBiDir, minNumTrials, verbose)
%
%       inStruct                = the annotation struct to filter the stim-pair and recording channels from
%       eventsFile              = path to the events.tsv file to determine the number of stimulation events
%       concatBiDir             = Concatenate bidirectional stimulated pairs
%       minNumTrials            = The minimum number of stimulation events required to keep a stim-pair
%       verbose                 = Display messages (default = 1)
%
%   Returns: 
%       outStruct               = A annotation struct with the stim-pairs filtered by number of trials
%
%

%   Max van den Boom (Multimodal Neuroimaging Lab, Mayo Clinic, Rochester MN), 2023
%
function outStruct = ccep_annot_filterByNumTrials(inStruct, eventsFile, concatBiDir, minNumTrials, verbose)
    if ~exist('verbose', 'var'), verbose = 1;   end

    % load events    
    events    = readtable(eventsFile, 'FileType', 'text', 'Delimiter', '\t', ...
                           'TreatAsEmpty', {'N/A', 'n/a'}, 'ReadVariableNames', true);
                        
    % variable to hold the list of excluded stim-pairs and recording channels
    exclStimPairIndices = [];
    exclStimPairList = {};

    % loop through the stim-pairs
    for iStimpair = 1:length(inStruct.stimpairs)
        stimpair = inStruct.stimpairs{iStimpair};
        stimpair_split = split(stimpair, '-');
        
        % collect the number of events for this stim-pair
        pair_events = find(strcmpi(events.electrical_stimulation_site, [stimpair_split{1}, '-', stimpair_split{2}]));
        if concatBiDir
            pair_events = [pair_events; find(strcmpi(events.electrical_stimulation_site, [stimpair_split{2}, '-', stimpair_split{1}]))];
        end
        if length(pair_events) < minNumTrials

            % add to list of excluded stim-pairs
            exclStimPairIndices(end + 1) = iStimpair;
            exclStimPairList{end + 1} = [stimpair, ' (', num2str(length(pair_events)), ' events)'];

            continue;
        end

    end
    
    % assign the output and filter
    outStruct = inStruct;
    if ~isempty(exclStimPairIndices)
        outStruct.annotations(:, exclStimPairIndices) = [];
        outStruct.stimpairs(exclStimPairIndices) = [];
    end
        
    % message
    if verbose && ~isempty(exclStimPairList)
        warning('backtrace', 'off')
        warning(['  The following stim-pairs were excluded by number of trials (min. ', num2str(minNumTrials), ' allowed): ', strjoin(exclStimPairList, ', ')]);
    end
    
end