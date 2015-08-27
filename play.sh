#/usr/bin/env bash

# overthewire-launcher
# Copyright (C) 2015 Robin Moussu
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA


SAVE_DIR=.

function echo_color() {
    echo "[1;34m$*[0m"
}

function play() {
    game_path=$1
    game=$(echo $game_path | sed 's#.*/###')
    level=$2

    while true; do
        pass=$(cat $game_path/$level)
        echo "$pass" | xclip -sel clip
        echo_color "Mot de passe pour $game, niveau $level: $pass "\
             "(mis dans le presse papier)"

        ssh "$game$level@$game.labs.overthewire.org"

        current_level=$level
        level=$(echo "$level + 1" | bc)

        echo_color "Enregistrer le mot de passe pour $game, niveau $level ? (Oui/non)"
        read rep
        if [[ "$rep" =~ ^[nN].* ]]; then
            menu
        else
            save $game_path $level

            echo_color 'niveau suivant ? (Oui/non)'
            read rep
            if [[ "$rep" =~ ^[nN].* ]]; then
                menu
                break
            fi
        fi
    done
}

function save() {
    game_path=$1
    game=$(echo $game_path | sed 's#.*/###')
    level=$2

    echo_color "Mot de passe pour le level $level"
    read pass
    echo "$pass" > $game_path/$level
    git add "$game_path/$level"
    git commit --allow-empty -m "save $game level $level"
}

function menu() {
    while true; do
        echo_color 'Quel jeu ?'
        for game_path in $(find $SAVE_DIR/* -type d) ; do
            echo_color "    $game_path" | sed "s#$SAVE_DIR/###"
        done
        echo_color 'ou'
        echo_color '    quitter ?'

        read rep
        if [[ "$rep" =~ ^[qQ].* ]]; then
            exit
        fi

        #so rep is a game_path
        game_path=$rep
        if [[ -d "$SAVE_DIR/$game_path" ]]; then
            game_path="$SAVE_DIR/$game_path"
        else
            # try autocomple
            game_path=$(find $SAVE_DIR/* -type d -name "*$game_path*")
        fi
        if [[ -d "$game_path" ]]; then
            break
        else
            game=$(echo $game_path | sed 's#.*/###')
            echo_color "Jeu inconnu ou formulation ambigue ($(echo $game_path))"
        fi
    done
    while true; do
        echo_color "Quel niveau ?"
        for level in $game_path/* ; do
            echo_color "    $level" | sed "s#$game_path/###"
        done
        read level
        if [[ ! -f "$SAVE_DIR/$level" ]]; then
            # try autocomple
            level=$(find $game_path/* -type f -name "*$level*" | sed "s#$game_path###")
        fi
        level=$(echo $level | sed "s#.*/###")
        if [[ -f $game_path/$level ]]; then
            break
        else
            echo_color "Niveau inconnu ($level)"
        fi
    done
    play $game_path $level
}

menu
