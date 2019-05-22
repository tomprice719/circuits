from heap cimport *
from libc.stdlib cimport malloc, free
from libc.stdio cimport printf

#TODO: single initial and terminal node

cdef:
  float INFINITY = float("inf")

  struct Node:
    float dist
    Edge * edges
    int num_edges
    HeapEm * hem
    Edge * best_edge
    int last_seen
    #int id
  struct Edge:
    Node * start
    Node * end
    float length
    int current
    float resistance

  inline void spot_node(Node *node, Edge *edge, float distance, int current_iteration, Heap *heap):
    node.dist = distance
    node.hem.priority = -distance
    node.best_edge = edge
    node.last_seen = current_iteration
    heap_push(node.hem, heap)

  inline void improve_node(Node *node, Edge *edge, float distance, Heap *heap):
    node.dist = distance
    node.hem.priority = -distance
    node.best_edge = edge
    bubble_up(node.hem, heap)

  int dijkstra(Node* initial_node, Node* terminal_node, Heap* heap, int current_iteration):
    cdef Edge * edge
    cdef Node * node
    cdef Node * end_node

    for i in range(initial_node.num_edges):
      edge = &initial_node.edges[i]
      spot_node(edge.end, edge, edge.length, current_iteration, heap)

    while(heap.size > 0):
      node = <Node*>heap_pop(heap).data
      if node == terminal_node:
        return 0
      for i in range(node.num_edges):
        edge = &node.edges[i]
        end_node = edge.end
        if end_node.last_seen < current_iteration:
          spot_node(end_node, edge, node.dist + edge.length, current_iteration, heap)
        elif node.dist + edge.length < end_node.dist:
          improve_node(end_node, edge, node.dist + edge.length, heap)
    return 1

  #TODO: handle error for when no path is found

  void determine_flow(Node * initial_node, Node * terminal_node, Heap * heap, int num_iterations):
    cdef int i
    cdef Node * node
    for i in range(num_iterations):
      dijkstra(initial_node, terminal_node, heap, i)
      node = terminal_node
      while(node != initial_node):
        edge = node.best_edge
        edge.current += 1
        edge.length = (2 * edge.current + 1) * edge.resistance # contribution to change in power
        node = edge.start
      heap.size = 0

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
    nodes[i].hem = &hems[i]
    #nodes[i].id = i
    #nodes[i].sp_in = NULL
    hems[i].data = &(nodes[i])
    nodes[i].best_edge = NULL
    nodes[i].last_seen = -1
  for start, end, resistance in edges:
    nodes[start].num_edges += 1
  for i in range(num_nodes):
    nodes[i].edges = <Edge *>malloc(nodes[i].num_edges * sizeof(Edge))
    nodes[i].num_edges = 0
  for start, end, resistance in edges:
    edge = &nodes[start].edges[nodes[start].num_edges]
    edge.start = &nodes[start]
    edge.end = &nodes[end]
    edge.resistance = resistance
    edge.length = resistance
    edge.current = 0
    nodes[start].num_edges += 1
  print "done preparing"

  determine_flow(&nodes[initial_node_index], &nodes[terminal_node_index], &heap, num_iterations)

  for i in range(num_nodes):
    for j in range(nodes[i].num_edges):
      edge = &nodes[i].edges[j]
      #print edge.resistance, edge.current
      power += edge.resistance * edge.current ** 2

  print power / num_iterations ** 2

  for i in range(num_nodes):
    free(nodes[i].edges)
  free(heap.inv_location)
  free(hems)
  free(nodes)
