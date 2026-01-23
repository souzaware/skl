package skl

import sdl "vendor:sdl3"
import os "core:os/os2"
import "core:encoding/ini"
import "vendor:sdl3/ttf"
import "core:strings"
import "core:fmt"
import "core:log"
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

Key_Command_Texts :: struct {
    key: ^ttf.Text,
    command: ^ttf.Text,
}

main :: proc() {
    load_config()

    if status := sdl.Init({.VIDEO}); !status {
        panic("error: failed starting SDL")
    }

    if status := ttf.Init(); !status {
        panic("error: failed starting TTF")
    }

    display := sdl.GetDesktopDisplayMode(sdl.GetPrimaryDisplay())

    window_width := 1920
    window_height := 1080

    display_id := sdl.GetPrimaryDisplay()

    if display_id == 0 {
        log.fatal("error: failed getting primary display")
    } 

    current_display := sdl.GetDesktopDisplayMode(display_id)

    if current_display == nil {
        log.fatal("error: failed getting primary information")
    }

    window := sdl.CreateWindow("", current_display.w, current_display.h, {
        .UTILITY,
        .MOUSE_CAPTURE,
        .FULLSCREEN,
        .MOUSE_FOCUS,
        .INPUT_FOCUS,
        .ALWAYS_ON_TOP,
        .TRANSPARENT,
        .KEYBOARD_GRABBED,
        .MOUSE_GRABBED,
        .BORDERLESS,
    })

    window_size := [2]i32{}

    sdl.GetWindowSize(window, &window_size.x, &window_size.y)
    window_center := [2]f32{
        f32(window_size.x) / 2,
        f32(window_size.y) / 2,
    }

    renderer := sdl.CreateRenderer(window, nil)

    sdl.SetRenderVSync(renderer, 1)

    font_file := #load("./FiraCode-Regular.ttf")
    font_size: f32 = 24
    font := ttf.OpenFontIO(sdl.IOFromMem(raw_data(font_file), len(font_file)), true, font_size)

    text_engine := ttf.CreateRendererTextEngine(renderer)

    keybind_texts := make([dynamic]Key_Command_Texts, len(config.keybinds))

    for i in 0..<len(config.keybinds) {
        cstr: cstring = strings.clone_to_cstring(utf8.runes_to_string([]rune{config.keybinds[i].key}, context.temp_allocator), context.temp_allocator)

        keybind_texts[i].key = ttf.CreateText(text_engine, font, cstr, len(cstr))

        cstr = strings.clone_to_cstring(config.keybinds[i].command, context.temp_allocator)

        keybind_texts[i].command = ttf.CreateText(text_engine, font, cstr, len(cstr))
    }

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

        frame_size := [2]f32{
            500,
            500,
        }
        frame_center := frame_size / 2

        sdl.RenderFillRect(renderer, &sdl.FRect{
            x = window_center.x - frame_center.x,
            y = window_center.y - frame_center.y,
            w = frame_size.x,
            h = frame_size.y,
        })
        
        line := 0
        line_height: f32 = 30
        for k in keybind_texts {
            text_offset := [2]f32 {
                50,
                50,
            }

            render_pos := window_center - frame_center + text_offset
            // the offset from the key text to the command text
            command_offset_x := 100
            
            render_pos.y += line_height * f32(line)

            ttf.DrawRendererText(k.key, render_pos.x, render_pos.y)
            ttf.DrawRendererText(k.command, render_pos.x + f32(command_offset_x), render_pos.y)

            line += 1
        }

        sdl.RenderPresent(renderer)

        free_all(context.temp_allocator)
    }
}
