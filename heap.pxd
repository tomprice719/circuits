cdef:
  struct HeapEm:
    float priority
    int location
    void * data
  struct Heap:
    HeapEm** inv_location
    int size
  void bubble_up(HeapEm * em, Heap* heap)
  void bubble_down(HeapEm* em, Heap* heap)
  void heap_push(HeapEm* em, Heap* heap)
  void heap_halfpush(HeapEm* em, Heap* heap)
  void heapify(Heap * heap)
  HeapEm* heap_pop(Heap* heap)
