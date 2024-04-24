#include "DummyCore.hpp"

#include <stdlib.h>
#include <string.h>

namespace dummycore {
    const uint8_t maxPlayers = 2;
    const uint32_t audioBufferSize = 2048 * 2;

    const uint32_t videoWidth = 160;
    const uint32_t videoHeight = 140;
    const uint32_t videoBufferSize = videoWidth * videoHeight * 4;

    struct DummyCoreCtx {
        const EKCoreCallbacks *callbacks;
        uint8_t *videoBuffer;
        int16_t *audioBuffer;
        uint8_t playersCount;
    };

    namespace methods {
        void deallocate(void *data) {
            DummyCoreCtx *ctx = static_cast<DummyCoreCtx *>(data);
            free(ctx->videoBuffer);
            free(ctx->audioBuffer);
            free(ctx);
        }

        EKCoreAudioFormat getAudioFormat(void *data) {
            return {
                .commonFormat = EKCoreCommonAudioFormatPcmInt16,
                .sampleRate = 44100,
                .channelCount = 2,
            };
        }

        EKCoreVideoFormat getVideoFormat(void *data) {
            return {
                .pixelFormat = EKCoreVideoPixelFormatBgra8Unorm,
                .renderingType = EKCoreVideoRenderingTypeFrameBuffer,
                .width = videoWidth,
                .height = videoHeight,
            };
        }

        double getDesiredFrameRate(void *data) {
            return 30.0;
        }

        bool canSetVideoPointer(void *data) {
            return true;
        }

        uint8_t *getVideoPointer(void *data, uint8_t *preferredPointer) {
            DummyCoreCtx *ctx = static_cast<DummyCoreCtx *>(data);
            if (preferredPointer != nullptr) {
                ctx->videoBuffer = preferredPointer;
            }
            return ctx->videoBuffer;
        }

        bool start(void *data, const char * const gamePath, const char * const savePath) {
            return true;
        }

        void stop(void *data) {}
        void restart(void *data) {}

        void play(void *data) {}
        void pause(void *data) {}

        void executeFrame(void *data, bool willRender) {
            DummyCoreCtx *ctx = static_cast<DummyCoreCtx *>(data);
            
            for (int i = 0; i < audioBufferSize; ++i) {
                ctx->audioBuffer[i] = (int16_t)(rand() & 0xffff);
            }
            ctx->callbacks->writeAudio(ctx->callbacks->callbackContext, ctx->audioBuffer, audioBufferSize);
            
            if (!willRender) return;
            
            for (int i = 0; i < videoBufferSize; i += 4) {
                int val = (rand() & 1) * 0xff;
                ctx->videoBuffer[i + 0] = val;
                ctx->videoBuffer[i + 1] = val;
                ctx->videoBuffer[i + 2] = val;
            }
        }

        bool save(void *data, const char *path) {
            return false;
        }

        bool saveState(void *data, const char *path) {
            return false;
        }

        bool loadState(void *data, const char *path) {
            return false;
        }

        uint8_t getMaxPlayers(void *data) {
            return maxPlayers;
        }

        /// Notifies a core that a new player has connected.
        bool playerConnected(void *data, uint8_t player) {
            DummyCoreCtx *ctx = static_cast<DummyCoreCtx *>(data);
            if (ctx->playersCount == maxPlayers) {
                return false;
            }
            ctx->playersCount++;
            return true;
        }

        /// Notifies a core that a player has been disconnected.
        void playerDisconnected(void *data, uint8_t player) {
            DummyCoreCtx *ctx = static_cast<DummyCoreCtx *>(data);
            ctx->playersCount -= (ctx->playersCount > 0);
        }

        void playerSetInputs(void *data, uint8_t player, uint32_t inputs) {}

        bool setCheats(void *data, EKCheat *cheats, size_t count) {
            return false;
        }
    }
    
    const EKCoreSetting settings[] = {};

    EKCore *initializeCore(EKSystem system, const EKCoreCallbacks *callbacks) {
        DummyCoreCtx* coreContext = static_cast<DummyCoreCtx *>(malloc(sizeof(DummyCoreCtx)));
        if (coreContext == nullptr) {
            return nullptr;
        }
        
        int16_t *audioBuffer = static_cast<int16_t *>(malloc(sizeof(int16_t) * audioBufferSize));
        if (audioBuffer == nullptr) {
            free(coreContext);
            return nullptr;
        }
        
        uint8_t *videoBuffer = static_cast<uint8_t *>(malloc(videoBufferSize));
        if (videoBuffer == nullptr) {
            free(coreContext);
            free(audioBuffer);
            return nullptr;
        }

        EKCore* core = static_cast<EKCore *>(malloc(sizeof(EKCore)));
        if (core == nullptr) {
            free(coreContext);
            free(audioBuffer);
            free(videoBuffer);
            return nullptr;
        }
        
        coreContext->callbacks = callbacks;
        coreContext->audioBuffer = audioBuffer;
        coreContext->videoBuffer = videoBuffer;
        coreContext->playersCount = 0;
        memset(coreContext->audioBuffer, 0x00, audioBufferSize);
        memset(coreContext->videoBuffer, 0xff, videoBufferSize);
        
        core->data = coreContext;
        core->deallocate = methods::deallocate;
        core->getAudioFormat = methods::getAudioFormat;
        core->getVideoFormat = methods::getVideoFormat;
        core->getDesiredFrameRate = methods::getDesiredFrameRate;
        core->canSetVideoPointer = methods::canSetVideoPointer;
        core->getVideoPointer = methods::getVideoPointer;
        core->start = methods::start;
        core->stop = methods::stop;
        core->restart = methods::restart;
        core->play = methods::play;
        core->pause = methods::pause;
        core->executeFrame = methods::executeFrame;
        core->save = methods::save;
        core->saveState = methods::saveState;
        core->loadState = methods::loadState;
        core->getMaxPlayers = methods::getMaxPlayers;
        core->playerConnected = methods::playerConnected;
        core->playerDisconnected = methods::playerDisconnected;
        core->playerSetInputs = methods::playerSetInputs;
        core->setCheats = methods::setCheats;

        return core;
    }
}

EKCoreInfo coreInfo = {
    .id = "dev.magnetar.dummycore",
    .name = "Dummy Core",
    .developer = "Magnetar",
    .sourceCodeUrl = "https://github.com/eclipseemu/eclipse-native",
    .settings = {
        .version = 1,
        .itemsCount = sizeof(dummycore::settings) / sizeof(EKCoreSetting),
        .items = dummycore::settings,
    },
    .cheatFormatsCount = 0,
    .cheatFormats = nullptr,
    .setup = dummycore::initializeCore,
};
