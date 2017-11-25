"""
    print_autoconf_hint(state::WizardState)

Print a hint for projets that use autoconf to have a good `./configure` line.
"""
function print_autoconf_hint(state::WizardState)
    print(state.outs, "     The recommended options for GNU Autoconf are")
    print(state.outs, " `")
    print_with_color(:bold, state.outs, "./configure --prefix=/ --host=\$target")
    println(state.outs, "`")
    println(state.outs, "    followed by `make` and `make install`. Since the DESTDIR environment")
    println(state.outs, "    variable is set already, this will automatically perform the installation")
    println(state.outs, "    into the correct directory.\n")
end

"""
    provide_hints(state::WizardState, path::AbstractString)

Given an unpacked source directory, provide hints on how a user might go about
building the binary bounty they so richly desire.
"""
function provide_hints(state::WizardState, path::AbstractString)
    files = readdir(path)
    println(state.outs,
        "You have the following contents in your working directory:")
    println(state.outs, join(map(x->string("  - ", x),files),'\n'))
    printed = false
    function start_hints()
        printed || print_with_color(:yellow, state.outs, "Hints:\n")
        printed = true
    end
    # Avoid providing duplicate hints (even for files in separate directories)
    # As long as the hint is the same, people will get the idea
    hints_provided = Set{Symbol}()
    function already_hinted(sym)
        start_hints()
        (sym in hints_provided) && return true
        push!(hints_provided, sym)
        return false
    end
    for (root, dirs, files) in walkdir(path)
        for file in files
            file_path = joinpath(root, file)
            contents = readstring(file_path)
            if file == "configure" && contains(contents, "Generated by GNU Autoconf")
                already_hinted(:autoconf) && continue
                println(state.outs, "  - ", replace(file_path, "$path/", ""), "\n")
                println(state.outs, "    This file is a configure file generated by GNU Autoconf. ")
                print_autoconf_hint(state)
            elseif file == "configure.in" || file == "configure.ac"
                already_hinted(:autoconf) && continue
                println(state.outs, "  - ", replace(file_path, "$path/", ""), "\n")
                println(state.outs, "    This file is likely input to GNU Autoconf. ")
                print_autoconf_hint(state)
            elseif file == "CMakeLists.txt"
                already_hinted(:CMake) && continue
                println(state.outs, "  - ", replace(file_path, "$path/", ""), "\n")
                print(state.outs,   "    This file is likely input to CMake. ")
                print(state.outs,   "The recommended options for CMake are\n")
                print(state.outs,   "    `")
                print_with_color(:bold, state.outs, "cmake -DCMAKE_INSTALL_PREFIX=/ -DCMAKE_TOOLCHAIN_FILE=/opt/\$target/\$target.toolchain")
                println(state.outs, "`")
                println(state.outs, "    followed by `make` and `make install`. Since the DESTDIR environment")
                println(state.outs, "    variable is set already, this will automatically perform the installation")
                println(state.outs, "    into the correct directory.\n")
            end
        end
    end
    println(state.outs)
end
