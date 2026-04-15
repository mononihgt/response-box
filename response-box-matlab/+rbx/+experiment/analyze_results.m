function stats = analyze_results(results)
%ANALYZE_RESULTS Compute summary and Stroop-condition statistics.

stats = struct();
stats.totalTrials = numel(results);
stats.respondedTrials = 0;
stats.correctTrials = 0;
stats.timeoutTrials = 0;
stats.accuracy = 0;
stats.meanRT = 0;
stats.congruent = local_empty_condition_stats();
stats.incongruent = local_empty_condition_stats();
stats.stroopEffect = 0;

if isempty(results)
    return;
end

responseKeys = [results.response_key];
correctFlags = logical([results.correct]);
t1Values = [results.t1_press];
timedOut = isnan(responseKeys);
conditions = logical([results.congruent]);

stats.respondedTrials = sum(~isnan(responseKeys));
stats.correctTrials = sum(correctFlags);
stats.timeoutTrials = sum(timedOut);

if stats.totalTrials > 0
    stats.accuracy = (stats.correctTrials / stats.totalTrials) * 100;
end

validCorrectRt = t1Values(correctFlags & ~isnan(t1Values));
if ~isempty(validCorrectRt)
    stats.meanRT = mean(validCorrectRt);
end

stats.congruent = local_analyze_condition(conditions == true, correctFlags, t1Values);
stats.incongruent = local_analyze_condition(conditions == false, correctFlags, t1Values);
if stats.congruent.count > 0 && stats.incongruent.count > 0 ...
        && stats.congruent.meanRT > 0 && stats.incongruent.meanRT > 0
    stats.stroopEffect = stats.incongruent.meanRT - stats.congruent.meanRT;
else
    stats.stroopEffect = NaN;
end

end

function out = local_analyze_condition(condMask, correctFlags, t1Values)
out = local_empty_condition_stats();
out.count = sum(condMask);
if out.count == 0
    return;
end

correctMask = condMask & correctFlags;
out.accuracy = (sum(correctMask) / out.count) * 100;
validRt = t1Values(correctMask & ~isnan(t1Values));
if ~isempty(validRt)
    out.meanRT = mean(validRt);
end
end

function out = local_empty_condition_stats()
out = struct("count", 0, "accuracy", 0, "meanRT", 0);
end
