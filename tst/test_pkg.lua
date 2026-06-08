-- Tests for pkg.lua - Package Manager Wrapper CLI
-- Run with: luam tst/test_pkg.lua

package.path = package.path .. ";./tst/?.lua"

require("utils").using("utils")
tests = require("test_framework")

print("\n" .. string.rep("=", 60))
print("Testing pkg.lua - Package Manager Wrapper")
print(string.rep("=", 60))

-- Load the pkg module functions (since main won't run because arg[0] is test_pkg.lua)
dofile("src/pkg.lua")

--------------------------------------------------------------------------------
-- Suite: Unit Tests for Helper Functions
--------------------------------------------------------------------------------
print("\n[SUITE] Helper Functions")

tests.run_test("get_repo_name_from_url parses hostname correctly", function()
    tests.assert_equal(get_repo_name_from_url("https://deb.nodesource.com/node_20.x"), "deb-nodesource-com")
    tests.assert_equal(get_repo_name_from_url("http://ppa.launchpad.net/neovim-ppa/stable"), "ppa-launchpad-net")
    tests.assert_equal(get_repo_name_from_url("invalid-url"), "custom-repo")
end)

tests.run_test("detect_package_manager returns apt on this Ubuntu system", function()
    pm = detect_package_manager()
    tests.assert_equal(pm, "apt", "Expected package manager to be apt on Ubuntu")
end)

--------------------------------------------------------------------------------
-- Suite: CLI Helps and UI
--------------------------------------------------------------------------------
print("\n[SUITE] CLI Help Messages")

tests.run_test("pkg.lua shows main help with no args", function()
    output, success = exec_command("luam src/pkg.lua 2>&1")
    tests.assert_true(success, "CLI should succeed with help output")
    tests.assert_contains(output, "Usage:", "Should contain Usage information")
    tests.assert_contains(output, "Active Package Manager:", "Should show the active package manager info")
    tests.assert_contains(output, "install", "Should show install command in help")
    tests.assert_contains(output, "source", "Should show source command in help")
end)

tests.run_test("pkg.lua shows install help", function()
    output, success = exec_command("luam src/pkg.lua install --help 2>&1")
    tests.assert_true(success, "CLI should succeed with subcommand help")
    tests.assert_contains(output, "Description:", "Should contain description")
    tests.assert_contains(output, "pkg install <package1>", "Should contain usage syntax")
end)

tests.run_test("pkg.lua shows remove help", function()
    output, success = exec_command("luam src/pkg.lua remove --help 2>&1")
    tests.assert_true(success, "CLI should succeed with subcommand help")
    tests.assert_contains(output, "Description:", "Should contain description")
    tests.assert_contains(output, "pkg remove <package1>", "Should contain usage syntax")
end)

tests.run_test("pkg.lua shows source help", function()
    output, success = exec_command("luam src/pkg.lua source --help 2>&1")
    tests.assert_true(success, "CLI should succeed with subcommand help")
    tests.assert_contains(output, "Subcommands:", "Should show subcommands section")
    tests.assert_contains(output, "pkg source add", "Should show source add usage")
end)

--------------------------------------------------------------------------------
-- Suite: Command Validations
--------------------------------------------------------------------------------
print("\n[SUITE] Command Validations")

tests.run_test("pkg.lua install with no packages fails", function()
    output, success = exec_command("luam src/pkg.lua install 2>&1")
    tests.assert_false(success, "Should fail when no packages are provided")
    tests.assert_contains(output, "requires at least one package name", "Should show error message")
end)

tests.run_test("pkg.lua remove with no packages fails", function()
    output, success = exec_command("luam src/pkg.lua remove 2>&1")
    tests.assert_false(success, "Should fail when no packages are provided")
    tests.assert_contains(output, "requires at least one package name", "Should show error message")
end)

tests.run_test("pkg.lua search with no query fails", function()
    output, success = exec_command("luam src/pkg.lua search 2>&1")
    tests.assert_false(success, "Should fail when no query is provided")
    tests.assert_contains(output, "requires a query string", "Should show error message")
end)

tests.run_test("pkg.lua source add with no spec fails", function()
    output, success = exec_command("luam src/pkg.lua source add 2>&1")
    tests.assert_false(success, "Should fail when no source spec is provided")
    tests.assert_contains(output, "requires a repository URL/spec", "Should show error message")
end)

--------------------------------------------------------------------------------
-- Print Summary
--------------------------------------------------------------------------------
tests.print_summary()
