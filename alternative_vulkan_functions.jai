#import "Sort";

alternativePickPhysicalDevice :: ()
{
    devices, result := vkEnumeratePhysicalDevices(instance,, temp);

    // Use an ordered map to automatically sort candidates by increasing score
    DeviceCandidate :: struct {
        score: int;
        device: VkPhysicalDevice;
    }

    candidates: [..]DeviceCandidate;
    defer array_free(candidates);
    
    for device: devices {
        score := rateDeviceSuitability(device);
        candidate: DeviceCandidate;
        candidate.score = score;
        candidate.device = device;
        array_add(*candidates, candidate);
    }

    quick_sort(candidates, (a, b) => a.score - b.score);
    
    // Check if the best candidate is suitable at all
    if candidates.count > 0 && candidates[candidates.count-1].score > 0 {
        physicalDevice = candidates[candidates.count-1].device;
    } else {
        assert(false, "failed to find a suitable GPU!\n");
    }
}

rateDeviceSuitability :: (device: VkPhysicalDevice) -> int
{
    deviceProperties: VkPhysicalDeviceProperties;
    vkGetPhysicalDeviceProperties(device, *deviceProperties);

    deviceFeatures: VkPhysicalDeviceFeatures;
    vkGetPhysicalDeviceFeatures(device, *deviceFeatures);

    score : int = 0;

    // Discrete GPUs have a significant performance advantage
    if deviceProperties.deviceType == .VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU
    {
        score += 1000;
    }

    // Maximum possible size of textures affects graphics quality
    score += deviceProperties.limits.maxImageDimension2D;

    // Application can't function without geometry shaders
    if (!deviceFeatures.geometryShader)
    {
        return 0;
    }

    return score;
}