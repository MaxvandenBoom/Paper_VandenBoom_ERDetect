%
%   Load and match the CCEP stim-pairs and channels from a manual/visual annotation file with the stim-pairs and channels from an app/automatic detection output file
%   and produce two annotation structs that hold the stim-pairs and channels that both have in common including each of their N1 matrices.
%   Note: P1 annotations will be converted to no-ER
%
%   [manualStruct, appStruct] = ccep_annot_matchManualAndAuto(manualAnnotFilepath, appAnnotFilepath, verbose)
%
%       manualAnnotFilepath     = path to the manuel/visual annotation file (produced in Mayo by mnl_ccep_erReviewAndAnnot, or converted annotation file from UMC Utrecht)
%       appAnnotFilepath        = path to the app detection output file (produced by the ERDetect library/app)
%       verbose                 = Display messages (default = 1)
%
%   Returns: 
%       manualStruct            = A manual/visual annotation struct with the channels (field 'channels)' and stimpairs (field 'stimpairs')
%                                 that the manual/visal and automatic detection files have in common. Including the manual/visual corresponding
%                                 annotations (field 'stimpairs' as a matrix in the format <channels> x stimpairs>)
%       appStruct               = An automatic detection annotation struct with the channels (field 'channels)' and stimpairs (field 'stimpairs')
%                                 that the automatic and manual/visal detection files have in common. Including the auto detected corresponding
%                                 annotations (field 'stimpairs' as a matrix in the format <channels> x stimpairs>)
%

%   Max van den Boom (Multimodal Neuroimaging Lab, Mayo Clinic, Rochester MN), 2022
%
function [manualStruct, appStruct] = ccep_annot_matchManualAndAuto(manualAnnotFilepath, appAnnotFilepath, verbose)
    if ~exist('verbose', 'var'), verbose = 1;   end
    
    % message
    if verbose == 1
        disp('----------');
        disp(manualAnnotFilepath);
    end
    
    % load the annotation files
    annot_manual    = load(manualAnnotFilepath);   annot_manual = annot_manual.annot;
    annot_app       = load(appAnnotFilepath);
    
    % 
    shared_channels = {};
    shared_stimpairs = {};
    shared_manual = {};              % channels x stimpairs
    shared_app = {};                % channels x stimpairs

    % variable to hold (for display) the list of excluded stim-pairs and channels (because they were not found in the automatic detection)
    exclStimPairList = {};
    exclChannelList = {};

    % loop through the manual/visual stim-pairs
    stimpairCounter = 0;
    for iManualStimpair = 1:length(annot_manual.stimpairs)
        manual_stimpair = annot_manual.stimpairs{iManualStimpair};
        manual_stimpair_split = split(manual_stimpair, '-');

        % try to find the manual/visual stim-pair in the automatically detected stim-pair annotations
        det_stimpair_idx = find(strcmpi(annot_app.stimpair_labels, manual_stimpair));
        if isempty(det_stimpair_idx)

            % add to list of excluded stim-pairs
            exclStimPairList{end + 1} = manual_stimpair;
            
            continue;
        end
		
        % add stimpair
        shared_stimpairs{end + 1} = manual_stimpair;
        stimpairCounter = stimpairCounter + 1;
        
        % loop through the manual/visual annotation recorded channels
        channelCounter = 0;
        for iManualChan = 1:length(annot_manual.channels)
            manual_channel = annot_manual.channels{iManualChan};

            % try to find the manual/visual channel in the automatically detected channel annotations
            app_channel_idx = find(strcmp(annot_app.channel_labels, manual_channel));
            if isempty(app_channel_idx)
                
                % we are looping through stim-pairs, so we will encounter all channels a number of times,
                % so we only need to exclude the channel once
                if length(shared_stimpairs) == 1
                    
                    % add to list of excluded channels
                    exclChannelList{end + 1} = manual_channel;
                    
                end
                continue;
            end
            
            % raise the channel counter
            channelCounter = channelCounter + 1;

            % add channel
            if length(shared_stimpairs) == 1
                shared_channels{end + 1} = manual_channel;    
            end


            %
            % automatic detection value
            %

            % check if the current channel is a stimulated channel on this stim-pair
            if any(strcmpi(manual_stimpair_split, manual_channel))
                % stimulated channel

                % set value to nan, don't include stimulated channels in the comparison
                det_val = nan;

            else
                % not a stimulated channel

                % convert the ampulitude value to a 0 for No-ER or 1 or N1
                det_val = annot_app.neg_peak_amplitudes(app_channel_idx, det_stimpair_idx);
                det_val = double(~isnan(det_val));

            end
            shared_app{channelCounter, stimpairCounter} = det_val;


            %
            % Manual/visual value
            %

            manual_value = annot_manual.annotations(iManualChan, iManualStimpair);

            % check if the current channel is marked as a stimulated channel on this stim-pair
            if manual_value == -1
                % stimulated channel

                % check if the flagging is correct
                if ~any(strcmp(manual_stimpair_split, manual_channel))
                    warning('backtrace', 'off')
                    warning('The value in the UMC data should not be -1');
                end

                % set value to nan, don't include stimulated channels in the comparison
                manual_value = nan;

            else
                % not a stimulated channel

                % convert P1s to No-ERs
                if manual_value == 2
                   manual_value = 0;
                end


            end
            shared_manual{channelCounter, stimpairCounter} = manual_value;
            
        end     % end of channel loop

    end     % end of stim-pair loop
    
    if verbose && ~isempty(exclStimPairList)
        warning('backtrace', 'off')
        warning(['  The following manual/visual stim-pairs were excluded since they were not found in the app/automatic annotations: ', strjoin(exclStimPairList)]);
    end

    if verbose && ~isempty(exclChannelList)
        warning('backtrace', 'off')
        warning(['  The following manual/visual channels were excluded since they were not found in the app/automatic annotations: ', strjoin(exclChannelList)]);
    end

    
    %
    manualStruct = struct();
    manualStruct.channels = shared_channels;
    manualStruct.stimpairs = shared_stimpairs;
    manualStruct.annotations = cell2mat(shared_manual);
    
    appStruct = struct();
    appStruct.channels = shared_channels;
    appStruct.stimpairs = shared_stimpairs;
    appStruct.annotations = cell2mat(shared_app);
    
end