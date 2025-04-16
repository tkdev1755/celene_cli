#!/bin/bash

gcc -fPIC -shared \
  -o libkeychain.so \
  linuxKeychain.c \
  `pkg-config --cflags --libs libsecret-1`

