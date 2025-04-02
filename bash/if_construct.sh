#!/bin/bash

read -p 'Are you a male or a female (m/f): '

if [[ $REPLY == 'm' ]]; then
    echo 'Male'
elif [[ $REPLY == 'f' ]]; then
    echo 'female'
else
    echo 'Wrong answer'
    exit 1
fi
