Template.registerHelper('getPing', function(hostname){
	return ReactiveMethod.call("checkHostPing", hostname);
})

Template.registerHelper('getHTTPCode', function(fqdn){
	return ReactiveMethod.call("checkHTTPCode", fqdn);
})
