/*
* Replace tabs to spaces
*/

Zepto(function($){
	var code = ($('pre code').html());
	var lines = code.split('\n');
	var ret = [];
	$.each(lines, function(i, line){
		var s = line.replace(/^([ ]+)/g, '$1$1$1$1$1$1$1$1');
		ret.push(s);
	});

	$('pre code').html(ret.join('\n'));
});