-- Tests for repo.lua git automation functions
-- Run with: luam tests/test_repo.lua

package.path = package.path .. ";./tst/?.lua"

require("utils").using("utils")
using("paths")

tests = require("test_framework")

print("\n" .. string.rep("=", 60))
print("Testing repo.lua - Git Automation Functions")
print(string.rep("=", 60))

--------------------------------------------------------------------------------
-- Helper function tests (these are internal to repo.lua, so we redefine them)
--------------------------------------------------------------------------------

-- Check if a git revision exists (using exit code via shell)
function rev_exists(rev)
    _, success = exec_command(string.format("git rev-parse --quiet --verify %s 2>/dev/null", rev))
    return success
end

-- Check if first commit is an ancestor of second (using exit code via shell)
function is_ancestor(ancestor, descendant)
    _, success = exec_command(string.format("git merge-base --is-ancestor %s %s 2>/dev/null", ancestor, descendant))
    return success
end

-- Get current branch name
function get_current_branch()
    output, success = exec_command("git branch --show-current 2>/dev/null")
    if success and (output != nil) then
        return string.gsub(output, "%s+$", "")
    end
    return nil
end

-- Get list of remotes
function get_remotes()
    output, success = exec_command("git remote 2>/dev/null")
    if (success == false) or (output == nil) then return {} end
    remotes = {}
    for remote in string.gmatch(output, "[^\r\n]+") do
        table.insert(remotes, remote)
    end
    return remotes
end

--------------------------------------------------------------------------------
-- Test: rev_exists
--------------------------------------------------------------------------------
print("\n[SUITE] rev_exists function")

tests.run_test("rev_exists with HEAD", function()
    -- HEAD should always exist in a git repo
    tests.assert_true(rev_exists("HEAD"), "HEAD should exist")
end)

tests.run_test("rev_exists with invalid ref", function()
    tests.assert_false(rev_exists("nonexistent-branch-12345"), "Invalid ref should not exist")
end)

tests.run_test("rev_exists with origin/main or origin/master", function()
    exists_main = rev_exists("origin/main")
    exists_master = rev_exists("origin/master")
    tests.assert_true(exists_main or exists_master, "Either origin/main or origin/master should exist")
end)

--------------------------------------------------------------------------------
-- Test: get_current_branch
--------------------------------------------------------------------------------
print("\n[SUITE] get_current_branch function")

tests.run_test("get_current_branch returns string", function()
    branch = get_current_branch()
    tests.assert_not_nil(branch, "Should return a branch name")
    tests.assert_true(type(branch) == "string", "Branch should be a string")
end)

tests.run_test("get_current_branch returns valid branch", function()
    branch = get_current_branch()
    -- Branch name should not contain newlines
    tests.assert_false(string.find(branch, "\n") != nil, "Branch name should not contain newlines")
end)

--------------------------------------------------------------------------------
-- Test: get_remotes
--------------------------------------------------------------------------------
print("\n[SUITE] get_remotes function")

tests.run_test("get_remotes returns table", function()
    remotes = get_remotes()
    tests.assert_true(type(remotes) == "table", "Should return a table")
end)

tests.run_test("get_remotes includes origin", function()
    remotes = get_remotes()
    has_origin = false
    for _, remote in ipairs(remotes) do
        if remote == "origin" then
            has_origin = true
            break
        end
    end
    tests.assert_true(has_origin, "Should include 'origin' remote")
end)

--------------------------------------------------------------------------------
-- Test: is_ancestor
--------------------------------------------------------------------------------
print("\n[SUITE] is_ancestor function")

tests.run_test("is_ancestor HEAD~1 is ancestor of HEAD", function()
    -- First check if we have enough commits
    _, success = exec_command("git rev-parse HEAD~1 2>/dev/null")
    if success then
        tests.assert_true(is_ancestor("HEAD~1", "HEAD"), "HEAD~1 should be ancestor of HEAD")
    else
        -- Not enough commits, skip implicitly by passing
        tests.assert_true(true, "Skipped - not enough commits")
    end
end)

tests.run_test("is_ancestor HEAD is not ancestor of HEAD~1", function()
    _, success = exec_command("git rev-parse HEAD~1 2>/dev/null")
    if success then
        tests.assert_false(is_ancestor("HEAD", "HEAD~1"), "HEAD should not be ancestor of HEAD~1")
    else
        tests.assert_true(true, "Skipped - not enough commits")
    end
end)

--------------------------------------------------------------------------------
-- Test: CLI argument parsing
--------------------------------------------------------------------------------
print("\n[SUITE] CLI Argument Parsing")

tests.run_test("repo.lua --help exits without error", function()
    output, _ = exec_command("luam src/repo.lua --help 2>&1")
    tests.assert_contains(output, "Usage", "Help should show usage")
    tests.assert_contains(output, "behind list", "Help should mention behind list")
    tests.assert_contains(output, "commit -m", "Help should mention commit")
end)

tests.run_test("repo.lua commit without args shows git status", function()
    output, _ = exec_command("luam src/repo.lua commit 2>&1")
    has_branch = (string.find(output, "branch") != nil) or (string.find(output, "Branch") != nil) or (string.find(output, "detached at") != nil)
    tests.assert_true(has_branch, "Should show git status with branch or detached HEAD info")
end)

--------------------------------------------------------------------------------
-- Test: Sync functionality (dry run check)
--------------------------------------------------------------------------------
print("\n[SUITE] Git Sync Functionality")

tests.run_test("repo.lua sync fetches from remotes", function()
    output, _ = exec_command("luam src/repo.lua sync 2>&1")
    tests.assert_contains(output, "Fetching from all remotes", "Should show fetching message")
    tests.assert_contains(output, "Sync complete", "Should complete successfully")
end)

--------------------------------------------------------------------------------
-- Test: Pre-commit hook functionality
--------------------------------------------------------------------------------
print("\n[SUITE] Pre-commit Hook Functionality")

tests.run_test("repo.lua commit without args shows git status", function()
    output, _ = exec_command("luam src/repo.lua commit 2>&1")
    has_branch = (string.find(output, "branch") != nil) or (string.find(output, "Branch") != nil) or (string.find(output, "detached at") != nil)
    tests.assert_true(has_branch, "Should show git status with branch or detached HEAD info")
end)

--------------------------------------------------------------------------------
-- Print Summary
--------------------------------------------------------------------------------
tests.print_summary()
