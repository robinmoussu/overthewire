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

function play() {
    path_game=$1
    game=$(echo $path_game | sed 's#.*/###')
    level=$2

    while true; do
        pass=$(cat $path_game/$level)
        echo "$pass" | xclip -sel clip
        echo "Mot de passe pour $game, niveau $level: $pass "\
             "(mis dans le presse papier)"

        ssh "$game$level@$game.labs.overthewire.org"

        current_level=$level
        level=$(echo "$level + 1" | bc)

        echo "Enregistrer le mot de passe pour $game, niveau $level ? (Oui/non)"
        read rep
        if [[ "$rep" =~ ^[nN].* ]]; then
            menu
        else
            save $path_game $level

            echo 'niveau suivant ? (Oui/non)'
            read rep
            if [[ "$rep" =~ ^[nN].* ]]; then
                menu
                break
            fi
        fi
    done
}

function save() {
    path_game=$1
    game=$(echo $path_game | sed 's#.*/###')
    level=$2

    echo "Mot de passe pour le level $level"
    read pass
    echo "$pass" > $path_game/$level
    git add "$path_game/$level"
    git commit --allow-empty -m "save $game level $level"
}

function menu() {
    while true; do
        echo 'Quel jeu ?'
        for game in $(find $SAVE_DIR/* -type d) ; do
            echo "    $game" | sed "s#$SAVE_DIR/###"
        done
        echo 'ou'
        echo '    quitter ?'

        read rep
        if [[ "$rep" =~ ^[qQ].* ]]; then
            exit
        fi

        #so rep is a game
        game=$rep
        if [[ -d "$SAVE_DIR/$game" ]]; then
            game_path="$SAVE_DIR/$game"
        else
            # try autocomple
            game_path=$(find $SAVE_DIR/* -type d -name "*$game*")
        fi
        if [[ -d "$game_path" ]]; then
            break
        else
            echo "Jeu inconnu ou formulation ambigue ($(echo $game_path))"
        fi
    done
    while true; do
        echo "Quel niveau ?"
        for level in $game_path/* ; do
            echo "    $level" | sed "s#$game_path/###"
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
            echo "Niveau inconnu ($level)"
        fi
    done
    play $game_path $level
}


menu
