#import "Basic";
#import "String";
#import "Window_Creation";
#import "Input";
#import "Vulkan";

#if OS ==.WINDOWS {
    #import "Windows";
}

DEBUG :: true;

WIDTH  : u32 = 640;
HEIGHT : u32 = 480;
window : Window_Type;

instance : VkInstance;

main :: (){
    window = create_window(WIDTH, HEIGHT, "Vulkan");
    initVulkan();
    mainLoop();
    cleanup();
}

initVulkan :: () {
    createInstance();
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
    vkDestroyInstance(instance, null);
}

createInstance :: () {
    // Application Info
    appInfo: VkApplicationInfo;
    appInfo.sType              = .VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName   = "No Application";
    appInfo.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
    appInfo.pEngineName        = "No Engine";
    appInfo.engineVersion      = VK_MAKE_VERSION(1, 0, 0);
    appInfo.apiVersion         = VK_API_VERSION_1_4;

    // Extensions
    #if DEBUG {
        extensionCount : u32;
        vkEnumerateInstanceExtensionProperties(null, *extensionCount, null);
        extensions := NewArray(extensionCount, VkExtensionProperties);
        defer free(extensions.data);
        vkEnumerateInstanceExtensionProperties(null, *extensionCount, extensions.data);
        print("available extensions:\n");
        for extensions print(" % (%)\n", to_string(it.extensionName.data), it.specVersion);
    }

    #if OS == .WINDOWS {
        requiredExtensions: [2] *u8;
        requiredExtensions[0] = VK_KHR_SURFACE_EXTENSION_NAME.data;
        requiredExtensions[1] = VK_KHR_WIN32_SURFACE_EXTENSION_NAME.data;
    } else #if OS == .LINUX {
        requiredExtensions: [0] *u8;
        #assert requiredExtensions.count > 0 "Extensions not defined";
    } else #if OS == .MACOS {
        requiredExtensions: [1] *u8;
        requiredExtensions[0] = VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME.data;
    } else {
        #assert false "OS not defined";
    }

    // Validation Layers
    validationLayers : [1] *u8;
    validationLayers[0] = "VK_LAYER_KHRONOS_validation";
    #if DEBUG {
        assert(checkValidationLayerSupport(validationLayers), "validation layers requested, but not available!");
    }
    

    // Instance Create Info
    createInfo: VkInstanceCreateInfo;
    createInfo.sType                   = .VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    createInfo.pApplicationInfo        = *appInfo;
    createInfo.enabledExtensionCount   = requiredExtensions.count;
    createInfo.ppEnabledExtensionNames = requiredExtensions.data;
    #if DEBUG {
        createInfo.enabledLayerCount   = validationLayers.count;
        createInfo.ppEnabledLayerNames = validationLayers.data;
    } else {
        createInfo.enabledLayerCount   = 0;
    }
    #if OS == .MACOS {
        createInfo.flags |= VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR;
    }

    // Create Vulkan Instance
    result := vkCreateInstance(*createInfo, null, *instance);
    assert(result == .SUCCESS, "vkCreateInstance result: %", result);
}

checkValidationLayerSupport :: (validationLayers: [] *u8) -> bool {
    layerCount : u32;
    vkEnumerateInstanceLayerProperties(*layerCount, null);

    availableLayers := NewArray(layerCount, VkLayerProperties);
    vkEnumerateInstanceLayerProperties(*layerCount, availableLayers.data);

    for layerName: validationLayers {
        layerFound := false;
        for layerProperties: availableLayers{
            if equal(to_string(layerName), to_string(*layerProperties.layerName[0]))
            {
                layerFound = true;
                break;
            }
        }

        if !layerFound {
            return false;
        }
        
    }

    return true;
}