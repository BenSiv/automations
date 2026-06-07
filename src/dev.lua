-- connect to docker container
package.path = "/home/bensiv/Projects/lua-automations/src/?.lua;" .. package.path
require("utils").using("utils")

function main()
	name = arg[1] or "celleste-dev"
	start_container = string.format("podman start '%s'", name)
	os.execute(start_container)
	
	open_container = string.format("podman exec -it '%s' bash", name)
	os.execute(open_container)
end

main()
