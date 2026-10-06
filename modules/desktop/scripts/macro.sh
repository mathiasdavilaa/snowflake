#!/usr/bin/env bash

# Macro de cliques para Hyprland + ydotool
#
# Adicione/remova posições no array POSITIONS abaixo.
# As coordenadas são globais no layout do Hyprland.

POSITIONS=(
    # "847 521"
    # "1200 600"
    # "1500 300"
)

MOVE_DELAY="0.05"
CLICK_DELAY="0.05"

run_macro() {
    for position in "${POSITIONS[@]}"; do
        read -r x y <<< "$position"

        ydotool mousemove --absolute "$x" "$y"
        sleep "$MOVE_DELAY"

        ydotool click 0xC0
        sleep "$CLICK_DELAY"
    done
}

list_positions() {
    if ((${#POSITIONS[@]} == 0)); then
        echo "Nenhuma posição cadastrada."
        return
    fi

    for i in "${!POSITIONS[@]}"; do
        printf '%d: %s\n' "$((i + 1))" "${POSITIONS[$i]}"
    done
}

test_positions() {
    for position in "${POSITIONS[@]}"; do
        read -r x y <<< "$position"

        echo "Movendo para: $x $y"
        ydotool mousemove --absolute "$x" "$y"
        sleep 0.5
    done
}

case "${1:-run}" in
    run)
        run_macro
        ;;
    list)
        list_positions
        ;;
    test)
        test_positions
        ;;
    *)
        echo "Uso: $0 [run|list|test]"
        exit 1
        ;;
esac
