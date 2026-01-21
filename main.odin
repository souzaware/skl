package skl

import sdl "vendor:sdl3"
import os "core:os/os2"
import "core:encoding/ini"
import "vendor:sdl3/ttf"
import "core:strings"
import "core:fmt"
import "core:unicode/utf8"

Config :: struct {
    keybinds: [dynamic]Keybind,
}

Keybind :: struct {
    key: rune,
    command: string,
}

config := Config{}

load_config :: proc() {
    builder := strings.Builder{}

    strings.builder_init(&builder, context.temp_allocator)

    fmt.sbprintf(&builder, "%s/.config/skl/config.ini", os.get_env("HOME", context.temp_allocator))

    config_file, err := os.read_entire_file(strings.to_string(builder), context.temp_allocator)

    if err != nil {
        panic("error: failed to find the config file")
    }

    config_it := ini.iterator_from_string(string(config_file))

    for k, v, ok := ini.iterate(&config_it); ok; k, v, ok = ini.iterate(&config_it) {
        append(&config.keybinds, Keybind { key = utf8.rune_at(k, 0), command = strings.clone(v, context.allocator) })
    }
}

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
    load_config()

    window := sdl.CreateWindow("", 1920, 1080, {
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

    renderer := sdl.CreateRenderer(window, nil)

    sdl.SetRenderVSync(renderer, 1)

    ttf.Init()

    font_file := #load("./FiraCode-Regular.ttf")
    font := ttf.OpenFontIO(sdl.IOFromMem(raw_data(font_file), len(font_file)), true, 32)

    text_engine := ttf.CreateRendererTextEngine(renderer)

    running := true
    for running {
        event: sdl.Event

        for sdl.PollEvent(&event) {
            #partial switch event.type {
            case .KEY_DOWN:
                for k in config.keybinds {
                    if rune(event.key.key) == k.key {
                        running = !spawn_command(k.command)
                    }
                }
            }

            if event.key.key == sdl.K_ESCAPE || event.type == .QUIT {
                running = false
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
        
        line := 0
        for key in config.keybinds {
            cstr: cstring = strings.clone_to_cstring(utf8.runes_to_string([]rune{key.key}, context.temp_allocator), context.temp_allocator)

            text := ttf.CreateText(text_engine, font, cstr, len(cstr))

            ttf.DrawRendererText(text, f32(1920 / 2 - 500 / 2 + 50), f32(1080 / 2 - 500 / 2 + 32 +(line * 36)))

            ttf.DestroyText(text)

            cstr = strings.clone_to_cstring(key.command, context.temp_allocator)

            text = ttf.CreateText(text_engine, font, cstr, len(cstr))

            ttf.DrawRendererText(text, f32(1920 / 2 - 500 / 2 + 100), f32(1080 / 2 - 500 / 2 + 32 + (line * 36)))

            ttf.DestroyText(text)

            line += 1
        }

        sdl.RenderPresent(renderer)

        free_all(context.temp_allocator)
    }
}
