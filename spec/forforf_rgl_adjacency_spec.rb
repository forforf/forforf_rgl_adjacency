require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module DAGSpecH

 
  ComplexGraph = [ [:aa, :a], [:bc, :bbb], [:bc,:b], [:aaa, :aa], [:b, nil], [:ba,:b],
                 [:ba, :ab], [:ac, :a], [:bbb, :bb], [:bbb, :aaa], [:a, :aa],
                 [:ab, :a], [:ab, :aaa], [:ab, :bb], [:bcc, :bc], [:bb, :b],
                 #this edge is unconnected to the rest of the graph
                 [:cc, :c], [nil, nil], [nil, :d], [:d, nil ] ]
   CGInDegree = { :a   => 3, :b   => 3, :c   => 1,
                  :aa  => 2, :ab  => 1, :ac  => 0,
                  :aaa => 2, 
                  :ba  => 0, :bb  => 2, :bc  => 1,
                  :bbb => 1, :bcc => 0,
                  :cc  => 0,
                  :d => 1,
                  nil => 3 } 

   CGOutDegree = { :a   => 1, :b   => 1, :c   => 0,
                   :aa  => 1, :ab  => 3, :ac  => 1,
                   :aaa => 1,
                   :ba  => 2, :bb  => 1, :bc  => 2,
                   :bbb => 2, :bcc => 1,
                   :cc => 1,
                   :d => 1,
                   nil => 2 } 

   CGTopNodes = [:ba, :ac, :bcc, :cc] 
   CGBestTopNodes = [:bcc] #underneath :bcc => :bc, :bbb, :aaa, :aa, :a, :bb, :b, nil, :d 
   SimpleGraph = [ [:a, :aa], [:a, :ab], [:b, :ba], [:b, :bc] ]
   SimpleGraphCopy = [ [:a, :aa], [:a, :ab], [:b, :ba], [:b, :bc] ]
   SimpleGraphReverse = [ [:aa, :a], [:ab, :a], [:ba, :b], [:bc, :b] ]
end

describe "ForforfRglAdjacency" do
  include DAGSpecH

  before(:each) do
    @complex = ComplexGraph
    @rgl_complex = @complex.flatten
    @complex_indegree = CGInDegree
    @complex_outdegree =CGOutDegree
    @complex_top_nodes = CGTopNodes
    @complex_best_top_nodes = CGBestTopNodes
    @simple = SimpleGraph
    @rgl_simple = @simple.flatten
    @simple_copy = SimpleGraphCopy
    @rgl_simple_copy = @simple_copy.flatten
    @simple_reverse = SimpleGraphReverse
    @rgl_simple_reverse = @simple_reverse.flatten
  end

  it "should initialize" do
    MyDG[*@rgl_complex].should_not == nil
  end

  it "tests for equality" do
    dg_orig = MyDG[*@rgl_simple]
    dg_copy = MyDG[*@rgl_simple_copy]
    dg_orig.hash.should == dg_copy.hash
    same = dg_orig.eql?(dg_copy)
    same.should == true
    dg_diff = MyDG[*@rgl_simple_reverse]
    diff = dg_diff.eql?(dg_orig)
    diff.should == false
  end

  it "counts in-degree" do
    dg = MyDG[*@rgl_complex]
    in_degrees = {}
    @rgl_complex.each do |vert|
      in_degrees[vert] = dg.in_degree(vert)
    end
    in_degrees.should == @complex_indegree 
  end

  it "counts out-degree" do
    dg = MyDG[*@rgl_complex]
    out_degrees = {}
    @rgl_complex.each do |vert|
      out_degrees[vert] = dg.out_degree(vert)
    end
    out_degrees.should == @complex_outdegree
  end

  it "finds nodes with no parents" do
    dg = MyDG[*@rgl_complex]
    dg.nodes_with_no_parents.should == @complex_top_nodes
  end

  it "finds the best top nodes (nodes with th most children)" do
    dg = MyDG[*@rgl_complex]
    dg.best_top_nodes.should == @complex_best_top_nodes
  end

  it "provides its edges as a nested array" do
    dg = MyDG[*@rgl_complex]
    #nils in arrays are kind of a pain
    dg_edges = dg.edge_array.flatten
    complex_edges = @complex.flatten
    #replace nils with :znull
    bye_nil = lambda{|e| e || :znull}
    dg_edges.map! &bye_nil
    complex_edges.map! &bye_nil
    dg_edges.sort.should == complex_edges.sort
  end

  it "isn't complete yet" do
    fail "need to add tests for 6 more methods"
  end

  
end
