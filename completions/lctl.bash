_lctl()
{
    local cword cur prev agents short_agents

    local cword="$COMP_CWORD"
    local cur="${COMP_WORDS[cword]}"
    local prev="${COMP_WORDS[cword - 1]}"

    case $cword in
        1)
            COMPREPLY=($(compgen -W "cat edit file listdisabled log logfiles reload tail
                bootout bootstrap disable enable kickstart kill list print" -- "$cur"))
            ;;
        2)
            [[ "$prev" == "listdisabled" ]] && return

            agents=("$HOME/Library/LaunchAgents/"*.plist)
            agents=("${agents[@]##*/}")
            agents=("${agents[@]%.plist}")
            short_agents=("${agents[@]#*.*.}")

            local IFS=$'\n'

            if [ "$cur" != "" ]; then
                short_agents+=("${agents[@]}")
            fi

            COMPREPLY=($(compgen -W "${short_agents[*]}" -- "$cur"))
            ;;
        *)
            return
            ;;
    esac
}

complete -F _lctl lctl
