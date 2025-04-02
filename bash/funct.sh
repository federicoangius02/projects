#!/bin/bash

b() {
    echo "Il valore di a è: $1"
}

read -p "Inserisci il valore di a: " a

b "$a"