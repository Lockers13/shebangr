function start_django_project() {
    read -p "Enter directory to initialize django project in (default is '~/django_projects/): " base_django_dir
    base_django_dir="${base_django_dir:-$HOME/django_projects}"
    read -p "Enter project name: " pname
    read -p "Enter desired python version: " version
    mkdir "$base_django_dir"
    project_home="$base_django_dir/$pname"
    mkdir "$project_home"; cd "$project_home"
    virtualenv env -p "python${version}"
    source env/bin/activate
    git init
    pip install django
    django-admin startproject app
    cd app
    python manage.py migrate
    alias_string="alias startup_$pname='cd $project_home; source env/bin/activate; cd app'"
    grep "$alias_string" "$HOME/.bash_profile" > /dev/null 2>&1  || echo "$alias_string" >> "$HOME/.bash_profile"
    printf "\n%s\n" "Your project has been set up successfully...You can now use the command 'startup_$pname' when the shell starts up to (re)initialize your workstation"
}  