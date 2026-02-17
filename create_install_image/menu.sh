#!/bin/bash
#This script requires dialog package

THEME=$(mktemp)

cat <<EOF > "$THEME"
use_shadow = OFF
use_colors = ON
shadow_color = (BLACK,BLACK,OFF)
screen_color = (BLACK,BLACK,OFF)
dialog_color = (WHITE,BLACK,OFF)
border_color = (BLUE,BLACK,ON)
border2_color = (BLUE,BLACK,ON)
menubox_border_color = (BLUE,BLACK,ON)
menubox_border2_color = (BLUE,BLACK,ON)
title_color = (GREEN,BLACK,ON)
menubox_color = (WHITE,BLACK,OFF)
item_color = (WHITE,BLACK,OFF)
item_selected_color = (BLACK,GREEN,ON)
tag_color = (WHITE,BLACK,ON)
tag_selected_color = (BLACK,GREEN,ON)
tag_key_color = (WHITE,BLACK,OFF)
tag_key_selected_color = (BLACK,GREEN,ON)
button_active_color = (BLACK,GREEN,ON)
button_inactive_color = (WHITE,BLACK,OFF)
button_key_active_color = (BLACK,GREEN,ON)
button_key_inactive_color = (WHITE,BLACK,OFF)
uarrow_color = (GREEN,BLACK,ON)
darrow_color = (GREEN,BLACK,ON)
position_indicator_color = (WHITE,BLACK,OFF)
gauge_color = (GREEN,BLACK,ON)
EOF

#Apply Theme
export DIALOGRC="$THEME"

BOOT_PARTITION=""
ROOT_PARTITION=""
BOOTLOADER_TYPE=""

select_partition(){
    local partition_path=$1
    local menu_title=$2
    local partitions=()
    local counter=0
    mapfile -t partitions_list < <(lsblk -prno NAME,LABEL,SIZE,FSTYPE,TYPE,RM | sed -n '/.*part 1$/p' | sed -e 's/part 1//')
    
    for partition in "${partitions_list[@]}"; do
        IFS=' ' read -r path label size type  <<< "$partition"
        partitions+=("$path" "Label: $label Size:$size Type:$type")
        
    done

    local choice
    choice=$(dialog --clear --title "$menu_title" --menu "Select partition from the list:" 0 0 3 "${partitions[@]}" 3>&1 1>&2 2>&3)
    
    printf -v "$partition_path" "%s" "$choice"

}

select_bootloader(){
    local bl=$1
    local menu_title=$2
    local choice
    choice=$(dialog --clear --title "$menu_title" --menu "Select bootloader from the list:" 0 0 2 "limine" "Simple and fast" "grub" "Most compatible and complex" 3>&1 1>&2 2>&3)
    printf -v "$bl" "%s" "$choice"
}


run_installer(){
    max_height=$(tput lines)
    max_width=$(tput cols)
    bash ./create_image.sh 2>&1 | dialog --clear --title " Installing... " --programbox "Live Installation:" $max_height $max_width
    dialog --title " Success " --msgbox "Images have been created !" 6 50
}

while true;
do
status_bt="${BOOT_PARTITION:-Not selected}"
status_rt="${ROOT_PARTITION:-Not selected}"
status_bl="${BOOTLOADER_TYPE:-Not selected}"

main_choice=$(dialog --clear --backtitle "Live installer setup" --title "Create USB Linux Installer" --menu "Configure the instalation target" 0 0 5 \
    "1" "Select BOOT partition [$status_bt]" \
    "2" "Select ROOT partition [$status_rt]" \
    "3" "Select the Bootloader [$status_bl]" \
    "4" "Run installer" \
    "5" "Exit" \
    3>&1 1>&2 2>&3)

    case $main_choice in
        1) select_partition BOOT_PARTITION "BOOT partition" ;;
        2) select_partition ROOT_PARTITION "ROOT partition" ;;
        3) select_bootloader BOOTLOADER_TYPE "Bootloader" ;;
        4) run_installer ;;
        5) break ;;
    esac
done
clear
rm -f $THEME

