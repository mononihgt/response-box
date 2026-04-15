function outFile = export_csv(results, participant, taskType, outDir)
%EXPORT_CSV Export python-aligned trial data to CSV.

if nargin < 4 || strlength(string(outDir)) == 0
    outDir = fullfile(rbx.util.get_documents_dir(), "response_box_data");
end
if ~isfolder(outDir)
    mkdir(outDir);
end

participantName = local_get_field(participant, "name", "unknown");
safeName = local_safe_filename_fragment(participantName);

stamp = datestr(now, 'yyyymmdd_HHMMSS');
outFile = fullfile(char(outDir), sprintf('stroop_%s_%s.csv', safeName, stamp));

tbl = local_build_table(results, participant, taskType);
try
    writetable(tbl, outFile, "FileType", "text", "Encoding", "UTF-8");
catch
    writetable(tbl, outFile, "FileType", "text");
end

end

function tbl = local_build_table(results, participant, taskType)
n = numel(results);

varNames = { ...
    'trial', 'word', 'color', 'congruent', 'correct_key', ...
    'response_key', 'response_name', 't1_press', 't2_release', ...
    'press_duration', 'software_rt', 'key_delay', 'system_delay', 'correct', ...
    'name', 'age', 'gender', 'date', 'time', 'task_type'};

varTypes = { ...
    'double', 'string', 'string', 'double', 'double', ...
    'double', 'string', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', ...
    'string', 'string', 'string', 'string', 'string', 'string'};

tbl = table('Size', [n, numel(varNames)], 'VariableTypes', varTypes, 'VariableNames', varNames);
if n == 0
    return;
end

name = string(local_get_field(participant, "name", ""));
age = string(local_get_field(participant, "age", ""));
gender = string(local_get_field(participant, "gender", ""));
dateStr = string(local_get_field(participant, "date", datestr(now, 'yyyy-mm-dd')));
timeStr = string(local_get_field(participant, "time", datestr(now, 'HH:MM:SS')));

for i = 1:n
    row = results(i);
    tbl.trial(i) = row.trial;
    tbl.word(i) = string(row.word);
    tbl.color(i) = string(row.color);
    tbl.congruent(i) = double(logical(row.congruent));
    tbl.correct_key(i) = row.correct_key;
    tbl.response_key(i) = row.response_key;
    tbl.response_name(i) = string(row.response_name);
    tbl.t1_press(i) = row.t1_press;
    tbl.t2_release(i) = row.t2_release;
    tbl.press_duration(i) = row.press_duration;
    tbl.software_rt(i) = row.software_rt;
    tbl.key_delay(i) = row.key_delay;
    tbl.system_delay(i) = row.system_delay;
    tbl.correct(i) = double(logical(row.correct));
    tbl.name(i) = name;
    tbl.age(i) = age;
    tbl.gender(i) = gender;
    tbl.date(i) = dateStr;
    tbl.time(i) = timeStr;
    tbl.task_type(i) = string(taskType);
end

end

function out = local_get_field(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    out = s.(fieldName);
else
    out = defaultValue;
end
end

function out = local_safe_filename_fragment(value)
out = string(value);
out = regexprep(out, '[<>:"/\\|?*\x00-\x1F]+', '_');
out = regexprep(out, '^[\s\._]+', '');
out = regexprep(out, '[\s\._]+$', '');
if strlength(out) == 0
    out = "unknown";
end
out = char(out);
end
