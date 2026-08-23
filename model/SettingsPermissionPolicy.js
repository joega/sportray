var DIRECTORY_MODE = "700";
var FILE_MODE = "600";

function isNonEmptyString(value) {
  return typeof value === "string" && value.length > 0;
}

function paths(statePath) {
  if (!isNonEmptyString(statePath)) return null;
  var slash = statePath.lastIndexOf("/");
  if (slash <= 0 || slash === statePath.length - 1) return null;
  return {
    statePath: statePath,
    stateDirectory: statePath.slice(0, slash)
  };
}

function commands(statePath) {
  var resolved = paths(statePath);
  if (!resolved) return null;
  return {
    makeDirectory: ["/usr/bin/mkdir", "-p", "--", resolved.stateDirectory],
    hardenDirectory: ["/usr/bin/chmod", DIRECTORY_MODE, "--", resolved.stateDirectory],
    checkFile: ["/usr/bin/test", "-f", resolved.statePath],
    hardenFile: ["/usr/bin/chmod", "--no-dereference", FILE_MODE, "--", resolved.statePath]
  };
}

// `test -f` exits 0 for an existing regular file and 1 for a missing file.
// Other results are failures; they must not be mistaken for a new state file.
function repairResult(parentExitCode, fileCheckExitCode, fileExitCode) {
  var parentReady = parentExitCode === 0;
  var fileExists = fileCheckExitCode === 0;
  var fileCheckReady = fileCheckExitCode === 0 || fileCheckExitCode === 1;
  var fileReady = !fileExists || fileExitCode === 0;
  return {
    parentReady: parentReady,
    fileExists: fileExists,
    fileReady: fileReady,
    ready: parentReady && fileCheckReady && fileReady
  };
}

function writeResult(exitCode) {
  return exitCode === 0;
}

var exported = {
  DIRECTORY_MODE: DIRECTORY_MODE,
  FILE_MODE: FILE_MODE,
  paths: paths,
  commands: commands,
  repairResult: repairResult,
  writeResult: writeResult
};

if (typeof module !== "undefined" && module.exports) module.exports = exported;
