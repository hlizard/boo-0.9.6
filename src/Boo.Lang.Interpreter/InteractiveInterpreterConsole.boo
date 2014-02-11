#region license
// Copyright (c) 2004, Rodrigo B. de Oliveira (rbo@acm.org)
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
//     * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//     * Neither the name of Rodrigo B. de Oliveira nor the names of its
//     contributors may be used to endorse or promote products derived from this
//     software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#endregion

namespace Boo.Lang.Interpreter

import System
import System.Collections
import System.IO
import System.Text
import System.Text.RegularExpressions
import System.Reflection

import Boo.Lang.Compiler
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Interpreter.ColorScheme

import PatternMatching

[CmdClass("Shell")]
class InteractiveInterpreterConsole:
	
	public final static HISTORY_FILENAME = "booish\\history"
	public final static HISTORY_CAPACITY = 1000
	
	struct HistoryEntry:
		[Getter(Text)]
		_text as string
		[Getter(IsValid)]
		_isValid as bool
		
		def constructor(text as string, isValid as bool):
			self._text = text
			self._isValid = isValid
	
	_history = List of HistoryEntry(HISTORY_CAPACITY)
	_historyFile = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), HISTORY_FILENAME)
	_historyIndex = 0
	_session = System.Collections.Generic.List of string()
	
	[Property(AutoIndention)]
	_autoIndention = true
	"""
	Turn auto indention on and off.
	"""
	
	_buffer = StringBuilder()	#buffer to be executed
	_line = StringBuilder()		#line being edited
	_multiline = false			#is the current line a multi-line?

	[property(BlockStarters, value is not null)]
	_blockStarters = (char(':'), char('\\'),)
	
	[property(ShowWarnings)]
	_showWarnings = false

	QQBegin = "[|"
	QQEnd= "|]"
	
	_interpreter as InteractiveInterpreter
	
	_shellCmdExecution = CmdExecution(self._interpreter)
		
	def constructor():
		self(InteractiveInterpreter())

	def constructor(interpreter as InteractiveInterpreter):
		self._interpreter = interpreter
		self._interpreter.RememberLastValue = true
		
		DisableColors = not string.IsNullOrEmpty(Environment.GetEnvironmentVariable("BOOISH_DISABLE_COLORS"))
		if not DisableColors: #make sure setting color does not throw an exception
			try:
				Console.ForegroundColor = InterpreterColor
				Console.BackgroundColor = BackgroundColor
			except:
				DisableColors = true
		self.DisableAutocompletion = not string.IsNullOrEmpty(Environment.GetEnvironmentVariable("BOOISH_DISABLE_AUTOCOMPLETION"))
		self.LoadHistory()
		self._interpreter.References.Add(typeof(InteractiveInterpreterConsole).Assembly)
		self._shellCmdExecution.AddCmdObject(self)
		
	def SetValue(name as string, value):
		_interpreter.SetValue(name, value)
	
	Line:
		get: return _line.ToString()

	LineLastChar:
		get: return (_line.Chars[LineLen-1] if LineLen != 0 else char('\0'))

	LineLen:
		get: return _line.Length
		set: _line.Length = value
	
	BooIndention = '\t'
	BooIndentionWidth = 4
	
	LineIndentWidth:
	"""
	The number of columns that the line indention covers if written
	on the console.
	"""
		get: return BooIndentionWidth * _indent

	CurrentPrompt as string:
		get:
			if self._autoIndention and self._indent > 0:
				return self.BlockPrompt
			elif self._buffer.Length > 0:
				return self.BlockPrompt
			elif self._autoIndention:
				return self.DefaultPrompt
			else:
				return self.PasteModePrompt
		
	PrintModules:
		get: return _interpreter.Pipeline.Find(Boo.Lang.Compiler.Steps.PrintBoo) != -1
		set:
			if value:
				if not PrintModules:
					_interpreter.Pipeline.Add(Boo.Lang.Compiler.Steps.PrintBoo())
			else:
				_interpreter.Pipeline.Remove(Boo.Lang.Compiler.Steps.PrintBoo)
				
	property DefaultPrompt = ">>> "
	property BlockPrompt = "... "
	property PasteModePrompt = "--> "

	property DisableAutocompletion = false
	
	[CmdDeclaration("autocompletion toggleAutocompletion",
	Description:"""Autocompletion will present you lists to complete the
current input line. Use this command to toggle the activation of
this feature.""")]
	def ToggleAutocompletion():
		self.DisableAutocompletion = not self.DisableAutocompletion
		if self.DisableAutocompletion:
			Console.WriteLine("Autocompletion is disabled.")
		else:
			Console.WriteLine("Autocompletion is enabled.")

	# messages from the interpreter (not from user code)
	_selectedSuggestionIndex as int?

	_suggestions as (object)

	CanAutoComplete as bool:
		get: return _selectedSuggestionIndex is not null

	private _filter as string
	
	def Eval(code as string) as Boo.Lang.Compiler.CompilerContext:
		try:
			result = _interpreter.Eval(code)
			DisplayResults(result)
			return result
		except x as Boo.Lang.Exceptions.UserRequestedAbortion:
			WithColor ExceptionColor:
				Console.WriteLine(x.Message)
		except x as System.Reflection.TargetInvocationException:
			if x.InnerException isa Boo.Lang.Exceptions.UserRequestedAbortion:
				WithColor ExceptionColor:
					Console.WriteLine(x.InnerException.Message)
			else:
				ConsolePrintException(x.InnerException)
		except x:
			ConsolePrintException(x)
		
	private def DisplayResults(results as CompilerContext):
		if ShowWarnings:
			DisplayProblems(results.Warnings, WarningColor)
		if not DisplayProblems(results.Errors, ErrorColor):
			ProcessLastValue()

	private def ConsolePrintPrompt():
		ConsolePrintPrompt(true)

	private def ConsolePrintPrompt(autoIndent as bool):
		return if _quit
		indent=-1
		indent = self._indent if autoIndent and CurrentPrompt == BlockPrompt
		WithColor PromptColor:
			Console.Write(self.CurrentPrompt)
		if autoIndent:
			for i in range(self._indent):
				WithColor IndentionColor:
					Console.Write(BooIndention)

	
	private def ConsolePrintMessage(msg as string):
		WithColor InterpreterColor:
			Console.WriteLine( msg )

	private def ConsolePrintException(e as Exception):
		WithColor ExceptionColor:
			Console.WriteLine( e.ToString() )

	private def ConsolePrintError(msg as string):
		WithColor ExceptionColor:
			Console.WriteLine( msg )
			
	private def NewLine():
		Console.Write(Environment.NewLine)
	
	_numberOfDisplayedSuggestions = 10
	protected def ConsolePrintSuggestions():
		cursorLeft = Console.CursorLeft
		#cursorTop = Console.CursorTop
		try:
			NewLine()
					
			i = 0
			count = 0
			suggestions = SuggestionDescriptions()
			suggestionsCount=len(suggestions)
			while self._selectedSuggestionIndex < 0:
				self._selectedSuggestionIndex+=suggestionsCount
			while self._selectedSuggestionIndex >= suggestionsCount:
				self._selectedSuggestionIndex-=suggestionsCount

			for s in suggestions:
				Console.ForegroundColor = SuggestionsColor if not DisableColors
				//Console.Write(", ") if i > 0
				if count >= _numberOfDisplayedSuggestions:
					Console.WriteLine("... (more candidates)")
					break
				if i+_numberOfDisplayedSuggestions/2 >= _selectedSuggestionIndex or i+_numberOfDisplayedSuggestions >= suggestionsCount:
					if count == 0 and i > 0:
						Console.WriteLine("... (more candidates)")					
					if i == _selectedSuggestionIndex:
						Console.ForegroundColor = SelectedSuggestionColor if not DisableColors
					Console.Write(i+1);
					Console.Write(": ");
					Console.WriteLine(s)
					count++
				i++

			Console.ResetColor() if not DisableColors
			#Console.CursorTop = cursorTop
			NewLine()
			ConsolePrintPrompt(false)
			Console.Write(Line)
			Console.CursorLeft = cursorLeft
		except x as Boo.Lang.Exceptions.UserRequestedAbortion:
			WithColor ExceptionColor:
				Console.WriteLine(x.Message)
	
	def SuggestionDescriptions() as (string):
		return array(string, DescriptionFor(s) for s in self._suggestions)
		
	def DescriptionFor(s):
		match s:
			case e = IEntity():
				return Boo.Lang.Interpreter.DescribeEntity(e)
			otherwise:
				return s.ToString()

	protected def WriteToReplace(s as string):
		Console.Write(s)
		_line.Append(s)		

	protected def Indent():
		WithColor IndentionColor:
			Console.Write(BooIndention)
		_indent++

	protected def Unindent():
		return if _indent == 0
		Console.CursorLeft -= self.BooIndentionWidth
		_indent--
	
	private def DeleteInMultilineMode():
	"""
	Delete the last character in multiline mode. This is the least support for edits.
	"""
		return if not self._multiline
		posX=Console.CursorLeft
		return if posX == 0
		_line.Remove(_line.Length-1, 1)
		Console.CursorLeft -= 1
		Console.Write(' ')
		Console.CursorLeft -= 1
	
	protected def Delete(count as int): #if count is 0, forward-delete
		return if LineLen == 0
		cx = Console.CursorLeft-len(CurrentPrompt)-count-LineIndentWidth
		count=1 if cx >= LineLen and count == 0
		return if cx < 0 or cx >= LineLen
		dcount = (count if count != 0 else 1)
		_line.Remove(cx, dcount)
		curX = Console.CursorLeft - count
		Console.CursorLeft = curX
		Console.Write("${_line.ToString(cx, LineLen-cx)} ")
		Console.CursorLeft = curX


	private static re_open = Regex("\\(", RegexOptions.Singleline)
	private static re_close = Regex("\\)", RegexOptions.Singleline)

	def DisplaySuggestions():
		DisplaySuggestions(Line)

	def DisplaySuggestions(query as string):
		return if DisableAutocompletion
		
		self._suggestions = self.GetSuggestionsForCmdArg(query)
		if self._suggestions != null:
			return
		
		#TODO: FIXME: refactor to one regex?
		p_open = re_open.Matches(query).Count
		p_close = re_close.Matches(query).Count
		if p_open > p_close:
			query = query.Split(" ,(\t".ToCharArray(), 100)[-1]
		else:
			query = query.Split(" ,\t".ToCharArray(), 100)[-1]
		if query.LastIndexOf('.') > 0:
			codeToComplete = query[0:query.LastIndexOf('.')+1]
			_filter = query[query.LastIndexOf('.')+1:]
			_suggestions = (
				_interpreter
				.SuggestCompletionsFor(codeToComplete+"__codecomplete__")
				.Select[of (object)](
					{ es | array(e as object for e in es if e.Name.StartsWith(_filter, StringComparison.InvariantCultureIgnoreCase)) })).Value
		else:
			# new feature: we didn't find a fullstop, thus we will list all globals and namespaces
			suggestionList=[]
			self._filter = query
			for globalValue in self._interpreter.Values:
				if globalValue.Key.StartsWith(query, StringComparison.InvariantCultureIgnoreCase):
					suggestionList.Add(globalValue.Key)
			# not to forget the shell commands
			for cmd in self._shellCmdExecution.CollectCmds():
				if cmd.Descr.Name.StartsWith(query, StringComparison.InvariantCultureIgnoreCase):
					suggestionList.Add(cmd)
				else:
					for cmdString in cmd.Descr.Shortcuts:
						if cmdString.StartsWith(query, StringComparison.InvariantCultureIgnoreCase):
							suggestionList.Add(cmd)
							break
			# namespaces to start traversal of the .NET framework and other loaded assemblies
			for nsName in Namespace.GetRootNamespace().NamespacesNames:
				if char.IsLetter(nsName[0]) and nsName.StartsWith(query, StringComparison.InvariantCultureIgnoreCase):
					suggestionList.Add(nsName)
			self._suggestions = suggestionList.ToArray()
		
		if _suggestions is null or 0 == len(_suggestions): #suggest a  var		
			_filter = query
			_suggestions = array(var.Key.ToString() as object
							for var in _interpreter.Values
							if var.ToString().StartsWith(_filter, StringComparison.InvariantCultureIgnoreCase))

		if _suggestions is null or 0 == len(_suggestions):
			_selectedSuggestionIndex = null
			#Console.Beep() #TODO: flash background?
		elif 1 == len(_suggestions):
			ConsolePrintSuggestions() # write the unique valid suggestion to show the signature of the selected entity
			AutoComplete()
		else:
			ConsolePrintSuggestions()


	def AutoComplete():
		raise InvalidOperationException("no suggestions") if _suggestions is null or 0==len(_suggestions) or _selectedSuggestionIndex is null

		Console.CursorLeft = self.LineLen + len(CurrentPrompt)
		Delete(len(_filter)) if _filter != null
		WriteToReplace(self.AutoCompletionFor(_suggestions[_selectedSuggestionIndex.Value]))
		
		_selectedSuggestionIndex = null
		_suggestions = null
		
	def AutoCompletionFor(s):
		builtinCmd = s as CmdDescr
		if builtinCmd == null:
			match s:
				case m = IMethod(Name: name):
					if len(m.GetParameters()) == 0:
						return "$(name)()"
					return "$(name)("
				case IEntity(Name: name):
					return name
				otherwise:
					return s.ToString()
		else:
			return builtinCmd.Descr.Name+' '
	
	private _beforeHistory = string.Empty

	def DisplayHistory():
		if _history.Count == 0 or _historyIndex < 0 or _historyIndex > _history.Count:
			return
		Console.CursorLeft = len(CurrentPrompt)
		Console.Write(string.Empty.PadLeft(LineLen, char(' ')))
		line = _history[_historyIndex].Text
		LineLen = 0
		Console.CursorLeft = len(CurrentPrompt)
		WriteToReplace(line)

	_inMultilineString=false
	def ReadEvalPrintLoop():
		Console.CursorVisible = true
		Console.ForegroundColor = InterpreterColor
		ConsolePrintPrompt()
		while not _quit:
			ReadEvalPrintLoopStep()
		SaveHistory()
		DisplayGoodbye()
		
	private def ReadEvalPrintLoopStep():
		cki = Console.ReadKey(true)
		key = cki.Key
		keyChar = cki.KeyChar
		control = false

		newLine = keyChar in Environment.NewLine
		shiftPressed = (cki.Modifiers & ConsoleModifiers.Shift)==ConsoleModifiers.Shift
		if char.IsControl(keyChar):
			control = true
			if keyChar == char('\t'):
				if shiftPressed or LineLen > 0 and (char.IsLetterOrDigit(LineLastChar) or LineLastChar == char('.')):
					_selectedSuggestionIndex = 0
					DisplaySuggestions()
				else:
					Indent()
			
			# delete the whole line
			if key == ConsoleKey.Escape:
				if self._selectedSuggestionIndex == null:
					curX = len(CurrentPrompt)
					sizeL = _line.Length
					_line.Remove(0, sizeL)
					Console.CursorLeft = curX
					Console.Write(string(' '[0], sizeL))
					Console.CursorLeft = curX
				else:
					self._selectedSuggestionIndex = null
			
			#line-editing support
			if _multiline:
				if key == ConsoleKey.Backspace:
					self.DeleteInMultilineMode()
			elif LineLen > 0 or _indent > 0:
				if Console.CursorLeft > len(CurrentPrompt):
					if key == ConsoleKey.Backspace:
						self._selectedSuggestionIndex = null
						if _indent > 0 and LineLen == 0:
							Unindent()
						elif LineLen > 0:
							Delete(1)
					elif key == ConsoleKey.LeftArrow and not self.CanAutoComplete:
						Console.CursorLeft--
				elif key == ConsoleKey.Backspace and _indent > 0:
					self._selectedSuggestionIndex = null
					Unindent()
				if key == ConsoleKey.Delete and LineLen > 0:
					self._selectedSuggestionIndex = null
					Delete(0)
				elif key == ConsoleKey.RightArrow and not self.CanAutoComplete:
					if Console.CursorLeft < (len(CurrentPrompt)+LineLen):
						Console.CursorLeft++
				elif key == ConsoleKey.Home:
					Console.CursorLeft = len(CurrentPrompt)
				elif key == ConsoleKey.End:
					Console.CursorLeft = len(CurrentPrompt) + LineLen
			
			#auto-completion support
			if CanAutoComplete:
				if key == ConsoleKey.LeftArrow or key == ConsoleKey.UpArrow:
					_selectedSuggestionIndex-- # module will run on displaying
					DisplaySuggestions()
				elif key == ConsoleKey.RightArrow or key == ConsoleKey.DownArrow:
					_selectedSuggestionIndex++ # module will run on displaying
					DisplaySuggestions()
				elif key == ConsoleKey.PageUp:
					self._selectedSuggestionIndex -= 10
					self.DisplaySuggestions()
				elif key == ConsoleKey.PageDown:
					self._selectedSuggestionIndex += 10
					self.DisplaySuggestions()
				if newLine:
					AutoComplete()
					return
			else:
				#history support
				if key == ConsoleKey.UpArrow:
					if _historyIndex > 0:
						_historyIndex--
						DisplayHistory()
						self._selectedSuggestionIndex = null
				elif key == ConsoleKey.DownArrow:
					if _historyIndex < _history.Count-1:
						_historyIndex++
						DisplayHistory()
						self._selectedSuggestionIndex = null
				elif key==ConsoleKey.PageDown:
					self._historyIndex += 10
					self._historyIndex = self._history.Count -1 if self._historyIndex >= self._history.Count
					self.DisplayHistory()
				elif key==ConsoleKey.PageUp:
					self._historyIndex -= 10;
					self._historyIndex =0 if self._historyIndex < 0
					self.DisplayHistory()
			if not newLine:
				return

		_selectedSuggestionIndex = null

		cx = Console.CursorLeft-len(CurrentPrompt)
		#multi-line?
		if cx < 0 or LineLen >= Console.WindowWidth-len(CurrentPrompt):
			cx = LineLen
			_multiline = true

		if not newLine:
			#line-editing support
			if cx < LineLen and not _multiline:
				_line.Insert(cx, keyChar) if not control
				Console.Write(_line.ToString(cx, LineLen-cx))
				Console.CursorLeft = len(CurrentPrompt)+cx+1
			else:
				_line.Append(keyChar) if not control
				Console.Write(keyChar)

		if newLine:
			Console.Write(Environment.NewLine)
			if not TryRunCommand(Line):
				_buffer.Append(self.BooIndention*self._indent)
				_buffer.Append(Line)
				_buffer.Append(Environment.NewLine)

				# unfortunately, brackets are not yet concerned here.
				firstTripleQuote=self.Line.IndexOf("\"\"\"")
				secondTripleQuote=-1
				if firstTripleQuote >= 0:
					secondTripleQuote=self.Line.IndexOf("\"\"\"", firstTripleQuote+3)
				if self._inMultilineString:
					firstTripleQuote, secondTripleQuote = secondTripleQuote, firstTripleQuote
				if (firstTripleQuote >= 0) != (secondTripleQuote >= 0):
					self._inMultilineString = not self._inMultilineString					
				if self._autoIndention:
					if LineLastChar in _blockStarters\
						or Line.EndsWith(QQBegin)\
						or (_indent == 0 and self._inMultilineString): # indent in multiline string
						++self._indent
					elif Line.EndsWith(BooIndention+"pass"):
						--self._indent
				else:
					self._indent = 0
				if Line.EndsWith(QQEnd):
					CheckBooLangCompilerReferenced()
					_indent--

				if shiftPressed or (_indent <= 0 and self._autoIndention and not _inMultilineString):
					_indent = 0
					_inMultilineString=false
					succeeded = false
					expr = _buffer.ToString()
					try:
						context=Eval(expr)
						succeeded = context != null and len(context.Errors)==0
					ensure:
						_buffer.Length = 0 #truncate buffer
					AddToHistory(expr, succeeded)

			_multiline = false
			LineLen = 0 #truncate line
			
			ConsolePrintPrompt()

	[CmdDeclaration("globals g", Description: "Displays a list of all globally defined variables.")]
	def Globals():
		Eval("globals()")
	
	[CmdDeclaration("describe d", Description: "Describes a type (or the type of an object)")]
	public def Describe([CmdArgument(CmdArgumentCompletion.Type)] typeOrObjectOrNamespace):
		nameString = typeOrObjectOrNamespace.ToString()
		ns = Namespace.Find(nameString)
		if ns == null:
			lastDot = nameString.LastIndexOf(".")
			done = false
			if lastDot > 0:
				potTypeName = nameString[:lastDot]
				potMethodName = nameString[lastDot+1:]
				_interpreter.Eval(potTypeName)
				t = _interpreter.LastValue as Type
				if t != null:
					miColl = List[of System.Reflection.MethodInfo]()
					for mi in t.GetMethods():
						if potMethodName.Equals( mi.Name, StringComparison.InvariantCultureIgnoreCase):
							miColl.Add(mi)
					if len(miColl) > 0:
						Boo.Lang.Interpreter.describe(miColl)
						done = true
			if not done:
				Eval("Boo.Lang.Interpreter.describe({0})"%(nameString,))
		else:
			Namespace.ListNamespace(ns, null)
			Namespace.ListTypes(ns)
	
	[CmdDeclaration("list l", Description: "List assemblies and types in assemblies.")]
	public def ListAssemblies(filter as string):
		for a in AppDomain.CurrentDomain.GetAssemblies():
			Console.WriteLine( a.FullName )
			if not string.IsNullOrEmpty(filter) and a.FullName.IndexOf(filter, StringComparison.CurrentCultureIgnoreCase) >= 0:
				for t in a.GetTypes():
					Console.WriteLine( "|"+t.FullName )

	def GetSuggestionsForCmdArg(query as string):
	"""
	Returns a string array of suggestions for the completion
	of a shell command argument or <c>null</c> if query is not
	a shell command.
	"""
		return self._shellCmdExecution.GetSuggestionsForCmdArg(query)
	
	def TryRunCommand(line as string):
	"""
	Run the buitin command as stated by a line string. Return false, if the
	line does not start a builtin command.
	Returns false if no command has been processed, true otherwise.
	"""
		if self._shellCmdExecution.TryRunCommand(line):
			self.AddToHistory(line, true)
			return true
		return false
	
	def TurnOnPreferenceShellCommands():
		self._shellCmdExecution.TurnOnPreferenceShellCommands()
	
	private _indent as int = 0
	[CmdDeclaration("logo", Description:"About this software.")]
	public def DisplayLogo():
		Console.WriteLine(""" ___   __    __               """)
		Console.WriteLine(""" |__| |  |  |oo|     __       """)
		Console.WriteLine(""" |__| |__| |    | | |__  |__| """)
		Console.WriteLine("""           |____| |  __| |  | """)
		Console.WriteLine()		
		WithColor HeadlineColor:
			Console.WriteLine( """Welcome to booish, an interactive interpreter for the boo programming language.""" )
		WithColor InterpreterColor:
			Console.WriteLine( """Copyright (c) 2004-2012, Rodrigo B. de Oliveira (rbo@acm.org)
Copyright (c) 2013-    , Harald Meyer auf'm Hofe (harald_meyer@users.sourceforge.net)""" )
		WithColor HeadlineColor:
			Console.WriteLine( """Running boo ${BooVersion} on ${Boo.Lang.Runtime.RuntimeServices.RuntimeDisplayName}.

Enter boo code in the prompt below (or type /help).""" )
	
	[CmdDeclaration("warn toggleWarning", Description: "Reverse the mode for displaying warnings.")]
	def ToggleWarnings():
		WithColor InterpreterColor:
			if self._showWarnings:
				self._showWarnings=false
				Console.WriteLine("From now on, warnings will NOT be displayed.")
			else:
				self._showWarnings=true
				Console.WriteLine("From now on, warnings will be displayed.")

	[CmdDeclaration("indent toggleAutoIndent", Description: """Reverse auto indention mode.
Auto indention is intended to help you on using the
keyboard to type in BOO statements. Indention increases
on block starting commands and decreases on PASS
automatically. However, this feature will hinder you
if you paste code fragments into the shell. Thus, you
can turn this off.""")]
	def ToggleAutoIndent():
		WithColor InterpreterColor:
			if self._autoIndention:
				self._autoIndention=false
				Console.WriteLine("Auto indention has been turned off. User [SHIFT][RETURN] to leave the editor and execute the command.")
			else:
				self._autoIndention=true
				Console.WriteLine("Auto indention has been turned on.")
	
	[CmdDeclaration("toggle /", Description:"""Toggle the preference w.r.t. shell commands.
If shell commands are not preferred, they have to be introduced
by a slash (e.g. /toggle).""")]
	def TogglePreferenceOnShellCommands():
		self._shellCmdExecution.TogglePreferenceOnShellCommands()

	[CmdDeclaration("help h ?", Description: "Display help.")]
	def DisplayHelp([CmdArgument(CmdArgumentCompletion.TypeOrMethodOrFunction)] filter as string):
		WithColor InterpreterColor:
			Console.Write("""Press TAB or SHIFT+TAB to view a list of suggestions.
	Use CURSOR LEFT, RIGHT, or PAGE UP, PAGE DOWN to select
	suggestions and RETURN to use the selected suggestion.
	Press ESC to leave this mode.
    Use CURSOR UP and DOWN to navigate the history.
    BACKSPACE and DELETE will have the commonly expected effect.
    ESC will delete the current line.
    Type in "h shell" to get additional information on using
    the shell (shell modes, commands, etc.).
    """)
		self._shellCmdExecution.DisplayHelp(filter)

	def DisplayGoodbye():	// booish is friendly
		WithColor HeadlineColor:
			Console.WriteLine()
			Console.WriteLine("All your boo are belong to us!")

	def LoadHistory():
		try:
			using history = File.OpenText(_historyFile):
				while line = history.ReadLine():
					AddToHistory(line, true)
		except:
			ConsolePrintError("Cannot load history from '${_historyFile}'")

	def AddToHistory(line as string, isValid as bool):
		if self._quit: return
		line = line.Replace("\n", "").Replace("\r", "")
		if 0 >= len(line): return
		# line might stem from the history
		if self._historyIndex >= self._history.Count\
			or line != self._history[self._historyIndex].Text:
			while _history.Count >= HISTORY_CAPACITY:
				_history.RemoveAt(0)
				_historyIndex-=1
			_history.Add(HistoryEntry(line, isValid))
			_historyIndex = _history.Count

	def SaveHistory():
		try:
			Directory.CreateDirectory(Path.GetDirectoryName(_historyFile))
			using sw = System.IO.File.CreateText(_historyFile):
				for line in _history:
					if line.IsValid:
						sw.WriteLine(line.Text)
		except exc as Exception:
			ConsolePrintError("Cannot save history to '${_historyFile}':\n${exc.Message}")
	
	[CmdDeclaration("load", Description: """Loads and evals a BOO file. You can also load
assemblies. After loading, the assembly will be referenced
by the interpreter.""")]
	def Load([required] path as string):
		if path.EndsWith(".boo"):
			ConsolePrintMessage("Evaluating '${path}' ...")
			DisplayResults(_interpreter.EvalCompilerInput(Boo.Lang.Compiler.IO.FileInput(path)))
		elif File.Exists(path):
			ConsolePrintMessage("Adding reference to '${path}'")
			try:
				_interpreter.References.Add(System.Reflection.Assembly.LoadFrom(path))
			except e:				
				ConsolePrintException(e)
		else:
			try:
				a=System.Reflection.Assembly.LoadWithPartialName(path)
				_interpreter.References.Add(a)
				ConsolePrintMessage("Adding reference to assembly '${a.FullName}'")
			except e:
				ConsolePrintError("Error adding reference to assembly '${path}'")
				ConsolePrintException(e)
	
	private def ProcessLastValue():
		_ = _interpreter.LastValue
		if _ is not null:
			Console.WriteLine(Boo.Lang.Interpreter.repr(_))
			_interpreter.SetValue("_", _)
	
	[CmdDeclarationAttribute("save", Description: "Save the lines of this session to a file.")]
	def Save([required][CmdArgument(CmdArgumentCompletion.File, DefaultValue:"booish_session.boo")] path as string):
		if not path.EndsWith(".boo"):
			path = "${path}.boo"
		try:
			using sw = System.IO.File.CreateText(path):
				for line in _session:
					sw.Write(line)
			ConsolePrintMessage("Session saved to '${path}'.")
		except:
			ConsolePrintError("Cannot save to '${path}'. Check if path is valid and has correct permissions.")

	private _quit = false
	
	[CmdDeclaration("quit q", Description: "Exits the shell.")]
	def Quit():
		_quit = true
		
	def DisplayProblems(problems as ICollection, color as ConsoleColor):
		return if problems is null or problems.Count == 0
		WithColor color:
			for problem as duck in problems:
				markLocation(problem.LexicalInfo)
				type = ("ERROR" if problem isa CompilerError else "WARNING")
				Console.WriteLine("${type}: ${problem.Message}")
		return true

	private def markLocation(location as Ast.LexicalInfo):
		pos = location.Column
		Console.WriteLine("---" + "-" * pos + "^") if pos > 0
		
	private def CheckBooLangCompilerReferenced():
		return if _blcReferenced
		_interpreter.References.Add(typeof(Boo.Lang.Compiler.CompilerContext).Assembly)
		_blcReferenced = true
		
	_blcReferenced = false