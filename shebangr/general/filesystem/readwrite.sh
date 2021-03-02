CONTENTS=""

function get_all() {
    read -p "Filename: " filename 
    CONTENTS=$(cat "$filename")
    printf '\n%*s\n\n%s\n%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - "$CONTENTS" "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

function filter_by_line() {
    read -p "Filename: " filename 
    SAVED_IFS=$IFS 
    IFS=$'-'
    read -p "Line Range (e.g. 5-10): " num1 num2
    IFS=$SAVED_IFS
    read -p "Output file (default => stdout): " output_file
    output_file=${output_file:-""}
    CONTENTS=$(sed -n "$num1,$num2 p" "$filename")
    if [[ "$output_file" == "" ]]; then
        printf '\n%*s\n\n%s\n%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - "$CONTENTS" "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    else
        echo "$CONTENTS" > "$output_file"
        echo "Ok, the specified line range from $filename has been written to $output_file..."
    fi
}

function filter_by_field() {
    read -p "Filename: " filename 
    read -p "Separator: " sep
    read -p "Field number: " fnum
    read -p "Output file (default => stdout): " output_file
    output_file=${output_file:-""}
    CONTENTS=$(cat $filename | cut -f$fnum -d$sep)
    echo "$CONTENTS"
    if [[ "$output_file" == "" ]]; then
        printf '\n%*s\n\n%s\n%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - "$CONTENTS" "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    else
        echo "$CONTENTS" > "$output_file"
        echo "Ok, the specified line range from $filename has been written to $output_file..."
    fi
}
