#!/bin/bash

usage() {
    cat << "EOF"
lctl - user-friendly launchctl wrapper and helper functions

USAGE
    lctl COMMAND AGENT
    lctl list|listdisabled|print
    lctl [-h|--help]

COMMANDS
    cat             print plist file to stdout
    edit            edit plist file in $EDITOR
    file            print plist file path to stdout
    listdisabled    list disabled agents
    log             view stdout and stderr logs in $PAGER
    logfiles        print stdout and stderr log file paths to stdout
    reload          shortcut for bootout => bootstrap
    tail            tail stdout log file

    bootout         unload the agent
    bootstrap       load the agent
    disable         prevent the agent from being loaded
    enable          enable the agent
    kickstart       execute the agent immediately
    kill            send SIGTERM to the agent
    list            summary of all agents or info on specific agent
    print           information about the domain or a specific agent

    See launchctl(1) for more information on second set of commands.

AGENT
    Case-insensitively glob matched against .plist files in
        ~/Library/LaunchAgents

EXAMPLES
    lctl reload myagent   bootout then bootstrap agent defined in
                              ~/Library/LaunchAgents/*myagent*.plist
    lctl listdisabled     list all disabled launchd user agents
EOF
}

lctl__cat() {
    cat "$agent_plist"
}

lctl__edit() {
    ${EDITOR:-vim} "$agent_plist"
}

lctl__file() {
    echo "$agent_plist"
}

lctl__listdisabled() {
    launchctl print-disabled "gui/$uid" | grep -E "${all_agents_regex}" \
        | grep "true" | cut -d'"' -f2
}

lctl__log() {
    [ "$(lctl__logfiles)" != "" ] &&
        IFS=$'\n' read -r -d "" -a logfiles < \
            <( lctl__logfiles | sed "s/^[^=]*= //" | uniq )
        ${PAGER:-less +G} "${logfiles[@]}"
}

lctl__logfiles() {
    launchctl print "gui/$uid/$agent_name" | grep -Eo "std(err|out) path = .*"
}

lctl__reload() {
    launchctl bootout "gui/$uid" "$agent_plist" &&
        launchctl bootstrap "gui/$uid" "$agent_plist"
}

lctl__tail() {
    tail -50f "$(lctl__logfiles | grep "^\\s*stdout" | sed "s/^[^=]*= //")"
}

lctl__bootout() {
    launchctl bootout "gui/$uid" "$agent_plist"
}

lctl__bootstrap() {
    launchctl bootstrap "gui/$uid" "$agent_plist"
}

lctl__disable() {
    launchctl disable "gui/$uid/$agent_name"
}

lctl__enable() {
    launchctl enable "gui/$uid/$agent_name"
}

lctl__kickstart() {
    launchctl kickstart "gui/$uid/$agent_name"
}

lctl__kill() {
    launchctl kill SIGTERM "gui/$uid/$agent_name"
}

lctl__list() {
    if [ -n "$agent_name" ]; then
        launchctl list "$agent_name"
    else
        launchctl list | grep -E "^PID|${all_agents_regex}" | sort -k3,3
    fi
}

lctl__print() {
    launchctl print "gui/$uid/$agent_name"
}

get_agent() {
    if [ -z "$arg_agent" ]; then
        echo "error: must specify agent for command $arg_command" >&2
        exit 1
    fi
    
    agent_search=("$agents_path"/*"$arg_agent"*.plist)
    agents_found="${#agent_search[@]}"

    case $agents_found in
        0)
            echo "error: no agents found for \"$arg_agent\"" >&2
            exit 1
            ;;
        1)
            idx=0
            ;;
        *)
            agent_exact_search=("$agents_path"/*".$arg_agent."*plist)

            if [ ${#agent_exact_search[@]} -eq 1 ]; then
                agent_search=("${agent_exact_search[@]}")
                idx=0
            else
                echo "$agents_found agents found for \"$arg_agent\":" >&2
                for i in "${!agent_search[@]}"; do
                    agent="${agent_search[$i]##*/}"
                    printf "  [%s] %s\n" "$(( i + 1 ))" "${agent%%.plist}" >&2
                done
                while :; do
                    read -r -p "Select: " j
                    if (( j >= 1 && j <= agents_found )); then
                        idx=$(( j - 1 ))
                        break
                    else
                        echo "number not in range, try again" >&2
                    fi
                done
            fi
            ;;
    esac

    agent_plist="${agent_search[$idx]}"
    agent_name="${agent_plist##*/}"
    agent_name="${agent_name%.plist}"
}

main() {
    shopt -s nocaseglob nullglob

    agents_path="${HOME}/Library/LaunchAgents"

    all_agents=("$agents_path"/*.plist)
    all_agents=("${all_agents[@]##*/}")
    all_agents=("${all_agents[@]%.plist}")

    if [ "${#all_agents[@]}" -eq 0 ]; then
        echo "error: no agents found in $agents_path" >&2
        exit 1
    fi

    all_agents_regex="$(printf "|%s" "${all_agents[@]}")"
    all_agents_regex="${all_agents_regex:1}"

    arg_command="$1"
    arg_agent="$2"

    uid=$(id -u)

    case "$arg_command" in
        "")
            lctl__list
            ;;
        -h|--help)
            usage
            ;;
        listdisabled)
            "lctl__$arg_command"
            ;;
        list|print)
            [ -n "$arg_agent" ] && get_agent "$arg_agent"
            "lctl__$arg_command"
            ;;
        *)
            function="lctl__$arg_command"
            if declare -f "$function" >/dev/null 2>&1; then
                get_agent "$arg_agent"
                "$function"
            else
                echo "error: command not recognised" >&2
                exit 1
            fi
            ;;
    esac
}

main "$@"
