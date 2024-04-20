#ifndef RingBuffer_h
#define RingBuffer_h

#include <stdio.h>
#include <stdatomic.h>

#define RING_BUFFER_CACHELINE 64

struct RingBuffer {
    _Alignas(RING_BUFFER_CACHELINE) atomic_uint_fast64_t head;
    _Alignas(RING_BUFFER_CACHELINE) atomic_uint_fast64_t tail;
    uint64_t capacity;
    uint8_t *inner;
};

typedef struct RingBuffer RingBuffer;

extern RingBuffer *ring_buffer_init(uint64_t capacity);
extern inline uint64_t ring_buffer_available_read_preloaded(RingBuffer *self, uint64_t tail, uint64_t head);
extern inline uint64_t ring_buffer_available_write_preloaded(RingBuffer *self, uint64_t tail, uint64_t head);
extern inline uint64_t ring_buffer_available_read(RingBuffer *self);
extern inline uint64_t ring_buffer_available_write(RingBuffer *self);
extern uint64_t ring_buffer_write(RingBuffer *self, const void *src, uint64_t length);
extern uint64_t ring_buffer_read(RingBuffer *self, void *dst, uint64_t length);
extern void ring_buffer_clear(RingBuffer *self);

#endif /* RingBuffer_h */
