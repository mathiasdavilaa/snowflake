#!/usr/bin/env bash

# Mostra a posição global do cursor no layout do Hyprland em tempo real.

while true; do
    printf '\033[2J\033[H'
    echo '╭────────────────────────╮'
    echo '│     Mouse Position     │'
    echo '╰────────────────────────╯'
    echo
    hyprctl cursorpos
    echo
    echo 'Ctrl+C para sair.'
    sleep 0.05
done
