from heap cimport *
from libc.stdlib cimport malloc, free
from libc.stdio cimport printf

#TODO: are you making unnecessary cdefs

cdef:
  float INFINITY = float("inf")

  struct Node:
    float forward_dist
    float reverse_dist
    float forward_heuristic
    float reverse_heuristic
    Edge ** edges_out #TODO: change to edges_out / num_edges_out
    int num_edges_out
    Edge ** edges_in
    int num_edges_in
    HeapEm * forward_hem
    HeapEm * reverse_hem
    Edge * best_edge_in
    Edge* best_edge_out
    bint initial
    bint terminal
    #int id
  struct Edge:
    Node * start
    Node * end
    float length
    int current
    float resistance

  void forward_propogate_lengthening_A(Node * node):
    cdef Edge * edge
    cdef Node * end_node
    for i in range(node.num_edges_out):
      edge = node.edges_out[i]
      end_node = edge.end
      if end_node.best_edge_in == edge:
        end_node.forward_dist = node.forward_dist + edge.length
        forward_propogate_lengthening_A(end_node)

  void reverse_propogate_lengthening_A(Node * node):
    cdef Edge * edge
    cdef Node * start_node
    for i in range(node.num_edges_in):
      edge = node.edges_in[i]
      start_node = edge.start
      if start_node.best_edge_out == edge:
        start_node.reverse_dist = node.reverse_dist + edge.length
        reverse_propogate_lengthening_A(start_node)

  void forward_propogate_lengthening_B(Node* node, Heap * heap, bint preserve_heap, float default_heuristic):
    cdef float new_dist
    cdef Edge * edge
    for i in range(node.num_edges_in):
      edge = node.edges_in[i]
      new_dist = edge.length + edge.start.forward_dist
      if new_dist < node.forward_dist:
        node.forward_dist = new_dist
        node.best_edge_in = edge
    if preserve_heap:
      if node.forward_hem.location == -1:
        node.forward_heuristic = min(node.reverse_dist, default_heuristic)
        node.forward_hem.priority = -(node.forward_dist + node.forward_heuristic)
        heap_push(node.forward_hem, heap)
      else:
        node.forward_hem.priority = -(node.forward_dist + node.forward_heuristic)
        bubble_down(node.forward_hem, heap)
    else:
      if node.forward_hem.location == -1:
        heap_halfpush(node.forward_hem, heap)

    for i in range(node.num_edges_out):
      edge = node.edges_out[i]
      if edge.end.best_edge_in == edge:
        forward_propogate_lengthening_B(edge.end, heap, preserve_heap, default_heuristic)

  void reverse_propogate_lengthening_B(Node* node, Heap * heap, bint preserve_heap, float default_heuristic):
    cdef float new_dist
    cdef Edge * edge
    for i in range(node.num_edges_out):
      edge = node.edges_out[i]
      new_dist = edge.length + edge.end.reverse_dist
      if new_dist < node.reverse_dist:
        node.reverse_dist = new_dist
        node.best_edge_out = edge
    if preserve_heap:
      if node.reverse_hem.location == -1:
        node.reverse_heuristic = min(node.forward_dist, default_heuristic)
        node.reverse_hem.priority = -(node.reverse_dist + node.reverse_heuristic)
        heap_push(node.reverse_hem, heap)
      else:
        node.reverse_hem.priority = -(node.reverse_dist + node.reverse_heuristic)
        bubble_down(node.reverse_hem, heap)
    else:
      if node.reverse_hem.location == -1:
        heap_halfpush(node.reverse_hem, heap)

    for i in range(node.num_edges_in):
      edge = node.edges_in[i]
      if edge.start.best_edge_out == edge:
        reverse_propogate_lengthening_B(edge.start, heap, preserve_heap, default_heuristic)


  inline void forward_spot_node(Node *node, Edge *edge, float distance, float default_heuristic, Heap *heap):
    node.forward_dist = distance
    node.forward_heuristic = min(node.reverse_dist, default_heuristic)
    node.forward_hem.priority = -(node.forward_dist + node.forward_heuristic)
    node.best_edge_in = edge
    heap_push(node.forward_hem, heap)

  inline void reverse_spot_node(Node *node, Edge *edge, float distance, float default_heuristic, Heap *heap):
    node.reverse_dist = distance
    node.reverse_heuristic = min(node.forward_dist, default_heuristic)
    node.reverse_hem.priority = -(node.reverse_dist + node.reverse_heuristic)
    node.best_edge_out = edge
    heap_push(node.reverse_hem, heap)

  inline void forward_improve_node(Node *node, Edge *edge, float distance, Heap *heap):
    node.forward_dist = distance
    node.forward_hem.priority = -(node.forward_dist + node.forward_heuristic)
    node.best_edge_in = edge
    bubble_up(node.forward_hem, heap)

  inline void reverse_improve_node(Node *node, Edge *edge, float distance, Heap *heap):
    node.reverse_dist = distance
    node.reverse_hem.priority = -(node.reverse_dist + node.reverse_heuristic)
    node.best_edge_out = edge
    bubble_up(node.reverse_hem, heap)

  #TODO: handle error for when no path is found

  int forward_loop(Heap * forward_heap, Heap * reverse_heap, float default_heuristic, int num_iterations):
    cdef int i
    cdef Node * node
    cdef Node * terminal_node
    cdef Edge * edge = NULL
    cdef Node * end_node
    cdef HeapEm * hem
    cdef int path_count = 0

    for i in range(forward_heap.size):
      hem = forward_heap.inv_location[i]
      node = <Node *>hem.data
      node.forward_heuristic = min(node.reverse_dist, default_heuristic)
      node.forward_hem.priority = -(node.forward_dist + node.forward_heuristic)

    heapify(forward_heap)

    for i in range(num_iterations):
      if forward_heap.size == 0:
        break
      hem = heap_pop(forward_heap)
      node = <Node*>hem.data
      if node.terminal:
        path_count += 1
        terminal_node = node
        while(not node.initial):
          edge = node.best_edge_in
          edge.current += 1
          edge.length = (2 * edge.current + 1) * edge.resistance # contribution to change in power
          node = edge.start
        edge.end.forward_dist = edge.length
        forward_propogate_lengthening_A(edge.end)
        forward_propogate_lengthening_B(edge.end, forward_heap, True, default_heuristic)

        edge = terminal_node.best_edge_in
        edge.start.reverse_dist = edge.length
        reverse_propogate_lengthening_A(edge.start)
        reverse_propogate_lengthening_B(edge.start, reverse_heap, False, 0.0)
      else:
        for i in range(node.num_edges_out):
          edge = node.edges_out[i]
          end_node = edge.end
          if end_node.forward_dist == INFINITY:
            forward_spot_node(end_node, edge, node.forward_dist + edge.length, default_heuristic, forward_heap)
          elif node.forward_dist + edge.length < end_node.forward_dist:
            forward_improve_node(end_node, edge, node.forward_dist + edge.length, forward_heap)
    return path_count

  int reverse_loop(Heap * forward_heap, Heap * reverse_heap, float default_heuristic, int num_iterations):
    cdef int i
    cdef Node * node
    cdef Node * initial_node
    cdef Edge * edge = NULL
    cdef Node * start_node
    cdef HeapEm * hem
    cdef int path_count = 0

    for i in range(reverse_heap.size):
      hem = reverse_heap.inv_location[i]
      node = <Node *>hem.data
      node.reverse_heuristic = min(node.forward_dist, default_heuristic)
      node.reverse_hem.priority = -(node.reverse_dist + node.reverse_heuristic)

    heapify(reverse_heap)

    for i in range(num_iterations):
      if reverse_heap.size == 0:
        break
      hem = heap_pop(reverse_heap)
      node = <Node*>hem.data
      if node.initial:
        path_count += 1
        initial_node = node
        while(not node.terminal):
          edge = node.best_edge_out
          edge.current += 1
          edge.length = (2 * edge.current + 1) * edge.resistance # contribution to change in power
          node = edge.end
        edge.start.reverse_dist = edge.length
        reverse_propogate_lengthening_A(edge.start)
        reverse_propogate_lengthening_B(edge.start, reverse_heap, True, default_heuristic)

        edge = initial_node.best_edge_out
        edge.end.forward_dist = edge.length
        forward_propogate_lengthening_A(edge.end)
        forward_propogate_lengthening_B(edge.end, forward_heap, False, 0.0)
      else:
        for i in range(node.num_edges_in):
          edge = node.edges_in[i]
          start_node = edge.start
          if start_node.reverse_dist == INFINITY:
            reverse_spot_node(start_node, edge, node.reverse_dist + edge.length, default_heuristic, reverse_heap)
          elif node.reverse_dist + edge.length < start_node.reverse_dist:
            reverse_improve_node(start_node, edge, node.reverse_dist + edge.length, reverse_heap)
    return path_count

  void forward_initialize_heap(int num_nodes, Node * nodes, float default_heuristic, Heap * heap):
    for i in range(num_nodes):
      if nodes[i].initial:
        forward_spot_node(&nodes[i], NULL, 0, default_heuristic, heap)

  void reverse_initialize_heap(int num_nodes, Node * nodes, float default_heuristic, Heap * heap):
    for i in range(num_nodes):
      if nodes[i].terminal:
        reverse_spot_node(&nodes[i], NULL, 0, default_heuristic, heap)

def circuit_test(num_nodes, initial_node_index, terminal_node_index, edges, num_iterations):
  cdef Node * nodes = <Node *> malloc(num_nodes * sizeof(Node))
  cdef HeapEm* forward_hems = <HeapEm*> malloc(num_nodes * sizeof(HeapEm))
  cdef HeapEm* reverse_hems = <HeapEm*> malloc(num_nodes * sizeof(HeapEm))
  cdef Edge* c_edges = <Edge*>malloc(len(edges) * sizeof(Edge))
  cdef Heap forward_heap
  cdef Heap reverse_heap
  cdef Edge * edge
  cdef float power = 0.0

  forward_heap.inv_location = <HeapEm**> malloc(num_nodes * sizeof(HeapEm*))
  reverse_heap.inv_location = <HeapEm**> malloc(num_nodes * sizeof(HeapEm*))
  forward_heap.size = 0
  reverse_heap.size = 0

  for i in range(num_nodes):
    if i == initial_node_index:
      nodes[i].forward_dist = 0.0
      nodes[i].initial = True
    else:
      nodes[i].forward_dist = INFINITY
      nodes[i].initial = False
    if i == terminal_node_index:
      nodes[i].reverse_dist = 0.0
      nodes[i].terminal = True
    else:
      nodes[i].reverse_dist = INFINITY
      nodes[i].terminal = False
    nodes[i].num_edges_out = 0
    nodes[i].num_edges_in = 0
    nodes[i].forward_hem = &forward_hems[i]
    nodes[i].reverse_hem = &reverse_hems[i]
    #nodes[i].id = i
    #nodes[i].sp_in = NULL
    forward_hems[i].data = &(nodes[i])
    forward_hems[i].location = -1
    reverse_hems[i].data = &(nodes[i])
    reverse_hems[i].location = -1
    nodes[i].best_edge_in = NULL
    nodes[i].best_edge_out = NULL
  for start, end, resistance in edges:
    nodes[start].num_edges_out += 1
    nodes[end].num_edges_in += 1
  for i in range(num_nodes):
    nodes[i].edges_out = <Edge **>malloc(nodes[i].num_edges_out * sizeof(Edge *))
    nodes[i].edges_in = <Edge **>malloc(nodes[i].num_edges_in * sizeof(Edge *))
    # Reset num_edges and num_edges_in
    # They will temporarily count only the edges that have been initialized
    nodes[i].num_edges_out = 0
    nodes[i].num_edges_in = 0
  for i, (start, end, resistance) in enumerate(edges):
    edge = &c_edges[i]
    nodes[start].edges_out[nodes[start].num_edges_out] = edge
    nodes[end].edges_in[nodes[end].num_edges_in] = edge
    edge.start = &nodes[start]
    edge.end = &nodes[end]
    edge.resistance = resistance
    edge.length = resistance
    edge.current = 0
    nodes[start].num_edges_out += 1
    nodes[end].num_edges_in += 1

  # initialize_heap(num_nodes, nodes, &heap)
  #
  # print "done preparing"
  #
  # print determine_flow(&heap, num_iterations)
  #
  # for i in range(num_nodes):
  #   for j in range(nodes[i].num_edges_out):
  #     edge = nodes[i].edges_out[j]
  #     #print edge.resistance, edge.current
  #     power += edge.resistance * edge.current ** 2
  #
  # print power / num_iterations ** 2
  #
  # for i in range(num_nodes):
  #   free(nodes[i].edges_out)
  # free(heap.inv_location)
  # free(hems)
  # free(nodes)
