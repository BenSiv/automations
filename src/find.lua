-- find a sequence within files

require("utils").using("utils")
using("argparse")

function main(arg)	
	arg_string = """
	    -s --what arg string true
	    -l --where arg string true
	    -u --unique flag string false
	"""

	expected_args = def_args(arg_string)
	args = parse_args(arg, expected_args)

	if args == nil then
		return
	end

	print_unique = ""
	if args["unique"] != nil then
		print_unique =  "--files-with-matches"
	end

	args["where"] = args["where"] or "."

	to_exec = string.format("grep --recursive --line-number --color=always %s '%s' '%s'", print_unique, args["what"], args["where"])
	output, success = exec_command(to_exec)
	if success == false then
		print("Failes to run command: " .. to_exec)
	end
	print(output)
end

main(arg)
