#!/usr/bin/env luam

package.path = "/home/bensiv/Projects/automations/src/?.lua;" .. package.path
require("utils").using("utils")

-- Define help strings
help_strings = {
    ["main"] = """
Usage:
  pkg <command> [arguments]

Commands:
  install       Install package(s)
  remove        Remove package(s) (aliases: uninstall)
  update        Refresh package databases
  upgrade       Upgrade all system packages
  search        Search for package(s)
  list          List all installed packages
  source        Manage package repositories/sources

Flags:
  -h, --help    Show this help message

Run 'pkg <command> --help' for details on a specific command.
""",
    ["install"] = """
Description:
  Installs one or more packages using the system's package manager.

Usage:
  pkg install <package1> [package2] ...

Examples:
  pkg install curl
  pkg install git tmux zsh
""",
    ["remove"] = """
Description:
  Removes one or more packages from the system.

Usage:
  pkg remove <package1> [package2] ...

Examples:
  pkg remove curl
  pkg remove git tmux
""",
    ["update"] = """
Description:
  Refreshes the package manager's local package index/databases.

Usage:
  pkg update
""",
    ["upgrade"] = """
Description:
  Upgrades all installed packages to their latest versions.

Usage:
  pkg upgrade
""",
    ["search"] = """
Description:
  Searches for packages matching a query string.

Usage:
  pkg search <query>

Examples:
  pkg search sqlite
""",
    ["list"] = """
Description:
  Lists all installed packages on the system.

Usage:
  pkg list
""",
    ["source"] = """
Description:
  Manages package repositories and sources.

Subcommands:
  add       Add a new package repository/source
  list      List all configured repositories

Usage:
  pkg source add [name] <url_or_ppa>
  pkg source list

Examples:
  pkg source add ppa:neovim-ppa/stable
  pkg source add nodesource https://deb.nodesource.com/node_20.x
  pkg source list
"""
}

-- Check if current user is root
function is_root()
    uid_str, ok = exec_command("id -u")
    if ok and uid_str != nil then
        uid = tonumber((string.gsub(uid_str, "%s+$", "")))
        return uid == 0
    end
    return false
end

-- Detect package manager
function detect_package_manager()
    -- Probe /etc/os-release
    raw_release = read("/etc/os-release")
    id = nil
    id_like = nil
    if raw_release != nil then
        for line in string.gmatch(raw_release, "[^\r\n]+") do
            k, v = string.match(line, "^([%w_]+)=%\"?([^%\"]*)%\"?$")
            if k == "ID" then
                id = v
            elseif k == "ID_LIKE" then
                id_like = v
            end
        end
    end

    if id != nil then id = string.lower(id) end
    if id_like != nil then id_like = string.lower(id_like) end

    -- Helper match checker
    function check_match(pattern)
        if id != nil and string.find(id, pattern) != nil then
            return true
        end
        if id_like != nil and string.find(id_like, pattern) != nil then
            return true
        end
        return false
    end

    if check_match("ubuntu") or check_match("debian") then
        return "apt"
    elseif check_match("arch") then
        _, has_yay = exec_command("which yay 2>/dev/null")
        if has_yay then
            return "yay"
        else
            return "pacman"
        end
    elseif check_match("fedora") or check_match("rhel") or check_match("centos") then
        return "dnf"
    elseif check_match("alpine") then
        return "apk"
    end

    -- Fallback: binary probing in PATH
    _, has_yay = exec_command("which yay 2>/dev/null")
    if has_yay then return "yay" end

    _, has_pacman = exec_command("which pacman 2>/dev/null")
    if has_pacman then return "pacman" end

    _, has_apt = exec_command("which apt-get 2>/dev/null")
    if has_apt then return "apt" end

    _, has_dnf = exec_command("which dnf 2>/dev/null")
    if has_dnf then return "dnf" end

    _, has_apk = exec_command("which apk 2>/dev/null")
    if has_apk then return "apk" end

    return nil
end

-- Get repository name from a URL/string
function get_repo_name_from_url(url)
    host = string.match(url, "https?://([^/]+)")
    if host == nil then
        return "custom-repo"
    end
    -- Replace non-alphanumeric chars with dashes
    name = string.gsub(host, "[^%w]", "-")
    return string.lower(name)
end

-- Custom APT list sources
function list_apt_sources()
    raw, ok = exec_command("cat /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null")
    if not ok then
        print("Error: Could not read APT sources.")
        return
    end
    print("Configured APT Repositories:")
    for line in string.gmatch(raw, "[^\r\n]+") do
        trimmed = string.gsub(string.gsub(line, "^%s+", ""), "%s+$", "")
        if string.sub(trimmed, 1, 4) == "deb " or string.sub(trimmed, 1, 8) == "deb-src " then
            print("  " .. trimmed)
        end
    end
end

-- Custom Pacman list sources
function list_pacman_sources()
    raw, ok = exec_command("cat /etc/pacman.conf 2>/dev/null")
    if not ok then
        print("Error: Could not read pacman.conf.")
        return
    end
    print("Configured Pacman Repositories:")
    current_repo = nil
    for line in string.gmatch(raw, "[^\r\n]+") do
        trimmed = string.gsub(string.gsub(line, "^%s+", ""), "%s+$", "")
        header = string.match(trimmed, "^%[([%w%-_]+)%]$")
        if header != nil and header != "options" then
            current_repo = header
        elseif current_repo != nil then
            server = string.match(trimmed, "^Server%s*=%s*(.+)$")
            if server != nil then
                print(string.format("  [%s] %s", current_repo, server))
                current_repo = nil
            end
        end
    end
end

-- Custom APK list sources
function list_apk_sources()
    raw, ok = exec_command("cat /etc/apk/repositories 2>/dev/null")
    if not ok then
        print("Error: Could not read apk repositories.")
        return
    end
    print("Configured APK Repositories:")
    for line in string.gmatch(raw, "[^\r\n]+") do
        trimmed = string.gsub(string.gsub(line, "^%s+", ""), "%s+$", "")
        if trimmed != "" and string.sub(trimmed, 1, 1) != "#" then
            print("  " .. trimmed)
        end
    end
end

-- Run command with user feedback
function run_pkg_cmd(cmd_str)
    print(string.format("[pkg] Running '%s'...", cmd_str))
    res = os.execute(cmd_str)
    -- os.execute returns a success flag (or code depending on Lua version)
    if res == true or res == 0 then
        print("[pkg] Command completed successfully.")
        return true
    else
        print("[pkg] Command failed.")
        return false
    end
end

function main(argv)
    -- Determine execution environment
    pm = detect_package_manager()
    if pm == nil then
        print("Error: No supported package manager found on this system.")
        print("Supported package managers: yay, pacman, apt, dnf, apk")
        os.exit(1)
    end

    root_user = is_root()
    sudo_prefix = "sudo "
    if root_user == true then
        sudo_prefix = ""
    end

    -- Setup command mappings
    pm_cmds = {
        ["apt"] = {
            name = "APT (Debian/Ubuntu)",
            install = sudo_prefix .. "apt-get install -y",
            remove = sudo_prefix .. "apt-get remove -y",
            update = sudo_prefix .. "apt-get update",
            upgrade = sudo_prefix .. "apt-get dist-upgrade -y",
            search = "apt-cache search",
            list = "apt list --installed"
        },
        ["yay"] = {
            name = "Yay (Arch Linux AUR)",
            install = "yay --sync --noconfirm",
            remove = "yay --remove --nosave --recursive --unneeded --noconfirm",
            update = "yay --sync --refresh",
            upgrade = "yay --sync --sysupgrade --refresh --noconfirm",
            search = "yay --sync --search",
            list = "yay --query"
        },
        ["pacman"] = {
            name = "Pacman (Arch Linux)",
            install = sudo_prefix .. "pacman --sync --noconfirm",
            remove = sudo_prefix .. "pacman --remove --nosave --recursive --unneeded --noconfirm",
            update = sudo_prefix .. "pacman --sync --refresh",
            upgrade = sudo_prefix .. "pacman --sync --sysupgrade --refresh --noconfirm",
            search = "pacman --sync --search",
            list = "pacman --query"
        },
        ["dnf"] = {
            name = "DNF (Fedora/RHEL)",
            install = sudo_prefix .. "dnf install -y",
            remove = sudo_prefix .. "dnf remove -y",
            update = sudo_prefix .. "dnf makecache",
            upgrade = sudo_prefix .. "dnf upgrade -y",
            search = "dnf search",
            list = "dnf list installed"
        },
        ["apk"] = {
            name = "APK (Alpine Linux)",
            install = sudo_prefix .. "apk add",
            remove = sudo_prefix .. "apk del",
            update = sudo_prefix .. "apk update",
            upgrade = sudo_prefix .. "apk upgrade",
            search = "apk search",
            list = "apk info"
        }
    }

    info = pm_cmds[pm]

    -- Parse arguments
    cmd = argv[1]
    if cmd == nil or cmd == "-h" or cmd == "--help" or cmd == "help" then
        print("Active Package Manager: " .. info.name)
        print(help_strings["main"])
        return
    end

    -- Help request for subcommands
    is_help = false
    clean_argv = {}
    for i = 2, length(argv) do
        val = argv[i]
        if val == "--help" or val == "-h" then
            is_help = true
        else
            table.insert(clean_argv, val)
        end
    end

    if is_help == true then
        help_cmd = cmd
        if cmd == "uninstall" then help_cmd = "remove" end
        if help_strings[help_cmd] != nil then
            print(help_strings[help_cmd])
        else
            print("Unknown command: " .. cmd)
            print(help_strings["main"])
        end
        return
    end

    -- Process commands
    if cmd == "install" then
        if length(clean_argv) == 0 then
            print("Error: 'install' command requires at least one package name.")
            print(help_strings["install"])
            os.exit(1)
        end
        pkgs = table.concat(clean_argv, " ")
        run_pkg_cmd(info.install .. " " .. pkgs)

    elseif cmd == "remove" or cmd == "uninstall" then
        if length(clean_argv) == 0 then
            print("Error: 'remove' command requires at least one package name.")
            print(help_strings["remove"])
            os.exit(1)
        end
        pkgs = table.concat(clean_argv, " ")
        run_pkg_cmd(info.remove .. " " .. pkgs)

    elseif cmd == "update" then
        run_pkg_cmd(info.update)

    elseif cmd == "upgrade" then
        run_pkg_cmd(info.upgrade)

    elseif cmd == "search" then
        if length(clean_argv) == 0 then
            print("Error: 'search' command requires a query string.")
            print(help_strings["search"])
            os.exit(1)
        end
        query = table.concat(clean_argv, " ")
        run_pkg_cmd(info.search .. " " .. query)

    elseif cmd == "list" then
        run_pkg_cmd(info.list)

    elseif cmd == "source" then
        sub = clean_argv[1]
        if sub == nil or sub == "-h" or sub == "--help" then
            print(help_strings["source"])
            return
        end

        if sub == "list" then
            if pm == "apt" then
                list_apt_sources()
            elseif pm == "pacman" or pm == "yay" then
                list_pacman_sources()
            elseif pm == "dnf" then
                run_pkg_cmd(sudo_prefix .. "dnf repolist")
            elseif pm == "apk" then
                list_apk_sources()
            end

        elseif sub == "add" then
            if length(clean_argv) < 2 then
                print("Error: 'source add' command requires a repository URL/spec.")
                print(help_strings["source"])
                os.exit(1)
            end

            -- Determine name and url
            name = nil
            url = nil
            if length(clean_argv) == 2 then
                url = clean_argv[2]
                name = get_repo_name_from_url(url)
            else
                name = clean_argv[2]
                url = clean_argv[3]
            end

            if pm == "apt" then
                -- Check if it's a PPA or raw deb line
                if string.sub(url, 1, 4) == "ppa:" then
                    run_pkg_cmd(sudo_prefix .. "add-apt-repository -y " .. url)
                else
                    run_pkg_cmd(string.format("echo 'deb %s' | %stee /etc/apt/sources.list.d/%s.list", url, sudo_prefix, name))
                end
            elseif pm == "pacman" or pm == "yay" then
                run_pkg_cmd(string.format("echo -e '\\n[%s]\\nSigLevel = Optional TrustAll\\nServer = %s' | %stee -a /etc/pacman.conf", name, url, sudo_prefix))
            elseif pm == "dnf" then
                run_pkg_cmd(sudo_prefix .. "dnf config-manager --add-repo " .. url)
            elseif pm == "apk" then
                run_pkg_cmd(string.format("echo -e '\\n# %s\\n%s' | %stee -a /etc/apk/repositories", name, url, sudo_prefix))
            end
        else
            print("Unknown source subcommand: " .. sub)
            print(help_strings["source"])
            os.exit(1)
        end

    else
        print("Unknown command: " .. cmd)
        print(help_strings["main"])
        os.exit(1)
    end
end

-- Run program if run directly
if arg[0] != nil and string.find(arg[0], "pkg.lua") != nil then
    main(arg)
end
