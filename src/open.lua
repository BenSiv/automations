-- open file with default program

length = require("utils").length

function print_help()
	print("Usage: open < what >")
end

function main()

	if length(arg) != 1 then
		print_help()
	else
		what = arg[1]
		to_exec = string.format("xdg-open '%s' 2>/dev/null" , what)
		os.execute(to_exec)
		-- print(to_exec)
	end
end

main()
