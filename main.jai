#import "Basic";
#import "Window_Creation";
#import "Input";

#if OS ==.WINDOWS {
    #import "Windows";
}

WIDTH  : u32 = 640;
HEIGHT : u32 = 480;
window : Window_Type;

main :: (){
    window = create_window(WIDTH, HEIGHT, "Vulkan");
    initVulkan();
    mainLoop();
    cleanup();
}

initVulkan :: () {
}

mainLoop :: (){
    quit := false;
    while !quit {
        update_window_events();

        for events_this_frame {
            if it.type == .QUIT then quit = true;
        }
    }
}

cleanup :: () {
}