#include <Security/Security.h>
#include <CoreFoundation/CoreFoundation.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdlib.h>

int add_password(const char* account, const char* service, const char* password) {
    CFStringRef accountStr = CFStringCreateWithCString(NULL, account, kCFStringEncodingUTF8);
    CFStringRef serviceStr = CFStringCreateWithCString(NULL, service, kCFStringEncodingUTF8);
    CFDataRef passwordData = CFDataCreate(NULL, (const UInt8*)password, strlen(password));

    const void* keys[] = { kSecClass, kSecAttrAccount, kSecAttrService, kSecValueData };
    const void* values[] = { kSecClassGenericPassword, accountStr, serviceStr, passwordData };

    CFDictionaryRef item = CFDictionaryCreate(NULL, keys, values, 4, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    OSStatus status = SecItemAdd(item, NULL);

    CFRelease(accountStr);
    CFRelease(serviceStr);
    CFRelease(passwordData);
    CFRelease(item);

    return (int)status;
}

char* read_password(const char* account, const char* service) {
    CFStringRef accountStr = CFStringCreateWithCString(NULL, account, kCFStringEncodingUTF8);
    CFStringRef serviceStr = CFStringCreateWithCString(NULL, service, kCFStringEncodingUTF8);

    const void* keys[] = {
            kSecClass,
            kSecAttrAccount,
            kSecAttrService,
            kSecReturnData,
            kSecMatchLimit
    };

    const void* values[] = {
            kSecClassGenericPassword,
            accountStr,
            serviceStr,
            kCFBooleanTrue,
            kSecMatchLimitOne
    };

    CFDictionaryRef query = CFDictionaryCreate(NULL, keys, values, 5, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CFDataRef resultData = NULL;
    OSStatus status = SecItemCopyMatching(query, (CFTypeRef*)&resultData);

    char* output = NULL;
    if (status == errSecSuccess && resultData != NULL) {
        CFIndex length = CFDataGetLength(resultData);
        const UInt8* dataBytes = CFDataGetBytePtr(resultData);

        // +1 pour le null terminator
        output = (char*)malloc(length + 1);
        if (output != NULL) {
            memcpy(output, dataBytes, length);
            output[length] = '\0';
        }

        CFRelease(resultData);
    }

    CFRelease(accountStr);
    CFRelease(serviceStr);
    CFRelease(query);

    return output;
}

void free_password(char* ptr) {
    if (ptr != NULL) {
        free(ptr);
    }
}

/*int main(int argc, char *argv[]) {
    char test[255];

    bzero(test);
    printf("test is %s", test);
    return EXIT_SUCCESS;
}*/