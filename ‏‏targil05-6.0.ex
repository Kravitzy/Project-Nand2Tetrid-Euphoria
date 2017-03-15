include std/console.e	-- needed for prompt_string()
include std/text.e -- needed for trim()
include std/regex.e as re -- needed for split() and is_match
include std/filesys.e  --include walk_dir 
include std/wildcard.e  -- needed for is_match
include std/convert.e	-- needed for to_integer
include std/map.e as ma -- needed for map
constant OUT = 1, FALSE = 0, TRUE = 1, EOF = -1, UNREADABLE=-1
regex space_re = re:new (`\s`)				--splits the words with white spaces
with trace

sequence operators={"+","-","*","/","&amp;","|","&lt;","&gt;","="}
sequence unaryOp={"-","~"}
sequence kewordConstant={"true","false","null","this"}

sequence fullpath, space=""
integer current_indentation= 0
integer xmlT_fn=UNREADABLE, xml_fn=UNREADABLE, vm_fn=UNREADABLE		--folder numbers
integer ok				--used as boolean
integer indent=0
sequence funcName
integer numOfExpression = 0
global sequence currentFileName = "" --will contain the name of the currently compiled .jack file
integer classStaticIndex = -1, classFieldIndex = -1 
integer subArgindex=-1,subVarIndex=-1
integer whileLabelCounter, ifLabelCounter
sequence classOrVarName
global map classScopeSymbolTable, methodScopeSymbolTable

--begin main:

fullpath = "C:\\Users\\kravi\\Desktop\\targil05\\project 11\\runing"

object exit_code = walk_dir(fullpath, routine_id("parse_setup"), FALSE)
prompt_string ("press enter to exit\n")

 
-- end main.

function parse_setup(sequence path_name, sequence item)	--creates xxx.xml file to write, and read xxxT.xml
  	ok=wildcard:is_match("*T.xml",item[D_NAME])
	if (ok) then

		xmlT_fn = open(path_name&"\\"&item[D_NAME],"r") -- read xxxT.xml
		if xmlT_fn = -1 then
			printf(OUT, "Can't open file %s\n", path_name&"\\"&item[D_NAME])
			abort(1)
		end if
		

		sequence trimed=trim_tail(item[D_NAME],"T.xml")

		xml_fn = open(path_name&"\\"&trimed&".xml","w") 	-- create xxx.xml file
		if xml_fn = -1  then
			printf(1, "Can't open file %s\n", path_name&"\\"&item[D_NAME])
			abort(1)
		end if 
		
		vm_fn = open(path_name&"\\"&trimed&".vm","w") 	-- create xxx.vm file
		if vm_fn = -1  then
			printf(1, "Can't open file %s\n", path_name&"\\"&item[D_NAME])
			abort(1)
		end if 
		
		currentFileName = trimed	--will contain the name of the currently compiled .jack file
		
		space ="\t"
		parser(xmlT_fn,xml_fn, vm_fn)    --send the files to the function that create and write the tokens
		close(xmlT_fn)
		close(xml_fn)
		close(vm_fn)
	end if
	
	
 
	return 0
end function

function parser(integer xmlT_fn, integer xml_fn, integer vm_fn)
	object line=gets(xmlT_fn)	-- gets <tokens>
	line=gets(xmlT_fn)	--get <keyword> class </keyword>
	className(line)	--send second line to className grammer
	line=gets(xmlT_fn)	--get last line </tokens>
	return 0
end function

function className(object line)
	classScopeSymbolTable = ma:new()
	printf(OUT,"<class>\n")
    puts(xml_fn,"<class>\n")
    space=""
	indent+=1
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&line)
    puts(xml_fn,space&line)		-- prints:	<keyword> 'class' </keyword>
    line=gets(xmlT_fn)
	printf(OUT,space&line)
    puts(xml_fn,space&line)		--prints:		<identifier> className </identifier>
    line=gets(xmlT_fn)
	printf(OUT,space&line)
    puts(xml_fn,space&line)		--prints	<symbol> { </symbol>
    line=gets(xmlT_fn)		--get ('field' | 'static')
	
	sequence data = re:split (space_re , line)
    while equal(data[2],"static") or equal(data[2],"field") do
        classVarDec(line)	--send ('field' | 'static') to classVarDec grammer
        line=gets(xmlT_fn)
        data = re:split (space_re , line)
    end while

    while equal(data[2],"constructor") or equal(data[2],"function") or equal(data[2],"method") do
		subroutineDec(line)
		line=gets(xmlT_fn)
		data = re:split (space_re , line)
		end while
	printf(OUT,space&line)	
    puts(xml_fn,space&line)	--print <symbol> } </symbol>
    indent-=1
	space=""
	for  i=1  to indent do
        space=space&"\t"
    end for
	line=gets(xmlT_fn)
	printf(OUT,"</class>\n")
    puts(xml_fn,"</class>\n")
	data = re:split (space_re , line)
	if equal(data[1],"</tokens>") then
		printf(OUT,"\n Works! \n")
	end if
    return 0
end function

function classVarDec(object line)
    printf(OUT,space&"<classVarDec>\n")
	puts(xml_fn,space&"<classVarDec>\n")
	space=""
    indent+=1
	for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&line)		
    puts(xml_fn,space&line)	--print <keyword> ('field'|'static') </keyword> -- kind
	sequence data = re:split (space_re , line)
	sequence vKind = data[2]
    line=gets(xmlT_fn)			
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <keyword> type </keyword> -- type
	 data = re:split (space_re , line)
	sequence vType = data[2]
    line=gets(xmlT_fn)
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <identifier> varName </identifier> -- name
	 data = re:split (space_re , line)

	object vName = data[2]
	printf(OUT, "%s", {data[2]})
    line=gets(xmlT_fn)

	if equal(vKind, "field") then
		classFieldIndex+=1
		put(classScopeSymbolTable, {vName}, {vType, vKind, classFieldIndex})	--add to class scope
	else
		classStaticIndex+=1
		put(classScopeSymbolTable, {vName}, {vType, vKind, classStaticIndex})	--add to class scope
	end if
	
	object v = values(classScopeSymbolTable)
    data = re:split (space_re , line)
    while equal(data[2],",") do
		printf(OUT,space&line)	
        puts(xml_fn,space&line)	--print <symbol> , </symbol>
        line=gets(xmlT_fn)
		printf(OUT,space&line)		
        puts(xml_fn,space&line)	--print <identifier> varName </identifier>
		data = re:split (space_re , line)
		vName = data[2]
		if equal(vKind, "field") then
			classFieldIndex+=1
			put(classScopeSymbolTable, {vName}, {vType, vKind, classFieldIndex})	--add to class scope
		else
			classStaticIndex+=1
			put(classScopeSymbolTable, {vName}, {vType, vKind, classStaticIndex})	--add to class scope
		end if
		line=gets(xmlT_fn)
        data = re:split (space_re , line)
    end while
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <symbol> ; </symbol>
	 
	indent-=1
    space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&"</classVarDec>\n")
    puts(xml_fn,space&"</classVarDec>\n")
    return 0
end function

function subroutineDec(object line)
	methodScopeSymbolTable = ma:new()
	subArgindex=-1
	subVarIndex=-1
	ifLabelCounter=0
	whileLabelCounter=0
	printf(OUT,space&"<subroutineDec>\n")
	puts(xml_fn,space&"<subroutineDec>\n")
	space=""
    indent+=1
	for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&line)		
    puts(xml_fn,space&line)	--print <keyword> ('constructor'|'function'|'method') </keyword>
	sequence data = re:split (space_re , line)
	sequence func = data[2]
	
    line=gets(xmlT_fn)			
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <identifier> ('void'|type) </identifier>
	data = re:split (space_re , line)

	sequence fType = data[2]
	
    line=gets(xmlT_fn)
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <identifier> subroutineName </identifier>
	data = re:split (space_re , line)
	sequence fName = data[2]
	
    line=gets(xmlT_fn)
	printf(OUT,space&line)
	puts(xml_fn,space&line)	--print <symbol> ( </symbol>
    line=gets(xmlT_fn)
	if equal(func,"method") then

		subArgindex+=1
		put(classScopeSymbolTable, "this", {currentFileName, "argument", subArgindex})	--add to class scope
	end if
	
	parameterList(line)		-- send <keyword> type </keyword> to parameterList law
	line=gets(xmlT_fn)

	subroutineBody(line, func, fName)	-- send <symbol> { </symbol> to soubroutineBody law
	
	indent-=1
    space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&"</subroutineDec>\n")
    puts(xml_fn,space&"</subroutineDec>\n")
	return 0
end function

function parameterList(object line)	-- did not check on perameters yet


	printf(OUT,space&"<parameterList>\n")
	puts(xml_fn,space&"<parameterList>\n")
	space=""
    indent+=1
	for  i=1  to indent do
        space=space&"\t"
    end for
	sequence data = re:split (space_re , line)
	if equal(data[2], ")") then goto "parameter_end"
	end if
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <keyword> ('int'|'char'|'boolean|className) </keyword>
	data = re:split (space_re , line)
	sequence fType = data[2]

	line=gets(xmlT_fn)			
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <identifier> varName </identifier>
	data = re:split (space_re , line)
	sequence fName = data[2]
	subArgindex+=1
	put(methodScopeSymbolTable, {fName}, {fType, "argument", subArgindex})	--add to class scope
	--printf(vm_fn, "push argument %d\n", {subArgindex})
	line=gets(xmlT_fn)
    data = re:split (space_re , line)
    while equal(data[2],",") do
		printf(OUT,space&line)
        puts(xml_fn,space&line)	--print <symbol> , </symbol>
        line=gets(xmlT_fn)
		printf(OUT,space&line)
        puts(xml_fn,space&line)	--print <keyword> ('int'|'char'|'boolean'|className) </keyword>
		data = re:split (space_re , line)
		fType = data[2]
		
		line=gets(xmlT_fn)
		printf(OUT,space&line)
        puts(xml_fn,space&line)	--print <identifier> varName </identifier>
		data = re:split (space_re , line)
		fName = data[2]
		
		subArgindex+=1
		put(methodScopeSymbolTable, {fName}, {fType, "argument", subArgindex})	--add to class scope
		--printf(vm_fn, "push argument %d\n", {subArgindex})

		
		line=gets(xmlT_fn)
        data = re:split (space_re , line)
    end while

	label "parameter_end"
	indent-=1
    space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&"</parameterList>\n")
    puts(xml_fn,space&"</parameterList>\n")
	printf(OUT,space&line)
	puts(xml_fn,space&line)	--print <symbol> ) </symbol>
    return 0
end function

function subroutineBody(object line, sequence func, sequence fName)


	printf(OUT, space&"<subroutineBody>\n")
	puts(xml_fn, space&"<subroutineBody>\n")
	space=""
    indent+=1
	for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT, space&line)
	puts(xml_fn, space&line)	--print	<symbol> { </symbol>
	line=gets(xmlT_fn)	--gets <keyword> var </keyword> (varDec*)	OR statments
	sequence data = re:split (space_re , line)
    while equal(data[2],"var") do
        varDec(line)	--did not implement yet
        line=gets(xmlT_fn)
        data = re:split (space_re , line)
    end while

	subVarIndex+=1
	--write to vm
	switch func do
		case "constructor" then
			printf(vm_fn, "function %s.%s %d\n", {currentFileName, fName, subVarIndex })
			printf(vm_fn, "push constant %d\n", {classFieldIndex+1})
			puts(vm_fn, "call Memory.alloc 1\n")
			puts(vm_fn, "pop pointer 0\n")
		case "method" then
			printf(vm_fn, "function %s.%s %d\n", {currentFileName, fName, subVarIndex })
			puts(vm_fn, "push argument 0\n")
			puts(vm_fn, "pop pointer 0\n")
		case "function" then
			printf(vm_fn, "function %s.%s %d\n", {currentFileName, fName, subVarIndex })
	end switch	
	
	statements(line)			----contains <statements>(let|if|while|do|return) </statements>
	indent-=1
    space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&"</subroutineBody>\n")
    puts(xml_fn,space&"</subroutineBody>\n")
    return 0
end function

function varDec(object line)	--need to check imlementation
    space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT, space&"<varDec>\n")
    puts(xml_fn,space&"<varDec>\n")
    indent+=1
    space=space&"\t"
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--prints <keyword> 'var' </keyword>
    line=gets(xmlT_fn)
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--prints keyword> type </keyword>
    sequence data = re:split (space_re , line)
    sequence vType=data[2]
    line=gets(xmlT_fn)
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--prints <identifier> varName </identifier>
    data = re:split (space_re , line)
    sequence vName=data[2]
    subVarIndex+=1
    put(methodScopeSymbolTable,{vName},{vType,"local",subVarIndex}) 
    line=gets(xmlT_fn)
    data = re:split (space_re , line)
    while equal(data[2],",") do
		printf(OUT, space&line)
        puts(xml_fn,space&line)	--print <symbol> , </symbol>
        line=gets(xmlT_fn)
		printf(OUT, space&line)
	data = re:split (space_re , line)
	vType=data[2]
        puts(xml_fn,space&line)	--print <identifier> varName </identifier>
        line=gets(xmlT_fn)
        data = re:split (space_re , line)
         vName=data[2]
         subVarIndex+=1
          put(methodScopeSymbolTable,{vName},{vType,"local",subVarIndex})
    end while
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--print <symbol> ; </symbol>
    indent-=1
    space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT, space&"</varDec>\n")
    puts(xml_fn,space&"</varDec>\n")
    return 0
end function

function statements(object line)
    space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT, space&"<statements>\n")
	puts(xml_fn, space&"<statements>\n")
	sequence data = re:split (space_re , line)

    while (equal(data[2],"let") or equal(data[2],"if") or equal(data[2],"while") or equal(data[2],"do") or equal(data[2],"return") ) do

		if equal(data[2],"let") then
			letStatement(line)
			line=gets(xmlT_fn)
			data = re:split (space_re , line)
      elsif equal(data[2],"if") then
          line= ifStatment (line)
          data = re:split (space_re , line)
      elsif equal(data[2],"while") then
          line=whileStatment(line)
          line=gets(xmlT_fn)
          data = re:split (space_re , line)
      elsif equal(data[2],"do") then

          doStatment(line)
          line=gets(xmlT_fn)
          data = re:split (space_re , line)
      elsif equal(data[2],"return") then
          returnStatment(line)
          line=gets(xmlT_fn)
          data = re:split (space_re , line)
		end if
    end while

	printf(OUT,space&"</statements>\n")
    puts(xml_fn,space&"</statements>\n")
	printf(OUT,space&line)	
	puts(xml_fn,space&line)	--used to print } didnt think was supposed to be here
    return 0
end function

function letStatement(object line)
    sequence data
    object val
	indent+=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
    printf(OUT,space&"<letStatement>\n")
	puts(xml_fn,space&"<letStatement>\n")
	indent+=1
	space=space&"\t"
	printf(OUT,space&line)	--print <keyword> let </keyword>
	puts(xml_fn,space&line)
	line=gets(xmlT_fn)
	printf(OUT,space&line)	-- varname

	object names = re:split (space_re , line)
	data = re:split (space_re , line)
	sequence vName=data[2]
    puts(xml_fn,space&line)	--print <identifier> varName </identifier>
        integer ok=has(methodScopeSymbolTable, vName)
        if ok then
            val=get(methodScopeSymbolTable, vName)
        end if
	line=gets(xmlT_fn)		--can be [ or =
        data = re:split (space_re , line)
    if equal(data[2],"[") then
		printf(OUT,space&line)	
        puts(xml_fn,space&line)	--print <symbol> [ </symbol>
        line=gets(xmlT_fn)
        printf(vm_fn, "push %s %d\n", {val[2], val[3]})  --write push
        printf(vm_fn, "add\n")
        line=expression(line)	--send to expression grammer
		printf(OUT,space&line)	--print <symbol> ] </symbol>
        puts(xml_fn,space&line)
		printf(vm_fn, "pop temp 0\n")
		printf(vm_fn, "pop pointer 1\n")
		printf(vm_fn, "push temp 0\n")
		printf(vm_fn, "pop that 0\n")
        line=gets(xmlT_fn)
        data = re:split (space_re , line)
    end if
	
	printf(OUT,space&line)
	puts(xml_fn,space&line)	--print print <symbol> = </symbol>
	
    line=gets(xmlT_fn)

	
	
    line=expression(line)	--send to expression grammer
	printf(OUT,space&line)
	
    data = re:split (space_re , line)
 	

	ok = has(methodScopeSymbolTable, {names[2]})	--1 if exists o if not
	if ok then
		val = get(methodScopeSymbolTable, {names[2]})
		printf(vm_fn, "pop %s %d\n", {val[2],val[3]}) --val[2]=kind, val[3]=#index
	else	--didnt check if exists in class, im assuming the program is legal!
		val = get(classScopeSymbolTable, {names[2]})
		if	equal(val[2], "field") then
			printf(vm_fn, "pop this %d\n", {val[3]}) --val[3]=#index
		else
			printf(vm_fn, "pop static %d\n", {val[3]}) --val[3]=#index
		end if
	end if		
	

	puts(xml_fn,space&line)	--print <symbol> ; </symbol>
    
	indent-=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
    printf(OUT,space&"</letStatement>\n")	
	puts(xml_fn,space&"</letStatement>\n")
	indent-=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	return 0
end function


function ifStatment(object line)
    integer counter=ifLabelCounter
    ifLabelCounter+=1
	indent+=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&"<ifStatement>\n")
    puts(xml_fn,space&"<ifStatement>\n")
	integer this_indent = indent	-- trick- didnt know why indent didn't work at end of </ifStatement>
	space = space&"\t"
	indent+=1
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--print <keyword> if </keyword>
    line=gets(xmlT_fn)
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--print <symbol> ( </symbol>
    line=gets(xmlT_fn)
	line=expression(line)		-- send to expression grammer
	printf(vm_fn,"not\n")
	printf(vm_fn, "if-goto IF_FALSE%d\n", {counter})
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--print <symbol> ) </symbol>
    line=gets(xmlT_fn)	
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--printe <symbol> { </symbol>
    line=gets(xmlT_fn)	
	line=statements(line)	--send to statment grammer
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--print <symbol> } </symbol>
	line=gets(xmlT_fn)
	printf(vm_fn, "goto IF_TRUE%d\n", {counter})
        printf(vm_fn, "label IF_FALSE%d\n", {counter})
	sequence data = re:split (space_re , line)
    if equal(data[2],"else") then
		printf(OUT, space&line)
        puts(xml_fn,space&line)
        line=gets(xmlT_fn)
		printf(OUT, space&line)
        puts(xml_fn,space&line)
        line=statements(line)
		printf(OUT, space&line)
        puts(xml_fn,space&line)
        line=gets(xmlT_fn)
        printf(vm_fn, "label IF_TRUE%d\n", {counter})
    end if
	indent-=1
	space=""
    for  i= 1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&"</ifStatement>\n")
	puts(xml_fn,space&"</ifStatement>\n")
	indent-=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	return line
end function

function whileStatment(object line)
    integer counter=whileLabelCounter
    whileLabelCounter+=1
	indent+=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT, space&line)
    puts(xml_fn,space&"<whileStatement>\n")
	space=space&"\t"
	indent+=1
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--print <keyword> while </keyword>
    line=gets(xmlT_fn)
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--print <symbol> ( </symbol>
    printf(vm_fn, "labet WHILE_EXP%d", {counter})
    line=gets(xmlT_fn)
    line=expression(line)	--send to expression grammer
	printf(OUT, space&line)
    printf(vm_fn, "not\n")
    printf(vm_fn, "if-goto WHILE_END%d\n", {counter})
    puts(xml_fn,space&line)	-- print  <symbol> ) </symbol>
    line=gets(xmlT_fn)
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--print <symbol> { </symbol>
    line=gets(xmlT_fn)
    line=statements(line)	--send to statements grammer
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--print <symbol> } </symbol>
    printf(vm_fn, "goto WHILE_EXP%d\n", {counter})
    printf(vm_fn, "label WHILE_END%d\n", {counter})
	
	indent-=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
    printf(OUT,space&"</whileStatement>\n")	
	puts(xml_fn,space&"</whileStatement>\n")
	indent-=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	return 0
end function

function doStatment(object line)
	indent+=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT, space&"<doStatement>\n")
    puts(xml_fn,space&"<doStatement>\n")
	space=space&"\t"
	indent+=1
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--print <keyword> do </keyword>
	line=gets(xmlT_fn)
    subroutineCall(line)	--send to soubroutineCall
    line=gets(xmlT_fn)
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--print <symbol> ; </symbol>
    printf(vm_fn, "pop temp 0\n")
	
	indent-=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
    printf(OUT,space&"</doStatement>\n")	
	puts(xml_fn,space&"</doStatement>\n")
	indent-=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	return 0
end function

function returnStatment(object line)
--trace(1)
	indent+=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT, space&"<returnStatement>\n")
    puts(xml_fn,space&"<returnStatement>\n")
	space=space&"\t"
	indent+=1
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--print <keyword> return </keyword>
	line=gets(xmlT_fn)
	sequence data = re:split (space_re , line)
	if not(equal(data[2],";")) then	--mat or may not have arguments to return
            line=expression(line)
        else printf(vm_fn, "push constant 0\n")
    end if
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--print <symbol> ; </symbol>
        printf(vm_fn, "return\n")
	
	indent-=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
    printf(OUT,space&"</returnStatement>\n")	
	puts(xml_fn,space&"</returnStatement>\n")
	indent-=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	return 0
end function

function subroutineCall(object line)
    integer numOfArgs=0
    sequence subroutineFullName
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--print soubroutineName
	sequence data = re:split (space_re , line)
	classOrVarName=data[2]
	funcName = data[2]
    line=gets(xmlT_fn)
	data = re:split (space_re , line)
    if equal(data[2],".") then
		printf(OUT, space&line)
        puts(xml_fn,space&line)
        line=gets(xmlT_fn)
		printf(OUT, space&line)
        puts(xml_fn,space&line)
        data = re:split (space_re , line)
        funcName=data[2]
        line=gets(xmlT_fn)
        data = re:split (space_re , line)
        
        integer ok=has(methodScopeSymbolTable,classOrVarName)
        if ok then
            object val=get(methodScopeSymbolTable,classOrVarName)
            subroutineFullName=val[1]&"."&funcName
            printf(vm_fn,"push %s %d\n", {val[2], val[3]})
            numOfArgs+=1
        elsif has(classScopeSymbolTable, classOrVarName) then
        object val=get(classScopeSymbolTable, classOrVarName)
        subroutineFullName=val[1]&"."&funcName
        printf(vm_fn,"push %s %d\n", {val[2], val[3]})
        numOfArgs+=1
        else subroutineFullName=classOrVarName&"."&funcName
		numOfArgs+=1
        end if
    else 
        subroutineFullName=currentFileName&"."&funcName
        printf(vm_fn, "push pointer 0\n")
        numOfArgs+=1
    end if
	printf(OUT, space&line)
    puts(xml_fn,space&line)

    line=gets(xmlT_fn)
    data = re:split (space_re , line)
    if not(equal(data[2],")")) then
        line=expressionList(line)
        numOfArgs+=numOfExpression
    else
        puts(xml_fn,space&"<expressionList>\n")
        puts(xml_fn,space&"</expressionList>\n")
    end if
--trace(1)
    printf(vm_fn, "call %s %d\n", {subroutineFullName, numOfArgs})
	printf(OUT, space&line)
    puts(xml_fn,space&line)
	return 0
end function

function expression(object line)
    printf(OUT,space&"<expression>\n")
    puts(xml_fn,space&"<expression>\n")
    line=term(line)	--send to term grammer
	sequence data = re:split (space_re , line)
	while not(find(data[2],operators)=FALSE) do
		printf(OUT, space&line)
        puts(xml_fn,space&line)	--print <symbol> op </symbol>
		
		object op = data[2]
		trace(1)
		line=gets(xmlT_fn)
		line = term(line)
		data = re:split (space_re , line)
		switch op do
			case "+" then
				printf(vm_fn, "add\n")
			case "-" then
				printf(vm_fn, "sub\n")
			case "*" then
				printf(vm_fn, "callMath.multiply 2\n")
			case "/" then
				printf(vm_fn, "callMath.divide 2\n")
			case "&amp" then
				printf(vm_fn, "and\n")
			case "|" then
				printf(vm_fn, "or\n")
			case "&lt" then
				printf(vm_fn, "lt\n")
			case "&gt" then
				printf(vm_fn, "gt\n")
			case "=" then
				printf(vm_fn, "eq\n")
		end switch	 
		trace(1)
		--if equal(data[2],',') then
        line=gets(xmlT_fn)
		--end if
        line=term(line)	--send to term grammer
        data = re:split (space_re , line)
    end while	
	printf(OUT,space&"</expression>\n")
    puts(xml_fn,space&"</expression>\n")
    return line
end function


function term(object line)

	indent+=1
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&"<term>\n")
    puts(xml_fn,space&"<term>\n")	
	space=space&"\t"
    indent+=1
	sequence data = re:split (space_re , line)
	sequence vName = data[2] --<<
	sequence wordType
	
	
	
	if equal(data[1], "<keyword>") then
		wordType = "keyword"
	elsif	equal(data[1], "<symbol>") then
		wordType = "symbol"
	elsif	equal(data[2], "&quot") then
		wordType = "stringConstant"
	elsif integer(data[2]) then
		wordType = "integerConstant"
	else
		wordType = "identifier"	
	end if
	
	switch wordType do
		case "integerConstant" then
			printf(vm_fn, "push constant %d\n", {data[2]})	
		case "stringConstant" then
			line=gets(xmlT_fn)	--get the string
			data = re:split (space_re , line)
			integer strLen = length(data[2])
			object word = data[2]
			object char
			--write allocation of mem for new string
			printf(vm_fn, "push constant %d\n", {strLen})
			printf(vm_fn, "call String.new 1\n")
			--write assignment of string constant to allocated mem
			for i=1 to strLen do
				char = word[i]
				printf(vm_fn, "push constant %d\n", {char})
				printf(vm_fn, "call String.appendChar 2\n")
			end for
		case "keyword" then	
			if equal(data[2], "false") or equal(data[2], "null") then
				printf(vm_fn, "push constant 0\n")
			elsif equal(data[2], "true") then
				printf(vm_fn, "push constant 0\n")
				printf(vm_fn, "not\n")
			elsif equal(data[2], "this") then
				printf(vm_fn, "push pointer 0\n")
			end if
			line=gets(xmlT_fn)
		case "symbol" then
			if equal(data[2],"(") then		-- '(' expression ')'	
				printf(OUT, space&line)
				puts(xml_fn,space&line)	-- <symbol> ( </symbol>
				line=gets(xmlT_fn)
				line=expression(line)
				printf(OUT, space&line)
				puts(xml_fn,space&line)	-- <symbol> ) </symbol>
				line=gets(xmlT_fn)
				data = re:split (space_re , line)
			elsif equal(data[2],"-") then
				printf(OUT, space&line)
				puts(xml_fn,space&line)	--<symbol> - </symbol>
				line=gets(xmlT_fn)
				line=term(line)		--send to term grammer
				printf(vm_fn, "neg\n")
				data = re:split (space_re , line)
			elsif equal(data[2],"~") then
				printf(OUT, space&line)
				puts(xml_fn,space&line)	--<symbol> ~ </symbol>
				line=gets(xmlT_fn)
				line=term(line)
				printf(vm_fn, "not\n")
				data = re:split (space_re , line)
			end if

		case "identifier" then
			printf(OUT, space&line)
			puts(xml_fn,space&line)	-- avreything else is a name
			line=gets(xmlT_fn)	--get next word
			data = re:split (space_re , line)
			object val
			switch data[2] do
				case "[" then --need to check this!
					ok = has(methodScopeSymbolTable, {vName})	--1 if exists o if not
					if ok then
						val = get(methodScopeSymbolTable, {vName})
						printf(vm_fn, "push %s %d\n", {val[2],val[3]}) --val[2]=kind, val[3]=#index
					else	--didnt check if exists in class, im assuming the program is legal!
						val = get(classScopeSymbolTable, {vName})
						if	equal(val[2], "field") then
							printf(vm_fn, "push this %d\n", {val[3]}) --val[3]=#index
						else
							printf(vm_fn, "push static %d\n", {val[3]}) --val[3]=#index
						end if
					end if		
					line=expression(line)	--send to expression grammer
					printf(OUT, space&line)
					puts(xml_fn,space&line)	--print ']'
					printf(vm_fn, "add\n")
					printf(vm_fn, "pop pointer 1\n")
					printf(vm_fn, "push that 0\n")
					line=gets(xmlT_fn)
					data = re:split (space_re , line)
				case "(" then
					subroutineCall(vName)					
				case "." then
				line=gets(xmlT_fn)
					subroutineCall(line)
				case else 
					ok = has(methodScopeSymbolTable, {vName})	--1 if exists o if not
					if ok then
				
						val = get(methodScopeSymbolTable, {vName})
						printf(vm_fn, "push %s %d\n", {val[2],val[3]}) --val[2]=kind, val[3]=#index
					else	--didnt check if exists in class, im assuming the program is legal!
		
						val = get(classScopeSymbolTable, {vName})
						if	equal(val[2], "field") then
						-->
							printf(vm_fn, "push this %d\n", {val[3]}) --val[3]=#index
							
						else
							printf(vm_fn, "push static %d\n", {val[3]}) --val[3]=#index
						end if
					end if		
			
			end switch
		
			if equal(data[2],"[") then
				--object vals = get()
				printf(OUT, space&line)
				puts(xml_fn,space&line)	-- print '['
				line=gets(xmlT_fn)	-- get the word
				data = re:split (space_re , line)
				object word = data[2]
				integer ok = has(methodScopeSymbolTable, word)	--1 if exists o if not
				if ok then
					val = get(methodScopeSymbolTable, word)
					printf(vm_fn, "push %s %s\n", {val[2],val[3]}) --val[2]=kind, val[3]=#index
				else	--didnt check if exists in class, im assuming the program is legal!
					val = get(classScopeSymbolTable, word)
					if	equal(val[2], "field") then
	
						printf(vm_fn, "push this %s\n", {val[3]}) --val[3]=#index
					else
						printf(vm_fn, "push static %s\n", {val[3]}) --val[3]=#index
					end if
				end if			
							
				line=expression(line)	--send to expression grammer
				printf(OUT, space&line)
				puts(xml_fn,space&line)	--print ']'
				printf(vm_fn, "add\n")
				printf(vm_fn, "pop pointer 1\n")
				printf(vm_fn, "push that 0\n")
				line=gets(xmlT_fn)
				data = re:split (space_re , line)
			elsif equal(data[2],".") then
				printf(OUT, space&line)
				puts(xml_fn,space&line)	--print '.'
				line=gets(xmlT_fn)
				printf(OUT, space&line)
				puts(xml_fn,space&line)	--print subroutineName
				line=gets(xmlT_fn)
				printf(OUT, space&line)
				puts(xml_fn,space&line)	--print '('
				line=gets(xmlT_fn)
				data = re:split (space_re , line)
				if not(equal(data[2],")")) then
					numOfExpression = 1

					line=expressionList(line)
				else --no expressions
									numOfExpression=0
					puts(OUT,space&"<expressionList>\n")
					puts(OUT,space&"</expressionList>\n")
					puts(xml_fn,space&"<expressionList>\n")
					puts(xml_fn,space&"</expressionList>\n")
				end if
				printf(OUT, space&line)
				puts(xml_fn,space&line)	--print ')'
				line=gets(xmlT_fn)
			--elsif equal(data[2],")") then
			--need to check about subname '(' expressionlist ')'
			end if
		
	end switch
	
	indent-=1
    space=""
    for  i=1 to indent do
        space=space&"\t"
    end for
	printf(OUT,space&"</term>\n")
    puts(xml_fn,space&"</term>\n")
	indent-=1
	space=""
    for  i=1 to indent do
        space=space&"\t"
    end for
    return line
end function

function expressionList(object line)
	printf(OUT,space&"<expressionList>\n")
    puts(xml_fn,space&"<expressionList>\n")
	space=space&"\t"
    indent+=1
	line=expression(line)
	sequence data = re:split (space_re , line)
    while equal(data[2],",") do
--trace(1)
		numOfExpression += 1
		printf(OUT, space&line)
        puts(xml_fn,space&line)	--print ','
        line=gets(xmlT_fn)
        line=expression(line)
        data = re:split (space_re , line)
		if not(equal(data[2],",")) then
			numOfExpression += 1
		end if
    end while
	indent-=1
    space=""
    for  i=1 to indent do
        space=space&"\t"
    end for
	printf(OUT,space&"</expressionList>\n")
    puts(xml_fn,space&"</expressionList>\n")
    return line
end function
