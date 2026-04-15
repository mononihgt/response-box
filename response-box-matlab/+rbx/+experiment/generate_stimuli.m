function stimuli = generate_stimuli(taskType, keyMapping)
%GENERATE_STIMULI Generate the base Stroop stimulus set.

if nargin < 1 || strlength(string(taskType)) == 0
    taskType = "color";
end
if nargin < 2 || isempty(keyMapping)
    keyMapping = struct("red", 3, "green", 1);
end

stimuli = repmat(local_empty_stimulus(), 1, 4);
stimuli(1) = local_build_stimulus("红", "red", true, taskType, keyMapping);
stimuli(2) = local_build_stimulus("绿", "green", true, taskType, keyMapping);
stimuli(3) = local_build_stimulus("红", "green", false, taskType, keyMapping);
stimuli(4) = local_build_stimulus("绿", "red", false, taskType, keyMapping);

end

function stim = local_build_stimulus(word, inkColor, congruent, taskType, keyMapping)
stim = local_empty_stimulus();
stim.word = string(word);
stim.color = string(inkColor);
stim.congruent = logical(congruent);
stim.correct_key = local_get_correct_key(taskType, stim.word, stim.color, keyMapping);
end

function key = local_get_correct_key(taskType, word, inkColor, keyMapping)
taskType = string(taskType);
word = string(word);
inkColor = string(inkColor);

if taskType == "color"
    if inkColor == "red"
        key = keyMapping.red;
    else
        key = keyMapping.green;
    end
else
    if word == "红"
        key = keyMapping.red;
    else
        key = keyMapping.green;
    end
end
end

function stim = local_empty_stimulus()
stim = struct( ...
    "word", "", ...
    "color", "", ...
    "congruent", false, ...
    "correct_key", NaN);
end
