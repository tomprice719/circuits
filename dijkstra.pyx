cdef:
  INFINITY = float("inf")

  struct Node:
    float dist
    Edge * edges
    int num_edges
    HeapEm * hem
  struct Edge:
    Node * end
    float length

  void dostuff():
    while(_):
      node = <Node*>heap_pop(heap).data
      for i in range(node.num_edges):
        end_node = node.edges[i].end
        if(node.dist + edge.length < end_node.dist):
          end_node.dist = node.dist + edge.length
          end_node.hem.priority = -end_node.dist
          if end_node.hem.location == -1:
            heap_push(end_node.hem, heap)
          else:
            bubble_up(end_node.hem, heap)
