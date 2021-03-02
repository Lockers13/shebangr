#!/bin/bash

# Note - sourcepath = path containing relevant files to be sourced

function _configure_from_input() {
    # print dashed lines across the width of the terminal console
    printf '\n%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

    sourcepath="$1"

    # if we have a .sh file corresponding to a given sourcepath, then source that file and add its sourced functions to our global array
    if [[ -f "$sourcepath.sh" ]]
    then
        _sourcery "$sourcepath"
    fi

    # print the options availabe to user at the given sourcepath level by checking what files are contained one level below the given sourcepath directory
    SAVED_IFS=$IFS
    IFS=$'\n'
    for option in $(ls -f "$sourcepath"/*.sh ); do echo "- $(basename $option .sh)"; done
    printf "%s\n\n" "- all"
    IFS=$SAVED_IFS

    # prompt for user input
    read -p "${prompts[$sourcepath]} " input

    if [[ "$input" == "quit" ]]
    then
        return
    fi

    # if the user selects 'ALL', then recursively source any '.sh' file (and also record the relevant function names) at or below the given sourcepath directory level, and return
    if [[ "$input" == "all" ]]
    then
        message="Sourcing all files relating to chosen domain(s)...standby"
        printf "\n%s\n" "$message"
        _source_all_rec "$sourcepath"
        return
    fi

    # build new sourcepath for recursion by appending validated input to the original path
    sourcepath=$(_get_new_sourcepath "$sourcepath" "$input")

    # before recurring on the new sourcepath, check if it is a directory; if not, then it must be a .sh file, so source it and return as we have reached the end of our shebangr tree (base case)
    if [[ ! -d "$sourcepath" ]]
    then
        _sourcery "$sourcepath"
        return
    fi

    # recur on the newly built sourcepath
    _configure_from_input "$sourcepath"

}

function _get_new_sourcepath() {
    # Function which uses a while loop to check the validity of inputted option based on predefined structure of shebangr directory
    local sourcepath="$1/$2"

    while [ ! -d "$sourcepath" ] && [ ! -f "$sourcepath.sh" ]
    do
        read -p "Error - Unrecognized command, please try again: " input
        sourcepath="$1/$input"
    done
    echo "$sourcepath"
}

function _init_prompts() {
    # Function to populate a global hashmap (associative array) with key: value pairs of the form "sourcepath": "prompt"
    # Used for automatically generating prompts based on the sourcepath
    # The prompts corresponding to each possible sourcepath are stored on disk in the file 'prompts.txt' in the format "sourcepath@prompt"
    # Hence the IFS is temporarily set to '@' below

    prompts_file="data/prompts.txt"

    while read line || [ -n "$line" ]; do
        SAVED_IFS=$IFS   
        IFS=$'@'      
        line=($line) 
        IFS=$SAVED_IFS
        line="${line[0]}"
        prompt="${line[1]}"   
        prompts["$line"]="$prompt"
    done < "$prompts_file"
}

function _source_all_rec() {
    ### utility function to recursively source all .sh files at or below a given sourcepath ###
    SAVED_IFS=$IFS
    IFS=$'\n'
    for filename in $(ls -R $1 | grep .sh$)
    do
        script="$(find $1 -name $filename)"
        if [[ "$script" == "" ]]; then
            continue
        fi
        _get_fnames "$script"
        source "$script"
    done
    IFS=$SAVED_IFS
}

function _sourcery() {
    # simple helper function to do the sourcing of '.sh' files and collection of sourced functions in one go
    
    if [[ "$1" == "shebangr" ]]
    then
        return
    fi

    source "$1.sh"
    _get_fnames "$1.sh"
}

function _get_fnames() {
    # helper function for collecting function names into a global array.
    # this function is called on any sourced .sh file in order to record a list of sourced functions, thus renderered available to the user as simple command line commands
    SAVED_IFS=$IFS
    IFS=$'\n'
    for fline in $(cat "$1" | grep function)
    do
        IFS=$SAVED_IFS
        
        if [[ $(echo "$fline" | cut  -d" " -f1) == "function" ]]
        then
            fname=$(echo "$fline" | cut  -d" " -f2) 
            fname=${fname%\(*)}
            
            if [[ ! " ${func_names[@]} " =~ " ${fname} " ]] && [[ ! "$fname" == _* ]]; then
                func_names+=("$fname  (from '${1#*shebangr/}')")
            fi
        fi
    done
}

function _parse_args() {
    ### function to parse args if any ###

    if [[ "$#" -eq 1 ]] ; then
        interactive=false
        case "$1" in
        -h|--help)
            printf "\n%s\n" "Shebangr - a simpler, conceptual interface for running bash commands"
            printf "\n%s\n" "Simply use the interactive prompt by calling 'shebangr' on its own"
            printf "\n%s\n\n" "Available options are: "
            ### display options ###
            for option in $(find shebangr | grep .sh$); do option_name="$(basename $(echo $option | cut -f1 -d'.'))"; echo "- $option_name : ($(dirname $option | sed 's/\// => /g'))"; done
            ;;
        *)
            echo "Error: unrecognized flag...exiting"
            echo "For help just enter: shebangr -h"
            echo "Or alternatively, simply type 'shebangr' to start interactive mode!"
            ;;
        esac
    elif [[ "$#" -gt 1 ]]; then
        echo "Error: too many arguments"
        echo "For help just enter: shebangr -h"
        echo "Or alternatively, simply type 'shebangr' to start interactive mode!"
        interactive=false
    fi
}

function _display_commands() {
    ### display results of recursive sourcing to console ###    
    if [ ! ${#func_names[@]} -eq 0 ]; then
        printf "\n%s\n\n" "Done....The following commands have been loaded : "
        for command in "${func_names[@]}"
        do
            echo "- $command"
        done
        printf "%s\n" ""
    else
        printf "\n%s\n" "0 commands have been loaded!"
    fi
}

function shebangr() {
    # initialize empty hashmap to hold prompts as values + their assocciated paths as keys
    declare -A prompts=()
    # initialize empty array to hold names of functions sourced during input loop
    declare -a func_names=()
    interactive=true
    _parse_args "$@"

    if [[ ! "$interactive" = true ]]; then return; fi

    # populate prompts hashmap from disk
    _init_prompts
    # begin main recursive input function
    _configure_from_input "shebangr"

    _display_commands
}