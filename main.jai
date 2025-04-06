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
physicalDevice: VkPhysicalDevice;
device        : VkDevice;
graphicsQueue : VkQueue;

main :: ()
{
    window = create_window(WIDTH, HEIGHT, "Vulkan");
    initVulkan();
    mainLoop();
    cleanup();
}

initVulkan :: ()
{
    createInstance();
    setupDebugMessenger();
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

pickPhysicalDevice :: ()
{
    devices, result := vkEnumeratePhysicalDevices(instance,, temp);
    assert(result == .VK_SUCCESS, "vkEnumeratePhysicalDevices result: %\n", result);
    assert(devices.count > 0, "Failed to find GPUs with Vulkan support!\n");

    for devices
    {
        if isDeviceSuitable(it)
        {
            physicalDevice = it;
            break;
        }
    }
    assert(physicalDevice != VK_NULL_HANDLE, "Failed to find a suitable GPU!\n");
}

createLogicalDevice :: ()
{
    queueFamilyIndex := findQueueFamilies(physicalDevice);
    queueCreateInfo: VkDeviceQueueCreateInfo;
    queueCreateInfo.sType = .VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queueCreateInfo.queueFamilyIndex = queueFamilyIndex;
    queueCreateInfo.queueCount = 1;
    queuePriority : float = 1;
    queueCreateInfo.pQueuePriorities = *queuePriority;

    deviceFeatures: VkPhysicalDeviceFeatures;

    createInfo: VkDeviceCreateInfo;
    createInfo.sType = .VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    createInfo.pQueueCreateInfos = *queueCreateInfo;
    createInfo.queueCreateInfoCount = 1;
    createInfo.pEnabledFeatures = *deviceFeatures;
    createInfo.enabledExtensionCount = 0;

    result := vkCreateDevice(physicalDevice, *createInfo, null, *device);
    assert(result == .VK_SUCCESS, "vkCreateDevice result: %\n", result);

    vkGetDeviceQueue(device, queueFamilyIndex, 0, *graphicsQueue);
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