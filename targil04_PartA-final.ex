include std/console.e	-- needed for prompt_string()
include std/text.e -- needed for trim()
include std/regex.e as re -- needed for split() and is_match
include std/filesys.e  --include walk_dir 
include std/wildcard.e  -- needed for is_match
include std/convert.e	-- needed for to_integer

with trace

constant IN = 0, OUT = 1, FALSE = 0, TRUE = 1, EOF = -1
--sequence keyword = {'class','constructor','function','method','field','static','var','int','char','boolean','void','true','false','null','this','let','do','if','else','while','return'}
sequence keyword = {"class","constructor","function","method","field","static","var","int","char","boolean","void","true","false","null","this","let","do","if","else","while","return"}
sequence symbol = {"{","}","(",")","[","]",".",",",";","+","-","*","/","&","|","<",">","=","~"}
sequence asciiSymbol = {'{','}','(',')','[',']','.',',',';','+','-','*','/','&','|','<','>','=','~'}
sequence fullpath
sequence func, param1, param2
sequence filename, foldername
sequence funcname=""
sequence parse, labelNo
sequence merge_asm_fullpath = ""		-- will be after init .../Folder/targil/targil.asm 
integer labelCounter=0
integer ok
integer sys_exists = FALSE
integer fn_merge
constant re_proper_name = re:new("[A-Z][a-z]+ [A-Z][a-z]+")

-----------------------------------
----------------------------------- Main:
	trace(0)
	fullpath = prompt_string ("enter full path name to use:\n CASE SENSITIVE!\n")
	object exit_code = walk_dir(fullpath, routine_id("create_xml_files"), TRUE)     --translate each vm file that exist in the directory
	
--	object exit_code1=walk_dir(fullpath,routine_id("sysExist"),TRUE)				--checks if folder contains Sys.vm	
	if equal(sys_exists, TRUE) then
		regex backslash_re = re:new (`\\`)								--how to split the words
		sequence data2 = re: split (backslash_re , fullpath)		--splits fullpath in order to get the last element
		integer last = length(data2)										--gives size of data2
		sequence thisfile = data2[last]									--gives us last element(filename.vm)
		foldername = trim_tail(fullpath, thisfile)					--gives the current folder		
		filename = trim_tail(thisfile, ".jack")							--trims the filename.vm-->filename
		
--		merge_asm_fullpath = foldername&filename&"\\"&filename&".asm"
--		fn_merge = open( merge_asm_fullpath, "w") 	-- creates filename.asm file if doesn"t exists
--		if (fn_merge) = -1  then
--					printf(1, "Can't open file %s\n", {fullpath})
					abort(1)
		--end if
--		printf(fn_merge,"@261\nD=A\n@SP\nM=D\n\n")
--		object exit_code2=walk_dir(fullpath, routine_id("write_Sys_asm_file"), TRUE)     --write the Sys.asm file at the beggining of the mearge asm file  
--		object exit_code3 = walk_dir(fullpath, routine_id("merge_asm_files"), TRUE)    --mearge all the asm files that exist in the directory to one asm file
		
	end if
	
--	close(fn_merge)

	any_key ("\n   Press any key to close this Window... ")

-----------------------------------
----------------------------------- End main.


-----------------------------------
----------------------------------- System Functions:

function create_xml_files(sequence path_name, sequence item) 
	ok=wildcard:is_match("*.jack",item[D_NAME])
	if ok then
		integer jack_fn = open(fullpath&"\\"&item[D_NAME],"r")
		
		if jack_fn = -1 then
			printf(OUT, "Can't open file %s\n", {fullpath})
			abort(1)
		end if
		
		sequence tmp=trim_tail(item[D_NAME],".jack")
		integer xml_fn = open(fullpath&"\\"&tmp&"T.xml","w") 	-- create xml file
		if xml_fn = -1  then
			printf(1, "Can't open file %s\n", {fullpath})
			abort(1)
		end if
		integer jack_fnFix = open(fullpath&"\\"&item[D_NAME]&"FIX","w")
		trace(0)
		makeSpacesAtSymbol(jack_fn,jack_fnFix)
		trace(0)
		integer readJack_fnFix = open(fullpath&"\\"&item[D_NAME]&"FIX","r")
		fromJacktoXML(xml_fn, readJack_fnFix,tmp)
		close(readJack_fnFix)
		close(xml_fn)
		delete_file (fullpath&"\\"&item[D_NAME]&"FIX")
	end if
		
	return 0
end function

function fromJacktoXML(integer xml_fn, integer jack_fnFix, sequence tmp)
puts(xml_fn,"<tokens>\n")
	object line   														
	
	while sequence(line) entry do	
		regex space_re = re:new (`\s`)								--how to split the words
		 sequence data = re: split (space_re , line)														
		integer  len = length(data)
	
		
		for i = 1 to len do
		object token = data[i]
		if equal(token, {}) then
		continue
		end if
trace(0)
			if equal(token,"/") and equal(data[i+2],"/") then
			exit
			end if
			
			if equal(token,"/") and equal(data[i+2],"*") then
				skipCommet(jack_fnFix)
			exit
			end if
		trace(0)
		integer isSymbol = (find(token,symbol))			
		if isSymbol != 0  then
			puts(xml_fn,"<symbol> "&token&" </symbol>\n")
			else				
			if not(equal(find(data[i],keyword),0))  then
				puts(xml_fn,"<keyword> "&token&" </keyword>\n")
				else
				if equal(isNumber(token),"true") then
					puts(xml_fn,"<integerConstant> "&token&" </integerConstant>\n")
					else
								if equal(isString(token),"true") then
									object tempString = trim_head(token,'"')
									object string = trim_tail(tempString,'"')
									puts(xml_fn,"<stringConstant> "&string&" </stringConstant>\n")
									else
										if equal(isDigit(token[1]),"true") then
										continue
										else
											puts(xml_fn,"<identifier> "&token&" </identifier>\n")
										end if
								end if
							
				end if		
			end if					
		end if			
		end for	
														
	entry												-- first iteration starts here
		line = gets(jack_fnFix)
	end while
	
	
puts(xml_fn,"</tokens>\n")	
	return 0
end function

function makeSpacesAtSymbol(integer jack_fn,integer jack_fnFix)
object char   														
	while not(equal(char,-1)) entry do
	integer isSymbol = find(char,asciiSymbol)
	if isSymbol = 0 then
		puts(jack_fnFix,char)
	else
		puts(jack_fnFix," "&char&" ")
	end if
	entry												-- first iteration starts here
		char = getc(jack_fn)
	end while
	close(jack_fnFix)
	return 0
end function

function isDigit(object char)
	if char > 47 and char < 58 then
		return "true"
	else
		return "false"
	end if
end function
function isNumber(object word)
	integer  wordLen = length(word)
	for i = 1 to wordLen do
		if equal(isDigit(word[i]),"false") then
			return "false"
		end if
	end for
	return "true"
	
end function	

function isString(object word)
	integer  wordLen = length(word)
		if equal(word[1],'"') and equal(word[wordLen],'"') then
			return "true"
		else
			return "false"
		end if
end function	

function skipCommet(integer jack_fnFix)
	object line1   														-- the next line from the file
	while sequence(line1) entry do	
		regex space_re = re:new (`\s`)								--how to split the words
		 sequence data1 = re: split (space_re , line1)														--first element in line
		integer  len1 = length(data1)
for i = 1 to len1 do
if equal(data1[i], {}) then
		continue
		end if
trace(0)
			
			
			if equal(data1[i],"*") and equal(data1[i+2],"/") then
				return 0
			end if
end for
	entry												-- first iteration starts here
		line1 = gets(jack_fnFix)
	end while
return 0	
end function