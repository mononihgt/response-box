function documentsDir = get_documents_dir()
%GET_DOCUMENTS_DIR Cross-platform Documents directory.

if ispc
    userHome = getenv("USERPROFILE");
else
    userHome = getenv("HOME");
end

if strlength(userHome) == 0
    userHome = pwd;
end

candidate = fullfile(char(userHome), "Documents");
if isfolder(candidate)
    documentsDir = candidate;
else
    documentsDir = char(userHome);
end

end

