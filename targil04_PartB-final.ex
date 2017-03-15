include std/console.e	-- needed for prompt_string()
include std/text.e -- needed for trim()
include std/regex.e as re -- needed for split() and is_match
include std/filesys.e  --include walk_dir 
include std/wildcard.e  -- needed for is_match
include std/convert.e	-- needed for to_integer
constant OUT = 1, FALSE = 0, TRUE = 1, EOF = -1, UNREADABLE=-1
regex space_re = re:new (`\s`)				--splits the words with white spaces
with trace

sequence operators={"+","-","*","/","&amp;","|","&lt;","&gt;","="}
sequence unaryOp={"-","~"}
sequence kewordConstant={"true","false","null","this"}

sequence fullpath, space=""
integer current_indentation= 0
integer xmlT_fn=UNREADABLE, xml_fn=UNREADABLE		--folder numbers
integer ok				--used as boolean
integer indent=0

sequence currentFileName = ""
integer whileLabelCounter, ifLabelCounter
map classScopeSymbolTable, methodScopeSymbolTable

--begin main:

fullpath = "C:\\Users\\kravi\\Desktop\\targil04\\project 10\\ArrayTest"

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
		space ="\t"
		parser(xmlT_fn,xml_fn)    --send the files to the function that create and write the tokens
		close(xmlT_fn)
		close(xml_fn)
	end if
 
	return 0
end function

function parser(integer xmlT_fn, integer xml_fn)
	object line=gets(xmlT_fn)	-- gets <tokens>
	line=gets(xmlT_fn)	--get <keyword> class </keyword>
	className(line)	--send second line to className grammer
	line=gets(xmlT_fn)	--get last line </tokens>
	return 0
end function

function className(object line)
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
    puts(xml_fn,space&line)	--print <keyword> ('field'|'static') </keyword>
    line=gets(xmlT_fn)			
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <keyword> type </keyword>
    line=gets(xmlT_fn)
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <identifier> varName </identifier>
    line=gets(xmlT_fn)
	
    sequence data = re:split (space_re , line)
    while equal(data[2],",") do
		printf(OUT,space&line)	
        puts(xml_fn,space&line)	--print <symbol> , </symbol>
        line=gets(xmlT_fn)
		printf(OUT,space&line)		
        puts(xml_fn,space&line)	--print <identifier> varName </identifier>
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
	printf(OUT,space&"<subroutineDec>\n")
	puts(xml_fn,space&"<subroutineDec>\n")
	space=""
    indent+=1
	for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT,space&line)		
    puts(xml_fn,space&line)	--print <keyword> ('constructor'|'function'|'method') </keyword>
    line=gets(xmlT_fn)			
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <identifier> ('void'|type) </identifier>
    line=gets(xmlT_fn)
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <identifier> subroutineName </identifier>
    line=gets(xmlT_fn)
	printf(OUT,space&line)
	puts(xml_fn,space&line)	--print <symbol> ( </symbol>
    line=gets(xmlT_fn)
	parameterList(line)		-- send <keyword> type </keyword> to parameterList law
	line=gets(xmlT_fn)
	subroutineBody(line)	-- send <symbol> { </symbol> to soubroutineBody law
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
    line=gets(xmlT_fn)			
	printf(OUT,space&line)
    puts(xml_fn,space&line)	--print <identifier> varName </identifier>
	
	line=gets(xmlT_fn)
    data = re:split (space_re , line)
    while equal(data[2],",") do
		printf(OUT,space&line)
        puts(xml_fn,space&line)	--print <symbol> , </symbol>
        line=gets(xmlT_fn)
		printf(OUT,space&line)
        puts(xml_fn,space&line)	--print <keyword> ('int'|'char'|'boolean'|className) </keyword>
        line=gets(xmlT_fn)
		printf(OUT,space&line)
        puts(xml_fn,space&line)	--print <identifier> varName </identifier>
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

function subroutineBody(object line)
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
    line=gets(xmlT_fn)
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--prints <identifier> varName </identifier>
    line=gets(xmlT_fn)
    sequence data = re:split (space_re , line)
    while equal(data[2],",") do
		printf(OUT, space&line)
        puts(xml_fn,space&line)	--print <symbol> , </symbol>
        line=gets(xmlT_fn)
		printf(OUT, space&line)
        puts(xml_fn,space&line)	--print <identifier> varName </identifier>
        line=gets(xmlT_fn)
        data = re:split (space_re , line)
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
	printf(OUT,space&line)	
    puts(xml_fn,space&line)	--print <identifier> varName </identifier>
	line=gets(xmlT_fn)		--can be [ or =
	sequence data = re:split (space_re , line)
    if equal(data[2],"[") then
		printf(OUT,space&line)	
        puts(xml_fn,space&line)	--print <symbol> [ </symbol>
        line=gets(xmlT_fn)
        line=expression(line)	--send to expression grammer
		printf(OUT,space&line)	--print <symbol> ] </symbol>
        puts(xml_fn,space&line)
        line=gets(xmlT_fn)
        data = re:split (space_re , line)
    end if
	printf(OUT,space&line)
	puts(xml_fn,space&line)	--print print <symbol> = </symbol>
    line=gets(xmlT_fn)
    line=expression(line)	--send to expression grammer
	printf(OUT,space&line)
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
    line=gets(xmlT_fn)
    line=expression(line)	--send to expression grammer
	printf(OUT, space&line)
    puts(xml_fn,space&line)	-- print  <symbol> ) </symbol>
    line=gets(xmlT_fn)
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--print <symbol> { </symbol>
    line=gets(xmlT_fn)
    line=statements(line)	--send to statements grammer
	printf(OUT, space&line)
    puts(xml_fn,space&line)	--print <symbol> } </symbol>
	
	
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
    end if
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--print <symbol> ; </symbol>

	
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
	space=""
    for  i=1  to indent do
        space=space&"\t"
    end for
	printf(OUT, space&line)
	puts(xml_fn,space&line)	--print soubroutineName
    line=gets(xmlT_fn)
	sequence data = re:split (space_re , line)
    if equal(data[2],".") then
		printf(OUT, space&line)
        puts(xml_fn,space&line)
        line=gets(xmlT_fn)
		printf(OUT, space&line)
        puts(xml_fn,space&line)
        line=gets(xmlT_fn)
        data = re:split (space_re , line)
    end if
	printf(OUT, space&line)
    puts(xml_fn,space&line)
    line=gets(xmlT_fn)
    data = re:split (space_re , line)
    if not(equal(data[2],")")) then
        line=expressionList(line)
    else
        puts(xml_fn,space&"<expressionList>\n")
        puts(xml_fn,space&"</expressionList>\n")
    end if
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
        line=gets(xmlT_fn)
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
        data = re:split (space_re , line)
    elsif equal(data[2],"~") then
		printf(OUT, space&line)
        puts(xml_fn,space&line)	--<symbol> ~ </symbol>
        line=gets(xmlT_fn)
        line=term(line)
        data = re:split (space_re , line)
	else
		printf(OUT, space&line)
		puts(xml_fn,space&line)	-- avreything else is a name
        line=gets(xmlT_fn)
        data = re:split (space_re , line)
		if equal(data[2],"[") then
			printf(OUT, space&line)
            puts(xml_fn,space&line)	-- print '['
            line=gets(xmlT_fn)
            line=expression(line)	--send to expression grammer
			printf(OUT, space&line)
            puts(xml_fn,space&line)	--print ']'
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
                line=expressionList(line)
			else --no expressions
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
	end if
		
	
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
		printf(OUT, space&line)
        puts(xml_fn,space&line)	--print ','
        line=gets(xmlT_fn)
        line=expression(line)
        data = re:split (space_re , line)
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

-- map functions