-- read directory content

require("utils").using("utils")
starts_with = require("string_utils").starts_with
using("prettyprint")
lfs = require("lfs")

function get_content(directory)
	files = {hidden={}, visible={}}
	dirs = {hidden={}, visible={}}

	dir, err = pcall(lfs.dir, directory)
    if dir == false then
        return nil
    end

    for entry in lfs.dir(directory) do
        if entry != "." and entry != ".." then
			path = directory .. "/" .. entry
            mode = lfs.attributes(path, "mode")
            if mode == "file" then
            	if starts_with(entry, ".") then
	            	table.insert(files.hidden, entry)
            	else
	            	table.insert(files.visible, entry)
            	end
            else
            	if starts_with(entry, ".") then
            		table.insert(dirs.hidden, entry)
            	else
            		table.insert(dirs.visible, entry)
            	end
            end
        end
    end

    content = {files = files, dirs = dirs}
    sorted_content = deep_sort(content)
    return sorted_content
end

function main()
	path = arg[1] or "."
    mode = lfs.attributes(path, "mode")

    if mode == nil then
        color("Error: cannot access " .. path .. ": No such file or directory", "red")
    elseif mode == "file" then
        print(path)
    else
        content = get_content(path)
        if content == nil then
            color("Error: could not read content of " .. path, "red")
        else

        	-- print hidden directories
			for _, dir in pairs(content["dirs"]["hidden"]) do
	        	color(dir, "blue")
	        end

	        -- print visible directories
	        for _, dir in pairs(content["dirs"]["visible"]) do
	            color(dir, "blue")
	        end

			-- print hidden files
			for _, file in pairs(content["files"]["hidden"]) do
	        	print(file)
	        end

	        -- print visible files
	        for _, file in pairs(content["files"]["visible"]) do
	            print(file)
	        end
	        
        end
    end
end

main()
