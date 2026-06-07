# lua-automations Tests (luam edition)

Test suite for the lua-automations repository, using the `luam` dialect.

## Running Tests

```bash
# Run all tests
./tst/run_all.sh

# Run individual test files
luam tst/test_repo.lua
luam tst/test_find.lua
luam tst/test_readdir.lua
```

## Test Files

| File | Description |
|------|-------------|
| `test_framework.lua` | Simple assertion-based test framework |
| `test_repo.lua` | Tests for git automation (sync, pre-commit) |
| `test_find.lua` | Tests for grep-based file search |
| `test_readdir.lua` | Tests for directory listing |

## Test Framework

The test framework (`test_framework.lua`) provides:

- `assert_equal(actual, expected, message)` - Check equality
- `assert_true(value, message)` - Check boolean true
- `assert_false(value, message)` - Check boolean false
- `assert_nil(value, message)` - Check nil
- `assert_not_nil(value, message)` - Check not nil
- `assert_contains(str, substring, message)` - Check string contains substring
- `run_test(name, function)` - Run a single test
- `skip_test(name, reason)` - Skip a test
- `print_summary()` - Print test results summary

## Adding New Tests

1. Create a new file `tst/test_<module>.lua`
2. Import the framework: `tests = require("test_framework")`
3. Define test suites with `print("\n[SUITE] ...")`
4. Add tests with `tests.run_test("name", function() ... end)`
5. Call `tests.print_summary()` at the end
