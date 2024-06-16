# fastfetch --logo /home/sen/Pictures/icon.png --logo-width 40 --logo-height 30 --pipe false;
fastfetch


# Used to make custom scripts available as commands
create_command() {
    name=$1
    string=$2

    if [ -z "$name" ] ; then
        echo "Error: command name must be provided"
        return
    fi
    if [ -z "$string" ] ; then
        echo "Error: command string must be provided"
        return
    fi

    if ! command -v $name &> /dev/null
    then
        echo "$name command not found, creating it..."

        cat << EOF | sudo tee /usr/local/bin/$name > /dev/null
$string
EOF
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create the command script."
            return
        fi
        sudo chmod +x /usr/local/bin/$name

        echo "$name command created successfully."
    fi
}

activate_gyatts_command_string='
#!/usr/bin/env bash
mv ~/.off.git ~/.git
'
create_command "activate-gyatts" $activate_gyatts_command_string

deactivate_gyatts_command_string='
#!/usr/bin/env bash
mv ~/.git ~/.off.git
'
create_command "deactivate-gyatts" $deactivate_gyatts_command_string

update_grub_command_string='
#!/usr/bin/env bash
set -e
exec grub-mkconfig -o /boot/grub/grub.cfg "$@"
'
create_command "update-grub" $update_grub_command_string

sync_gyatts_command_string='
#!usr/bin/env bash
cd ~/
echo "Dumping dconf"
dconf dump / > .config/backup.dfconf
echo "Dumping packages"
pacman -Qen > .config/packages/pacman
pacman -Qem > .config/packages/paru
echo "Gitting"
activate-gyatts
git commit -am "Automated sync"
git push origin master
deactivate-gyatts
echo "Gyatt"
'
create_command "sync-gyatts" $sync_gyatts_command_string

# Run command on loop
loop_command_string='
#!usr/bin/env bash

clear_flag=false
if [ "$1" = "-c" ]; then
  clear_flag=true
  shift
fi

sleep_time=1
if [ "$1" = "-t" ]; then
  sleep_time="$2"
  shift 2
fi

while true; do
  output="$($@)"
  if [ "$clear_flag" = true ]; then
    clear
  fi
  echo "$output"
  sleep "$sleep_time"
done
'
create_command "loop" $loop_command_string


# Move to trash 
# Did not expanded $HOME so expanded so that the script works with sudo too 
# since when ran as sudo home is at root and root doesn't trash folder i.e., root/.local/share/Trash
trash_command_string='
#!/usr/bin/env bash

for file in "$@"; do 
    base=$(basename "$file")
    dest="'${HOME}'/.local/share/Trash/files/$base"
    if [ -e "$dest" ]; then 
        i=1
        while [ -e "'${HOME}'/.local/share/Trash/files/${base} ($i)" ]; do 
            let i++
        done
        dest="'${HOME}'/.local/share/Trash/files/${base} ($i)"
    fi
    mv "$file" "$dest"
done
'
create_command "trash" $trash_command_string


# Profile memory usage of process's matching the provided string
memp_command_string=$(cat <<"EOF"
#!/usr/bin/env bash

# Function to print usage
usage() {
	echo "Usage: $0 process_name [-u | -r | -p]"
	echo "  -u  Calculate USS (Unique Set Size)"
	echo "  -r  Calculate RSS (Resident Set Size)"
	echo "  -p  Calculate PSS (Proportional Set Size)"
	exit 1
}

# Default memory type
memory_type="uss"

# Check if process name is provided
if [[ -z "$1" ]]; then
	usage
fi

# Get the process name
process_name=$1
shift

# Parse the optional memory type flag
while getopts ":urp" opt; do
	case ${opt} in
	u)
		memory_type="uss"
		;;
	r)
		memory_type="rss"
		;;
	p)
		memory_type="pss"
		;;
	\?)
		usage
		;;
	esac
done

# Ensure smem is installed
if ! command -v smem &>/dev/null; then
	echo "smem could not be found. Please install smem to use this script."
	exit 1
fi

# Retrieve PIDs
pids=$(pgrep -f "$process_name" | tr '\n' ' ')
if [[ -z "$pids" ]]; then
	echo "No processes found matching: $process_name"
	exit 1
fi

# Use smem and awk to calculate the total memory usage based on the specified type
total_memory_mb=$(smem -c "pid pss uss rss" | awk -v pids="$pids" -v mem_type="$memory_type" 'NR==1; NR>1 && index(pids,$1)>0 {print $0}' | awk -v mem_type="$memory_type" '
  BEGIN {col=0}
  NR==1 {
    for (i=1; i<=NF; i++) {
      if ($i == toupper(mem_type)) {
        col=i
        break
      }
    }
  }
  NR>1 {sum += $col}
  END {print sum/1024 " MB"}
')

# Print the result
echo "Total ${memory_type^^} for processes matching '$process_name': $total_memory_mb"
EOF
)
create_command "memp" $memp_command_string




# Oh my posh
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/easy-term.omp.json)"

# Command aliases
alias update-mirrors="sudo reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist && sudo pacman -Sy"
alias py="python"
alias py11="python3.11"
alias py9="python3.9"
alias py7="python3.7"
alias nt="nautilus"
alias pacprune="sudo pacman -Rs $(pacman -Qtdq)"
alias paruskip="paru --noconfirm --skipreview --removemake --cleanafter -S"


# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# If set to an empty array, this variable will have no effect.
# a theme from this variable instead of looking in $ZSH/themes/
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git 
  zsh-autosuggestions 
  fast-syntax-highlighting 
  zsh-autocomplete 
  # zsh-syntax-highlighting 
  # zsh-vi-mode
)
source $ZSH/oh-my-zsh.sh
# Vim
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
bindkey '^I' autosuggest-accept



# Use lf to switch directories 
lfcd () {
    tmp="$(mktemp)"
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
bindkey -s '^l' 'lfcd\n'
bindkey -s '^f' 'nautilus\n'



# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
 else
   export EDITOR='mvim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

SUDO_EDITOR=nvim
export SUDO_EDITOR

export PATH="$PATH:/${HOME}/.local/bin"
export MUTTER_DEBUG=all
if [ "$TMUX" = "" ]; then tmux; fi
