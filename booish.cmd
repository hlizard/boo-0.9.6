cd src/booc/bin/Release/PublishOutput
booc.Core -target:library -debug- -nostdlib -srcdir:/mycode/boo-0.9.6/src/booish -srcdir:/mycode/boo-0.9.6/src/Boo.Lang.Interpreter -srcdir:/mycode/boo-0.9.6/src/booish.mod.os -r:Boo.Lang.Parser.dll -r:Boo.Lang.Compiler.dll -r:Boo.Lang.dll -r:Boo.Lang.Extensions.dll -r:Boo.Lang.Useful.dll -r:Boo.Lang.PatternMatching.dll -r:System.Private.CoreLib.dll -r:System.Private.Xml.dll -r:System.Runtime.Extensions.dll -r:System.Runtime.dll -r:System.IO.FileSystem.dll -r:System.Console.dll -r:System.Collections.dll -r:System.Diagnostics.Process.dll -r:System.Diagnostics.TextWriterTraceListener.dll -r:System.Linq.dll
