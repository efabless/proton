#!/bin/sh

Xvfb -ac :$1 &
DISPLAY=localhost:$1 proton --win &
