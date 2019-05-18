from heap cimport *
from libc.stdlib cimport malloc, free
from libc.stdio cimport printf

#TODO: multiple initial / terminal nodes
#TODO: are you making unnecessary cdefs
#TODO: initialize edges_in

cdef:
  float INFINITY = float("inf")

  struct Node:
    float dist
    Edge * edges #TODO: change to edges_out / num_edges_out
    int num_edges
    Edge ** edges_in
    int num_edges_in
    HeapEm * hem
    Edge * best_edge
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
    for i in range(node.num_edges):
      edge = &node.edges[i]
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
    for i in range(node.num_edges):
      edge = &node.edges[i]
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

  int dijkstra(Node* terminal_node, Heap* heap):
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
      if node == terminal_node:
        return 0
      for i in range(node.num_edges):
        edge = &node.edges[i]
        end_node = edge.end
        if end_node.dist == INFINITY:
          spot_node(end_node, edge, node.dist + edge.length, heap)
        elif node.dist + edge.length < end_node.dist:
          improve_node(end_node, edge, node.dist + edge.length, heap)
    return 1

  #TODO: handle error for when no path is found

  int determine_flow(Node * initial_node, Node * terminal_node, Heap * heap, int num_iterations):
    cdef int i
    cdef Node * node
    cdef Edge * edge = NULL
    spot_node(initial_node, NULL, 0, heap)
    for i in range(num_iterations):
      if dijkstra(terminal_node, heap) == 1:
        return 1
      node = terminal_node
      while(node != initial_node):
        edge = node.best_edge
        edge.current += 1
        edge.length = (2 * edge.current + 1) * edge.resistance # contribution to change in power
        node = edge.start
      edge.end.dist = edge.length
      propogate_lengthening_A(edge.end)
      propogate_lengthening_B(edge.end, heap)
    return 0

def circuit_test(num_nodes, initial_node_index, terminal_node_index, edges, num_iterations):
  cdef Node * nodes = <Node *> malloc(num_nodes * sizeof(Node))
  cdef HeapEm* hems = <HeapEm*> malloc(num_nodes * sizeof(HeapEm))
  cdef Heap heap
  cdef Edge * edge
  cdef float power = 0.0

  heap.inv_location = <HeapEm**> malloc(num_nodes * sizeof(HeapEm*))
  heap.size = 0

  for i in range(num_nodes):
    if i == initial_node_index:
      nodes[i].dist = 0.0
    else:
      nodes[i].dist = INFINITY
    nodes[i].num_edges = 0
    nodes[i].num_edges_in = 0
    nodes[i].hem = &hems[i]
    #nodes[i].id = i
    #nodes[i].sp_in = NULL
    hems[i].data = &(nodes[i])
    hems[i].location = -1
    nodes[i].best_edge = NULL
  for start, end, resistance in edges:
    nodes[start].num_edges += 1
    nodes[end].num_edges_in += 1
  for i in range(num_nodes):
    nodes[i].edges = <Edge *>malloc(nodes[i].num_edges * sizeof(Edge))
    nodes[i].edges_in = <Edge **>malloc(nodes[i].num_edges_in * sizeof(Edge *))
    # Reset num_edges and num_edges_in
    # They will temporarily count only the edges that have been initialized
    nodes[i].num_edges = 0
    nodes[i].num_edges_in = 0
  for start, end, resistance in edges:
    edge = &nodes[start].edges[nodes[start].num_edges]
    nodes[end].edges_in[nodes[end].num_edges_in] = edge
    edge.start = &nodes[start]
    edge.end = &nodes[end]
    edge.resistance = resistance
    edge.length = resistance
    edge.current = 0
    nodes[start].num_edges += 1
    nodes[end].num_edges_in += 1
  print "done preparing"

  print determine_flow(&nodes[initial_node_index], &nodes[terminal_node_index], &heap, num_iterations)

  for i in range(num_nodes):
    for j in range(nodes[i].num_edges):
      edge = &nodes[i].edges[j]
      print edge.resistance, edge.current
      power += edge.resistance * edge.current ** 2

  print power / num_iterations ** 2

  for i in range(num_nodes):
    free(nodes[i].edges)
  free(heap.inv_location)
  free(hems)
  free(nodes)
