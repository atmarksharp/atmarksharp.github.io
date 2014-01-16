/*
* Replace tabs to spaces
*/

window.Pretab = {};

window.Pretab.fix = function(){
	$('pre code').each(function(){
		var $this = $(this);
		var code = ($this.html());

		if(code){
			var lines = code.split('\n');
			var ret = [];
			$.each(lines, function(i, line){
				var s = line.replace(/^([ ]+)/g, '$1$1$1$1');
				ret.push(s);
			});

			$this.html(ret.join('\n'));
		}
	});
};