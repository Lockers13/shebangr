CONTENTS=""

function get_all() {
    input_file=$(_read_inputfile)
    CONTENTS=$(cat "$input_file")
    output_file=""
    _print_contents "$output_file" "$CONTENTS"
}

function filter_by_line() {
    input_file=$(_read_inputfile)
    SAVED_IFS=$IFS 
    IFS=$'-'
    read -p "Line Range (e.g. 5-10): " num1 num2
    IFS=$SAVED_IFS
    output_file=$(_read_outputfile)
    CONTENTS=$(sed -n "$num1,$num2 p" $input_file)
    _print_contents "$output_file" "$CONTENTS"
}

function filter_by_field() {
    input_file=$(_read_inputfile)
    read -p "Separator: " sep
    read -p "Field number: " fnum
    output_file=$(_read_outputfile)
    CONTENTS=$(cat "$input_file" | cut -f"$fnum" -d"$sep")
    _print_contents "$output_file" "$CONTENTS"
}

function get_funcs() {
    input_file=$(_read_inputfile)
    output_file=$(_read_outputfile)
    fbname=$(basename $input_file | cut -d'.' -f1)
    ext=$(basename $input_file | cut -d'.' -f2)
    case "$ext" in
    py|rb)
        keyword="def"
        ;;
    sh)
        keyword="function"
        ;;
    *)
        echo "Error: unrecognized file format => $ext"
        return
        ;;
    esac

    CONTENTS=$(cat "$input_file" | grep ^"$keyword")
    _print_contents "$output_file" "$CONTENTS"
}

function _print_contents() {
    if [[ "$1" == "" ]]; then
        printf '\n%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - 
        printf "%s\n" "$2" 
        printf "\n%*s\n\n" "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    else
        echo "$2" > "$1"
        echo "Ok, the specified line range has been written to $1..."
    fi
}

function _read_inputfile() {
    read -p "Filename: " input_file
    if [[ "$input_file" == ~* ]]; then
        input_file="$HOME/${input_file:1}"
    fi
    echo "$input_file"
}

function _read_outputfile() {
    read -p "Output file (default => stdout): " output_file
    output_file=${output_file:-""}
    echo "$output_file"
}