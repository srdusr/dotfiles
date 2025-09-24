#!/usr/bin/env awk -f
#
# AWK script to send multiple `sendkey` commands to a QEMU virtual machine.
# It writes at a rate of roughly 40 keys per second, due to lower delays
# resulting in garbage output.
#
# It makes use of a TCP client created by an external utility, such as OpenBSD
# Netcat, to interact with QEMU's monitor and send a stream of `sendkey`
# commands. This is a practical way to transfer a small file or to script
# interactions with a terminal user interface.

BEGIN {
  # Set default delay if not provided via command-line args
  if (!delay) {
    delay = 0.025
  }

  # Define key mappings for common characters and symbols
  key["#"] = "backspace"
  key["	"] = "tab"
  key[" "] = "spc"
  key["!"] = "shift-1"
  key["\""] = "shift-apostrophe"
  key["#"] = "shift-3"
  key["$"] = "shift-4"
  key["%"] = "shift-5"
  key["&"] = "shift-7"
  key["'"] = "apostrophe"
  key["("] = "shift-9"
  key[")"] = "shift-0"
  key["*"] = "shift-8"
  key["+"] = "shift-equal"
  key[","] = "comma"
  key["-"] = "minus"
  key["."] = "dot"
  key["/"] = "slash"
  key[":"] = "shift-semicolon"
  key[";"] = "semicolon"
  key["<"] = "shift-comma"
  key["="] = "equal"
  key[">"] = "shift-dot"
  key["?"] = "shift-slash"
  key["@"] = "shift-2"

  # Map numbers
  for (i = 48; i < 48 + 10; ++i) {
    number = sprintf("%c", i)
    key[number] = number
  }

  # Map letters A-Z, including shift
  for (i = 65; i < 65 + 26; ++i) {
    key[sprintf("%c", i)] = sprintf("shift-%c", i + 32)
  }

  # Other symbols
  key["["] = "bracket_left"
  key["\\"] = "backslash"
  key["]"] = "bracket_right"
  key["^"] = "shift-6"
  key["_"] = "shift-minus"
  key["`"] = "grave_accent"
  key["{"] = "shift-bracket_left"
  key["|"] = "shift-backslash"
  key["}"] = "shift-bracket_right"
  key["~"] = "shift-grave_accent"
  key[""] = "delete"

  # Handle Super and Caps Lock key mappings (for remapping Caps to Super)
  key["capslock"] = "super"
  key["super"] = "super"

  # Handle other keys if needed
}

{
  split($0, chars, "")
  for (i = 1; i <= length($0); i++) {
    # Print sendkey command for the character, mapping it through the key[] array
    if (key[chars[i]] != "") {
      printf("sendkey %s\n", key[chars[i]])
    }
    system("sleep " delay) # Sleep for the defined delay
  }
  printf "sendkey ret\n" # Send "return" (enter) key at the end
}
