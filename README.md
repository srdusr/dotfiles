## Dotfiles mainly for linux 
    
- - -  
  
### Dependencies  
- fzf    
- ripgrep    
- ninja  
- cmake  

  
- - -  
  
### Development Environment  
#### Languages  
##### Python  
##### Java  
Recommended to choose Openjdk 8 or 10 otherwise get an error when using Android tools  
##### Rust  
- Download and run rustup script  
```bash  
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh    
```  
##### Go  
```bash

```

##### Lua  
- Download LuaRocks  
```bash
$ git clone git://github.com/luarocks/luarocks.git  
```
- Install and specify the installation directory to build and configure LuaRocks  
```bash
$ ./configure --prefix=/usr/local/luarocks
$ make build
$ sudo make install
```
- Add LuaRocks to system's environment variables by running the following command or add it `.bashrc`/`.zshrc` or any similar shell configuration file to make it persistent across sessions  
```bash
export PATH=$PATH:/usr/local/luarocks/bin
```
- Install Lua
```bash
$ luarocks install lua
```

##### PHP  
- Install PHP  
- Install Web server (Apache or Nginx)  
- Install PHP extensions   
```
php-apache php-cgi php-fpm php-gd  php-embed php-intl php-redis php-snmp  
mysql-server php8.1-mysql  
phpmyadmin  
```
  
- Install composer (Dependency Manager for PHP)  
```bash  
$ curl -sS https://getcomposer.org/installer | php  
```  
- Install laravel  
```bash  
$ composer global require laravel/installer  
```  
- Edit PHP config  
```bash  
$ sudoedit /etc/php/php.ini  
```  
- Enable PHP extensions, make sure these lines are uncommented (remove the `;` from each line)  
```  
extention=bcmath  
extention=zip  
extension=pdo_mysql  
extension=mysqli  
extension=iconv  
  
extension=gd  
extension=imagick  
extension=pdo_pgsql  
extension=pgsql  
```  
- Recommended to set correct timezone  
```  
date.timezone = <Continent/City>  
```  
- Display errors to debug PHP code  
```  
display_errors = On  
```  
- Allow paths to be accessed by PHP  
```  
open_basedir = /srv/http/:/var/www/:/home/:/tmp/:/var/tmp/:/var/cache/:/usr/share/pear/:/usr/share/webapps/:/etc/webapps/  
```  
  
  
##### Dart  
- Install dart or skip and install flutter (recommended) that includes dart    
```bash  
$ curl -O "https://storage.googleapis.com/dart-archive/channels/be/raw/latest/sdk/dartsdk-linux-x64-release.zip"  
$ unzip dartsdk-linux-x64-release.zip  
$ sudo mv dart-sdk /usr/lib/dart  
```  
NOTE: If Dart SDK is downloaded separately, make sure that the Flutter version of dart is first in path, as the two versions might not be compatible. Use this command `which flutter dart` to see if flutter and dart originate from the same bin directory and are therefore compatible.  
- Install flutter  
```bash  
$ git clone https://github.com/flutter/flutter.git -b stable  
```  
- Move flutter to the `/opt` directory  
```bash
$ sudo mv flutter /opt/
```
- Export Flutter over Dart by putting this into `.bashrc`/`.zshrc` or any similar shell configuration file to make it persistent across sessions  
```bash
export PATH="/opt/flutter:/usr/lib/dart/bin:$PATH"
```
- Set permissions since only Root has access    
```bash  
$ sudo groupadd flutterusers  
$ sudo gpasswd -a $USER flutterusers  
$ sudo chown -R :flutterusers /opt/flutter  
$ sudo chmod -R g+w /opt/flutter/  
```  
- If still getting any permission denied errors then do this    
```bash  
$ sudo chown -R $USER /opt/flutter  
```  
- Continue to step ***Android Studio*** section to complete setup  
  
##### Javascript    
- nvm install/update script    
```bash  
$ curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash    
```  
- Put these lines into `.bashrc`/`.zshrc` or any similar shell configuration file to make it persistent across sessions  
```bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
```
- Install node    
```bash  
$ nvm install node  
```  
  
##### MySQL    
- Install MySQL  
  
- Ensure the MySQL service starts when reboot or startup machine.  
```bash  
$ sudo systemctl start mysqld    
```  
  
- Setup MySQL for use  
```bash  
$ sudo mysql_secure_installation  
```  
  
- To check its installed and working just open up mysql command prompt with  
```  
$ sudo mysql  
```  
##### Android Studio/SDK  
> NOTE: Android Studio is an Integrated Development Environment (IDE) that provides a comprehensive set of tools for Android app development. It includes the Android SDK (Software Development Kit), which consists of various libraries, tools, and system images necessary for developing Android applications.

> The Android SDK can be installed separately without Android Studio, allowing you to use alternative text editors or IDEs for development. However, Android Studio provides a more streamlined and feature-rich development experience.

> Make sure to properly set the Java environment (either 8 or 10, eg., java-8-openjdk) otherwise android-studio will not start.  

> If Android Studio shows up as a blank window try exporting `_JAVA_AWT_WM_NONREPARENTING=1`.  
- Install android studio  
  - Directly from the official website  
  ```bash  
  $ curl -L -o android-studio.tar.gz "$(curl -s "https://developer.android.com/studio#downloads" | grep -oP 'https://redirector\.gvt1\.com/[^"]+' | head -n 1)"  
  $ tar -xvzf android-studio.tar.gz  
  $ sudo mv android-studio /opt/  
  $ cd /opt/android-studio/bin script # Configure Android Studio by running this script    
  $ ./studio.sh  
  ```  
  - Or optionally install jetbrains-toolbox that includes android-studio amongst many other applications/tools from jetbrains  
  ```bash  
  $ latest_url=$(curl -sL "https://data.services.jetbrains.com/products/releases?code=TBA" | grep -oP 'https://download.jetbrains.com/toolbox/jetbrains-toolbox-\d+\.\d+\.\d+\.\d+\.tar\.gz' | head -n 1) && curl -L -o jetbrains-toolbox.tar.gz "$latest_url"  
  $ tar -xvzf jetbrains-toolbox.tar.gz  
  $ sudo mv jetbrains-toolbox /opt/jetbrains  
  ```  
- Complete the Android Studio Setup Wizard  
  - Click `Next` on the Welcome Window  
  - Click `Custom` and `Next`
  - Make sure `/opt/android-sdk` directory exists otherwise create it by typing in the following command in a terminal  
  ```bash
  $ sudo mkdir /opt/android-sdk
  ```
  - Click on the folder icon next to the SDK path field.
  - In the file picker dialog, navigate to the /opt directory and select the android-sdk directory.
  - Proceed with the setup wizard, following the remaining instructions to complete the installation.

- Put these lines into `.bashrc`/`.zshrc` or any similar shell configuration file to make it persistent across sessions  
```
# Android Home
export ANDROID_HOME=/opt/android-sdk
export PATH=$ANDROID_HOME/tools:$PATH
export PATH=$ANDROID_HOME/tools/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
# Android emulator PATH
export PATH=$ANDROID_HOME/emulator:$PATH
# Android SDK ROOT PATH
export ANDROID_SDK_ROOT=/opt/android-sdk
export PATH=$ANDROID_SDK_ROOT:$PATH
```
- Android SDK and tools installation  
  > NOTE: Can be installed either through Android Studio or separately.  
  - Android Studio Installed: Launch Android Studio and go to the "SDK Manager" (usually found under "Configure" or "Preferences" menu). From the SDK Manager, select the desired SDK components (platforms, build tools, system images, etc.) and click "Apply" to install them.  
  - To install Android SDK separately (without Android Studio):  
  ```bash
  $ curl -L -o commandlinetools.zip "$(curl -s "https://developer.android.com/studio#downloads" | grep -oP 'https://dl.google.com/android/repository/commandlinetools-linux-\d+_latest\.zip' | head -n 1)"
  $ unzip commandlinetools.zip -d android-sdk
  $ sudo mv android-sdk /opt/
  ```
- If Android SDK was installed separately then configure the user's permissions since android-sdk is installed in /opt/android-sdk directory  
```bash
$ sudo groupadd android-sdk  
$ sudo gpasswd -a $USER android-sdk  
$ sudo setfacl -R -m g:android-sdk:rwx /opt/android-sdk  
$ sudo setfacl -d -m g:android-sdk:rwX /opt/android-sdk  
```
- If Android SDK was installed separately then install platform-tools and build-tools like this:  
  - First list `sdkmanager`'s available/installed packages  
  ```bash
  $ sdkmanager --list
  ```
  - Install platform-tools and build-tools
  > NOTE: Replace <version> with the specific version number for platforms and build tools to install (e.g.,  "platforms;android-`33`" "build-tools;`34.0.0`").  
  ```bash
  $ sdkmanager "platform-tools" "platforms;android-<version>" "build-tools;<version>"
  ```
- Android emulator  
  - List of available android system images.  
  ```bash  
  $ sdkmanager --list  
  ```
  - Install an android image of your choice. For example.  
  ```bash  
  $ sdkmanager --install "system-images;android-29;default;x86"  
  ```
  - Then create an android emulator using Android Virtual Devices Manager  
  ```bash  
  $ avdmanager create avd -n <name> -k "system-images;android-29;default;x86"  
  ```
- Continuing from ***Dart(flutter)*** section  
  - Update Flutter Config SDK PATH for custom SDK PATH  
  ```bash  
  $ flutter config --android-sdk /opt/android-sdk  
  ```  
  - Accept all of licences by this command  
  ```
  $ flutter doctor --android-licenses  
  ```
  - If licences are still not accepted even after running `flutter doctor --android-licences` try these commands and then run `flutter doctor --android-licences again`  
  ```
  $ sudo chown -R $(whoami) $ANDROID_SDK_ROOT  
  ```
  - Run this  
  ```
  $ flutter doctor  
  ```
- Update emulator binaries  
```bash
$ sdkmanager --sdk_root=${ANDROID_HOME} tools  
```
- Accept emulator licenses  
> NOTE: Required to accept the necessary license for each package installed.  
```bash
$ sdkmanager --licenses  
```
- - -  
  
### Commands  
  
  
- - -  
