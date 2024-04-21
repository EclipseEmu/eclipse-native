#include "RingBuffer.h"
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

RingBuffer *ring_buffer_init(uint64_t capacity) {
    struct RingBuffer *ring = malloc(sizeof(struct RingBuffer));
    if (ring == NULL) {
        return NULL;
    }
    
    void *inner = malloc(capacity);
    if (inner == NULL) {
        free(ring);
        return NULL;
    }
    
    ring->inner = inner;
    ring->capacity = capacity;
    ring->head = 0;
    ring->tail = 0;

    return ring;
}

inline void ring_buffer_deinit(RingBuffer *self) {
    free(self->inner);
    free(self);
}

inline uint64_t ring_buffer_available_read_preloaded(RingBuffer *self, uint64_t tail, uint64_t head) {
    // NOTE: this is equivalent to
    // `return tail >= head ? tail - head : tail + self->capacity - head;`
    return tail + ((tail >= head) * self->capacity) - head;
}

inline uint64_t ring_buffer_available_write_preloaded(RingBuffer *self, uint64_t tail, uint64_t head) {
    return tail >= head ? self->capacity - tail + head : head - tail;
}

inline uint64_t ring_buffer_available_read(RingBuffer *self) {
    uint64_t head = atomic_load_explicit(&(self->head), memory_order_relaxed);
    uint64_t tail = atomic_load_explicit(&(self->tail), memory_order_relaxed);
    return ring_buffer_available_read_preloaded(self, tail, head);
}

inline uint64_t ring_buffer_available_write(RingBuffer *self) {
    uint64_t head = atomic_load_explicit(&(self->head), memory_order_relaxed);
    uint64_t tail = atomic_load_explicit(&(self->tail), memory_order_relaxed);
    return ring_buffer_available_write_preloaded(self, tail, head);
}

/// this is under the assumption that length will never be more than capacity
uint64_t ring_buffer_write(RingBuffer *self, const void *src, uint64_t length) {
    uint64_t head = atomic_load_explicit(&(self->head), memory_order_relaxed);
    uint64_t tail = atomic_load_explicit(&(self->tail), memory_order_acquire);
    
    uint64_t available = ring_buffer_available_write_preloaded(self, tail, head);
    if (available < length) {
        return 0;
    }
    
    uint64_t next_tail = tail + length;
    bool needs_wrap = next_tail >= self->capacity;
    next_tail -= needs_wrap * self->capacity;
    
    uint64_t len1 = needs_wrap ? self->capacity - tail : length;
    uint64_t len2 = needs_wrap * next_tail;
    
    memcpy(self->inner + tail, src, len1);
    memcpy(self->inner, src + len1, len2);
    
    atomic_store_explicit(&(self->tail), next_tail, memory_order_release);
    return length;
}

uint64_t ring_buffer_read(RingBuffer *self, void *dst, uint64_t length) {
    uint64_t head = atomic_load_explicit(&(self->head), memory_order_acquire);
    uint64_t tail = atomic_load_explicit(&(self->tail), memory_order_relaxed);
    
    uint64_t available = ring_buffer_available_read_preloaded(self, tail, head);
    if (available < length) {
        return 0;
    }
    
    uint64_t next_head = head + length;
    bool needs_wrap = next_head >= self->capacity;
    next_head -= needs_wrap * self->capacity;
    
    uint64_t len1 = needs_wrap ? self->capacity - head : length;
    uint64_t len2 = needs_wrap * next_head;
    
    memcpy(dst, self->inner + head, len1);
    memcpy(dst + head, self->inner, len2);
    
    atomic_store_explicit(&(self->head), next_head, memory_order_release);
    return length;
}

void ring_buffer_clear(RingBuffer *self) {
    atomic_store_explicit((&self->head), 0, memory_order_relaxed);
    atomic_store_explicit((&self->tail), 0, memory_order_relaxed);
    memset(self->inner, 0, self->capacity);
}
