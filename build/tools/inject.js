/**
 * @license Copyright (c) 2010-2011, The Dojo Foundation All Rights Reserved.
 * Available via the MIT or new BSD license.
 * see: http://github.com/jrburke/require-cs for details
 */

(function(){function wrapModules(){var text="";return files.forEach(function(file){text+="(function () {\nvar exports = __MODULES['"+file+"'] = {};\n"+fs.readFileSync(csDir+file+".js")+"return exports;\n"+"}());"}),text}var fs=require("fs"),csDir=process.argv[2],pluginFile=process.argv[3],version=process.argv[4],files=["helpers","rewriter","lexer","parser","scope","nodes","coffee-script"],injectionStart="//START COFFEESCRIPT",injectionEnd="//END COFFEESCRIPT",versionRegExp=/CoffeeScriptVersion\:\s*'([^']+)'/g,text,pluginContents,startIndex,endIndex;if(!csDir||!pluginFile||!version){console.log("Usage: node inject.js path/to/coffeescript/lib/dir plugin.js coffeescriptversion");return}csDir.charAt(csDir.length-1)!=="/"&&(csDir+="/"),pluginContents=fs.readFileSync(pluginFile,"utf8"),text="//START COFFEESCRIPT\nCoffeeScript = (function () {\nvar __MODULES = {}; function require(name) { return __MODULES[name.substring(2)]; };\n"+wrapModules()+"\nreturn __MODULES['coffee-script'];\n"+"\n}());\n"+"//END COFFEESCRIPT",startIndex=pluginContents.indexOf(injectionStart),endIndex=pluginContents.indexOf(injectionEnd),pluginContents=pluginContents.replace(versionRegExp,"CoffeeScriptVersion: '"+version+"'"),pluginContents=pluginContents.substring(0,startIndex)+text+pluginContents.substring(endIndex+injectionEnd.length,pluginContents.length),fs.writeFileSync(pluginFile,pluginContents,"utf8")})()