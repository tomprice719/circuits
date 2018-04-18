cdef:
  struct HeapEm:
    float priority
    int location
    void * data
  struct Heap:
    HeapEm** inv_location
    int size

  inline void swap_heap_elements(HeapEm* orig_parent, HeapEm* orig_child, Heap* heap):
    heap.inv_location[orig_parent.location] = orig_child
    heap.inv_location[orig_child.location] = orig_parent
    orig_parent.location = orig_child.location
    orig_child.location = (orig_child.location - 1) / 2

  void bubble_up(HeapEm * em, Heap* heap):
    cdef HeapEm* parent
    while(em.location > 0):
      parent = heap.inv_location[(em.location - 1) / 2]
      if (em.priority > parent.priority):
        swap_heap_elements(parent, em, heap)
      else:
        break

  void bubble_down(HeapEm* em, Heap* heap):
    cdef HeapEm* max_child
    cdef HeapEm* left_child
    cdef HeapEm* right_child

    while(True):

      if 2 * em.location + 1 < heap.size:
        left_child = heap.inv_location[2 * em.location + 1]
        max_child = NULL

        if 2 * em.location + 2 < heap.size:
          right_child = heap.inv_location[2 * em.location + 2]

          if left_child.priority > em.priority:
            if right_child.priority > left_child.priority:
              max_child = right_child
            else:
              max_child = left_child
          elif right_child.priority > em.priority:
              max_child = right_child
        elif left_child.priority > em.priority:
          max_child = left_child
        if max_child != NULL:
          swap_heap_elements(em, max_child, heap)
        else:
          break
      else:
        break

  void heap_push(HeapEm* em, Heap* heap):
    heap.inv_location[heap.size] = em
    em.location = heap.size
    heap.size += 1
    bubble_up(em, heap)

  HeapEm* heap_pop(Heap* heap):
    cdef HeapEm* orig_top = heap.inv_location[0]
    heap.size -= 1
    cdef HeapEm* orig_bottom = heap.inv_location[heap.size]

    heap.inv_location[0] = orig_bottom
    orig_top.location = -1
    orig_bottom.location = 0

    bubble_down(orig_bottom, heap)
    return orig_top

def heap_test():
  cdef Heap heap;
  cdef HeapEm* inv_location[20]
  cdef HeapEm ems[20]

  heap.size = 0
  heap.inv_location = inv_location

  nums = [2, 12, 7, 14, 19, 5, 1, 16, 0, 6, 10, 17, 9, 13, 15, 11, 3, 18, 8, 4]

  for i in range(20):
    ems[i].priority = nums[i]
    ems[i].location = -1
    heap_push(&ems[i], &heap)

  for i in range(20):
    print heap_pop(&heap).priority
