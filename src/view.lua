-- view table from delimited file

require("utils").using("utils")
using("delimited_files")
using("dataframes")
using("argparse")

arg_string = """
    -i --input arg string true
"""

expected_args = def_args(arg_string)
args = parse_args(arg, expected_args)

function main(args)
	delimited_map = {
		tsv = "\t",
		csv = ","
	}
	
	file_extension = split(args["input"], ".")[2]
	delimited = delimited_map[file_extension]
	content = readdlm(args["input"], delimited, true)
	view(content)
end

-- run script
main(args)
