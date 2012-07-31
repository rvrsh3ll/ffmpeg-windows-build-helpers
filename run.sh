#!/usr/bin/env bash

yes_no_sel () {
unset user_input
local question="$1"
shift
while [[ "$user_input" != [YyNn] ]]; do
  echo -n "$question"
  read user_input
  if [[ "$user_input" != [YyNn] ]]; then
    clear; echo 'Your selection was not vaild, please try again.'; echo
  fi
done
# downcase it
user_input=`echo $user_input | tr '[A-Z]' '[a-z]'`
}

pwd=`pwd`

intro () {
  echo "##################### Welcome ######################
  Welcome to the ffmpeg cross-compile builder-helper script.
  Downloads and builds will be installed to directories within $pwd.
  If this is not ok, then exit now, and cd to the directory where you'd
  like them installed, then run this script again."

  yes_no_sel "Is using $pwd as your scratch directory ok [y/n]?"
  if [[ "$user_input" = "n" ]]; then
    exit 1;
  fi
}

install_cross_compiler() {
  if [ -f "mingw-w64-i686/compiler.done" ]; then
   echo "compiler already installed..."
   return
  fi
  read -p 'First we will download and compile a gcc cross-compiler (MinGW-w64).
  You will be prompted with a few questions as it installs (it takes quite awhile).
  Enter to continue:'

  wget http://zeranoe.com/scripts/mingw_w64_build/mingw-w64-build-3.0.6 -O mingw-w64-build-3.0.6
  chmod u+x mingw-w64-build-3.0.6
  ./mingw-w64-build-3.0.6 || exit 1
  touch mingw-w64-i686/compiler.done
  clear
  echo "Ok, done building MinGW-w64 cross-compiler..."
}

do_git_checkout() {
  repo_url="$1"
  to_dir="$2"
  shift
  if [ ! -d $to_dir ]; then
    echo "Downloading (via git clone) $to_dir"
    # prevent partial checkouts by renaming it only after success
    git clone $repo_url $to_dir.tmp
    mv $to_dir.tmp $to_dir
    echo "done downloading $to_dir"
  else
    cd $to_dir
    echo "Updating to latest $to_dir version..."
    git pull
    cd ..
  fi
}


do_configure() {
  configure_options="$1"
  pwd2=`pwd`
  english_name=`basename $pwd2`
  touch_name=`echo -- $configure_options | tr '[/\-\. ]' '_'` # sanitize
  if [ ! -f "$touch_name" ]; then
    echo "configuring $english_name as $configure_options"
    ./configure $configure_options
    touch -- "$touch_name"
  else
    echo "already configured $english_name" 
  fi
  echo "making $english_name"
  make
}

build_x264() {
  do_git_checkout "http://repo.or.cz/r/x264.git" "x264"
  cd x264
  do_configure "--host=i686-w64-mingw32 --enable-static --cross-prefix=../mingw-w64-i686/bin/i686-w64-mingw32- --prefix=../mingw-w64-i686/i686-w64-mingw32 --enable-win32thread"
  make
  make install
  cd ..
}


build_ffmpeg() {
  do_git_checkout https://github.com/FFmpeg/FFmpeg.git ffmpeg_git
  cd ffmpeg_git
  do_configure "--enable-memalign-hack --enable-avisynth --arch=x86   --target-os=mingw32    --cross-prefix=i686-w64-mingw32-  --pkg-config=pkg-config"
  make
  cd ..
  echo 'you can find your binaries in ffmpeg_git/*.exe'
}

intro
install_cross_compiler
build_x264
build_ffmpeg
echo 'exiting run.sh'
