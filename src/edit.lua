-- edit file with micro

function print_help()
	print("Usage: edit <file>")
end

function main()
	if #arg == 0 then
		print_help()
	else
		file_to_edit = arg[1]
		-- to_exec = string.format("gnome-text-editor '%s' > /dev/null 2>&1 &", file_to_edit)
		to_exec = string.format("micro '%s'", file_to_edit)
		os.execute(to_exec)
	end
end

main()
