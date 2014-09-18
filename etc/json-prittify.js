#!/usr/bin/env node

var stdin = ''; process.stdin.resume(); process.stdin.setEncoding('utf8'); process.stdin.on('data', function (chunk) { stdin += chunk}); process.stdin.on('end', function () { var output = JSON.stringify(JSON.parse(stdin), null, '    '); console.log(output) });