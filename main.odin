package skl

import sdl "vendor:sdl3"

main :: proc() {
    window := sdl.CreateWindow("Teste", 480, 640, {.BORDERLESS, .UTILITY})
    renderer := sdl.CreateRenderer(window, nil)

    for {
        event: sdl.Event

        for sdl.PollEvent(&event) {
            if event.type == .QUIT {
                return
            }
        }

        sdl.SetRenderDrawColor(renderer, 255, 255, 255, 255)
        
        sdl.RenderClear(renderer)

        sdl.RenderPresent(renderer)
    }
}
