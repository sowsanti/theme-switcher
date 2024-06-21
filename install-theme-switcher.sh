#!/bin/bash

# Check if fzf is installed
check_fzf_installed() {
	if ! command -v fzf &>/dev/null; then
		echo "fzf is not installed or not in PATH. Please install fzf to use this script."
		exit 1
	fi
}

# Define a function to prompt for file path with a default or current value
prompt_for_path() {
	local program=$1
	local current_path=$2
	local display_path
	local prompt_message

	if [[ $current_path == ${default_paths[$program]} ]]; then
		display_path="default: $current_path"
	else
		display_path="current: $current_path"
	fi

	prompt_message="Enter the full path for the current theme file for $program [$display_path]: "
	read -rp "$prompt_message" filepath
	filepath=${filepath:-$current_path}
	echo "$program=$filepath" >>"$CONFIG_FILE"
}

# Function to get current or default paths
get_paths() {
	local program=$1
	local path_in_config=${config[$program]}
	local default_path=${default_paths[$program]}
	if [[ -n $path_in_config ]]; then
		if [[ $path_in_config == $default_path ]]; then
			echo "$default_path (default)"
		else
			echo "$path_in_config (current)"
		fi
	else
		echo "$default_path (default)"
	fi
}

# Load config file if it exists
load_config() {
	if [[ -f $CONFIG_FILE ]]; then
		while IFS='=' read -r key value; do
			config["$key"]="$value"
		done <"$CONFIG_FILE"
	fi
}

# Prompt user to select programs
select_programs() {
	echo "Select the programs you want the theme switcher to affect (use tab/shift+tab to select multiple options):"
	local header_message=$'\e[1;32mUse the \e[1;33marrow keys\e[1;32m to navigate and the \e[1;33mtab/shift+tab key\e[1;32m to select multiple options.\nPress \e[1;33mEnter\e[1;32m to confirm your selection.\e[0m'
	selected_programs=$(printf "%s\n" "${programs[@]}" | fzf --multi --header "$header_message")
}

# Save configuration
save_config() {
	>"$CONFIG_FILE"
	for program in $selected_programs; do
		local current_path=${config[$program]:-${default_paths[$program]}}
		prompt_for_path "$program" "$current_path"
	done
	echo "Configuration saved to $CONFIG_FILE"
}

# Main script
main() {
	CONFIG_FILE=~/.theme-switcher-config
	declare -A config

	# Default paths for each program
	declare -A default_paths=(
		["alacritty"]="~/.config/alacritty/currenttheme.toml"
		["kitty"]="~/.config/kitty/currenttheme.conf"
		["vim"]="~/.config/vim/currenttheme.vim"
		["nvim"]="~/.config/nvim/currenttheme.lua"
		["lazyvim"]="~/.config/nvim/currenttheme.lua"
		["tmux"]="~/.config/tmux/currenttheme.conf"
	)

	# List of programs to select from
	programs=("alacritty" "kitty" "vim" "nvim" "lazyvim" "tmux")

	check_fzf_installed
	load_config
	select_programs
	save_config
}

main
