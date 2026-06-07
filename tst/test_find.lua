-- Tests for find.lua - file search functionality
-- Run with: luam tests/test_find.lua

package.path = package.path .. ";./tst/?.lua"

require("utils").using("utils")

tests = require("test_framework")

print("\n" .. string.rep("=", 60))
print("Testing find.lua - File Search Functionality")
print(string.rep("=", 60))

--------------------------------------------------------------------------------
-- Test: Basic grep functionality
--------------------------------------------------------------------------------
print("\n[SUITE] Basic Search")

tests.run_test("find.lua searches for pattern in directory", function()
    -- Search for 'function' in lua files
    output, _ = exec_command("luam src/find.lua -s 'function' -l . 2>&1")
    tests.assert_not_nil(output, "Should return output")
    -- Should find 'function' in lua files
    tests.assert_contains(output, "function", "Should find function keyword")
end)

tests.run_test("find.lua shows line numbers", function()
    output, _ = exec_command("luam src/find.lua -s 'main' -l src/repo.lua 2>&1")
    -- Output should contain lines like "13:function main..." 
    -- Strip ALL escape sequences (ESC followed by anything up to a letter)
    clean_output = string.gsub(output, "\027%[[%d;]*%a", "")
    -- grep with --line-number shows format like "13:function main"
    tests.assert_true(string.find(clean_output, "%d+:") != nil, 
        "Should show line numbers in format 'N:text'")
end)

tests.run_test("find.lua unique flag works", function()
    output, _ = exec_command("luam src/find.lua -s 'function' -l . -u 2>&1")
    -- With --files-with-matches, output should be file names only
    tests.assert_not_nil(output, "Should return output")
end)

--------------------------------------------------------------------------------
-- Test: Edge cases
--------------------------------------------------------------------------------
print("\n[SUITE] Edge Cases")

tests.run_test("find.lua handles missing pattern gracefully", function()
    output, _ = exec_command("luam src/find.lua 2>&1")
    -- Should show help or error message
    tests.assert_not_nil(output, "Should return some output")
end)

tests.run_test("find.lua handles non-existent directory", function()
    output, _ = exec_command("luam src/find.lua -s 'test' -l /nonexistent 2>&1")
    -- Should handle gracefully
    tests.assert_not_nil(output, "Should return some output")
end)

--------------------------------------------------------------------------------
-- Print Summary
--------------------------------------------------------------------------------
tests.print_summary()
