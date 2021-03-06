#!/bin/bash

parameters="${1}${2}${3}${4}${5}${6}${7}${8}${9}"

Escape_Variables()
{
	text_progress="\033[38;5;113m"
	text_success="\033[38;5;113m"
	text_warning="\033[38;5;221m"
	text_error="\033[38;5;203m"
	text_message="\033[38;5;75m"

	text_bold="\033[1m"
	text_faint="\033[2m"
	text_italic="\033[3m"
	text_underline="\033[4m"

	erase_style="\033[0m"
	erase_line="\033[0K"

	move_up="\033[1A"
	move_down="\033[1B"
	move_foward="\033[1C"
	move_backward="\033[1D"
}

Parameter_Variables()
{
	if [[ $parameters == *"-v"* || $parameters == *"-verbose"* ]]; then
		verbose="1"
		set -x
	fi
}

Path_Variables()
{
	script_path="${0}"
	directory_path="${0%/*}"

	patch_resources_path="$directory_path/resources/patch"
	revert_resources_path="$directory_path/resources/revert"

	system_version_path="System/Library/CoreServices/SystemVersion.plist"
}

Input_Off()
{
	stty -echo
}

Input_On()
{
	stty echo
}

Output_Off() {
	if [[ $verbose == "1" ]]; then
		"$@"
	else
		"$@" &>/dev/null
	fi
}

Check_Environment()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Checking system environment."${erase_style}
	if [ -d /Install\ *.app ]; then
		environment="installer"
	fi
	if [ ! -d /Install\ *.app ]; then
		environment="system"
	fi
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Checked system environment."${erase_style}
}

Check_Root()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Checking for root permissions."${erase_style}
	if [[ $environment == "installer" ]]; then
		root_check="passed"
		echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Root permissions check passed."${erase_style}
	else
		if [[ $(whoami) == "root" && $environment == "system" ]]; then
			root_check="passed"
			echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Root permissions check passed."${erase_style}
		fi
		if [[ ! $(whoami) == "root" && $environment == "system" ]]; then
			root_check="failed"
			echo -e $(date "+%b %m %H:%M:%S") ${text_error}"- Root permissions check failed."${erase_style}
			echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Run this tool with root permissions."${erase_style}
			Input_On
			exit
		fi
	fi
}

Check_SIP()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Checking System Integrity Protection status."${erase_style}

	if [[ $(csrutil status | grep status) == *disabled* ]] || [[ $(csrutil status | grep status) == *Custom\ Configuration* && $(csrutil status | grep "Kext Signing") == *disabled* ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ System Integrity Protection status check passed."${erase_style}
	fi
	if [[ $(csrutil status | grep status) == *enabled* && ! $(csrutil status | grep status) == *Custom\ Configuration* ]] || [[ $(csrutil status | grep status) == *Custom\ Configuration* && $(csrutil status | grep "Kext Signing") == *enabled* ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${text_error}"- System Integrity Protection status check failed."${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Run this tool with System Integrity Protection disabled."${erase_style}
		Input_On
		exit
	fi
}

Check_Resources()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Checking for resources."${erase_style}
	if [[ -d "$patch_resources_path" && -d "$revert_resources_path" ]]; then
		resources_check="passed"
		echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Resources check passed."${erase_style}
	fi
	if [[ ! -d "$patch_resources_path" || ! -d "$revert_resources_path" ]]; then
		resources_check="failed"
		echo -e $(date "+%b %m %H:%M:%S") ${text_error}"- Resources check failed."${erase_style}
	fi
}

Check_Internet()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Checking for internet conectivity."${erase_style}
	if [[ $(ping -c 5 www.google.com) == *transmitted* && $(ping -c 5 www.google.com) == *received* ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Internet conectivity check passed."${erase_style}
		internet_check="passed"
	else
		echo -e $(date "+%b %m %H:%M:%S") ${text_error}"- Internet conectivity check failed."${erase_style}
		internet_check="failed"
	fi
}

Check_Options()
{
	if [[ $resources_check == "failed" && $internet_check == "failed" ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${text_error}"- Resources check and internet conectivity check failed"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Run this tool with the required resources and/or an internet connection."${erase_style}
		Input_On
		exit
	fi

	if [[ $resources_check == "passed" && $internet_check == "passed" ]]; then
		options="1"
	fi
	if [[ $resources_check == "passed" && $internet_check == "failed" ]]; then
		options="2"
	fi
	if [[ $resources_check == "failed" && $internet_check == "passed" ]]; then
		options="3"
	fi
}

Input_Volume()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ What volume would you like to use?"${erase_style}
	echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Input a volume name."${erase_style}
	for volume_path in /Volumes/*; do 
		volume_name="${volume_path#/Volumes/}"
		if [[ ! "$volume_name" == com.apple* ]]; then
			echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     ${volume_name}"${erase_style} | sort
		fi
	done
	Input_On
	read -e -p "$(date "+%b %m %H:%M:%S") / " volume_name
	Input_Off

	volume_path="/Volumes/$volume_name"
}

Check_Volume_Version()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Checking system version."${erase_style}	
	volume_version="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion.plist ProductVersion)"
	volume_version_short="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion.plist ProductVersion | cut -c-5)"
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Checked system version."${erase_style}
}

Check_Volume_Support()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Checking installer support."${erase_style}
	if [[ $volume_version_short == "10.1"[0-5] ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ System support check passed."${erase_style}
	else
		echo -e $(date "+%b %m %H:%M:%S") ${text_error}"- System support check failed."${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Run this tool on a supported system."${erase_style}
		Input_On
		exit
	fi
}

Input_Operation()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ What operation would you like to run?"${erase_style}
	echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Input an operation number."${erase_style}
	if [[ $options == "1" || $options == "2" ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     1 - Patch"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     2 - Revert"${erase_style}
	fi

	if [[ $options == "1" ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     3 - Patch from internet"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     4 - Revert from internet"${erase_style}
	fi

	if [[ $options == "3" ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     1 - Patch from internet"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     2 - Revert from internet"${erase_style}
	fi
	Input_On
	read -e -p "$(date "+%b %m %H:%M:%S") / " operation
	Input_Off

	if [[ $options == "1" || $options == "2" ]]; then
		if [[ $operation == "1" ]]; then operation="patch"; fi
		if [[ $operation == "2" ]]; then operation="revert"; fi
	fi

	if [[ $options == "1" ]]; then
		if [[ $operation == "3" ]]; then operation="patch_internet"; fi
		if [[ $operation == "4" ]]; then operation="revert_internet"; fi
	fi

	if [[ $options == "3" ]]; then
		if [[ $operation == "1" ]]; then operation="patch_internet"; fi
		if [[ $operation == "2" ]]; then operation="revert_internet"; fi
	fi

	if [[ $operation == "patch_internet" || $operation == "revert_internet" ]]; then
		Download_Internet
	fi

	if [[ $operation == "patch" || $operation == "patch_internet" ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ What wallpaper would you like to use?"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Input an operation number."${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     1 - RMC"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     2 - Desert 5"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     3 - Desert 6"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     4 - Mojave Day"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     5 - Mojave Night"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     6 - High Sierra"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     7 - Sierra"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     8 - Catalina Light"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     9 - Catalina Dark"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     10 - El Capitan"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     11 - Yosemite"${erase_style}
		Input_On
		read -e -p "$(date "+%b %m %H:%M:%S") / " operation_wallpaper
		Input_Off
	
		if [[ $operation_wallpaper == "1" ]]; then wallpaper="RMC"; fi
		if [[ $operation_wallpaper == "2" ]]; then wallpaper="Desert 5"; fi
		if [[ $operation_wallpaper == "3" ]]; then wallpaper="Desert 6"; fi
		if [[ $operation_wallpaper == "4" ]]; then wallpaper="Mojave Day"; fi
		if [[ $operation_wallpaper == "5" ]]; then wallpaper="Mojave Night"; fi
		if [[ $operation_wallpaper == "6" ]]; then wallpaper="High Sierra"; fi
		if [[ $operation_wallpaper == "7" ]]; then wallpaper="Sierra"; fi
		if [[ $operation_wallpaper == "8" ]]; then wallpaper="Catalina Light"; fi
		if [[ $operation_wallpaper == "9" ]]; then wallpaper="Catalina Dark"; fi
		if [[ $operation_wallpaper == "8" ]]; then wallpaper="El Capitan"; fi
		if [[ $operation_wallpaper == "9" ]]; then wallpaper="Yosemite"; fi
	
		Patch_Volume
	fi

	if [[ $operation == "revert" || $operation == "revert_internet" ]]; then
		Revert_Volume
	fi
}

Download_Internet()
{
	curl -L -s -o /tmp/desert-deserter.zip https://github.com/julian-fairfax/desert-deserter/archive/master.zip
	unzip -q /tmp/desert-deserter.zip -d /tmp

	patch_resources_path="/tmp/desert-deserter-master/resources/patch"
	revert_resources_path="/tmp/desert-deserter-master/resources/revert"
}

Patch_Volume()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Patching device icons."${erase_style}
	cp -R "$patch_resources_path"/"$wallpaper"/CoreTypes/ "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/

	if [[ -d "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MJTlrL7BTqUr.bundle ]]; then
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbook-retina-gold.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MJTlrL7BTqUr.bundle/Contents/Resources
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbook-retina-silver.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MJTlrL7BTqUr.bundle/Contents/Resources
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbook-retina-space-gray.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MJTlrL7BTqUr.bundle/Contents/Resources
	fi

	if [[ -d "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes.bundle ]]; then
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbook-retina-rose-gold.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes.bundle/Contents/Resources
	fi

	if [[ -d "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-3DC57F5C7A.bundle ]]; then
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookpro-13-retina-usbc-space-gray.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-3DC57F5C7A.bundle/Contents/Resources
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookpro-13-retina-usbc-silver.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-3DC57F5C7A.bundle/Contents/Resources
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookpro-13-retina-touchid-space-gray.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-BBBAA77A32.bundle/Contents/Resources
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookpro-13-retina-touchid-silver.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-BBBAA77A32.bundle/Contents/Resources
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookpro-15-retina-touchid-space-gray.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-C4EBFEA440.bundle/Contents/Resources
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookpro-15-retina-touchid-silver.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-C4EBFEA440.bundle/Contents/Resources
	fi

	if [[ -d "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-23D5DDDA06.bundle ]]; then
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.imacpro-2017.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-23D5DDDA06.bundle/Contents/Resources/
	fi

	if [[ -d "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018a.bundle ]]; then
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbook-retina-gold-2018.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018b.bundle/Contents/Resources
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookair-2018-gold.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018c.bundle/Contents/Resources
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookair-2018-silver.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018c.bundle/Contents/Resources
		cp "$patch_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookair-2018-space-gray.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018c.bundle/Contents/Resources
	fi
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Patched device icons."${erase_style}

	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Patching system icons."${erase_style}
	if [[ $volume_version_short == "10.14" ]]; then
		cp "$patch_resources_path"/"$wallpaper"/system/Assets.car "$volume_path"/Applications/Utilities/System\ Information.app/Contents/Resources/
	fi

	if [[ $volume_version_short == "10.1"[0-3] ]]; then
		cp "$patch_resources_path"/"$wallpaper"/system/SystemLogo.tiff "$volume_path"/Applications/Utilities/System\ Information.app/Contents/Resources/
	fi
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Patched system icons."${erase_style}

	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Copying system wallpapers."${erase_style}
	if [[ $volume_version_short == "10.1"[0-3] ]]; then
		cp -R "$patch_resources_path"/wallpapers/ "$volume_path"/Library/Desktop\ Pictures/
	fi

	cp "$patch_resources_path"/wallpapers/RMC.jpg "$volume_path"/Library/Desktop\ Pictures
	cp "$patch_resources_path"/wallpapers/Catalina\ Light.jpg "$volume_path"/Library/Desktop\ Pictures
	cp "$patch_resources_path"/wallpapers/Catalina\ Dark.jpg "$volume_path"/Library/Desktop\ Pictures
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Copied system wallpapers."${erase_style}
	
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Patching system wallpapers."${erase_style}
	if [[ $volume_version_short == "10.14" ]]; then
		rm "$volume_path"/System/Library/CoreServices/DefaultBackground.jpg
		rm "$volume_path"/System/Library/CoreServices/DefaultDesktop.heic

		ln -s "$volume_path"/Library/Desktop\ Pictures/"$wallpaper".jpg "$volume_path"/System/Library/CoreServices/DefaultBackground.jpg
		ln -s "$volume_path"/Library/Desktop\ Pictures/"$wallpaper".jpg "$volume_path"/System/Library/CoreServices/DefaultDesktop.heic

		if [[ -e "$volume_path"/Library/Desktop\ Pictures/Mojave.heic ]]; then
			mv "$volume_path"/Library/Desktop\ Pictures/Mojave.heic "$volume_path"/Library/Desktop\ Pictures/Default.heic
		fi
		if [[ -e "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Mojave.heic ]]; then
			mv "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Mojave.heic "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Default.heic
		fi
	fi

	if [[ $volume_version_short == "10.1"[0-3] ]]; then
		rm "$volume_path"/System/Library/CoreServices/DefaultDesktop.jpg

		ln -s "$volume_path"/Library/Desktop\ Pictures/"$wallpaper".jpg "$volume_path"/System/Library/CoreServices/DefaultDesktop.jpg
		rm "$volume_path"/Library/Caches/com.apple.desktop.admin.png

		if [[ -e "$volume_path"/Library/Desktop\ Pictures/High\ Sierra.jpg ]]; then
			mv "$volume_path"/Library/Desktop\ Pictures/High\ Sierra.jpg "$volume_path"/Library/Desktop\ Pictures/Default.jpg
		fi
		if [[ -e "$volume_path"/Library/Desktop\ Pictures/.thumbnails/High\ Sierra.jpg ]]; then
			mv "$volume_path"/Library/Desktop\ Pictures/.thumbnails/High\ Sierra.jpg "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Default.jpg
		fi
	fi
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Patched system wallpapers."${erase_style}

	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Patching setup icons."${erase_style}
	if [[ $volume_version_short == "10.14" ]]; then
		cp "$patch_resources_path"/"$wallpaper"/setup/Assets.car "$volume_path"/System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/
	fi

	if [[ $volume_version_short == "10.13" ]]; then
		cp "$patch_resources_path"/"$wallpaper"/system/SystemLogo.icns "$volume_path"/System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/
	fi

	if [[ $volume_version_short == "10.12" ]]; then
		cp "$patch_resources_path"/"$wallpaper"/system/SystemLogo.tiff "$volume_path"/System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/
	fi

	if [[ $volume_version_short == "10.1"[0-1] ]]; then
		cp "$patch_resources_path"/"$wallpaper"/system/SystemLogo.tiff "$volume_path"/System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/newX.tiff
	fi
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Patched setup icons."${erase_style}

	if [[ $volume_version_short == "10.14" ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Patching preference panes icons."${erase_style}
			cp "$patch_resources_path"/"$wallpaper"/appearance/Assets.car "$volume_path"/System/Library/PreferencePanes/Appearance.prefPane/Contents/Resources/
		echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Patched preference panes icons."${erase_style}
	fi
}

Revert_Volume()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Removing device icons."${erase_style}
	cp -R "$revert_resources_path"/CoreTypes/ "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/

	if [[ -d "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MJTlrL7BTqUr.bundle ]]; then
		cp "$revert_resources_path"/CoreTypes/com.apple.macbook-retina-gold.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MJTlrL7BTqUr.bundle/Contents/Resources
		cp "$revert_resources_path"/CoreTypes/com.apple.macbook-retina-silver.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MJTlrL7BTqUr.bundle/Contents/Resources
		cp "$revert_resources_path"/CoreTypes/com.apple.macbook-retina-space-gray.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MJTlrL7BTqUr.bundle/Contents/Resources
	fi

	if [[ -d "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes.bundle ]]; then
		cp "$revert_resources_path"/CoreTypes/com.apple.macbook-retina-rose-gold.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes.bundle/Contents/Resources
	fi

	if [[ -d "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-3DC57F5C7A.bundle ]]; then
		cp "$revert_resources_path"/CoreTypes/com.apple.macbookpro-13-retina-usbc-space-gray.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-3DC57F5C7A.bundle/Contents/Resources
		cp "$revert_resources_path"/CoreTypes/com.apple.macbookpro-13-retina-usbc-silver.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-3DC57F5C7A.bundle/Contents/Resources
		cp "$revert_resources_path"/CoreTypes/com.apple.macbookpro-13-retina-touchid-space-gray.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-BBBAA77A32.bundle/Contents/Resources
		cp "$revert_resources_path"/CoreTypes/com.apple.macbookpro-13-retina-touchid-silver.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-BBBAA77A32.bundle/Contents/Resources
		cp "$revert_resources_path"/CoreTypes/com.apple.macbookpro-15-retina-touchid-space-gray.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-C4EBFEA440.bundle/Contents/Resources
		cp "$revert_resources_path"/CoreTypes/com.apple.macbookpro-15-retina-touchid-silver.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-C4EBFEA440.bundle/Contents/Resources
	fi

	if [[ -d "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-23D5DDDA06.bundle ]]; then
		cp -R "$revert_resources_path"/CoreTypes/ "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-23D5DDDA06.bundle/Contents/Resources/
	fi

	if [[ -d "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018a.bundle ]]; then
		cp "$revert_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbook-retina-gold-2018.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018b.bundle/Contents/Resources
		cp "$revert_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookair-2018-gold.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018c.bundle/Contents/Resources
		cp "$revert_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookair-2018-silver.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018c.bundle/Contents/Resources
		cp "$revert_resources_path"/"$wallpaper"/CoreTypes/com.apple.macbookair-2018-space-gray.icns "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018c.bundle/Contents/Resources
	fi
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Removed device icons."${erase_style}

	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Removing system icons."${erase_style}
	if [[ $volume_version_short == "10.14" ]]; then
		cp "$revert_resources_path"/system/Assets.car "$volume_path"/Applications/Utilities/System\ Information.app/Contents/Resources/
	fi

	if [[ $volume_version_short == "10.1"[0-3] ]]; then
		cp "$revert_resources_path"/system/SystemLogo.tiff "$volume_path"/Applications/Utilities/System\ Information.app/Contents/Resources/
	fi
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Removed system icons."${erase_style}

	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Removing system wallpapers."${erase_style}
	if [[ $volume_version_short == "10.13" ]]; then
		rm "$volume_path"/Library/Desktop\ Pictures/Desert\ 5.jpg
		rm "$volume_path"/Library/Desktop\ Pictures/Desert\ 6.jpg
		rm "$volume_path"/Library/Desktop\ Pictures/Mojave\ Day.jpg
		rm "$volume_path"/Library/Desktop\ Pictures/Mojave\ Night.jpg
	fi

	rm "$volume_path"/Library/Desktop\ Pictures/RMC.jpg
	rm "$volume_path"/Library/Desktop\ Pictures/Catalina\ Light.jpg
	rm "$volume_path"/Library/Desktop\ Pictures/Catalina\ Dark.jpg
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Removed system wallpapers."${erase_style}
	
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Removing system wallpapers."${erase_style}
	if [[ $volume_version_short == "10.14" ]]; then
		rm "$volume_path"/System/Library/CoreServices/DefaultBackground.jpg
		rm "$volume_path"/System/Library/CoreServices/DefaultDesktop.heic

		ln -s "$volume_path"/Library/Desktop\ Pictures/Mojave\ Day.jpg "$volume_path"/System/Library/CoreServices/DefaultBackground.jpg
		ln -s "$volume_path"/Library/Desktop\ Pictures/Mojave.heic "$volume_path"/System/Library/CoreServices/DefaultDesktop.heic

		if [[ -e "$volume_path"/Library/Desktop\ Pictures/Default.heic ]]; then
			mv "$volume_path"/Library/Desktop\ Pictures/Default.heic "$volume_path"/Library/Desktop\ Pictures/Mojave.heic
		fi
		if [[ -e "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Default.heic ]]; then
			mv "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Default.heic "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Mojave.heic
		fi
	fi

	if [[ $volume_version_short == "10.1"[0-3] ]]; then
		rm "$volume_path"/System/Library/CoreServices/DefaultDesktop.jpg

		ln -s "$volume_path"/Library/Desktop\ Pictures/High\ Sierra.jpg "$volume_path"/System/Library/CoreServices/DefaultDesktop.jpg
		rm "$volume_path"/Library/Caches/com.apple.desktop.admin.png

		if [[ -e "$volume_path"/Library/Desktop\ Pictures/Default.jpg ]]; then
			mv "$volume_path"/Library/Desktop\ Pictures/Default.jpg "$volume_path"/Library/Desktop\ Pictures/High\ Sierra.jpg
		fi
		if [[ -e "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Default.jpg ]]; then
			mv "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Default.jpg "$volume_path"/Library/Desktop\ Pictures/.thumbnails/High\ Sierra.jpg
		fi
	fi
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Removed system wallpapers."${erase_style}

	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Removing setup icons."${erase_style}
	if [[ $volume_version_short == "10.14" ]]; then
		cp "$revert_resources_path"/setup/Assets.car "$volume_path"/System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/
	fi
	
	if [[ $volume_version_short == "10.13" ]]; then
		cp "$revert_resources_path"/system/SystemLogo.icns "$volume_path"/System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/
	fi

	if [[ $volume_version_short == "10.12" ]]; then
		cp "$revert_resources_path"/system/SystemLogo.tiff "$volume_path"/System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/
	fi

	if [[ $volume_version_short == "10.1"[0-1] ]]; then
		cp "$revert_resources_path"/system/SystemLogo.tiff "$volume_path"/System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/newX.tiff
	fi
	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Removed setup icons."${erase_style}

	if [[ $volume_version_short == "10.14" ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Removing preference panes icons."${erase_style}
			cp "$revert_resources_path"/appearance/Assets.car "$volume_path"/System/Library/PreferencePanes/Appearance.prefPane/Contents/Resources/
		echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Removed preference panes icons."${erase_style}
	fi
}

Repair()
{
	chown -R 0:0 "$@"
	chmod -R 755 "$@"
}

Repair_Permissions()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Repairing permissions."${erase_style}

	Repair "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/

	if [[ $machardwaretypes_1 == "yes" ]]; then
		Repair "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-23D5DDDA06.bundle/Contents/Resources/
	fi

	if [[ $machardwaretypes_2 == "yes" ]]; then
		Repair "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018b.bundle/Contents/Resources/
		Repair "$volume_path"/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MacHardwareTypes-2018c.bundle/Contents/Resources/
	fi

	Repair "$volume_path"/Applications/Utilities/System\ Information.app/Contents/Resources/

	if [[ $volume_version_short == "10.14" ]]; then
		Repair "$volume_path"/System/Library/CoreServices/DefaultBackground.jpg
		Repair "$volume_path"/System/Library/CoreServices/DefaultDesktop.heic
	fi

	if [[ $volume_version_short == "10.13" ]]; then
		Repair "$volume_path"/System/Library/CoreServices/DefaultDesktop.jpg

		Repair "$volume_path"/Library/Desktop\ Pictures/Desert\ 5.jpg
		Repair "$volume_path"/Library/Desktop\ Pictures/Desert\ 6.jpg
		Repair "$volume_path"/Library/Desktop\ Pictures/Mojave\ Day.jpg
		Repair "$volume_path"/Library/Desktop\ Pictures/Mojave\ Night.jpg
	fi

	if [[ -e "$volume_path"/Library/Desktop\ Pictures/Mojave.heic ]]; then
		Repair "$volume_path"/Library/Desktop\ Pictures/Mojave.heic
	fi
	if [[ -e "$volume_path"/Library/Desktop\ Pictures/Default.heic ]]; then
		Repair "$volume_path"/Library/Desktop\ Pictures/Default.heic
	fi
	if [[ -e "$volume_path"/Library/Desktop\ Pictures/Default.jpg ]]; then
		Repair "$volume_path"/Library/Desktop\ Pictures/Default.jpg
	fi
	if [[ -e "$volume_path"/Library/Desktop\ Pictures/High\ Sierra.jpg ]]; then
		Repair "$volume_path"/Library/Desktop\ Pictures/High\ Sierra.jpg
	fi

	if [[ -e "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Mojave.heic ]]; then
		Repair "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Mojave.heic
	fi
	if [[ -e "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Default.heic ]]; then
		Repair "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Default.heic
	fi
	if [[ -e "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Default.jpg ]]; then
		Repair "$volume_path"/Library/Desktop\ Pictures/.thumbnails/Default.jpg
	fi
	if [[ -e "$volume_path"/Library/Desktop\ Pictures/.thumbnails/High\ Sierra.jpg ]]; then
		Repair "$volume_path"/Library/Desktop\ Pictures/.thumbnails/High\ Sierra.jpg
	fi

	Repair "$volume_path"/System/Library/CoreServices/Setup\ Assistant.app/Contents/Resources/

	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Repaired permissions."${erase_style}	
}

Rebuild_Cache()
{
	echo -e $(date "+%b %m %H:%M:%S") ${text_progress}"> Rebuilding cache."${erase_style}

	find "$volume_path"/private/var/folders/ -name com.apple.dock.iconcache -exec rm {} \;
	rm -rf "$volume_path"/Library/Caches/com.apple.iconservices.store

	echo -e $(date "+%b %m %H:%M:%S") ${move_up}${erase_line}${text_success}"+ Rebuilt cache."${erase_style}
}

Input_Restart()
{
	if [[ $(diskutil info "$volume_name"|grep "Mount Point") == *"/" && ! $(diskutil info "$volume_name"|grep "Mount Point") == *"/Volumes" ]]; then
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Would you like to restart now?"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Input an operation number."${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     1 - No"${erase_style}
		echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/     2 - Yes"${erase_style}
		Input_On
		read -e -p "$(date "+%b %m %H:%M:%S") / " operation_restart
		Input_Off

		if [[ $operation_restart == "1" ]]; then
			echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Restart your machine soon."${erase_style}
			echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Thank you for using Desert Deserter"${erase_style}
			Input_On
			exit
		fi

		if [[ $operation_restart == "2" ]]; then
			echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Your machine will restart soon."${erase_style}
			echo -e $(date "+%b %m %H:%M:%S") ${text_message}"/ Thank you for using Desert Deserter."${erase_style}
			reboot
		fi
	fi
}

Input_Off
Escape_Variables
Parameter_Variables
Path_Variables
Check_Environment
Check_Root
Check_SIP
Check_Resources
Check_Internet
Check_Options
Input_Volume
Check_Volume_Version
Check_Volume_Support
Input_Operation
Repair_Permissions
Rebuild_Cache
Input_Restart