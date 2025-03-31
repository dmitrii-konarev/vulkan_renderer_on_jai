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
debugMessenger: VkDebugUtilsMessengerEXT;

main :: (){
    window = create_window(WIDTH, HEIGHT, "Vulkan");
    initVulkan();
    mainLoop();
    cleanup();
}

initVulkan :: () {
    createInstance();
    setupDebugMessenger();
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
    cleanupDebugMessenger();
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
    #if DEBUG {printAvailableExtensuins();}
    extensions := getExtensions();

    // Validation Layers
    validationLayers := getValidationLayers();
    
    // Instance Create Info
    createInfo: VkInstanceCreateInfo;
    createInfo.sType                   = .VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    createInfo.pApplicationInfo        = *appInfo;
    createInfo.enabledExtensionCount   = xx extensions.count;
    createInfo.ppEnabledExtensionNames = extensions.data;
    #if DEBUG {
        createInfo.enabledLayerCount   = xx validationLayers.count;
        createInfo.ppEnabledLayerNames = validationLayers.data;

        debugCreateInfo: VkDebugUtilsMessengerCreateInfoEXT;
        populateDebugMessengerCreateInfo(*debugCreateInfo);
        createInfo.pNext = cast(*VkDebugUtilsMessengerCreateInfoEXT) *debugCreateInfo;
    } else {
        createInfo.enabledLayerCount   = 0;
    }
    #if OS == .MACOS {
        createInfo.flags |= VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR;
    }

    // Create Vulkan Instance
    result := vkCreateInstance(*createInfo, null, *instance);
    assert(result == .SUCCESS, "vkCreateInstance result: %\n", result);
}

populateDebugMessengerCreateInfo :: (createInfo: *VkDebugUtilsMessengerCreateInfoEXT) {
    createInfo: VkDebugUtilsMessengerCreateInfoEXT;
    createInfo.sType           = .VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
    createInfo.messageSeverity = .VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
                                 .VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
                                 .VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
                                 .VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
    createInfo.messageType     = .VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
                                 .VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
                                 .VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
    createInfo.pfnUserCallback = debugCallback;
    createInfo.pUserData       = null;

}

setupDebugMessenger :: () {
    #if DEBUG {
        createInfo: VkDebugUtilsMessengerCreateInfoEXT;
        populateDebugMessengerCreateInfo(*createInfo);

        result := CreateDebugUtilsMessengerEXT(instance, *createInfo, null, *debugMessenger);
        assert(result == .VK_SUCCESS, "Failed to set up debug messenger: %\n", result);
    }
}

printAvailableExtensuins :: () {
        extensionCount : u32;
        vkEnumerateInstanceExtensionProperties(null, *extensionCount, null);
        extensions := NewArray(extensionCount, VkExtensionProperties);
        defer free(extensions.data);
        vkEnumerateInstanceExtensionProperties(null, *extensionCount, extensions.data);
        print("available extensions:\n");
        for extensions print(" % (%)\n", to_string(it.extensionName.data), it.specVersion);
}

getExtensions :: () -> [..] *u8 {
    extensions: [..] *u8;
    #if OS == .WINDOWS {
        array_add(*extensions, VK_KHR_SURFACE_EXTENSION_NAME.data);
        array_add(*extensions, VK_KHR_WIN32_SURFACE_EXTENSION_NAME.data);
    } else #if OS == .LINUX {
        #assert extensions.count > 0 "Extensions not defined";
    } else #if OS == .MACOS {
        array_add(*extensions, VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME.data);
    } else {
        #assert false "OS not defined";
    }

    #if DEBUG {
        array_add(*extensions, VK_EXT_DEBUG_UTILS_EXTENSION_NAME.data);
    }

    return extensions;
}

getValidationLayers :: () -> [..] *u8 {
    validationLayers : [..] *u8;;
    #if DEBUG {
        array_add(*validationLayers, "VK_LAYER_KHRONOS_validation");
        assert(checkValidationLayerSupport(validationLayers), "validation layers requested, but not available!\n");
    }
    return validationLayers;
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

cleanupDebugMessenger :: () {
    #if DEBUG { DestroyDebugUtilsMessengerEXT(instance, debugMessenger, null);}
}

debugCallback :: (
    messageSeverity: VkDebugUtilsMessageSeverityFlagBitsEXT,
    messageType: VkDebugUtilsMessageTypeFlagsEXT,
    $$pCallbackData: *VkDebugUtilsMessengerCallbackDataEXT,
    pUserData: *void)
    -> VkBool32
    #c_call {
        push_context {
            if messageSeverity >= .VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT {
                // Message is important enough to show
                if messageSeverity == {
                    case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT; print("VERBOSE ");
                    case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT;    print("INFO ");
                    case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT; print("WARNING ");
                    case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;   print("ERROR ");
                }

                if messageType == {
                    case .VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT;     print("GENERAL:\n");
                    case .VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT;  print("VALIDATION:\n");
                    case .VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT; print("PERFORMANCE:\n");
                }

                print("   %\n", pCallbackData.pMessage);
            }
        }
        
        return VK_FALSE;
}

CreateDebugUtilsMessengerEXT :: (
    instance: VkInstance,
    $$pCreateInfo : *VkDebugUtilsMessengerCreateInfoEXT,
    $$pAllocator: *VkAllocationCallbacks,
    pDebugMessenger : *VkDebugUtilsMessengerEXT) 
    -> VkResult {
    func : PFN_vkCreateDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
    if func != null {
        return func(instance, pCreateInfo, pAllocator, pDebugMessenger);
    } else {
        return .VK_ERROR_EXTENSION_NOT_PRESENT;
    }
}

DestroyDebugUtilsMessengerEXT :: (
    instance: VkInstance,
    debugMessenger: VkDebugUtilsMessengerEXT,
    $$pAllocator: *VkAllocationCallbacks) {
    func : PFN_vkDestroyDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
    if func != null {
        func(instance, debugMessenger, pAllocator);
    }
}