function cfg = default_config()
%DEFAULT_CONFIG Default configuration for response-box MATLAB experiments.

cfg = struct();

% Serial protocol
cfg.baudRate = 115200;
cfg.whiteKey = 5;
cfg.validResponseKeys = [1, 2, 3, 4];

% Python-aligned experiment timing (milliseconds)
cfg.nTrials = 12;
cfg.maskMs = 1000;
cfg.fixationMs = 500;
cfg.responseTimeoutMs = 2000;
cfg.feedbackMs = 1000;
cfg.itiMs = 1000;

% Task defaults (aligned with python/experiment_psychopy.py)
cfg.taskType = "color";  % "color" or "word"
cfg.keyMapping = struct("red", 3, "green", 1);
cfg.usePsychtoolbox = true;

% Render defaults (Psychtoolbox)
cfg.windowBackground = [0, 0, 0];
cfg.maskColor = [255, 255, 255];
cfg.fixationColor = [255, 255, 255];
cfg.feedbackColor = struct( ...
    "correct", [0, 255, 0], ...
    "incorrect", [255, 0, 0], ...
    "timeout", [255, 255, 0], ...
    "fast", [0, 128, 255], ...
    "invalid", [255, 255, 255], ...
    "normal", [255, 255, 255]);

if ismac
    cfg.fontName = "PingFang SC";
else
    cfg.fontName = "Microsoft YaHei";
end

cfg.stimulusTextSize = 120;
cfg.maskTextSize = 120;
cfg.fixationTextSize = 80;
cfg.feedbackTextSize = 34;
cfg.infoTextSize = 24;

% Data output
cfg.outputDir = fullfile(rbx.util.get_documents_dir(), "response_box_data");

end
