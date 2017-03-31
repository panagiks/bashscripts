#! /bin/bash

#-------------------------------------------------------------------------------------------------------
#
# Filename : installation_ubuntu.sh
# Author: Alexandros Dorodoulis
# Description: Script for installing the following programms on Ubuntu
#   Tools: Wget, Curl, Tmux, Zsh, Git, Dropbox, Ubuntu Make, Ubuntu restricted, Unity tweak
#   Text Editors: Vim, Atom, Sublime
#   Multimedia Vlc, Gimp, Spotify
#   Browsers: Firefox for developers, Chromium, Chrome
#   Mail Clients / IM: Thunderbird
#   Security: Iptables, Wireshark, Hydra, Nmap, Aircrack-ng, Medusa
#   Compilers: Python, Oracle's jdk 8, Ruby, G++, GCC
#   IDEs: IntelliJ IDEA, Android Studio, Eclipse, Pycharm
#
#-------------------------------------------------------------------------------------------------------


export logDir="/var/log/installation_script" #Log directory
export logFile="$logDir/installation_script_ubuntu.log" # Log file
export architecture=$(uname -m) # Computers architecture
export tempDir=$(mktemp -d /tmp/tempdir.XXXXXXXX) # Create temp directory
export alreadyInstalledCode=999 # Already installed code
export showLog=false
userRunningTheScript=$SUDO_USER # Find the user who is running the script

# Set home path
if [[ ! -z  $userRunningTheScript ]]; then
	userHome="/home/$userRunningTheScript/"
else
	userHome="/root/"
fi

# Programms to be installed from reposittories
declare -a tools=(wget curl git ubuntu-make ubuntu-restricted-extras unity-tweak-tool) #Tools
declare -a textEditor=(vim nano atom) #Text Editors
declare -a multimedia=(vlc) #Multimedia
declare -a browsers=(firefox chromium-browser google-chrome-stable) #Browsers
declare -a mailClient=(thunderbird) #Mail Client
declare -a security=(iptables wireshark hydra nmap aircrack-ng medusa) #Security
declare -a compilers=(ruby python3 python3-pip g++ gcc oracle-java8-installer oracle-java8-set-default) #Compilers

# Check for root privilages
function check_root_privilages(){
 if [[ $EUID -ne 0 ]]; then
   echo "This script needs root privilages"
   exit 1
  fi
}

# Check the internet connection
function check_conection(){
  if [[ ! "$(ping -c 1 google.com)" ]];then
    echo "Please check your internet connection and execute the script again"
    exit 2
  fi
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
  #TO DO
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

# Install applications from reposittories
function install_repo_apps(){
  name=$1[@]
  arrayName=("${!name}")
  for i in "${arrayName[@]}"; do
    if ! appLocation="$(type -p "$i")" || [ -z "$appLocation" ]; then # Check if the application isn't installed
      apt-get install -y $i
      exitLog=$?
      write_log $i $exitLog
    else
      write_log $i $alreadyInstalledCode
    fi
  done
}

# Gnome Staging PPA, adds Gnome 3.20 to Ubuntu 16.04 LTS. Should run on "clean" installation.
function gnome_staging(){
	add-apt-repository ppa:gnome3-team/gnome3-staging
	apt-get -y dist-upgrade
}

function gnome_themes(){
	if [[ ! -d $userHome/.themes ]]; then
	     mkdir $userHome/.themes
	    fi
	wget -O $userHome/.themes/Gnome-OSX-II-2-5-1.tar.xz -q https://dl.opendesktop.org/api/files/download/id/1489657686/Gnome-OSX-II-2-5-1.tar.xz
	wget -O $userHome/.themes/Gnome-OSX-Dark-Shell.tar.gz -q https://dl.opendesktop.org/api/files/download/id/1488138514/Gnome-OSX-Dark-Shell.tar.gz
	cd $userHome/.themes/
	tar xf Gnome-OSX-II-2-5-1.tar.xz
	tar xf Gnome-OSX-Dark-Shell.tar.gz
	rm Gnome-OSX-II-2-5-1.tar.xz
	rm Gnome-OSX-Dark-Shell.tar.gz
	cd $userHome
	if [[ ! -d $userHome/.icons ]]; then
	     mkdir $userHome/.icons
	    fi
	git clone https://github.com/keeferrourke/la-capitaine-icon-theme.git
}

# Add repositories
function add_repositories(){
	add-apt-repository -y ppa:libreoffice/ppa #Libreoffice oficial repo
#	add-apt-repository -y  ppa:ubuntu-mozilla-daily/firefox-aurora  #Firefox for developers
#	add-apt-repository -y  ppa:otto-kesselgulasch/gimp  #Gimp latest stable version
	add-apt-repository -y  ppa:videolan/stable-daily  #Vlc latest stable version
#	apt-add-repository "deb http://repository.spotify.com stable non-free"  #Spotify
#	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 94558F59 #Spotify public key
	add-apt-repository -y  ppa:webupd8team/java  #Oracle java
	add-apt-repository -y  ppa:webupd8team/atom  #Atom text editor
	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - #Add key for Chrome
	sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'  #Set repo for Chrome
#	apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E #Add key for Dropbox
#	add-apt-repository -y  "deb http://linux.dropbox.com/ubuntu $(lsb_release -sc) main"  #Add repo for Dropbox
	add-apt-repository -y  ppa:ubuntu-desktop/ubuntu-make  #Ubuntu Make
	apt-get update
}

# Install the latest build of Sublime Text 3
function install_sublime_text_3(){
  frontUrl="http://c758482.r82.cf2.rackcdn.com/sublime-text_build-"
  build=$(curl -Ls https://www.sublimetext.com/3 |
          grep '<h2>Build' | head -n1 |
          sed -E 's#<h2>Build ([0-9]+)</h2>#\1#g')

  sublimeName="Sublime_Text_3_$build"

  if [[ ! -z $(which subl) && $(subl -v | awk '{print $NF}') == $build ]] ; then
    		write_log $sublimeName $alreadyInstalledCode
  else
		if [ $architecture == "x86_64" ]; then
      url=$frontUrl$build"_amd64.deb"
      wget -q $url
      dpkg -i sublime-text_build*
      exitLog=$?
      write_log $sublimeName $exitLog

    else
      url=$frontUrl$build"_i386.deb"
      wget -q $url
      dpkg -i sublime-text_build*
      exitLog=$?
      write_log $sublimeName $exitLog
  	fi
	fi
}

# Configure tmux
function configure_tmux(){
  # Check for existing files or directories and create needed ones
    if [[ -e $userHome.tmux.conf ]] ; then
  	   mv $userHome.tmux.conf $userHome.tmux.conf.old$(date +%Y%m%d)
  	  fi
    if [[ -e $userHome.tmux ]] ; then
  	   mv $userHome.tmux $userHome.tmux.old$(date +%Y%m%d)
  	  fi
    if [[ ! -d $userHome.tmux ]] ; then
	     mkdir $userHome.tmux
    else
      if [[ -e $userHome.tmux/inx ]] ; then
    	   mv $userHome.tmux/inx $userHome.tmux/inx.old$(date +%Y%m%d)
    	  fi
      if [[ -e $userHome.tmux/xless ]] ;
	       then mv $userHome.tmux/xless $userHome.tmux/xless.old$(date +%Y%m%d)
	      fi
    fi

  # Download configuration files
    wget -O $userHome.tmux.conf -q https://raw.githubusercontent.com/alexdor/tmux/master/.tmux.conf
    wget -O $userHome.tmux/inx -q https://raw.githubusercontent.com/alexdor/tmux/master/.tmux/inx
    wget -O $userHome.tmux/xless -q https://raw.githubusercontent.com/alexdor/tmux/master/.tmux/xless
}

# Install and configure oh-my-zsh
function configure_zsh(){
  wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O - | bash

  # Install zsh-syntax-highlighting
    if [[ ! -d $userHome/.oh-my-zsh/custom ]]; then
	     mkdir $userHome/.oh-my-zsh/costum
	    fi
    cd $userHome/.oh-my-zsh/custom/plugins
    git clone git://github.com/zsh-users/zsh-syntax-highlighting.git
    cd

  # Configure .zshrc
    sed -i 's/#COMPLETION_WAITING_DOTS/COMPLETION_WAITING_DOTS/' $userHome/.zshrc
    sed -i 's/robbyrussell/wedisagree/' $userHome/.zshrc
    sed -i 's/plugins=(.*/plugins=(git command-not-found tmux zsh-syntax-highlighting)/g' $userHome/.zshrc

  # Set zsh as the default shell
    chsh -s $(which zsh) $userRunningTheScript
}


# Main part
echo "Checking for root privilages"
check_conection
echo "Checking the internet connection"
check_root_privilages
echo "Upgrading Gnome to 3.20"
gnome_staging
echo "Adding necessary repositories"
add_repositories
echo "Creating log directory"
create_log_directory

cd $tempDir
echo "Installing the applications..."

#apt-get -y purge openjdk* #delete openjdk
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections # Accepts oracl's license


# Install all the programms
install_repo_apps tools
install_repo_apps textEditor
install_repo_apps multimedia
install_repo_apps browsers
install_repo_apps mailClient
install_repo_apps compilers
#install_repo_apps security
#install_sublime_text_3

# Download Gnome themes
gnome_themes

# Install IDEs
#	echo "a" | umake android $userHome/tools/android-Studio; write_log android-studio $? # Auto accept android-studio license
#	umake ide idea $userHome/tools/idea; write_log idea $?
#	umake ide eclipse $userHome/tools/eclipse; write_log eclipse $?
#	umake ide pycharm $userHome/tools/pycharm; write_log pycharm $?

# Make user able to run wireshark without root privilages, changes take efect after log out and log in
#		addgroup -system wireshark
#		chown root:wireshark /usr/bin/dumpcap
#		setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap
#		usermod -a -G wireshark $USER

  sed -i 's/gedit.desktop/atom/g' /etc/gnome/defaults.list # Set Atom as default text editor

# Configure Zsh
#configure_zsh

# Configure Tmux
#configure_tmux

#Cleaning up
  rm -rf $tempDir
	apt-get check
	apt-get -f install
	apt-get -y autoremove
	apt-get -y autoclean

echo $showLog
if [[ "$showLog" = true ]]; then
  echo "One or more programms wasn't installed successfully please check the \""$logFile"\" for more informations"
else
  echo "The installation was successful"
fi
