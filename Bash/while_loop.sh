#!/bin/bash

a=1

while [[ $a -lt 10 ]]
do 
    ((a++))
done

echo "Valore di a è uguale a: $a"