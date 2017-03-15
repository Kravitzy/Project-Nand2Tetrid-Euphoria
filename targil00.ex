include std/filesys.e -- needed for walk_dir
include std/wildcard.e -- needed for is_match
include std/console.e	-- needed for prompt_string	
with trace
-- address to use:
-- C:\Euphoria\bin\programs

constant IN = 0, OUT = 1, FALSE = 0, TRUE = 1, EOF = -1
integer ok
sequence answer
object exit_code
integer mone = 0

--------- hello_vm procedure --------

procedure hello_vm(sequence path_name, sequence item)

	object line   -- the next line from the file
	sequence fullpath = path_name&"\\"&item[D_NAME]
	integer fn_vm = open(fullpath, "r")							-- opens the hello.vm file
	integer fn_asm = open( path_name&"\\hello.asm", "w") 		-- creates hello.asm file if doesn't exists

	if (fn_asm) = -1  then
				printf(1, "Can't open file %s\n", {path_name&"\\hello.asm"})
				abort(1)
	end if 
	if (fn_vm) = -1  then
				printf(1, "Can't open file %s\n", {fullpath})
				abort(1)
	end if 

	while sequence(line) entry do										-- exits while when line = -1

		printf(fn_asm, "%s", {line})
		if match("you", line) then
			printf(OUT,"%s in line: %s\n",{"found: YOU", line})
		end if
		
		entry
		line = gets(fn_vm)

	end while

	close (fn_asm)
	close(fn_vm)

end procedure


------ walk_dir function------
-- will go throug all the files in the folder user enterd

function look_at(sequence path_name, sequence item) -- this is going to work on every file	

	ok = is_match("*.vm", item[D_NAME])
	if ok then
		mone += 1
		sequence fullpath = path_name&"\\"&item[D_NAME]
		integer fn = open(fullpath, "a")	-- open to append mode. item has a few elements in it, we just need the first 1 that has the file name
		if fn = -1 then
			printf(1, "Can't open file %s\n", {fullpath})
			abort(1)
		end if 
		printf(fn,"\n%d",mone)
		close(fn)
		if equal(item[D_NAME],"hello.vm") then
			hello_vm(path_name, item)
		end if
	end if
	return 0		
	
end function


--------Code stars here:--------

answer = prompt_string ("enter full path name to use:\n")
exit_code = walk_dir(answer, routine_id("look_at"), TRUE)
if exit_code = -1 then
	printf(OUT, "Folder doesn't exists\n")
else
	printf(OUT, "Executed\n")
end if

any_key ("\n   Press any key to close this Window... ")


