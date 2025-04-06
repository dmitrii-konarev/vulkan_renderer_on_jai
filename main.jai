#import "Basic";
#import "String";
#import "Window_Creation";
#import "Input";
#import "Vulkan";
#import "Math";

#if OS ==.WINDOWS {#import "Windows";}

#load "additional_vulkan_functions.jai";

DEBUG :: true;

WIDTH  : u32 = 640;
HEIGHT : u32 = 480;
window : Window_Type;

instance      : VkInstance;
debugMessenger: VkDebugUtilsMessengerEXT;
surface       : VkSurfaceKHR;
physicalDevice: VkPhysicalDevice;
device        : VkDevice;
graphicsQueue : VkQueue;
presentQueue  : VkQueue;

main :: ()
{
    window = create_window(WIDTH, HEIGHT, "Vulkan", 400, 200);
    initVulkan();
    mainLoop();
    cleanup();
}

initVulkan :: ()
{
    createInstance();
    setupDebugMessenger();
    createSurface();
    pickPhysicalDevice();
    createLogicalDevice();
}

mainLoop :: ()
{
    quit := false;
    while !quit
    {
        update_window_events();
        for events_this_frame
        {
            if it.type == .QUIT then quit = true;
        }
    }
}

cleanup :: ()
{
    vkDestroyDevice(device, null);
    cleanupDebugMessenger();
    vkDestroySurfaceKHR(instance, surface, null);
    vkDestroyInstance(instance, null);
}

createInstance :: ()
{
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
    #if DEBUG
    {
        createInfo.enabledLayerCount   = xx validationLayers.count;
        createInfo.ppEnabledLayerNames = validationLayers.data;

        debugCreateInfo: VkDebugUtilsMessengerCreateInfoEXT;
        populateDebugMessengerCreateInfo(*debugCreateInfo);
        createInfo.pNext = cast(*VkDebugUtilsMessengerCreateInfoEXT) *debugCreateInfo;
    }
    else
    {
        createInfo.enabledLayerCount   = 0;
    }
    #if OS == .MACOS
    {
        createInfo.flags |= VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR;
    }

    // Create Vulkan Instance
    result := vkCreateInstance(*createInfo, null, *instance);
    assert(result == .SUCCESS, "vkCreateInstance result: %\n", result);
}

setupDebugMessenger :: ()
{
    #if DEBUG
    {
        createInfo: VkDebugUtilsMessengerCreateInfoEXT;
        populateDebugMessengerCreateInfo(*createInfo);

        result := CreateDebugUtilsMessengerEXT(instance, *createInfo, null, *debugMessenger);
        assert(result == .VK_SUCCESS, "Failed to set up debug messenger: %\n", result);
    }
}

createSurface :: ()
{
    #if OS == .WINDOWS {
        hwnd := window;
        createInfo: VkWin32SurfaceCreateInfoKHR;
        createInfo.sType = .VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
        createInfo.hwnd = hwnd;
        createInfo.hinstance = GetModuleHandleW(null);
        result := vkCreateWin32SurfaceKHR(instance, *createInfo, null, *surface);
        assert(result == .SUCCESS, "vkCreateWin32SurfaceKHR result: %", result);
    } else {
        // @ToDo: Non-Windows version
        #assert false "Create non Windows surface";
    }
}

pickPhysicalDevice :: ()
{
    devices, result := vkEnumeratePhysicalDevices(instance,, temp);
    assert(result == .VK_SUCCESS, "vkEnumeratePhysicalDevices result: %\n", result);
    assert(devices.count > 0, "Failed to find GPUs with Vulkan support!\n");

    for devices
    {
        if isDeviceSuitable(it, surface)
        {
            physicalDevice = it;
            break;
        }
    }
    assert(physicalDevice != VK_NULL_HANDLE, "Failed to find a suitable GPU!\n");
}

createLogicalDevice :: ()
{
    graphicsQueueFamilyIndex, presentQueueFamilyIndex := findQueueFamilies(physicalDevice, surface);

    queueCreateInfos: [..] VkDeviceQueueCreateInfo;
    queuePriority : float = 1;

    graphicsQueueCreateInfo: VkDeviceQueueCreateInfo;
    graphicsQueueCreateInfo.sType = .VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    graphicsQueueCreateInfo.queueFamilyIndex = graphicsQueueFamilyIndex;
    graphicsQueueCreateInfo.queueCount = 1;
    graphicsQueueCreateInfo.pQueuePriorities = *queuePriority;
    array_add(*queueCreateInfos, graphicsQueueCreateInfo);

    if graphicsQueueFamilyIndex != presentQueueFamilyIndex
    {
        presentQueueCreateInfo: VkDeviceQueueCreateInfo;
        presentQueueCreateInfo.sType = .VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
        presentQueueCreateInfo.queueFamilyIndex = presentQueueFamilyIndex;
        presentQueueCreateInfo.queueCount = 1;
        presentQueueCreateInfo.pQueuePriorities = *queuePriority;
        array_add(*queueCreateInfos, presentQueueCreateInfo);
    }

    deviceFeatures: VkPhysicalDeviceFeatures;

    createInfo: VkDeviceCreateInfo;
    createInfo.sType = .VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    createInfo.pQueueCreateInfos = queueCreateInfos.data;
    createInfo.queueCreateInfoCount = xx queueCreateInfos.count;
    createInfo.pEnabledFeatures = *deviceFeatures;
    createInfo.enabledExtensionCount = 0;

    result := vkCreateDevice(physicalDevice, *createInfo, null, *device);
    assert(result == .VK_SUCCESS, "vkCreateDevice result: %\n", result);

    vkGetDeviceQueue(device, graphicsQueueFamilyIndex, 0, *graphicsQueue);
    vkGetDeviceQueue(device, presentQueueFamilyIndex, 0, *presentQueue);
}

cleanupDebugMessenger :: ()
{
    #if DEBUG {DestroyDebugUtilsMessengerEXT(instance, debugMessenger, null);}
}

debugCallback :: (
    messageSeverity: VkDebugUtilsMessageSeverityFlagBitsEXT,
    messageType: VkDebugUtilsMessageTypeFlagsEXT,
    $$pCallbackData: *VkDebugUtilsMessengerCallbackDataEXT,
    pUserData: *void)
    -> VkBool32
    #c_call
{
        push_context
        {
            if messageSeverity >= .VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT {
                // Message is important enough to show
                if messageSeverity ==
                {
                    case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT; print("VERBOSE ");
                    case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT;    print("INFO ");
                    case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT; print("WARNING ");
                    case .VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;   print("ERROR ");
                }

                if messageType ==
                {
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
    -> VkResult
{
    func : PFN_vkCreateDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
    if func != null
    {
        return func(instance, pCreateInfo, pAllocator, pDebugMessenger);
    }
    else
    {
        return .VK_ERROR_EXTENSION_NOT_PRESENT;
    }
}

DestroyDebugUtilsMessengerEXT :: (
    instance: VkInstance,
    debugMessenger: VkDebugUtilsMessengerEXT,
    $$pAllocator: *VkAllocationCallbacks)
{
    func : PFN_vkDestroyDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
    if func != null
    {
        func(instance, debugMessenger, pAllocator);
    }
}