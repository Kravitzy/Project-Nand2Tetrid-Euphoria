
-- C:\Euphoria\bin\programs\targil01\SimpleAdd.vm


include std/console.e	-- needed for prompt_string()
include std/text.e -- needed for trim()
include std/regex.e as re -- needed for split() and is_match
include std/filesys.e  --include walk_dir 
include std/wildcard.e  -- needed for is_match
include std/convert.e	-- needed for to_integer

with trace

constant IN = 0, OUT = 1, FALSE = 0, TRUE = 1, EOF = -1


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


-----------------------------------
----------------------------------- Main:
	
	
	fullpath = prompt_string ("enter full path name to use:\n CASE SENSITIVE!\n")
	object exit_code = walk_dir(fullpath, routine_id("translate_vm_files"), TRUE)     --translate each vm file that exist in the directory
	
	object exit_code1=walk_dir(fullpath,routine_id("sysExist"),TRUE)				--checks if folder contains Sys.vm	
	if equal(sys_exists, TRUE) then
		regex backslash_re = re:new (`\\`)								--how to split the words
		sequence data2 = re: split (backslash_re , fullpath)		--splits fullpath in order to get the last element
		integer last = length(data2)										--gives size of data2
		sequence thisfile = data2[last]									--gives us last element(filename.vm)
		foldername = trim_tail(fullpath, thisfile)					--gives the current folder		
		filename = trim_tail(thisfile, ".vm")							--trims the filename.vm-->filename
		
		merge_asm_fullpath = foldername&filename&"\\"&filename&".asm"
		fn_merge = open( merge_asm_fullpath, "w") 	-- creates filename.asm file if doesn't exists
		if (fn_merge) = -1  then
					printf(1, "Can't open file %s\n", {fullpath})
					abort(1)
		end if
		printf(fn_merge,"@261\nD=A\n@SP\nM=D\n\n")
		object exit_code2=walk_dir(fullpath, routine_id("write_Sys_asm_file"), TRUE)     --write the Sys.asm file at the beggining of the mearge asm file  
		object exit_code3 = walk_dir(fullpath, routine_id("merge_asm_files"), TRUE)    --mearge all the asm files that exist in the directory to one asm file
		
	end if
	
	close(fn_merge)
	any_key ("\n   Press any key to close this Window... ")
-----------------------------------
----------------------------------- End main.


-----------------------------------
----------------------------------- System Functions:

function sysExist(sequence path_name, sequence item)    --count how many vm files are exist
        ok=wildcard:is_match("Sys.vm",item[D_NAME])
        if ok then
			sys_exists = TRUE
        end if
        return 0
end function

function translate_vm_files(sequence path_name, sequence item) -- translate all the vm fles that exist in the directory to hack
	ok=wildcard:is_match("*.vm",item[D_NAME])
	if ok then
		integer vm_fn = open(fullpath&"\\"&item[D_NAME],"r")
		
		if vm_fn = -1 then
			printf(OUT, "Can't open file %s\n", {fullpath})
			abort(1)
		end if
		
		sequence tmp=trim_tail(item[D_NAME],".vm")
		integer asm_fn = open(fullpath&"\\"&tmp&".asm","w") 	-- create .asm file
		if asm_fn = -1  then
			printf(1, "Can't open file %s\n", {fullpath})
			abort(1)
		end if 
		fromVMtoHACK(asm_fn, vm_fn,tmp)
	end if
	return 0
end function



function write_Sys_asm_file(sequence path_name, sequence item) -- write the Sys.asm file at the beggining of the merge asm file

	if  wildcard:is_match("Sys.asm",item[D_NAME]) then
		integer sys_asm_Num=open(path_name&"\\Sys.asm","r")
		if sys_asm_Num = -1 then
			printf(1, "Can't open file %s\n", {fullpath})
			abort(1)
		end if 
			
		while TRUE do				--copy line by line from Sys.asm to merge.asm 
			object line = gets(sys_asm_Num)
			if atom(line) then
				exit
			end if
			puts(fn_merge,line) 
		end while
		puts(fn_merge,"\n")
	end if
	return 0
end function

function merge_asm_files(sequence path_name, sequence item) -- merge all thw asm files to one asm file
	ok= wildcard:is_match("*.asm",item[D_NAME]) 
	if ok then	
		integer check = equal(item[D_NAME],"Sys.asm")
		if not(check) then
			integer fn_asm_num=open(path_name&"\\"&item[D_NAME],"r")
			if fn_asm_num = -1 then
				printf(1, "Can't open file %s\n", {fullpath})
				abort(1)
			end if 
								
			while TRUE do
				object line= gets(fn_asm_num)
				if atom(line) then
					exit
				end if
				puts(fn_merge,line) 
			end while
			puts(fn_merge,"\n")
		end if
	end if
	return 0
end function
	
function fromVMtoHACK(integer fn_asm, integer fn_vm, sequence tmp)
	object line   														-- the next line from the file
	while sequence(line) entry do										-- exits while when line = -1
		regex space_re = re:new (`\s`)								--how to split the words
		sequence data = re: split (space_re , line)		
		func = data[1]												--first element in line
		integer  len = length(data)									--check the ammount of words in command
		
		if equal(func, {}) then										--check if line is empty
			--do nothing, line is empty
		else
			switch data[1] do
					--length1:
					case "add" then
						parse = add()
						printf(fn_asm, "%s\n", {parse})
					case "sub" then
						parse = sub()
						printf(fn_asm, "%s\n", {parse})
					case "neg" then
						parse = neg()
						printf(fn_asm, "%s\n", {parse})
					case "eq" then
						parse = eq()
						printf(fn_asm, "%s\n", {parse})
					case "not" then
						parse = nott()
						printf(fn_asm, "%s\n", {parse})
					case "gt" then
						parse = gt()
						printf(fn_asm, "%s\n", {parse})
					case "lt" then
						parse = lt()
						printf(fn_asm, "%s\n", {parse})
					case "and" then
						parse = andd()
						printf(fn_asm, "%s\n", {parse})
					case "or" then
						parse = orr()
						printf(fn_asm, "%s\n", {parse})
					case "return" then
						parse=returnn()
						printf(fn_asm,"%s\n",{parse})
					--lentgh2
					case "label" then
						param1=data[2]
						parse=labell(param1,funcname)
						printf(fn_asm,"%s\n",{parse})
					case "goto" then
						param1=data[2]
						parse=goTo(param1,funcname)
						printf(fn_asm,"%s\n",{parse})
					case "if-goto" then
						param1=data[2]
						parse=ifGoto(param1,funcname)
						printf(fn_asm,"%s\n",{parse})						
					--length3:
					case "pop" then
						param1 = data[2]
						param2 = data [3]
						parse = pop(param1,param2,tmp)
						printf(fn_asm, "%s\n", {parse})
					case "push" then
						param1 = data[2]
						param2 = data [3]
						parse = push(param1,param2,tmp)
						printf(fn_asm, "%s\n", {parse})
					case "function" then
						param1 = data[2]
						param2 = data [3]
						funcname=param1
						parse=functionn(param1)
						printf(fn_asm,"%s\n",{parse})
						integer i=to_integer(param2)
						while (i>0) do							-- initialize local variables
							parse=push("constant", "0",tmp)
							printf(fn_asm,"%s\n",{parse})
							i-=1
						end while
					case "call" then
						param1 = data[2]
						param2 = data [3]
						parse=calll(param1, param2,funcname)
						printf(fn_asm,"%s\n",{parse})
					case "//" then
						--do nothing. this is a comment.						
					case "{}" then
						--do nothing
					case else
						printf(OUT, "Error: not in lexical analyzer.\n Expecting: add, sub, neg, eq, not, gt, lt, and, or, label, goto, if-goto, pop, push, function, call, return\n")
						abort(1)
			end switch
		end if
		entry												-- first iteration starts here
		line = gets(fn_vm)
	end while
	
	close(fn_vm)
	close(fn_asm)
	return 0
end function
-----------------------------------
----------------------------------- End Functions.



----------------------------------- Parser:

---------- functions: pop,push

function pop(sequence param1,sequence param2,sequence funcname)
	sequence parsed = ""
	switch param1 do
		case "local" then
			parsed = "@SP\nM=M-1\n@"&param2&"\nD=A\n@LCL\nD=M+D\n@13\nM=D\n@SP\nA=M\nD=M\n@13\nA=M\nM=D\n"
		case "argument" then
			parsed = "@SP\nM=M-1\n@"&param2&"\nD=A\n@ARG\nD=M+D\n@13\nM=D\n@SP\nA=M\nD=M\n@13\nA=M\nM=D\n"
		case "static" then
			parsed = "@SP\nM=M-1\n@SP\nA=M\nD=M\n@"&funcname&"."&param2&"\nM=D\n"
		case "temp" then
			parsed = "@SP\nM=M-1\n@"&param2&"\nD=A\n@5\nD=A+D\n@13\nM=D\n@SP\nA=M\nD=M\n@13\nA=M\nM=D\n"
		case "pointer" then
			if equal(param2, "0") or equal(param2, "1")then
				parsed = "@SP\nM=M-1\n@"&param2&"\nD=A\n@3\nD=A+D\n@13\nM=D\n@SP\nA=M\nD=M\n@13\nA=M\nM=D\n"
			else
				printf(OUT, "Error: pointer value illegal.\n Expecting: 0,1\n")
				abort(1)
			end if
		case "this" then
			parsed = "@SP\nM=M-1\n@"&param2&"\nD=A\n@THIS\nD=M+D\n@13\nM=D\n@SP\nA=M\nD=M\n@13\nA=M\nM=D\n"
		case "that" then
			parsed = "@SP\nM=M-1\n@"&param2&"\nD=A\n@THAT\nD=M+D\n@13\nM=D\n@SP\nA=M\nD=M\n@13\nA=M\nM=D\n"
	end switch
	return parsed
end function

function push(sequence param1,sequence param2,sequence funcname)
	sequence parsed = ""
	switch param1 do
		case "local" then
			parsed = "@"&param2&"\nD=A\n@LCL\nA=M+D\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
		case "argument" then
			parsed = "@"&param2&"\nD=A\n@ARG\nA=M+D\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
		case "constant" then
			parsed = "@"&param2&"\nD=A\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
		case "static" then
			parsed = "@"&funcname&"."&param2&"\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
		case "temp" then
			parsed = "@"&param2&"\nD=A\n@5\nA=A+D\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
		case "pointer" then
			if equal(param2, "0") or equal(param2, "1")then
				parsed = "@"&param2&"\nD=A\n@3\nA=A+D\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
			else
				printf(OUT, "Error: pointer value illegal.\n Expecting: 0,1\n")
				abort(1)
			end if
		case "this" then
			parsed = "@"&param2&"\nD=A\n@THIS\nA=M+D\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
		case "that" then
			parsed = "@"&param2&"\nD=A\n@THAT\nA=M+D\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
	end switch
	return parsed
end function
------------ Computation: add,sub,neg,eq,not,gt,lt,and,or
function add()
	sequence parsed = "@SP\nA=M\nA=A-1\nD=M\nA=A-1\nD=D+M\nM=D\n@SP\nM=M-1\n"
	return parsed
end function

function sub()
	sequence parsed = "@SP\nA=M\nA=A-1\nD=M\nA=A-1\nD=M-D\nM=D\n@SP\nM=M-1\n"
	return parsed
end function

function neg()
	sequence parsed = "@SP\nA=M-1\nD=M\nM=-D\n"
	return parsed
end function

function eq()
	sequence parsed = "@SP\nM=M-1\n@SP\nA=M\nD=M\n@SP\nM=M-1\n@SP\nA=M\nA=M\nD=D-A\n@Label_A\nD ; JEQ\n@Label_F\nD=0 ; JEQ\n(Label_A)\nD=-1\n(Label_F)\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
	return parsed
end function

function nott()
	sequence parsed = "@SP\nA=M-1\nD=M\nM=!D\n"
	return parsed
end function

function gt()
	sequence parsed = "@SP\nM=M-1\n@SP\nA=M\nD=M\n@SP\nM=M-1\n@SP\nA=M\nA=M\nD=A-D\n@Label_D\nD ; JGT\n@Label_E\nD=0 ; JEQ\n(Label_D)\nD=-1\n(Label_E)\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
	return parsed
end function

function lt()
	sequence parsed = "@SP\nM=M-1\n@SP\nA=M\nD=M\n@SP\nM=M-1\n@SP\nA=M\nA=M\nD=D-A\n@Label_B\nD ; JGT\n@Label_C\nD=0 ; JEQ\n(Label_B)\nD=-1\n(Label_C)\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"
	return parsed
end function

function andd()
	sequence parsed = "@SP\nA=M\nA=A-1\nD=M\nA=A-1\nD=D&M\nM=D\n@SP\nM=M-1\n"
	return parsed
end function

function orr()
	sequence parsed = "@SP\nA=M\nA=A-1\nD=M\nA=A-1\nD=D|M\nM=D\n@SP\nM=M-1\n"
	return parsed
end function

---- control flow:

function labell(sequence param1,sequence funcname)
        sequence parsed="("&funcname&"$"&param1&")\n"
        return parsed
end function

function goTo(sequence param1, sequence funcname)
        sequence parsed="@"&funcname&"$"&param1&"\n1; JMP\n"
        return parsed
end function

function ifGoto(sequence param1, sequence funcname)
        sequence parsed="@SP\nM=M-1\nA=M\nD=M\n@"&funcname&"$"&param1&"\nD; JNE\n"
        return parsed
end function

--- function calling:

function functionn(sequence param1)
     sequence parsed="("&param1&")\n"
	return parsed
end function


function calll(sequence param1, sequence param2,sequence funcname)
        labelNo="Label_"&to_string(labelCounter)  --push the return address
        labelCounter+=1
        sequence translatePush=push("constant", labelNo,funcname)
        sequence storeLcl="@LCL\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"   --store caller's LCL
        sequence storeArg="@ARG\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"   --store caller's ARG
        sequence storeThis="@THIS\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"   --store caller's THIS
        sequence storeThat="@THAT\nD=M\n@SP\nA=M\nM=D\n@SP\nM=M+1\n"   --store caller's THAT
        --change arg to callee's arg, change arg to callee's lcl, goto- function call, return address label
        sequence parsed=translatePush&storeLcl&storeArg&storeThis&storeThat&"@"&param2&"\nD=A\n@5\nD=D+A\n@SP\nD=M-D\n@ARG\nM=D\n@SP\nD=M\n@LCL\nM=D\n@"&param1&"\n1; JMP\n("&labelNo&")\n"
	return parsed
end function

function returnn()
	sequence translatePop=pop("argument","0",funcname)  --save function computation result to the top of the stack
	sequence restoreThat="@LCL\nD=M\n@1\nA=D-A\nD=M\n@THAT\nM=D\n"  --restore caller's THAT
	sequence restoreThis="@LCL\nD=M\n@2\nA=D-A\nD=M\n@THIS\nM=D\n"   --restore caller's THIS
	sequence restoreArg="@LCL\nD=M\n@3\nA=D-A\nD=M\n@ARG\nM=D\n"   --restore caller's ARG
	sequence restoreLcl="@LCL\nD=M\n@4\nA=D-A\nD=M\n@LCL\nM=D\n"   --restore caller's LCL
	--store return address in R14, restore caller's sp, jump to return address (that was stored in R14)
	sequence parsed="@LCL\nD=M\n@5\nA=D-A\nD=M\n@R14\nM=D\n"&translatePop&"@ARG\nD=M+1\n@SP\nM=D\n"&restoreThat&restoreThis&restoreArg&restoreLcl&"@R14\nA=M\n1; JMP\n"
	return parsed
end function
