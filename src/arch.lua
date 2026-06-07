#!/usr/bin/env luam

package.path = "/home/bensiv/Projects/automations/src/?.lua;" .. package.path
require("utils").using("utils")

function print_help()
	print("""
Usage: arch <argument> <program_name>
Arguments:
	- install
	- remove
	- update
    """)
end

function main()	
    command_parser = {
        ["install"] = "yay --sync --noconfirm",
        ["remove"] = "yay --remove --nosave --recursive --unneeded --noconfirm",
        ["update"] = "yay --sync --sysupgrade --refresh --noconfirm && yay --sync --clean --noconfirm",
        ["list"] = "yay --query"
    }
    
    no_args = {"update", "list"}
	
    if length(arg) == 0 then
        print("missing command\n")
        print_help()
    elseif length(arg) == 1 then
	    command = arg[1]
	    if command_parser[command] then
	        if occursin(command, no_args) then
                to_exec = command_parser[command]
                os.execute(to_exec)
            else
                print("'" .. command .. "' is missing program name\n")
                print_help()
            end
        else
            print("'" .. command .. "' is not a valid argument\n")
            print_help()
        end
    elseif length(arg) == 2 then
        command = arg[1]
        program_name = arg[2]
		
        if command_parser[command] and not occursin(command, no_args) then
            to_exec = command_parser[command] .. " " .. program_name
            os.execute(to_exec)
        else
            print("'" .. command .. "' is not a valid argument\n")
            print_help()
        end
    else
        print("too many arguments given\n")
        print_help()
    end
end

main()
