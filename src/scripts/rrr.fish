#!/usr/bin/fish

while true
    # Read the sentinel value
    read -l sentinel
    if test -z "$sentinel"
        break
    end

    # Read lines until the sentinel is found again
    set code_to_run ""
    while read -l line
        if test "$line" = "$sentinel"
            break
        end
        set code_to_run "$code_to_run$line\n"
    end

    # Evaluate the collected code
    eval "$code_to_run"

    # Print the sentinel to signal completion
    echo "$sentinel"
end
