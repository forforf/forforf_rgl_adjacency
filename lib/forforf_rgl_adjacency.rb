require 'rgl/adjacency'
require 'rgl/traversal'
require 'json'

class MyDG < RGL::DirectedAdjacencyGraph
  
  #Graph identity is based on edges
  def hash
    a = self.edge_array.sort
    h = a.hash
  end
 
  #Graphs are #eql? if edges are equal
  #TODO update the other equality methods
  def eql?(other)
    self.edge_array.sort == other.edge_array.sort
  end

  #A rough hack to get the in-degree for a vertex
  #nil vertices are not counted (TODO Prevent nil verts in RGL)
  #There's probably a better way than #reverse
  #but I lack the chops for it
  def in_degree(v)
    rdg = self.reverse
    rdg.out_degree(v)
  end

  def out_degree(v)
    self.adjacent_vertices(v).size
  end
  
  #Find nodes with #in_degree of 0
  def nodes_with_no_parents
    top_nodes = []
    self.each_vertex do |v|
      if in_degree(v) == 0
        top_nodes << v
      end
    end
    top_nodes
  end
  
  #selects the node(s) with the maximum tree size (not just out degree)
  def best_top_nodes
    top_nodes = {}
    self.each_vertex do |v|
      top_nodes[v] = self.bfs_search_tree_from(v).size
    end
    max = top_nodes.values.max
    top_verts = top_nodes.select{|k,v| v == max}.keys
  end

  #returnes edges as a nested array
  # [ [from, to], [from, to] ... ]
  def edge_array
    self.edges.map{|edge| edge.to_a}
  end
  
  #find parents to a given vertex
  def source_vertices(v)
    rdg = self.reverse
    rdg.adjacent_vertices(v)
  end
  
  #determines if current digraph overlaps
  #with another digraph (i.e. any shared vertices)
  def connected_to?(dg)
    self_verts = self.vertices
    dg_verts = dg.vertices
    connected = if (self_verts & dg_verts).empty?
        false
    else
      true
    end
    connected
  end
  
  #merge with another digraph
  def merge(other)
    self.add_edges(*other.edge_array)
    self
  end
  
  #returns false if no connected edges, otherwise returns
  #the edges that connects
  #shoulr probably return nil if no edges connect
  def connected_edges?(this_edges, other_edges)
    intersection = this_edges.flatten & other_edges.flatten
    if intersection.nil? || intersection.empty? 
      false
    else
      this_edges | other_edges
    end
  end
  
  #This breaks the graph down and returns an array of 
  #its component digraphs, where each edge forms a single digraph
  #(i.e., an array of digraphs, each with two vertices)
  def atomic_graphs
    edges = self.edge_array
    uniq_dgs = edges.map {|edge| MyDG[*edge] }
    uniq_dgs
  end
 
  #Takes a list of digraphs and determines if they have any overlap
  #and combines any overlapped digraphs into a common digraph 
  def find_connected_graphs(dgs=self.atomic_graphs)
    #dg = directed graph
    merged_dgs = Marshal.load(Marshal.dump(dgs))
    uniq_dgs = []
    
    until  merged_dgs.empty? do

      eval_dg = merged_dgs.shift
      uniq = true
      
      #check and see if the dg under eval should be merged into 
      #one of the other dgs
      merged_dgs.each do |other_dg| #merge loop

        if eval_dg.connected_to? other_dg
          uniq = false
          other_dg.merge(eval_dg)
          #eval_dg is now part of an existing dg in the merged_dgs array
          
          #we are now merged, and the new merged dg will be checked against the
          #remaining dgs, so there's no reason to continue the loop
          break #exit merge loop
        end
      end
      
      
      if uniq == true #means we went through the entire array without a match
        uniq_uniq = true
        #see if it merges with any thing in the uniq list so far
        uniq_dgs.each do |u_dg|
          if eval_dg.connected_to? u_dg
            uniq_uniq = false
            u_dg.merge(eval_dg)
          end
        end
        uniq_dgs << eval_dg if uniq_uniq
      end
    end
    uniq_dgs.uniq
  end
end
