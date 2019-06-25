process_exec_sync = function (command) {
  // Load future from fibers
  var Future = Npm.require("fibers/future");
  // Load exec
  var child = Npm.require("child_process");
  // Create new future
  var future = new Future();
  // Run command synchronous
  child.exec(command, function(error, stdout, stderr) {
    // return an onbject to identify error and success
    var result = {};
    // test for error
    if (error) {
      result.error = error;
    }
    // return stdout
    result.stdout = stdout;
    future.return(result);
  });
  // wait for future
  return future.wait();
}
