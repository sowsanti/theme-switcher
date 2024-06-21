#!/bin/bash

# Configuration file path
CONFIG_FILE=~/.theme-switcher-config

# Function to locate tmux configuration folder and install_plugins script
locate_tpm_install() {
	local xdg_location="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins/tpm/bin/install_plugins"
	local default_location="$HOME/.tmux/plugins/tpm/bin/install_plugins"

	if [ -f "$xdg_location" ]; then
		echo "$xdg_location"
	else
		echo "$default_location"
	fi
}

# Function to locate tmux.conf file
locate_tmux_conf() {
	local xdg_location="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
	local default_location="$HOME/.tmux.conf"

	if [ -f "$xdg_location" ]; then
		echo "$xdg_location"
	else
		echo "$default_location"
	fi
}

# Check if fzf is installed
check_fzf_installed() {
	if ! command -v fzf &>/dev/null; then
		echo "fzf is not installed or not in PATH. Please install fzf to use this script."
		exit 1
	fi
}

# Load configuration from file
load_config() {
	declare -A config
	while IFS='=' read -r key value; do
		config["$key"]="$value"
	done <"$CONFIG_FILE"
	echo "$(declare -p config)"
}

# Select a theme directory using fzf
select_theme() {
	local absolute_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
	find "$absolute_path/themes/" -mindepth 1 -maxdepth 1 -type d | fzf
}

# Apply the selected theme to various programs
apply_theme() {
	local selected_theme=$1
	local -n config_ref=$2

	for program in "${!config_ref[@]}"; do
		local theme_file

		case $program in
		vim | nvim | lazyvim)
			theme_file="$selected_theme/${program}.vim"
			[ -f "$theme_file" ] || theme_file="$selected_theme/${program}.lua"
			;;
		*)
			theme_file="$selected_theme/${program}.conf"
			[ -f "$theme_file" ] || theme_file="$selected_theme/${program}.toml"
			;;
		esac

		local current_theme_file="${config_ref[$program]}"
		current_theme_file="${current_theme_file/#\~/$HOME}" # Expand ~ to home directory

		# Ensure directory exists for current theme file
		mkdir -p "$(dirname "$current_theme_file")"

		if [ -f "$theme_file" ]; then
			cp "$theme_file" "$current_theme_file"
			echo "Copied $theme_file to $current_theme_file"
			reload_configuration "$program" "$current_theme_file"
		else
			echo "Theme file for $program not found in $selected_theme"
		fi
	done
}

# Reload or source configuration for each program
reload_configuration() {
	local program=$1
	local current_theme_file=$2

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
		if pgrep "tmux" >/dev/null; then
			echo "Reloading tmux configuration..."
			local tmux_conf
			tmux_conf=$(locate_tmux_conf)
			echo $tmux_conf

			if [ -n "$tmux_conf" ]; then
				tmux source-file "$tmux_conf"
				echo "Tmux configuration reloaded from $tmux_conf."
				# Install and update TPM plugins
				local tpm_install_script=$(locate_tpm_install)
				if [ -f "$tpm_install_script" ]; then
					"$tpm_install_script"
					echo "Tmux plugins installation triggered."
				else
					echo "TPM install_plugins script not found."
				fi
			else
				echo "Unable to find tmux.conf file."
			fi
		else
			echo "Tmux is not running. Please start tmux to apply the new theme automatically."
		fi
		;;
	esac
}

# Main function
main() {
	check_fzf_installed
	eval "$(load_config)"
	selected_theme=$(select_theme)

	if [ -z "$selected_theme" ]; then
		echo "No theme selected. Exiting..."
		exit 1
	fi

	apply_theme "$selected_theme" config
}

# Run the main function
main
