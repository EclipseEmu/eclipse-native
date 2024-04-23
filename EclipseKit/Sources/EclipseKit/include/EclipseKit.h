#ifndef EclipseKit_h
#define EclipseKit_h

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#ifndef EK_SWIFT_CC
#if __has_attribute(swiftcall)
#define EK_SWIFT_CC __attribute__((swiftcall))
#else
#define EK_SWIFT_CC
#endif
#endif

#ifndef EK_EXPORT_AS
#define EK_EXPORT_AS(name) __attribute__((swift_name(name)))
#endif

#ifndef EK_SWIFT_ENUM
#define EK_SWIFT_ENUM __attribute__((enum_extensibility(open)))
#else
#define EK_SWIFT_ENUM
#endif

#pragma mark - Function Pointers

typedef EK_SWIFT_CC void (*EKCoreSaveCallback)(const char *path);
typedef EK_SWIFT_CC uint64_t (*EKCoreAudioWriteCallback)(const void *ctx, const void *buffer, uint64_t count);

typedef struct {
    const void *ctx;
    EKCoreSaveCallback didSave;
    EKCoreAudioWriteCallback writeAudio;
} EKCoreCallbacks;

#pragma mark - Enum

EK_EXPORT_AS("GameCoreCommonAudioFormat")
typedef enum EK_SWIFT_ENUM {
    EKCoreCommonAudioFormatOtherFormat,
    EKCoreCommonAudioFormatPcmInt16,
    EKCoreCommonAudioFormatPcmInt32,
    EKCoreCommonAudioFormatPcmFloat32,
    EKCoreCommonAudioFormatPcmFloat64
} EKCoreCommonAudioFormat;

EK_EXPORT_AS("GameCoreVideoPixelFormat")
typedef enum EK_SWIFT_ENUM {
    EKCoreVideoPixelFormatBgra8Unorm,
} EKCoreVideoPixelFormat;

EK_EXPORT_AS("GameCoreVideoRenderingType")
typedef enum EK_SWIFT_ENUM {
    EKCoreVideoRenderingTypeFrameBuffer,
} EKCoreVideoRenderingType;


typedef enum EK_SWIFT_ENUM {
    EKCoreSettingKindFile,
    EKCoreSettingKindBoolean,
} EKCoreSettingKind;

EK_EXPORT_AS("GameInput")
typedef enum EK_SWIFT_ENUM {
    EKInputNone                 = 0b00000000000000000000000000000000,
    EKInputFaceButtonUp         = 0b00000000000000000000000000000001,
    EKInputFaceButtonDown       = 0b00000000000000000000000000000010,
    EKInputFaceButtonLeft       = 0b00000000000000000000000000000100,
    EKInputFaceButtonRight      = 0b00000000000000000000000000001000,
    EKInputStartButton          = 0b00000000000000000000000000010000,
    EKInputSelectButton         = 0b00000000000000000000000000100000,
    EKInputShoulderLeft         = 0b00000000000000000000000001000000,
    EKInputShoulderRight        = 0b00000000000000000000000010000000,
    EKInputTriggerLeft          = 0b00000000000000000000000100000000,
    EKInputTriggerRight         = 0b00000000000000000000001000000000,
    EKInputDpadUp               = 0b00000000000000000000010000000000,
    EKInputDpadDown             = 0b00000000000000000000100000000000,
    EKInputDpadLeft             = 0b00000000000000000001000000000000,
    EKInputDpadRight            = 0b00000000000000000010000000000000,
    EKInputLeftJoystickUp       = 0b00000000000000000100000000000000,
    EKInputLeftJoystickDown     = 0b00000000000000001000000000000000,
    EKInputLeftJoystickLeft     = 0b00000000000000010000000000000000,
    EKInputLeftJoystickRight    = 0b00000000000000100000000000000000,
    EKInputRightJoystickUp      = 0b00000000000001000000000000000000,
    EKInputRightJoystickDown    = 0b00000000000010000000000000000000,
    EKInputRightJoystickLeft    = 0b00000000000100000000000000000000,
    EKInputRightJoystickRight   = 0b00000000001000000000000000000000,
    EKInputTouchPosX            = 0b00000000010000000000000000000000,
    EKInputTouchNegX            = 0b00000000100000000000000000000000,
    EKInputTouchPosY            = 0b00000001000000000000000000000000,
    EKInputTouchNegY            = 0b00000010000000000000000000000000,
    EKInputLid                  = 0b00000100000000000000000000000000,
    EKInputMic                  = 0b00001000000000000000000000000000,
} EKInput;

EK_EXPORT_AS("GameSystem")
typedef enum EK_SWIFT_ENUM {
    EKSystemUnknown    = 0,
    EKSystemGb         = 1,
    EKSystemGbc        = 2,
    EKSystemGba        = 3,
    EKSystemNes        = 4,
    EKSystemSnes       = 5,
} EKSystem;

#pragma mark - Structs

EK_EXPORT_AS("GameCoreAudioFormat")
typedef struct {
    EKCoreCommonAudioFormat commonFormat;
    double sampleRate;
    uint32_t channelCount;
    bool isInterleaved;
} EKCoreAudioFormat;

EK_EXPORT_AS("GameCoreVideoFormat")
typedef struct {
    EKCoreVideoRenderingType renderingType;
    EKCoreVideoPixelFormat pixelFormat;
    uint32_t width;
    uint32_t height;
} EKCoreVideoFormat;

EK_EXPORT_AS("GameCoreCheat")
typedef struct {
    const char *formatId;
    const char *code;
    bool enabled;
} EKCheat;

EK_EXPORT_AS("GameCoreSettingFile")
typedef struct {
    /// The expected MD5 checksum of the file.
    const char *md5;
    /// The user-shown name of the file.
    const char *displayName;
} EKCoreSettingFile;

EK_EXPORT_AS("GameCoreSettingBoolean")
typedef struct {
    /// The default value of this setting
    bool defaultValue;
} EKCoreSettingBoolean;

EK_EXPORT_AS("GameCoreSetting")
typedef struct {
    /// The core-unique identifier for this setting.
    const char *id;
    /// The system this applies to, use ``EKGameSystemUnknown`` if it applies to any system.
    EKSystem system;
    /// The user-shown name of this setting.
    const char *displayName;
    /// Whether or not this setting is required for the core to run.
    bool required;
    /// What type of setting this will be.
    EKCoreSettingKind kind;
    
    union {
        EKCoreSettingFile *file;
        EKCoreSettingBoolean *boolean;
    };
} EKCoreSetting;

EK_EXPORT_AS("GameCoreSettings")
typedef struct {
    /// The version of these settings.
    uint16_t version;
    /// The number of settings in the ``items`` field.
    size_t itemsCount;
    /// The list of settings.
    const EKCoreSetting *const items;
} EKCoreSettings;

EK_EXPORT_AS("GameCore")
typedef struct {
    /// Additional data that can be used with your core. It is passed as the first arg to every method that may need it.
    void *data;
    
    /// Called when the core will no longer be used, do all clean up code here.
    void (*deallocate)(void *data);
    
#pragma mark - General setup functions
    
    /// Gets the audio format, including common format (i.e. AVFoundation's AVAudioCommonFormat), sample rate, whether or not its interleaved, and the channel count.
    /// - Parameter data: the data field on the GameCore struct.
    EKCoreAudioFormat (*getAudioFormat)(void *data);
    
    /// Gets the video format, including width, height, pixel format, and rendering type.
    /// - Parameter data: the data field on the GameCore struct.
    EKCoreVideoFormat (*getVideoFormat)(void *data);
    
    double (*getDesiredFrameRate)(void *data);
    
    /// Whether or not the `preferredPointer` parameter will be used.
    /// - Parameter data: the data field on the GameCore struct.
    bool (*canSetVideoPointer)(void *data);
    
    /// Gets the pointer to the video buffer.
    ///
    /// - Parameters:
    ///    - data: the data field on the GameCore struct.
    ///    - preferredPointer: foo
    uint8_t *(*getVideoPointer)(void *data, uint8_t *preferredPointer);
    
#pragma mark - Lifecycle
    
    bool (*start)(void *data, const char * const gamePath, const char * const savePath);
    void (*stop)(void *data);
    void (*restart)(void *data);

    void (*play)(void *data);
    void (*pause)(void *data);
    
    void (*executeFrame)(void *data, bool willRender);
    
#pragma mark - Saving
    
    bool (*save)(void *data, const char *path);
    bool (*saveState)(void *data, const char *path);
    bool (*loadState)(void *data, const char *path);
    
#pragma mark - Controls
    
    /// Returns the maximum number of players.
    uint8_t (*getMaxPlayers)(void *data);
    
    /// Notifies a core that a new player has connected.
    bool (*playerConnected)(void *data, uint8_t player);
    
    /// Notifies a core that a player has been disconnected.
    void (*playerDisconnected)(void *data, uint8_t player);
    
    // FIXME: associated values for inputs, i.e. touch x/y values
    void (*playerSetInputs)(void *data, uint8_t player, uint32_t inputs);
    
#pragma mark - Cheats
    
    bool (*setCheats)(void *data, EKCheat *cheats, size_t count);
} EKCore;

EK_EXPORT_AS("GameCoreInfo")
typedef struct {
    // A unique identifier for this core.
    const char *id;
    /// The user-shown name of the core.
    const char *name;
    /// The developer(s) responsible for the core.
    const char *developer;
    /// The version of the core.
    const char *version;
    /// The URL to the core's source code repository.
    const char *sourceCodeUrl;
    /// The settings this core provides.
    EKCoreSettings settings;

    /// A function to do any initialization.
    ///
    /// - Parameters
    ///    - system: The system to use
    ///    - callbacks: The core callbacks
    /// - Returns: an instance of an EKCore.
    EKCore *(*setup)(EKSystem system, EKCoreCallbacks callbacks);
} EKCoreInfo;

#endif /* EclipseKit_h */
