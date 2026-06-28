# completions/lctl.fish

function __lctl_agents
    for file in ~/Library/LaunchAgents/*.plist
        set --local label (path basename --no-extension -- $file)
        string match --regex '[^.]+$' $label
        test -n (commandline --current-token); and echo $label
    end
end


# disable files by default
complete --command lctl --no-files

# -h|--help
complete --command lctl --condition __fish_use_subcommand --short-option h --long-option help --description 'Show usage'

set --local cmds \
    "cat:Print plist file contents" \
    "edit:Edit plist file in \$EDITOR" \
    "file:Show file" \
    "listdisabled:List disabled agents" \
    "log:Show log" \
    "logfiles:Show log files" \
    "reload:Reload agent" \
    "tail:Tail log" \
    "bootout:Boot out agent" \
    "bootstrap:Bootstrap agent" \
    "disable:Disable agent" \
    "enable:Enable agent" \
    "kickstart:Kickstart agent" \
    "kill:Kill agent" \
    "list:List agents" \
    "print:Print information"

printf '%s\n' $cmds | while read --delimiter : --local cmd desc
    complete --command lctl --condition __fish_use_subcommand --arguments $cmd --description $desc
end

# agent completions for second argument (skip for commands that don't take one)
set --local agent_cmds (string match --groups-only --regex '^(?!listdisabled)([^:]+)' $cmds)
complete --command lctl --condition "__fish_seen_subcommand_from $agent_cmds" --arguments '(__lctl_agents)'
