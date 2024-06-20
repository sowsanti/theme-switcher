#!/bin/bash

# Path to the configuration file
CONFIG_FILE=~/.theme-switcher-config

# Function to load config
load_config() {
	declare -A config
	while IFS='=' read -r key value; do
		config["$key"]="$value"
	done <"$CONFIG_FILE"
	echo "${config[@]}"
}

# Check if fzf is installed
if ! command -v fzf &>/dev/null; then
	echo "fzf is not installed or not in PATH. Please install fzf to use this script."
	exit 1
fi

# Load configuration
declare -A config
config=$(load_config)

# Get the list of available themes
ABSOLUTE_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SELECTED_THEME=$(find -d "$ABSOLUTE_PATH/themes/"* | fzf)

# Check if a theme was selected
if [ -z "$SELECTED_THEME" ]; then
	echo "No theme selected. Exiting..."
	exit 1
fi

# Apply the selected theme
for program in "${!config[@]}"; do
	case $program in
	vim | nvim | lazyvim)
		theme_file="$SELECTED_THEME/${program}.vim"
		[ -f "$theme_file" ] || theme_file="$SELECTED_THEME/${program}.lua"
		;;
	*)
		theme_file="$SELECTED_THEME/${program}.conf"
		[ -f "$theme_file" ] || theme_file="$SELECTED_THEME/${program}.yml"
		;;
	esac
	current_theme_file="${config[$program]}"
	if [ -f "$theme_file" ]; then
		cp "$theme_file" "$current_theme_file"
		echo "Copied $theme_file to $current_theme_file"

		# Reload or source the configuration for each program
		case $program in
		alacritty)
			if pgrep -x "alacritty" >/dev/null; then
				echo "Alacritty configuration reloaded."
			fi
			;;
		kitty)
			if pgrep -x "kitty" >/dev/null; then
				kitty @ --to=unix:/tmp/mykitty set-colors -a -c "$current_theme_file"
				echo "Kitty configuration reloaded."
			fi
			;;
		vim | nvim | lazyvim)
			if pgrep -x "vim" >/dev/null || pgrep -x "nvim" >/dev/null; then
				echo "Please manually source the ${program^} configuration file to apply the new theme."
			fi
			;;
		tmux)
			if pgrep -x "tmux" >/dev/null; then
				tmux source-file "$current_theme_file"
				echo "Tmux configuration reloaded."
			fi
			;;
		esac
	else
		echo "Theme file for $program not found in $SELECTED_THEME"
	fi
done
