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