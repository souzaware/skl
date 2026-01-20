package skl

import sdl "vendor:sdl3"
import os "core:os/os2"

spawn_command :: proc(command: string) -> (ok: bool) {
    program: os.Process_Desc = {
        command = { command }
    }

    if process, err := os.process_start(program); err != nil {
        return false
    }

    return true
}

main :: proc() {
    window := sdl.CreateWindow("Teste", 1920, 1080, {
        .UTILITY,
        .MOUSE_CAPTURE,
        .FULLSCREEN,
        .MOUSE_FOCUS,
        .INPUT_FOCUS,
        .ALWAYS_ON_TOP,
        .TRANSPARENT,
        .KEYBOARD_GRABBED,
        .MOUSE_GRABBED,
        .INPUT_FOCUS,
        .BORDERLESS,
        .UTILITY
    })

    commands := make(map[rune]string)

    commands['d'] = "discord"
    commands['h'] = "helium"
    commands['o'] = "obs"
    commands['z'] = "zapzap"
    commands['a'] = "aseprite"
    commands['k'] = "keepassxc"
    commands['n'] = "obsidian"
    commands['r'] = "reaper"

    renderer := sdl.CreateRenderer(window, nil)

    sdl.SetRenderVSync(renderer, 1)

    running := true
    for running {
        event: sdl.Event

        for sdl.PollEvent(&event) {
            if event.key.key == sdl.K_ESCAPE || event.type == .QUIT {
                return
            }

            for k, v in commands {
                if rune(event.key.key) == k {
                    running = !spawn_command(v)
                }
            }
        }

        sdl.SetRenderDrawColor(renderer, 0, 0, 0, 0)
        sdl.RenderClear(renderer)

        sdl.SetRenderDrawColor(renderer, 40, 40, 40, 255)

        sdl.RenderFillRect(renderer, &sdl.FRect{
            x = 1920 / 2 - 500 / 2,
            y = 1080 / 2 - 500 / 2,
            w = 500,
            h = 500,
        })

        sdl.RenderPresent(renderer)
    }
}
