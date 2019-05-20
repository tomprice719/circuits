from heap cimport *
from libc.stdlib cimport malloc, free
from libc.stdio cimport printf

#TODO: are you making unnecessary cdefs

cdef:
  float INFINITY = float("inf")

  struct Node:
    float dist
    Edge ** edges_out #TODO: change to edges_out / num_edges_out
    int num_edges_out
    Edge ** edges_in
    int num_edges_in
    HeapEm * hem
    Edge * best_edge
    bint initial
    bint terminal
    #int id
  struct Edge:
    Node * start
    Node * end
    float length
    int current
    float resistance

  void propogate_lengthening_A(Node * node):
    cdef Edge * edge
    cdef Node * end_node
    for i in range(node.num_edges_out):
      edge = node.edges_out[i]
      end_node = edge.end
      if end_node.best_edge == edge:
        end_node.dist = node.dist + edge.length
        #end_node.hem.priority = -distance
        propogate_lengthening_A(end_node)

  void propogate_lengthening_B(Node* node, Heap * heap):
    cdef float new_dist
    cdef Edge * edge
    for i in range(node.num_edges_in):
      edge = node.edges_in[i]
      new_dist = edge.length + edge.start.dist
      if new_dist < node.dist:
        node.dist = new_dist
        node.best_edge = edge
    node.hem.priority = -node.dist
    if node.hem.location == -1:
      heap_push(node.hem, heap)
    else:
      bubble_down(node.hem, heap)
    for i in range(node.num_edges_out):
      edge = node.edges_out[i]
      if edge.end.best_edge == edge:
        propogate_lengthening_B(edge.end, heap)


  inline void spot_node(Node *node, Edge *edge, float distance, Heap *heap):
    node.dist = distance
    node.hem.priority = -distance
    node.best_edge = edge
    heap_push(node.hem, heap)

  inline void improve_node(Node *node, Edge *edge, float distance, Heap *heap):
    node.dist = distance
    node.hem.priority = -distance
    node.best_edge = edge
    bubble_up(node.hem, heap)

  Node* dijkstra(Heap* heap):
    cdef Edge * edge
    cdef Node * node
    cdef Node * end_node
    cdef HeapEm * hem

    #for i in range(initial_node.num_edges):
    #  edge = &initial_node.edges[i]
    #  spot_node(edge.end, edge, edge.length, current_iteration, heap)

    while(heap.size > 0):
      hem = heap_pop(heap)
      node = <Node*>hem.data
      if node.terminal:
        return node
      for i in range(node.num_edges_out):
        edge = node.edges_out[i]
        end_node = edge.end
        if end_node.dist == INFINITY:
          spot_node(end_node, edge, node.dist + edge.length, heap)
        elif node.dist + edge.length < end_node.dist:
          improve_node(end_node, edge, node.dist + edge.length, heap)
    return NULL

  #TODO: handle error for when no path is found

  int determine_flow(Heap * heap, int num_iterations):
    cdef int i
    cdef Node * node
    cdef Edge * edge = NULL

    for i in range(num_iterations):
      node = dijkstra(heap)
      if node == NULL:
        return 1
      while(not node.initial):
        edge = node.best_edge
        edge.current += 1
        edge.length = (2 * edge.current + 1) * edge.resistance # contribution to change in power
        node = edge.start
      edge.end.dist = edge.length
      propogate_lengthening_A(edge.end)
      propogate_lengthening_B(edge.end, heap)
    return 0

  void initialize_heap(int num_nodes, Node * nodes, Heap * heap):
    for i in range(num_nodes):
      if nodes[i].initial:
        spot_node(&nodes[i], NULL, 0, heap)

def circuit_test(num_nodes, initial_node_index, terminal_node_index, edges, num_iterations):
  cdef Node * nodes = <Node *> malloc(num_nodes * sizeof(Node))
  cdef HeapEm* hems = <HeapEm*> malloc(num_nodes * sizeof(HeapEm))
  cdef Edge* c_edges = <Edge*>malloc(len(edges) * sizeof(Edge))
  cdef Heap heap
  cdef Edge * edge
  cdef float power = 0.0

  heap.inv_location = <HeapEm**> malloc(num_nodes * sizeof(HeapEm*))
  heap.size = 0

  for i in range(num_nodes):
    if i == initial_node_index:
      nodes[i].dist = 0.0
      nodes[i].initial = True
    else:
      nodes[i].dist = INFINITY
      nodes[i].initial = False
    if i == terminal_node_index:
      nodes[i].terminal = True
    else:
      nodes[i].terminal = False
    nodes[i].num_edges_out = 0
    nodes[i].num_edges_in = 0
    nodes[i].hem = &hems[i]
    #nodes[i].id = i
    #nodes[i].sp_in = NULL
    hems[i].data = &(nodes[i])
    hems[i].location = -1
    nodes[i].best_edge = NULL
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

  initialize_heap(num_nodes, nodes, &heap)

  print "done preparing"

  print determine_flow(&heap, num_iterations)

  for i in range(num_nodes):
    for j in range(nodes[i].num_edges_out):
      edge = nodes[i].edges_out[j]
      #print edge.resistance, edge.current
      power += edge.resistance * edge.current ** 2

  print power / num_iterations ** 2

  for i in range(num_nodes):
    free(nodes[i].edges_out)
  free(heap.inv_location)
  free(hems)
  free(nodes)
