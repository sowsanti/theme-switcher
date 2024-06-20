#!/bin/bash

# Check if fzf is installed
if ! command -v fzf &>/dev/null; then
	echo "fzf is not installed or not in PATH. Please install fzf to use this script."
	exit 1
fi

CONFIG_FILE=~/.theme-switcher-config

# Define a function to prompt for file path with a default value
prompt_for_path() {
	local program=$1
	local default_path=$2
	read -rp "Enter the full path for the current theme file for $program [default: $default_path]: " filepath
	filepath=${filepath:-$default_path}
	echo "$program=$filepath" >>"$CONFIG_FILE"
}

# Function to get current or default paths
get_paths() {
	local program=$1
	local path_in_config=${config[$program]}
	local default_path=${default_paths[$program]}
	if [[ -n $path_in_config ]]; then
		if [[ $path_in_config == $default_path ]]; then
			echo "$path_in_config (default)"
		else
			echo "$path_in_config (current)"
		fi
	else
		echo "$default_path (default)"
	fi
}

# Check if config file exists and load paths
declare -A config
if [[ -f $CONFIG_FILE ]]; then
	while IFS='=' read -r key value; do
		config["$key"]="$value"
	done <"$CONFIG_FILE"
fi

# Prompt user to select programs
echo "Select the programs you want the theme switcher to affect (use tab/shift+tab to select multiple options):"
programs=("alacritty" "kitty" "vim" "nvim" "lazyvim" "tmux")
header_message=$'\e[1;32mUse the \e[1;33marrow keys\e[1;32m to navigate and the \e[1;33mtab/shift+tab key\e[1;32m to select multiple options.\nPress \e[1;33mEnter\e[1;32m to confirm your selection.\e[0m'
selected_programs=$(printf "%s\n" "${programs[@]}" | fzf --multi --header "$header_message")

# Create or clear the config file
>"$CONFIG_FILE"

# Default paths for each program
declare -A default_paths
default_paths=(
	["alacritty"]="~/.config/alacritty/currenttheme.yml"
	["kitty"]="~/.config/kitty/currenttheme.conf"
	["vim"]="~/.config/vim/currenttheme.vim"
	["nvim"]="~/.config/nvim/currenttheme.lua"
	["lazyvim"]="~/.config/nvim/currenttheme.lua"
	["tmux"]="~/.config/tmux/currenttheme.conf"
)

# Get file paths for selected programs
for program in "${programs[@]}"; do
	if [[ ${config[$program]} ]]; then
		default_paths["$program"]=${config[$program]}
	fi
	prompt_for_path "$program" "${default_paths[$program]}"
done

echo "Configuration saved to $CONFIG_FILE"
