#!/bin/bash
#This script requires dialog package

THEME=$(mktemp)

cat <<EOF > "$THEME"
use_shadow = OFF
use_colors = ON
shadow_color = (BLACK,BLACK,OFF)
screen_color = (BLACK,BLACK,OFF)
dialog_color = (WHITE,BLACK,OFF)
border_color = (WHITE,BLACK,ON)
border2_color = (WHITE,BLACK,ON)
menubox_border_color = (WHITE,BLACK,ON)
menubox_border2_color = (WHITE,BLACK,ON)
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
button_label_active_color = (BLACK,GREEN,ON)
button_label_inactive_color = (WHITE,BLACK,OFF)
uarrow_color = (BLACK,GREEN,ON)
darrow_color = (BLACK,GREEN,ON)
position_indicator_color = (WHITE,BLACK,OFF)
gauge_color = (GREEN,BLACK,ON)
EOF

#Apply Theme
export DIALOGRC="$THEME"

BOOT_PARTITION=""
ROOT_PARTITION=""
BOOTLOADER_TYPE=""
DESTINATION_PATH=""

select_partition(){
    local partition_path=$1
    local menu_title=$2
    local partitions=()
    local counter=0
    mapfile -t partitions_list < <(lsblk -prno NAME,LABEL,SIZE,FSTYPE,TYPE,RM | sed -n '/.*part 1$/p' | sed -e 's/part 1//')
    
    if [[ ${#partitions_list[@]} -eq 0 ]]; then
        dialog --title " Error " --msgbox "No removable devices found on this system!" 8 40
        return
    fi

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
    choice=$(dialog --clear --title "$menu_title" --menu "Select bootloader from the list:" 0 0 2 "limine" "" "grub" "" 3>&1 1>&2 2>&3)
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        printf -v "$bl" "%s" "$choice"
    fi
}


create_installer(){
    max_height=$(tput lines)
    max_width=$(tput cols)
    bash ./create_image.sh tmpfs 2>&1 | tee out.log | dialog --clear --title " Installing... " --progressbox "Live Installation:" $max_height $max_width
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        dialog --title " Success " --msgbox "Images have been created !" 6 50
    else
        dialog --title " Failed " --msgbox "Error ocurred! Check out.log file." 6 50
    fi
    umount -R live-install
}

specify_destination_path(){
    local dp=$1
    local result=$(dialog --clear --title "Installer image destination" --inputbox "Enter the path:" 15 0 "" 3>&1 1>&2 2>&3)
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        printf -v "$dp" "%s" "$result"
    fi
}

install_to_drive(){
    return
}

while true;
do
status_bt="${BOOT_PARTITION:-Not selected}"
status_rt="${ROOT_PARTITION:-Not selected}"
status_bl="${BOOTLOADER_TYPE:-Not selected}"
status_path="${DESTINATION_PATH:-Not specified}"

main_choice=$(dialog --clear --title " Create Linux Installer " --menu "Configure the instalation target" 15 0 0 \
    "1" "Select BOOT partition [$status_bt]" \
    "2" "Select ROOT partition [$status_rt]" \
    "3" "Select the Bootloader [$status_bl]" \
    "4" "Linux installer path  [$status_path]" \
    "5" "Create Linux installer" \
    "6" "Install to USB drive" \
    "7" "Exit" \
    3>&1 1>&2 2>&3)

    exit_code=$?

    case $exit_code in
        1) break ;;
        255) break ;;
    esac


    case $main_choice in
        1) select_partition BOOT_PARTITION "BOOT partition" ;;
        2) select_partition ROOT_PARTITION "ROOT partition" ;;
        3) select_bootloader BOOTLOADER_TYPE "Bootloader" ;;
        4) specify_destination_path DESTINATION_PATH ;;
        5) create_installer ;;
        6) install_to_drive ;;
        7) break ;;
    esac
done
clear
rm -f $THEME

