from heap cimport *
from libc.stdlib cimport malloc, free
from libc.stdio cimport printf

#TODO: single initial and terminal node

cdef:
  float INFINITY = float("inf")

  float * das #distance alternating sums

  struct Node:
    float dist
    Edge ** edges_out
    int num_edges_out
    Edge ** edges_in
    int num_edges_in
    HeapEm * hem
    Edge * best_edge
    int last_seen
    int last_popped
    float last_popped_dist
    float heuristic
    #int id
  struct Edge:
    Node * start
    Node * end
    float length
    int current
    float resistance

  inline void spot_node(Node *node, Edge *edge, float distance, int current_iteration, Heap *heap):
    if (current_iteration - node.last_popped) % 2 == 0:
      node.heuristic = das[current_iteration - 1] + das[node.last_popped] - node.last_popped_dist
    else:
      node.heuristic = das[current_iteration - 1] - das[node.last_popped] + node.last_popped_dist
    node.dist = distance
    node.hem.priority = -(distance + node.heuristic)
    node.best_edge = edge
    node.last_seen = current_iteration
    heap_push(node.hem, heap)

  inline void improve_node(Node *node, Edge *edge, float distance, Heap *heap):
    node.dist = distance
    node.hem.priority = -(distance + node.heuristic)
    node.best_edge = edge
    bubble_up(node.hem, heap)

  inline void forward_pop_action(Node * node, Heap * heap, int current_iteration):
    cdef Edge * edge
    cdef Node * end_node
    cdef int i
    node.last_popped = current_iteration
    node.last_popped_dist = node.dist
    for i in range(node.num_edges_out):
      edge = node.edges_out[i]
      end_node = edge.end
      if end_node.last_seen < current_iteration:
        spot_node(end_node, edge, node.dist + edge.length, current_iteration, heap)
      elif node.dist + edge.length < end_node.dist:
        improve_node(end_node, edge, node.dist + edge.length, heap)

  inline void reverse_pop_action(Node * node, Heap * heap, int current_iteration):
    cdef Edge * edge
    cdef Node * start_node
    cdef int i
    node.last_popped = current_iteration
    node.last_popped_dist = node.dist
    for i in range(node.num_edges_in):
      edge = node.edges_in[i]
      start_node = edge.start
      if start_node.last_seen < current_iteration:
        spot_node(start_node, edge, node.dist + edge.length, current_iteration, heap)
      elif node.dist + edge.length < start_node.dist:
        improve_node(start_node, edge, node.dist + edge.length, heap)

  void forward_A_star(Node* initial_node, Node* terminal_node, Heap* heap, int current_iteration):
    cdef Edge * edge
    cdef Node * node
    cdef Node * end_node
    cdef int i

    for i in range(initial_node.num_edges_out):
      edge = initial_node.edges_out[i]
      spot_node(edge.end, edge, edge.length, current_iteration, heap)

    i = 0

    while(heap.size > 0):
      node = <Node*>heap_pop(heap).data
      if node == terminal_node:
        break
      forward_pop_action(node, heap, current_iteration)
      i += 1
    while(heap.size > 0 and i > 0):
      node = <Node*>heap_pop(heap).data
      forward_pop_action(node, heap, current_iteration)
      i -= 1

  void reverse_A_star(Node* initial_node, Node* terminal_node, Heap* heap, int current_iteration):
    cdef Edge * edge
    cdef Node * node
    cdef Node * end_node
    cdef int i

    for i in range(terminal_node.num_edges_in):
      edge = terminal_node.edges_in[i]
      spot_node(edge.start, edge, edge.length, current_iteration, heap)

    i = 0

    while(heap.size > 0):
      node = <Node*>heap_pop(heap).data
      if node == initial_node:
        break
      reverse_pop_action(node, heap, current_iteration)
      i += 1
    while(heap.size > 0 and i > 0):
      node = <Node*>heap_pop(heap).data
      reverse_pop_action(node, heap, current_iteration)
      i -= 1

  #TODO: handle error for when no path is found

  void determine_flow(Node * initial_node, Node * terminal_node, Heap * heap, int num_iterations):
    cdef int i
    cdef Node * node

    das = <float *>malloc((num_iterations + 1) * sizeof(float))

    das[0] = 0

    for i in range(1, num_iterations + 1, 2):
      forward_A_star(initial_node, terminal_node, heap, i)

      node = terminal_node
      while(node != initial_node):
        edge = node.best_edge
        edge.current += 1
        edge.length = (2 * edge.current + 1) * edge.resistance # contribution to change in power
        node = edge.start
      heap.size = 0

      das[i] = terminal_node.dist - das[i - 1]

      reverse_A_star(initial_node, terminal_node, heap, i + 1)

      node = initial_node
      while(node != terminal_node):
        edge = node.best_edge
        edge.current += 1
        edge.length = (2 * edge.current + 1) * edge.resistance # contribution to change in power
        node = edge.end
      heap.size = 0

      das[i + 1] = initial_node.dist - das[i]
