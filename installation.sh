#! /bin/bash

# DISCLAIMER: This script is currently under development and hasn't been tested !!!

#-------------------------------------------------------------------------------------------------------
#
# Filename : installation.sh
# Description: Script for auto installing and configuring software in several linux distros
# Author: Alexandros Dorodoulis
#
# Software for distros with "apt-get":
#   Software for Ubuntu :
#     Tools: Wget, Curl, Git, Dropbox, Y PPA Manager, Ubuntu Make, Ubuntu restricted
#     Text Editors: Vim,  Atom, Sublime
#     Multimedia Vlc, Gimp, Spotify
#     Browsers: Firefox for developers, Chromium, Chrome
#     Mail Clients / IM: Thunderbird
#     Security: Iptables, Wireshark, Hydra, Nmap, Aircrack-ng, Medusa
#     Compilers: Python, Oracle's jdk 8, Ruby, G++, GCC
#     IDEs: IntelliJ IDEA, Android Studio, Eclipse, Pycharm
#   Other distros: TO DO
# Software for distros with "yum" : TO DO
# Software for distros with "zypper" : TO DO
# Software for distros with "pacman" : TO DO
# Software for distros with "yaourt" : TO DO
#
#-------------------------------------------------------------------------------------------------------

export distro=$(lsb_release -si) # Linux distribution
export displayLog=false
export logDir="/var/log/installation_script" # Log directory
export logFile="$logDir/installation_script.log" # Log file
export architecture=$(uname -m) # Computer's architecture
export tempDir=$(mktemp -d /tmp/tempdir.XXXXXXXX) # Create temp directory
declare -a apps=(wget vim git curl zsh tmux g++ gcc) # Programms from the official repo to be install
export alreadyInstalledCode=999

# Check for root privilages
function check_root_privilages(){
   if [[ $EUID -ne 0 ]]; then
     echo "This script needs root privilages"
     exit 1
fi
}

# Check the internet connection
function check_conection(){
  if ![ "$(ping -c 1 google.com)" ];then
    echo "Please check your internet connection and execute the script again"
    exit 2
  fi
}

# Find the package manager
function find_package_manager_tool(){
  if [ -x $(which apt-get) ];  then
    packageManagerTool="apt-get"
  elif [ -x "$(which yum)" ]; then
    packageManagerTool="yum"
  elif [ -x "$(which zypper )" ]; then
    packageManagerTool="zypper"
  elif [ -x "$(which pacman)" ]; then
    packageManagerTool="pacman"
  elif [ -x "$(which yaourt)" ]; then
    packageManagerTool="yaourt"
  else
      echo "Your package manager isn't supported"
      exit 3
  fi
}

# Install applications from reposittories
function install_repo_apps(){
  name=$1[@]
  arrayName=("${!name}")
  for i in "${arrayName[@]}"; do
    if ! appLocation="$(type -p "$i")" || [ -z "$appLocation" ]; then # Check if the application isn't installed
      case $packageManagerTool in
	pacman)
		$packageManagerTool -S $i
	;;
	*)
		$packageManagerTool install -y $i
	;;
	esac	      	
	exitLog=$?
      write_log $i $exitLog
    else
      write_log $i $alreadyInstalledCode
    fi
  done
}

# Create log directory
function create_log_directory(){
    	if [ ! -d $logDir ];then
    		mkdir $logDir
    		chown $USER:$USER $logDir
    	fi
    	if [ -e $logFile ];then
    		mv $logFile $logFile$(date +%Y%m%d).log
    		touch $logFile
    	fi
}

# Write log file
function write_log(){
  if [ -z "$2" ];then
    echo "$1 : Parameter error" >> $logFile
  else
    case $2 in
      0)
        echo "$1 : successfully installed" >> $logFile
        ;;
      $alreadyInstalledCode)
        echo "$1 : already installed" >> $logFile
        ;;
      *)
        echo "$1 : installation failed (error code = $2)" >> $logFile
        showLog=true
        ;;
      esac
    fi
}

# Configure tmux
function configure_tmux(){
  # Check for existing files or directories and create needed ones
    if [[ -e ~/.tmux.conf ]] ; then
  	   mv ~/.tmux.conf ~/.tmux.conf.old$(date +%Y%m%d)
  	  fi
    if [[ -e ~/.tmux ]] ; then
  	   mv ~/.tmux ~/.tmux.old$(date +%Y%m%d)
  	  fi
    if [[ ! -d ~/.tmux ]] ; then
	     mkdir ~/.tmux
    else
      if [[ -e ~/.tmux/inx ]] ; then
    	   mv ~/.tmux/inx ~/.tmux/inx.old$(date +%Y%m%d)
    	  fi
      if [[ -e ~/.tmux/xless ]] ;
	       then mv ~/.tmux/xless ~/.tmux/xless.old$(date +%Y%m%d)
	      fi
    fi
  # Download configuration files
    wget -O ~/.tmux.conf -q https://raw.githubusercontent.com/alexdor/tmux/master/.tmux.conf
    wget -O ~/.tmux/inx -q https://raw.githubusercontent.com/alexdor/tmux/master/.tmux/inx
    wget -O ~/.tmux/xless -q https://raw.githubusercontent.com/alexdor/tmux/master/.tmux/xless
}

# Install and configure oh-my-zsh
function configure_zsh(){
  wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | bash

  # Install zsh-syntax-highlighting
    if [[ ! -d ~/.oh-my-zsh/custom ]]; then
	     mkdir ~/.oh-my-zsh/costum
	    fi
    cd ~/.oh-my-zsh/custom/plugins
    git clone git://github.com/zsh-users/zsh-syntax-highlighting.git
    cd

  # Configure .zshrc
    sed -i 's/#COMPLETION_WAITING_DOTS/COMPLETION_WAITING_DOTS/' ~/.zshrc
    sed -i 's/robbyrussell/wedisagree/' ~/.zshrc
    sed -i 's/plugins=(.*/plugins=(git command-not-found tmux zsh-syntax-highlighting)/g' ~/.zshrc

  # Set zsh as the default shell
    chsh -s $(which zsh)
}

# Install the latest build of Sublime Text 3
function install_sublime_text_3(){
  aptGetUrl="http://c758482.r82.cf2.rackcdn.com/sublime-text_build-"
  elseGetUrl="http://c758482.r82.cf2.rackcdn.com/sublime_text_3_build_"
  build=$(curl -Ls https://www.sublimetext.com/3 |
          grep '<h2>Build' | head -n1 |
          sed -E 's#<h2>Build ([0-9]+)</h2>#\1#g')
  sublimeName="Sublime_Text_3_$build"

  if [$packageManagerTool == "apt-get"]; then
    if [[ ! -z $(which subl) && $(subl -v | awk '{print $NF}') == $build ]] ; then
      write_log $sublimeName $alreadyInstalledCode
    else
      if [ $architecture == "x86_64" ]; then
        url=$aptGetUrl$build"_amd64.deb"
      else
        url=$aptGetUrl$build"_i386.deb"
      fi
    fi
    wget -q $url
    dpkg -i sublime-text_build*
    exitLog=$?
    write_log $sublimeName $exitLog
  else
    if [[ ! -z $(which subl) && $(subl -v | awk '{print $NF}') == $build ]] ; then
      write_log $sublimeName $alreadyInstalledCode
    else
      if [ $architecture == "x86_64" ]; then
        url=$elseGetUrl$build"_x64.tar.bz2"
      else
        url=$elseGetUrl$build"_x32.tar.bz2"
      fi
      wget -q $url
      tar vxjf sublime*
      rm sublime*.tar.br2
      cp sublime_text_3 /opt/
      ln -s /opt/sublime_text_3/sublime_text /usr/bin/subl
    fi
  fi
}

# Main part
check_conection
check_root_privilages
find_package_manager_tool

cd $tempDir

if [[ $distro == "Ubuntu" ]];then
  apt-get install -y wget
  wget -q -O - https://raw.githubusercontent.com/GNULinuxACMTeam/installing_software_on_linux/master/installation_alexdor.sh | bash
else
  install_repo_apps apps
  install_sublime_text_3
  case $packageManagerTool in
    apt-get)
      #TO DO
      wget -q https://atom.io/download/deb
      dpkg -i atom*
      ;;
    yum || zypper)
      #TO DO
      wget -q https://atom.io/download/rpm
      rpm -i atom*
      ;;
    pacman || yaourt)
      #TO DO
      ;;
    *)
      echo "This script doesn't support your package manager"
        ;;
  esac
  configure_tmux
  configure_zsh
fi

rm -rf $tempDir
