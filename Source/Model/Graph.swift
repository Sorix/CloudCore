//
//  Graph.swift
//  CloudCore
//
//  Created by Juan Ignacio on 3/21/18.
//  Copyright © 2018 Vasily Ulianov. All rights reserved.
//

// Part of this code are from the SwiftGraph project: https://github.com/davecom/SwiftGraph
class Graph {
    
    var vertices : [String]
    var edges = [String:[String]]()
    
    init(vertices:[String]) {
        self.vertices = vertices
        vertices.forEach {
            self.edges[$0] = [String]()
        }
    }
    
    func addEdge(from:String, to:String) {
        edges[from]!.append(to)
    }
    
    func indexOfVertex(_ v:String) -> Int? {
        return vertices.index(of: v)
    }
    
    func neighborsForVertex(_ v:String) -> [String]? {
        return edges[v]
    }
    
    func detectCycles() -> [[String]] {
        var cycles = [[String]]() // store of all found cycles
        var openPaths: [[String]] = vertices.map{ [$0] } // initial open paths are single vertex lists
        
        while openPaths.count > 0 {
            let openPath = openPaths.removeFirst() // queue pop()
            //if openPath.count > maxK { return cycles } // do we want to stop at a certain length k
            if let tail = openPath.last, let head = openPath.first {
                let neighbors = neighborsForVertex(tail)!
                for neighbor in neighbors {
                    
                    if neighbor == head {
                        cycles.append(openPath + [neighbor]) // found a cycle
                    } else if !openPath.contains(neighbor) && indexOfVertex(neighbor)! > indexOfVertex(head)! {
                        openPaths.append(openPath + [neighbor]) // another open path to explore
                    }
                }
            }
        }
        return cycles
    }
    
    
    func topologicalSort() -> [String]? {
        var sortedVertices = [String]()
        let tsNodes = vertices.map{ TSNode<String>(vertex: $0, color: .white) }
        var notDAG = false
        
        func visit(_ node: TSNode<String>) {
            guard node.color != .gray else {
                notDAG = true
                return
            }
            if node.color == .white {
                node.color = .gray
                for inode in tsNodes where (neighborsForVertex(node.vertex)?.contains(inode.vertex))! {
                    visit(inode)
                }
                node.color = .black
                sortedVertices.insert(node.vertex, at: 0)
            }
        }
        
        for node in tsNodes where node.color == .white {
            visit(node)
        }
        
        if notDAG {
            return nil
        }
        
        return sortedVertices
    }
    
    fileprivate enum TSColor { case black, gray, white }
    
    fileprivate class TSNode<String> {
        fileprivate let vertex: String
        fileprivate var color: TSColor
        
        init(vertex: String, color: TSColor) {
            self.vertex = vertex
            self.color = color
        }
    }
}

