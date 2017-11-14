Meteor.methods({
  checkHostPing: function(hostname) {
    this.unblock();
    var result = process_exec_sync('ping -c 3 -t 3 ' + hostname);
    if (result.error) {
      return "btn-danger"
    }
    else {
      return "btn-success"
    }
  },
  checkHTTPCode: function(fqdn) {
    this.unblock();
    try {
      const result = HTTP.get(fqdn, {
        timeout: 1000
      });
      return "btn-success"
    } catch (e) {
      // console.log(e)
      return "btn-danger"
    }
  }
});
